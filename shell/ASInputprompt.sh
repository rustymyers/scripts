#!/bin/bash

# Written by Rusty Myers
# 20110727

# This is an example script. Use this code to ask a user for input using AppleScript dialogs


Input=`/usr/bin/osascript << EOT
tell application "System Events"
	tell application "System Events" to activate
	display dialog "Please Enter Some Text" default answer "Default Text"  buttons ["OK"] default button "OK" 
	set result to text returned of result
end tell
EOT`

echo "Text inputed: "$Input

exit 0


