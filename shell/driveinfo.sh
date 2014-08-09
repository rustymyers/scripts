#!/bin/bash

# Written by Rusty Myers
# 20111003

# Script to gather data on Mac

INTERNAL_DRIVE=`system_profiler SPSerialATADataType | awk -F': ' '/Mount Point/ { print $2}'|head -n1`

echo -e "Gathering Data for $INTERNAL_DRIVE\r" >> ~/Desktop/Inventory.txt
# Gather Data
Model=`system_profiler SPHardwareDataType|awk -F': ' '/Model Identifier/ { print $2 }'`
Serial=`system_profiler SPHardwareDataType|awk -F': ' '/Serial Number/ { print $2 }'`

# Print out data
if [[ -e "$INTERNAL_DRIVE"/Library/Preferences/SystemConfiguration/preferences.plist ]];then 
	CompName=`/usr/libexec/PlistBuddy "$INTERNAL_DRIVE"/Library/Preferences/SystemConfiguration/preferences.plist -c "print :System:System:ComputerName"`
	echo -e "Name:	$CompName" >> ~/Desktop/Inventory.txt
else
	echo "Name:	None" >> ~/Desktop/Inventory.txt
fi
echo "Model:	$Model" >> ~/Desktop/Inventory.txt
echo "Serial:	$Serial" >> ~/Desktop/Inventory.txt
if [[ -e "$INTERNAL_DRIVE"/var/radmind/cert/cert.pem ]]; then
	Cert=`ls -l "$INTERNAL_DRIVE"/var/radmind/cert/cert.pem | awk '{print $11}'| awk -F'/' '{print $3}'`
	echo "Cert:	$Cert" >> ~/Desktop/Inventory.txt
else
	echo "Cert:	None" >> ~/Desktop/Inventory.txt
fi
echo ""  >> ~/Desktop/Inventory.txt

exit 0
