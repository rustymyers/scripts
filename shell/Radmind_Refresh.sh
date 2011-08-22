#!/bin/bash

# Written by Rusty Myers
# 20110720

# Run radmind refresh on this Mac now
# Run as sudo

if [ "$(id -u)" != "0" ]; then
	#Must run as root
	echo "This script must be run as root"
	exit 1
fi

systemsetup -setdisplaysleep 0 ; rm -rf /Library/PSUtemp/psuCurrentUser.dat ; /Library/PSUadmin/hooks/psuRunMaint.hook root no_sleep >> /Library/PSUlog/psu.log 2>&1

exit 0
