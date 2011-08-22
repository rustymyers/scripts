#!/bin/sh

# 
# Revisions:
# 2008/07/16 By Justin Elliott <jde6@psu.edu>
# 2009/12/15 By Justin Elliott <jde6@psu.edu> Deleting more files, writing to psuMacType.output file. Accepting IP and restore HD path.
# 2010/02/24 By Justin Elliott <jde6@psu.edu> added PlistBuddy changes to BigFix files.

export PATH=/bin:/sbin:/usr/bin:/usr/sbin

restored_HD_Path=$1

myFileName="`basename "$0"`"
myDir="`dirname "$0"`"

# echo "****************"
# 
# echo "myDir: $myDir"
# echo "myFileName: $myFileName"
# echo "My Full Path: $0"
# echo "Restored HD Volume Path: '$restored_HD_Path'"
# echo "IP Address Received: '$ip'"
# 
# echo "****************"

# Wipe the contents of  (but don't delete) the file: /Library/PSUlog/psu.log
if [[ -f "$restored_HD_Path/Library/PSUlog/psu.log" ]]; then
	echo "Found the psu.log file, erasing contents ..."
	echo "" > "$restored_HD_Path/Library/PSUlog/psu.log" # Empty out the file
else
	echo "Did NOT find the psu.log file. Nothing to clear out."
fi

echo "Deleting KeyAccess files ..."

# Upon build, delete (some may not exist) the following files or dirs used by KeyAccess:
rm -rdf "$restored_HD_Path/Library/Preferences/KeyAccess"
rm -rdf "$restored_HD_Path/Library/Preferences/KeyAccess/KeyAccess Audit"
rm -rdf "$restored_HD_Path/Library/Preferences/KeyAccess/KeyAccess Offline"
rm -rdf "$restored_HD_Path/Library/Preferences/KeyAccess/KeyAccess Prefs"
rm -rdf "$restored_HD_Path/Library/Preferences/KeyAccess/Portable Keys"

rm -rdf "$restored_HD_Path/private/var/root/Library/Preferences/KeyAccess"
rm -rdf "$restored_HD_Path/private/var/root/Library/Preferences/KeyAccess Audit"
rm -rdf "$restored_HD_Path/private/var/root/Library/Preferences/KeyAccess Offline"
rm -rdf "$restored_HD_Path/private/var/root/Library/Preferences/KeyAccess Prefs"
rm -rdf "$restored_HD_Path/private/var/root/Library/Preferences/Portable Keys (don't move)"

echo "Deleting BigFix files ..."

# Upon build, delete (some may not exist) the following files or dirs used by BigFix:
rm -rdf "$restored_HD_Path/Library/Application Support/BigFix/BES Agent/__BESData"
rm -rdf "$restored_HD_Path/Library/BESAgent/BESAgent.app/Contents/MacOS/actionsite.afxm"
/usr/libexec/PlistBuddy -c "Delete :Options:GlobalOptions:ComputerId" "$restored_HD_Path/Library/Preferences/com.bigfix.BESAgent.plist"
/usr/libexec/PlistBuddy -c "Delete :Options:GlobalOptions:RegCount" "$restored_HD_Path/Library/Preferences/com.bigfix.BESAgent.plist"
/usr/libexec/PlistBuddy -c "Delete :Options:GlobalOptions:ReportSequenceNumber" "$restored_HD_Path/Library/Preferences/com.bigfix.BESAgent.plist"

echo "Deleting  psuMacType.dat ..."

rm -rdf "$restored_HD_Path/Library/PSUcurl/psuMacType.dat"

echo "delete swapfiles"
rm "$restored_HD_Path/private/var/vm/swapfile*"

echo "delete volume info DB"
rm "$restored_HD_Path/private/var/db/volinfo.database"

echo "clean up global caches and temp data"
rm -rf "$restored_HD_Path/Library/Caches/*"
rm -rf "$restored_HD_Path/System/Library/Caches/*"
rm -rf "$restored_HD_Path/Users/Shared/*"

echo "log cleanup.  We touch the log file after removing it since syslog won't create missing logs."

rm "$restored_HD_Path/private/var/log/alf.log"
touch "$restored_HD_Path/private/var/log/alf.log"
rm "$restored_HD_Path/private/var/log/cups/access_log"
touch "$restored_HD_Path/private/var/log/cups/access_log"
rm "$restored_HD_Path/private/var/log/cups/error_log"
touch "$restored_HD_Path/private/var/log/cups/error_log"
rm "$restored_HD_Path/private/var/log/cups/page_log"
touch "$restored_HD_Path/private/var/log/cups/page_log"
rm "$restored_HD_Path/private/var/log/daily.out"
rm "$restored_HD_Path/private/var/log/ftp.log*"
touch "$restored_HD_Path/private/var/log/ftp.log"
rm -rf "$restored_HD_Path/private/var/log/httpd/*"
rm "$restored_HD_Path/private/var/log/lastlog"
rm "$restored_HD_Path/private/var/log/lookupd.log*"
rm "$restored_HD_Path/private/var/log/lpr.log*"
rm "$restored_HD_Path/private/var/log/mail.log*"
touch "$restored_HD_Path/private/var/log/lpr.log"
rm "$restored_HD_Path/private/var/log/mail.log*"
touch "$restored_HD_Path/private/var/log/mail.log"
rm "$restored_HD_Path/private/var/log/monthly.out"
rm "$restored_HD_Path/private/var/log/run_radmind.log"
rm -rf "$restored_HD_Path/private/var/log/samba/*"
rm "$restored_HD_Path/private/var/log/secure.log"
touch "$restored_HD_Path/private/var/log/secure.log"
rm "$restored_HD_Path/private/var/log/system.log*"
touch "$restored_HD_Path/private/var/log/system.log"
rm "$restored_HD_Path/private/var/log/weekly.out"
rm "$restored_HD_Path/private/var/log/windowserver.log"
touch "$restored_HD_Path/private/var/log/windowserver.log"
rm "$restored_HD_Path/private/var/log/windowserver_last.log"
rm "$restored_HD_Path/private/var/log/wtmp.*"

exit 0