#!/bin/sh

##
# User1
# Make archive directory in /Users/User1 to hold system data
##
echo "Deleting and recreating Daily Archive folder"
rm -rf /Users/backup/Archives/
mkdir /Users/backup/Archives/

##
# Remove any .DS_Store files and backup Document Root
##
#echo "Removing .DS_Store files"
#find /Library/Apache2/htdocs/. -iname ".DS_Store" -delete
#echo "Archiving /Library/Apache2/htdocs"
#tar czf /Users/rusty/Archives/ApacheDocRoot.tar.gz /Library/Apache2/htdocs
#echo "Archiving /Library/Apache2/conf"
#tar czf /Users/rusty/Archives/ApacheConfig.tar.gz /Library/Apache2/conf
#echo "Archiving /Library/Apache2/logs"
#tar czf /Users/rusty/Archives/ApacheLogs.tar.gz /Library/Apache2/logs

##
# Dump and Zip up SQL Data
##
#echo "Dumping Database Data"
#/Library/MySQL/bin/mysqldump --user=XXXXXXXX --password=XXXXXXXX -A > /Users/User1/Archives/SQLDump.txt
#echo "Zipping up Database Data"
#tar czf /Users/rusty/Archives/SQLDump.txt.tar.gz /Users/User1/Archives/SQLDump.txt
#echo "Removing Dump File"
#rm /Users/User1/Archives/SQLDump.txt

##
# Creating the backup disk image file and volume name
##
echo "Creating archived .dmg from /Users/rusty"
SOURCE='/Users/rusty'
FILEDEST='/Volumes/Backups/Archives'
VOLUMENAME=`date +%Y-%m-%d`_User1
IMAGENAME=$FILEDEST/$VOLUMENAME.dmg

hdiutil create -srcfolder $SOURCE -encryption -passphrase ve3n2zxc -fs HFS+ -volname $VOLUMENAME $IMAGENAME

##
# User2
##
echo "Creating archived .dmg from /Users/User2"
SOURCE='/Users/bree'
FILEDEST='/Volumes/Backups/Archives'
VOLUMENAME=`date +%Y-%m-%d`_User2
IMAGENAME=$FILEDEST/$VOLUMENAME.dmg

hdiutil create -srcfolder $SOURCE -encryption -passphrase jerkoff -fs HFS+ -volname $VOLUMENAME $IMAGENAME

echo "Daily Backups Completed"
