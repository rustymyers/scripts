#!/bin/sh

if [ "$1" = "" ]
then
	echo "Error: Missing Disk Image filename.\nUsage: $0 imageName.dmg"
	exit -1
else
	hdiutil imageinfo -plist "$1" | grep -i -A 1 udif-ordered-chunks	
fi

