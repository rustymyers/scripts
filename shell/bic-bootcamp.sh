#!/bin/sh
# Used with Blast Image Config to restore windows partition
# Also used winclone
# 2010

## DISK PARTITIONING PARAMETERS

# Written by Derick Okihara
# dokihara@hawaii.edu

#set the size you want the windows partition by percentage
volume='/Volumes/Mac'
mac='60%'
windows='39%'
 
echo "Resizing " $volume " to add Windows partition. This is NON destructive."
# Resize the disk
/usr/sbin/diskutil resizeVolume "$volume" $mac MS-DOS windows $windows
 
echo "Running WinClone self extraction…"
#run self-extraction incline
exec /Volumes/Mac/Wist131WinXP-6-4-10.winclone/winclone.perl -self-extract
 
echo "Setting Windows Partition as boot partition to run Windows setup..."
/usr/sbin/bless --device /dev/disk0s3 --setBoot --legacy
 
echo "Deleting winclone image"
rm -rf /Volumes/Mac/Wist131WinXP-6-4-10.winclone
 
exit 0