#!/bin/bash

# Requires:
# 	/bin/isightcapture		- http://www.intergalactic.de/pages/iSight.html
#	/bin/tracking.sh		- This script. rustymyers@gmail.com
#	/bin/sendEmail			- http://caspian.dotconf.net/menu/Software/SendEmail/
#	/Library/LaunchDaemons/org.ensure.plist

# Writes Logs to /Library/Track/MACADDRESS.txt

MACADD=`networksetup -getmacaddress Ethernet | awk '{print $3}'|tr -d ':'`
DATE=`date "+%Y%m%d%H%M%S"`
# script to record computer data.
# If the computer doen't have the Tracking folder,
if [[ ! -e /Library/Track/ ]]; then
	# Create the directory
	/bin/mkdir -p /Library/Track
fi

# Touch log file if it doesn't exist
if [[ ! -e "/Library/Track/$MACADD.txt" ]]; then
	LOGFILE="/Library/Track/$MACADD"
	/usr/bin/touch "$LOGFILE"
fi

# Write all data to "$LOGFILE"
# Gather public IP, Users loged in, iSight picture

# Start with Seperator and Date
echo -e "####################################################" >> "$LOGFILE"
echo -e "##LOG FILE: $DATE" >> "$LOGFILE"
echo -e "####################################################" >> "$LOGFILE"
echo -e "" >> "$LOGFILE"

# iSight Picture
PIC="/Library/Track/isight$DATE.jpg"
/bin/isightcapture $PIC && echo -e "iSight Picture Saved" >> "$LOGFILE"
echo -e "" >> "$LOGFILE"

# Screen Capture
SCREEN="/Library/Track/screen$DATE.jpg"
/usr/sbin/screencapture -x "$SCREEN" && echo -e "Screen Capture Saved $SCREEN" >> "$LOGFILE"
echo -e "" >> "$LOGFILE"

# Tar internet cache
# TARFILE="/Library/Track/cache$DATE.tar"
# tar -czf $TARFILE /Users/*/Library/Caches/Metadata/Safari /Users/*/Library/Caches/Firefox && echo -e "Browser Cache Saved" >> "$LOGFILE"
# echo -e "" >> "$LOGFILE"

# Public IP
echo -e "Public IP Address:"  >> "$LOGFILE"
echo -e "####################################################" >> "$LOGFILE"
/usr/bin/curl -s http://checkip.dyndns.org | sed 's/[a-zA-Z/<> :]//g' >> "$LOGFILE"
echo -e "####################################################" >> "$LOGFILE"
echo -e "" >> "$LOGFILE"

# Users loged in
echo -e "Users Logged In" >> "$LOGFILE"
echo -e "####################################################" >> "$LOGFILE"
who -a >> "$LOGFILE"
echo -e "####################################################" >> "$LOGFILE"
echo -e "" >> "$LOGFILE"

# Airport and Wireless information dump
echo -e "Wireless information saved" >> "$LOGFILE"
echo -e "####################################################" >> "$LOGFILE"
/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -Is  >> "$LOGFILE"
echo -e "####################################################" >> "$LOGFILE"
echo -e "" >> "$LOGFILE"

# Files modified in the last 5 minutes
echo -e "Finding files modified in the last 5 minutes" >> "$LOGFILE"
echo -e "####################################################" >> "$LOGFILE"
find /Users -mmin -5 >> "$LOGFILE"
echo -e "####################################################" >> "$LOGFILE"
echo -e "" >> "$LOGFILE"


# Package log and send in email, attach picture send email
if [[ -e "$PIC" ]]; then

	sendEmail -t "ensuretracking@gmail.com" -u "Tracking Email for $MACADD" -s smtp.gmail.com:587 -xu ensuretracking@gmail.com -xp "ensure2011" -f ensuretracking@gmail.com -o message-file="$LOGFILE" -a "$PIC" "$SCREEN" # "$TARFILE"
else
	echo -e "ERROR: No picture was taken." >> "$LOGFILE"
	echo -e "" >> "$LOGFILE"	
	sendEmail -t "ensuretracking@gmail.com" -u "Tracking Email for $MACADD" -s smtp.gmail.com:587 -xu ensuretracking@gmail.com -xp "ensure2011" -f ensuretracking@gmail.com -o message-file="$LOGFILE" -a "$SCREEN"
fi