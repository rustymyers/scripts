#!/bin/bash
# Variables
# Server to connect to:
psuserver="smb://udrive.win.psu.edu/sysman/ED-IT-ETC/"

if [[ `cat /Library/Preferences/edu.mit.Kerberos | grep educ` = "" ]]; then
		echo "Using PSU kerb file."
		kerbfile=PSU
		altkerb=EDUC
	else
		echo "Using EDUC kerb file."
		kerbfile=EDUC
		altkerb=PSU
fi

#Ask for PSU Access ID (abc1234) with Applescript
# DoSwitch=`/usr/bin/osascript << EOT
# tell application "System Events"
# 	display dialog "Do you want to switch from $kerbfile to $altkerb? y or n" default answer "y"  buttons ["OK"] default button "OK" 
# 	set result to text returned of result
# end tell
# EOT`
# echo $DoSwitch
echo "Do you want to switch from $kerbfile to $altkerb?"
echo "y or n"
read answer

if [[ $answer != "y" && $answer != "n" ]]; then
	echo "Please enter a lower case y or n to make your choice."
	exit 1
fi

if [[ $answer = "y" && $kerbfile = "PSU" ]]; then
	# Move PSU out of way and put EDUC kerb file in place
	mv /Library/Preferences/edu.mit.Kerberos /Library/Preferences/edu.mit.Kerberos.psu
	mv /Library/Preferences/edu.mit.Kerberos.educ /Library/Preferences/edu.mit.Kerberos
	# Conver to simple message
	echo "You are now using the EDUC kerberos file."
elif [[ $answer = "y" && $kerbfile = "EDUC" ]]; then
	# Move EDUC out of way and put PSU kerb file in place
	mv /Library/Preferences/edu.mit.Kerberos /Library/Preferences/edu.mit.Kerberos.educ
	mv /Library/Preferences/edu.mit.Kerberos.psu /Library/Preferences/edu.mit.Kerberos
	# Conver to simple message
	echo "You are now using the PSU kerberos file."
	# Conver to applescript variable
	echo "Would you like to connect to $psuserver? y or n"
	read connectserver
	if [[ $connectserver = "y" ]]; then
		if [[ `klist | grep dce.psu.edu` = "" ]]; then
			echo | kinit
		fi
		#kinit $USER\@dce.psu.edu
		# connect to smb://udrive.win.psu.edu/sysman
		osascript -e "try" -e "mount volume \"$psuserver\"" -e "end try"
		else
		# Conver to simple message
		echo "No Mounts"
		exit 0
	fi
	
else
	exit 0
fi