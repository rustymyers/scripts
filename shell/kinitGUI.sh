#!/bin/bash
# Variables
# Server to connect to:
psuserver="smb://udrive.win.psu.edu/sysman"
sharename="sysman"

if [[ `cat /Library/Preferences/edu.mit.Kerberos | grep educ` = "" ]]; then
		echo "Using PSU kerberos file."
		kerbfile=PSU
		altkerb=EDUC
	else
		echo "Using EDUC kerberos file."
		kerbfile=EDUC
		altkerb=PSU
fi

#Ask for PSU Access ID (abc1234) with Applescript
DoSwitch=`/usr/bin/osascript << EOT
tell application "System Events"
	display dialog "Do you want to switch from $kerbfile to $altkerb? y or n" default answer "y"  buttons ["OK"] default button "OK" 
	set result to text returned of result
end tell
EOT`
echo $DoSwitch
# echo "Do you want to switch from $kerbfile to $altkerb?"
# echo "y or n"
# read answer
function checkanswer {
if [[ $DoSwitch != "y" && $DoSwitch != "n" ]]; then
	# echo "Please enter a lower case y or n to make your choice."
	/usr/bin/osascript -e "tell application \"System Events\"" -e "display dialog \"Please enter a lower case y or n to make your choice.\" buttons [\"OK\"] default button \"OK\"" -e "end tell"	
	exit 1
fi
}

checkanswer

if [[ $DoSwitch = "y" && $kerbfile = "PSU" ]]; then
	# Move PSU out of way and put EDUC kerb file in place
	mv /Library/Preferences/edu.mit.Kerberos /Library/Preferences/edu.mit.Kerberos.psu
	mv /Library/Preferences/edu.mit.Kerberos.educ /Library/Preferences/edu.mit.Kerberos
	# Conver to simple message
	/usr/bin/osascript -e "tell application \"System Events\"" -e "display dialog \"You are now using the EDUC kerberos file.\" buttons [\"OK\"] default button \"OK\"" -e "end tell"	
	exit 1
elif [[ $DoSwitch = "y" && $kerbfile = "EDUC" ]]; then
	# Move EDUC out of way and put PSU kerb file in place
	mv /Library/Preferences/edu.mit.Kerberos /Library/Preferences/edu.mit.Kerberos.educ
	mv /Library/Preferences/edu.mit.Kerberos.psu /Library/Preferences/edu.mit.Kerberos
	# Conver to simple message
	/usr/bin/osascript -e "tell application \"System Events\"" -e "display dialog \"You are now using the PSU kerberos file.\" buttons [\"OK\"] default button \"OK\"" -e "end tell"	
	# Conver to applescript variable
	#echo "Would you like to connect to $psuserver? y or n"
connectserver=`/usr/bin/osascript << EOT
tell application "System Events"
	display dialog "Would you like to connect to $psuserver? y or n" default answer "y"  buttons ["OK"] default button "OK" 
	set result to text returned of result
end tell
EOT`
	echo "You chose $connectserver"
	
	if [[ $connectserver = "y" ]]; then
		echo | kinit
		#kinit $USER\@dce.psu.edu
		# connect to smb://udrive.win.psu.edu/sysman
		osascript -e "try" -e "mount volume \"$psuserver\"" -e "end try"
		exit 0
		else
		# Conver to simple message
		/usr/bin/osascript -e "tell application \"System Events\"" -e "display dialog \"No mounts.\" buttons [\"OK\"] default button \"OK\"" -e "end tell"
		exit 0
	fi
	
else
	exit 0
fi