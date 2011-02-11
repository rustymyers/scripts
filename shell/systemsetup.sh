#!/bin/bash

#System Setup

#Time Zone Setup
systemsetup -settimezone America/New_York

#Set to use Network Time Server clock.psu.edu
systemsetup -setusingnetworktime on
systemsetup -setnetworktimeserver clock.psu.edu

#Update NTP
sudo ntpdate -bvs clock.psu.edu

#Disable Time Machine "use this disk"
defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool YES

#Enable MCX Login Scripts for Viper trust
sudo defaults write /var/root/Library/Preferences/com.apple.loginwindow EnableMCXLoginScripts -bool TRUE
sudo defaults write /var/root/Library/Preferences/com.apple.loginwindow MCXScriptTrust Authenticated

#Enable ARD for etcadmin
/System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -configure -allowAccessFor -specifiedUsers
/System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -activate -configure -access -on -users "etcadmin" -privs -all -restart -agent

#Start Remote Login
sudo /sbin/service ssh start

#Enable advanced Screen Sharing Features
#10.5 only
defaults write com.apple.ScreenSharing ShowBonjourBrowser_Debug 1
defaults write com.apple.ScreenSharing \
'NSToolbar Configuration ControlToolbar' -dict-add 'TB Item Identifiers' \
'(Scale,Control,Share,Curtain,Capture,FullScreen,GetClipboard,SendClipboard,Quality)'

#Copy screen Sharing app to Applications
cp -R /System/Library/CoreServices/Screen\ Sharing.app /Applications/Screen\ Sharing.app
sudo chown -R etcadmin:staff /Applications/Screen\ Sharing.app/

#Set hard drive name
diskutil rename / "Macintosh HD"

#Set hostname
hostName=InstaDMG
/usr/sbin/scutil --set ComputerName $hostName
/usr/sbin/scutil --set LocalHostName $hostName

#Set SAV to autoupdate daily
sudo "/Applications/Symantec Solutions/Symantec Scheduler.app/Contents/Resources/symsched" -f LiveUpdate "Updates" 1 1 -d 11:00 "All Products" -quiet

#disable ipv6
networksetup -setv6off Ethernet

#Last Bit to run

#Run coecomputernames scripts to download csv and name computer
sudo sh /path/to/computernames/curlcname.sh

#Remove Launchd item
sudo rm /Library/LaunchDaemons/com.example.systemsetup.plist


#If it's a laptop, skip this part. So, only a desktop needs to bind

if sysctl -n hw.model | grep 'Book' ;then
	echo "Laptop; Not binding."
else
#Set AD/OD Bind Launchd item
mv /path/to/adodbind/edu.psu.educ.etc.adodautobind.plist /Library/LaunchDaemons/edu.psu.educ.etc.adodautobind.plist

#Make sure the permissons are correct
sudo chown root:wheel /Library/LaunchDaemons/edu.psu.educ.etc.adodautobind.plist
sudo chmod 644 /Library/LaunchDaemons/edu.psu.educ.etc.adodautobind.plist

fi

#Reboot in 1 minute
sleep 60
sudo reboot


#Self Destruct
#srm "$0"
mv $0 $0.done