# remove this line; added to prevent possible RFI <?php exit(254); ?>
#!/bin/bash

# The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO WARRANTIES, 
# EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED WARRANTIES OF NON-
# INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING THE APPLE 
# SOFTWARE OR ITS USE AND OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS. 
#
# IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR CONSEQUENTIAL 
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS 
# OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, 
# REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND 
# WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR 
# OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# admachcrt.sh

#
# Script to auto-enroll an OS X system via an AD CA's web enrollment.
#

# v. .13e

## Constants

# OS Version in preparation of bifurcating handling 802.1X profiles.
OS_VER=`sw_vers | awk '/ProductVersion/ { print $2 }'`

# The URL of the CA web enrollment page.
# Would be great to find a way to programmatically find this out...
# Ensure this is a FQDN, to make Kerberos work better
CA_URL="http://172.16.10.1/certsrv"

# Certificate template to be used.
CERT_TYPE_MACHINE="CompCert"
CERT_TYPE_USER="UserCert"

CERT_TO_INSTALL="EMPTY"

## Create a temp directory and then use that for staging.

TEMP_DIR=`mktemp -d -t autoenroll`

KEY="${TEMP_DIR}/autoenroll.key"
CSR="${TEMP_DIR}/autoenroll.csr"
DER="${TEMP_DIR}/autoenroll.der"
PEM="${TEMP_DIR}/autoenroll.pem"
PK12="${TEMP_DIR}/autoenroll.p12"
CA_CERT="${TEMP_DIR}/autoenroll-ca.crt"
OPENSSL_CONF="${TEMP_DIR}/openssl.conf"
MY1xCONF="${TEMP_DIR}/1xConf.networkConnect"

## Defaults

SERVER_STYLE="2k3"
CERT_STYLE="MACHINE"
NETWORK_SERVICE="Airport"
PROFILE_PATH=
SECURE_IMPORT="NO"
EVAL_CERT="NO"

## Get any supplied options.

while getopts k:c:p:l:m:t:n:s:u:i:exh? SWITCH
do
	case $SWITCH in
		k) KEYCHAIN_PATH=$OPTARG;;
		c) CERT_TEMP=$OPTARG;;
		p) PROFILE_PATH=$OPTARG;;
		s) NETWORK_SERVICE=$OPTARG;;
		l) CA_URL=$OPTARG;;
		m) CERT_TYPE_MACHINE=$OPTARG;;
		t) CERT_TYPE_USER=$OPTARG;;
		u) CERT_STYLE=${OPTARG:="USER"};;
		i) CERT_TO_INSTALL=$OPTARG;;
		x) SECURE_IMPORT="YES";;
		e) EVAL_CERT="YES";;
		?) USAGE=YES;;
		h) USAGE=YES;;
		*) USAGE=YES;;
	esac
done

# Functions

## Check to ensure wer're bound to AD and exit if not.
check_bind_and_name() {
	BIND_STATUS=$(dsconfigad -show | sed -n 2p)
	if [ "$BIND_STATUS" != "You are bound to Active Directory:" ]; then
		echo "You aren't bound to AD!"
		exit 78; # EX_CONFIG
	fi
	
	# We're bound, so get the machine name from AD.
	DOMAIN_NAME=`/usr/sbin/dsconfigad -show | grep "Active Directory Domain" | awk '{ print $5 }'`
	MACHINE_NAME=`/usr/sbin/dsconfigad -show | grep "Computer Account" | awk '{ print $4 }'`
}

## Check to ensure we have a user TGT
check_tgt() {
	### CHANGE ME - ADD LOGIC TO ENSURE NON-ZERO result
	MY_TGT_NAME=`klist | grep Default | awk '{ print $3 }'`
}

## Generate csr with openssl for a machine
generate_csr_machine() {
	/usr/bin/openssl req -new -batch -newkey rsa:2048 -nodes -keyout "${KEY}" -out "${CSR}" -subj "/CN=${MACHINE_NAME}.${DOMAIN_NAME}"
}

## Generate csr with openssl for a user
generate_csr_user() {
	/usr/bin/openssl req -new -batch -newkey rsa:2048 -nodes -keyout "${KEY}" -out "${CSR}" -subj "/CN=${MY_TGT_NAME}"
}

## Get TGT via kinit - If 2k3, use password method if 2k8
get_tgt_kinit() {
	/usr/bin/kinit -k ${MACHINE_NAME}$
}

## Get TGT via password
get_tgt_password() {
	
		AD_PASS=$(defaults read /Library/Preferences/DirectoryService/ActiveDirectory "AD Computer Password" | xxd -r -p)

		expect <<EOF
			spawn /usr/bin/kinit ${MACHINE_NAME}$
			expect "Please enter the password"
			send -- "${AD_PASS}\r"
			expect eof
EOF
}

## curl the csr up
curl_csr() {
# First we do some really really ugly-looking awk work to url-encode the csr
# Later versions of curl do this for us... but we don't have that luxury.

ENCODED_CSR=`cat ${CSR} | hexdump -v -e '1/1 "%02x\t"' -e '1/1 "%_c\n"' |
LANG=C awk '
    $1 == "20"                      { printf("%s",      "+");   next    }
    $2 ~  /^[a-zA-Z0-9.*()\/-]$/    { printf("%s",      $2);    next    }
                                    { printf("%%%s",    $1)             }'`


	# Now to post this to the Web Enrollment page.
	# We'll need to capture the ReqID when it finishes. If it's a 2k8 domain, we just don't use it.
	# New method 11-03-2009
	REQ_ID=`curl --negotiate -u : -d CertRequest=${ENCODED_CSR} -d SaveCert=yes -d Mode=newreq -d CertAttrib=CertificateTemplate:"${CERT_TYPE}" ${CA_URL}/certfnsh.asp | grep ReqID | sed -e 's/.*ReqID=\(.*\)&amp.*/\1/g'`
	echo REQ_ID is ${REQ_ID}
		
	# Verify if we actually have a request ID - if not, we need to bail.
	if [ ! "$REQ_ID" ]; then 
		echo "WARNING: I didn't receive a request ID from the Certificate Authority."
		echo "This likely means the certificate request failed - please contact your administrator."
		exit 69; #EX_UNAVAILABLE
	fi

}

## curl down the cert if it's a 2k3 domain
curl_cert() {
	#NOTE: 	curl accepts whatever cert the server is using, to make it more likely to work in different
	#		environments. Also this pulls the cert down in PEM format, which needs to be converted into a
	# 		PKCS12 file and then imported into the keychain.
	##
	echo CRT is ${CRT}, CA_USR is ${CA_URL}
	echo curl -k -o ${CRT} --negotiate -u : "${CA_URL}/certnew.cer?ReqID=${REQ_ID}&Enc=b64"
	curl -k -o ${PEM} -A "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.9.0.5) Gecko/2008120122 Firefox/3.0.5" --negotiate -u : "${CA_URL}/certnew.cer?ReqID=${REQ_ID}&Enc=b64"
}

eval_cert() {
	# Find out if cert is trusted
	if [ ! "`security verify-cert -c ${PEM} | grep "successful"`" ]; then
		CA_URL=`openssl x509 -in ${PEM} -text | grep "CA Issuers - URI:http://" | awk '{ print $4 }' | sed 's/URI://'`
		curl -o ${CA_CERT} ${CA_URL}
		## I currently limit this to just the X.509 basic policy, else all policies are trusted.
		/usr/bin/security add-trusted-cert -d -p basic -k ${KEYCHAIN_PATH} ${CA_CERT}
	fi
}

add_cert() {
	# General tool for adding in certs by hand if so desired.
	if [ -f ${CERT_TO_INSTALL} ]; then
		/usr/bin/security add-trusted-cert -d -p eap -k ${KEYCHAIN_PATH} ${CERT_TO_INSTALL}
	else
		echo "WARNING: ${CERT_TO_INSTALL} doens't exist."
	fi
}

## Pack the cert up and import it ito the keyhcain
pack_and_import() {
	## Build the cert and private key into a PKCS12
	openssl pkcs12 -export -in ${PEM} -inkey ${KEY} -out ${PK12} -name "$MACHINE_NAME" -passout pass:pass

	if [ "SECURE_IMPORT" = "YES" ]; then
		/usr/bin/security -x import ${PK12} -k ${KEYCHAIN_PATH} -f pkcs12 -P pass 
	else
		/usr/bin/security import ${PK12} -k ${KEYCHAIN_PATH} -f pkcs12 -P pass 
	fi
}

## Import 802.1X profile and associate TLS identity with it
import_and_associate_machine(){
	networksetup -import8021xProfiles ${NETWORK_SERVICE} ${PROFILE_PATH}
	networksetup -settlsidentityonsystemprofile ${NETWORK_SERVICE} ${PK12} pass
}

## Import 802.1X profile and associate TLS identity with it
import_and_associate_user(){
	networksetup -import8021xProfiles ${NETWORK_SERVICE} ${PROFILE_PATH}
	networksetup -settlsidentityonuserprofile ${NETWORK_SERVICE} ${PK12} pass	
}

## If you have particular configuration needs when generating the CSR you can build and use an OpenSSL config file here

build_openssl.conf(){
echo > ${OPENSSL_CONF} "	[ req ]
	default_bits            = 2048
	default_md              = sha1
	#default_keyfile         = key.pem
	distinguished_name      = req_distinguished_name
	prompt                  = no
	string_mask             = nombstr
	req_extensions          = v3_req

	[ req_distinguished_name ]
	countryName             = US
	stateOrProvinceName     = CA
	organizationName        = Your Company Here
	organizationalUnitName  = ITS
	commonName              = ${MACHINE_NAME}.${DOMAIN_NAME}


	[ v3_req ]
	basicConstraints        = CA:FALSE
	keyUsage                = nonRepudiation, digitalSignature, keyEncipherment
	subjectAltName          = @alt_names

	[ alt_names ]
	DNS.1 = ${MACHINE_NAME}.${DOMAIN_NAME}"
}

## You can put your 1x profile in here after exporting it from System Preferences or using networksetup

build_1xconfig(){
echo > ${MY1xCONF} "	<?xml version="1.0" encoding="UTF-8"?>
	<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
	<plist version="1.0">
	<dict>
		<key>8021X</key>
		<dict>
			<key>SystemProfiles</key>
			<array>
				<dict>
					<key>EAPClientConfiguration</key>
					<dict>
						<key>AcceptEAPTypes</key>
						<array>
							<integer>13</integer>
						</array>
						<key>UserName</key>
						<string>host/${MACHINE_NAME}.${DOMAIN_NAME}</string>
						<key>Wireless Network</key>
						<string>YourSSIDHere</string>
					</dict>
					<key>UserDefinedName</key>
					<string>System Profile</string>
				</dict>
			</array>
		</dict>
	</dict>
	</plist>"
}

usage(){
	SCRIPT=`basename $0`
	cat <<EOF
    Summary:
      Manages identities and 802.1X profile for EAP-TLS authentication.
      It currently only works with a Microsoft Certificate Services CA.
      
    Usage:
    $SCRIPT [ -? ]
     -k <PATH>       : Path to the target keychain. 
                       The default is the system keychain for MACHINE identities
                       and the user's default keychain for USER identities.
     -c <PATH>       : TBD
     -p <PATH>       : Path to the 802.1X profile to be imported.
     -s <Interface>  : Target network interface for the 802.1X profile.
                       The default is Airport.
     -l <URL>        : URL to the target Certificate Authority. 
                       NOTE: You must use HTTP vs. HTTPS unless the CA's
                       root certificate is already trusted.
     -m <TEMPLATE>   : Cert template to use for machine identity requests.
     -t <TEMPLATE>   : Cert template to use for user identity requests.
     -i <PATH>       : RADIUS cert to install into the System Keychain with 
                       the EAP trust policy. This is optional.
     -u <STYLE>      : Defines the identity type to request, MACHINE or USER.
                       The default is MACHINE.
     -x <YES|NO>     : Prevent the identity's private key from being exported 
                       from the keychain. The default is "YES".
     -e <YES|NO>     : Flags whether to evalute if the identitiy is trusted 
                       or not. If not the script will pull down the CA's 
                       root cert and set full trust. The default is "NO".
    e.g.
     $ $SCRIPT -m "Computer Template" -l "http://ca.mydomain.lan/certsrv"

     Add a RADIUS server certificate to the System keychain with EAP trust settings:

     $ $SCRIPT -i ~/Desktop/myradius_server.crt

EOF

}
	
## Actual script here:

if [ "$USAGE" == "YES" ]; then
	usage
	exit 0
fi

if [ "${CERT_TO_INSTALL}" != "EMPTY" ]; then
	## I assume you only want to add the cert and exit afterwards.
	add_cert
	exit 0
fi


if [ "$CERT_STYLE" = "MACHINE" ]; then
	# Set keychain to the system keychain if not otherwise specified
	[ "${KEYCHAIN_PATH}" = "" ] && KEYCHAIN_PATH="/Library/Keychains/System.keychain"
	check_bind_and_name
	generate_csr_machine
	# TPH - 07-21-2009
	CERT_TYPE=${CERT_TYPE_MACHINE}
	get_tgt_kinit
	curl_csr
	curl_cert
	[ "${EVAL_CERT}" == "YES" ] && eval_cert
	[ -n "${PROFILE_PATH}" ] && import_and_associate_machine
else
	check_tgt
	generate_csr_user
	CERT_TYPE=${CERT_TYPE_USER}
	curl_csr
	curl_cert
	# set the keychain to the default user keychain if not otherwise specified
	[ "${KEYCHAIN_PATH}" = "" ] && KEYCHAIN_PATH=`security default-keychain | sed -e 's/"//g'`
	[ "${EVAL_CERT}" == "YES" ] && eval_cert
	[ -n "${PROFILE_PATH}" ] && import_and_associate_user
fi

pack_and_import
srm ${TEMP_DIR}

## TO DO

# Wire up cert eval and ensure CA cert can be added --this should be optional since we won't be getting the radius server's cert, but the CA's and admins' may not want it trusted for all policies.
# Long term - think about using MCX to supply defaults