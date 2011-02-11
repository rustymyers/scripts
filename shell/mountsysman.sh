#!/bin/bash
# Variables
# Server to connect to:
psuserver="smb://udrive.win.psu.edu/sysman"
domain="dce.psu.edu"

if [[ `cat /Library/Preferences/edu.mit.Kerberos | grep educ` = "" ]]; then
		echo "Using PSU kerberos file."
		kerbfile=PSU
		altkerb=EDUC
	else
		echo "Using EDUC kerberos file."
		kerbfile=EDUC
		altkerb=PSU
fi

# Make PSU kerberos file

if [[ -e /Library/Preferences/edu.mit.Kerberos.psu ]]; then
	echo "PSU File avail"
else
	echo "[domain_realm]
	.psu.edu = dce.psu.edu
	psu.edu = dce.psu.edu

[libdefaults]
	default_realm = dce.psu.edu
	dns_lookup_kdc = true
	forwardable = true
	noaddresses = true" > /Library/Preferences/edu.mit.Kerberos.psu
fi



connectserver=`/usr/bin/osascript << EOT
tell application "System Events"
	display dialog "Would you like to connect to $psuserver? y or n" default answer "y"  buttons ["OK"] default button "OK" 
	set result to text returned of result
end tell
EOT`

echo "You chose $connectserver"
	
if [[ $connectserver != "y" && $connectserver != "n" ]]; then
	# echo "Please enter a lower case y or n to make your choice."
	/usr/bin/osascript -e "tell application \"System Events\"" -e "display dialog \"Please enter a lower case y or n to make your choice.\" buttons [\"OK\"] default button \"OK\"" -e "end tell"	
	exit 1
fi


if [[ $connectserver = "y" && $kerbfile = "EDUC" ]]; then
	# Move EDUC out of way and put PSU kerb file in place
	echo "move educ out of the way"
	mv /Library/Preferences/edu.mit.Kerberos /Library/Preferences/edu.mit.Kerberos.educ
	echo "put in psu kerb file"
	mv /Library/Preferences/edu.mit.Kerberos.psu /Library/Preferences/edu.mit.Kerberos
	
	if [[ `klist | grep dce.psu.edu` = "" ]]; then
		echo | kinit $USER@$domain
	else
		echo "We have a kerb ticket"
	fi
	
	echo "trying to mount server"
	osascript -e "try" -e "mount volume \"$psuserver\"" -e "end try"
	/usr/bin/osascript -e "tell application \"System Events\"" -e "display dialog \"Mount successful.\" buttons [\"OK\"] default button \"OK\"" -e "end tell"

	# Move PSU out of way and put EDUC kerb file in place
	echo "put away psu kerb file"
	mv /Library/Preferences/edu.mit.Kerberos /Library/Preferences/edu.mit.Kerberos.psu
	echo "put back educ kerb file"
	mv /Library/Preferences/edu.mit.Kerberos.educ /Library/Preferences/edu.mit.Kerberos
	exit 0
else
	/usr/bin/osascript -e "tell application \"System Events\"" -e "display dialog \"Mount unsuccessful.\" buttons [\"OK\"] default button \"OK\"" -e "end tell"

fi
