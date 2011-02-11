#!/bin/sh

# This script binds to AD and configures advanced options of the AD plugin
# As this scripts contains a password, be sure to take appropriate security
# precautions
# 
# A good way to run this script is to set it as a login hook on your master machine
# Because it only needs to be run once, the last thing this script does is to delete
# itself. If you have another login script that you typically run, include the 
# script on your master machine, and indicate its path in the "newLoginScript"
# variable.
#
# If running this as a one-time login hook to bind to AD after imaging,
# be sure to enable auto-login (for any local user) before creating your master image


# Host-specific parameters
# computerid should be set dynamically, this value must be machine-specific
# This value may be restricted to 19 characters! The only error you'll receive upon entering
# an invalid computer id is to the effect of not having appropriate privileges to perform the requested operation
#computerid=`/sbin/ifconfig en0 | awk '/ether/ { gsub(":", ""); print $2 }'` # MAC Address
#computerid=`hostname`
#computerid=`/usr/sbin/scutil --get LocalHostName | cut -c 1-19` # Assure that this will produce unique names!
computerid=`/usr/sbin/scutil --get LocalHostName`

# Standard parameters
domain=""			# fully qualified DNS name of Active Directory Domain
udn=""			# username of a privileged network user
password=""					# password of a privileged network user
odudn=""			# username of a privileged network user
odpassword=""					# password of a privileged network user
ou=""		# Distinguished name of container for the computer
odserver=""			#OD Server

# Advanced options
alldomains="enable"		# 'enable' or 'disable' automatic multi-domain authentication
localhome="disable"			# 'enable' or 'disable' force home directory to local drive
protocol="afp"				# 'afp' or 'smb' change how home is mounted from server
mobile="disable"			# 'enable' or 'disable' mobile account support for offline logon
mobileconfirm="disable"		# 'enable' or 'disable' warn the user that a mobile acct will be created
useuncpath="enable"			# 'enable' or 'disable' use AD SMBHome attribute to determine the home dir
user_shell="/bin/bash"		# e.g., /bin/bash or "none"
preferred="-nopreferred"	# Use the specified server for all Directory lookups and authentication
							# (e.g. "-nopreferred" or "-preferred ad.server.edu")
admingroups=""				# These comma-separated AD groups may administer the machine (e.g. "" or "APPLE\mac admins")
packetsign="allow"			# allow | disable | require
packetencrypt="allow"		# allow | disable | require
passinterval="14"			# number of days
namespace="domain"			# forest | domain

# Login hook setting -- specify the path to a login hook that you want to run instead of this script
newLoginHook=""		# e.g., "/Library/Management/login.sh"


### End of configuration

#Add LDAPv3 to od server

odcsp="/LDAPv3/$odserver"

# Activate the AD plugin
defaults write /Library/Preferences/DirectoryService/DirectoryService "Active Directory" "Active"
plutil -convert xml1 /Library/Preferences/DirectoryService/DirectoryService.plist

# Bind to AD
dsconfigad -f -a $computerid -domain $domain -u $udn -p "$password" -ou "$ou"

# Bind to OD

sleep 10
dsconfigldap -v -f -a "$odserver" -n "$odserver" -c $computerid -u $odudn -p "$odpassword"
sleep 20

# Configure advanced AD plugin options
if [ "$admingroups" = "" ]; then
	dsconfigad -nogroups
else
	dsconfigad -groups "$admingroups"
fi

dsconfigad -alldomains $alldomains -localhome $localhome -protocol $protocol \
	-mobile $mobile -mobileconfirm $mobileconfirm -useuncpath $useuncpath \
	-shell $user_shell $preferred -packetsign $packetsign -packetencrypt $packetencrypt \
	-passinterval $passinterval -namespace $namespace

# Restart DirectoryService (necessary to reload AD plugin activation settings)
killall DirectoryService

# Add the AD node to the search path
if [ "$alldomains" = "enable" ]; then
	csp="/Active Directory/All Domains"
else
	csp="/Active Directory/$domain"
fi

dscl "/Active Directory/All Domains" -list /Computers > /dev/null
sleep 10
dscl /Search -append / CSPSearchPath "$csp"
dscl /Search -create / SearchPolicy dsAttrTypeStandard:CSPSearchPath
dscl /Search/Contacts -append / CSPSearchPath "$csp"
dscl /Search/Contacts -create / SearchPolicy dsAttrTypeStandard:CSPSearchPath

dscl /Search -append / CSPSearchPath "$odcsp"
dscl /Search/Contacts -append / CSPSearchPath "$odcsp"



# This works in a pinch if the above code does not
#defaults write /Library/Preferences/DirectoryService/SearchNodeConfig "Search Node Custom Path Array" -array "/Active Directory/All Domains"
#defaults write /Library/Preferences/DirectoryService/SearchNodeConfig "Search Policy" -int 3
#plutil -convert xml1 /Library/Preferences/DirectoryService/SearchNodeConfig.plist
#killall DirectoryService


# Destroy the login hook (or change it)
if [ "${newLoginHook}" == "" ]; then
	defaults delete /var/root/Library/Preferences/com.apple.loginwindow LoginHook
else
	defaults write /var/root/Library/Preferences/com.apple.loginwindow LoginHook $newLoginHook
fi


# Disable autologin
defaults delete /Library/Preferences/com.apple.loginwindow autoLoginUser
srm /etc/kcpassword

# Kill loginwindow to return to the login screen
#killall loginwindow

# Destroy this script!
#srm "$0"
