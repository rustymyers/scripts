#!/bin/bash

# Uninstaller for Ensure Tracking scripts
# This script will remove these files:
# 	/bin/isightcapture		- http://www.intergalactic.de/pages/iSight.html
#	/bin/tracking.sh		- This script. rustymyers@gmail.com
#	/bin/sendEmail			- http://caspian.dotconf.net/menu/Software/SendEmail/
#	/Library/LaunchDaemons/edu.psu.educ.ensure.plist
#	/Library/Track/			- Contains all logs and pictures

if [ "$(id -u)" != "0" ]; then
	#Run as root if linking files
	echo "This script must be run as root"
	exit 1
fi

# Remove all files
rm /bin/isightcapture
rm /bin/tracking.sh
rm /bin/sendEmail	
rm /Library/LaunchDaemons/edu.psu.educ.ensure.plist
rm -R /Library/Track/

echo "All files removed for Ensure Tracking"
exit 0