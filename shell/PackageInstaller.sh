#!/bin/bash

# Add-On Script for Blast Image Config
# Written 05/2010 on Mac OS X 10.6.3 Build 10D2094
# Use this script to install packages to your restored image before immediately after restore AND/OR during first boot


#########
# Variables
#########

# Paths
firstbootpkgs=/Users/rzm102/Desktop/PSU\ Blast\ Image\ Config\ 2\.9/Packages/firstboot/
immediatepkg="/Users/rzm102/Desktop/PSU Blast Image Config 2.9/Packages/immediately/"
targetVolume="/Volumes/Disk Image/"
LogPath=

#########
# Immediate Installs
#########

# List packages in the immediate folder and Install Packages in thhe immediate folder
ls "$immediatepkg"
echo $immediatepkg

ls ""$immediatepkg"" | while read i 
do
echo "########Installing Package $i########"
installer -pkg $immediatepkg"$i" -target "$targetVolume"
if [ $? > 0 ]; then
	echo "########Installing Package $i Failed########"
	echo "########Exiting Script########"
	exit 20 # Exit script with error 20
fi
echo "$i has been installed" >> $LogPath
echo "########Done Installing $i########"
sleep 2
done


#########
# First Boot Installs
#########

# Copy All packages from firstboot folder to /usr/local/bicpkg/
# set launchd item on target disk to run Master Script
# write Master Script to /usr/local/bicms.sh
# List packages in the immediate folder
# Install Packages in thhe immediate folder

echo "########Exiting Script. Will run again at next boot.########"
