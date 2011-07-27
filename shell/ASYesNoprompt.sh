#!/bin/bash

# Written by Rusty Myers
# 20110727

# This is an example script. Use this code to prompt a user with AppleScript for a Yes/No response

ASreturn=`/usr/bin/osascript << EOT
tell application "System Events"
	tell application "System Events" to activate
	set agree_dialog to display dialog "Answer this Question with a Yes or No button?" buttons ["No", "Yes"] with title "Do Something?"  default button "No" 
end tell`

if [ "$ASreturn" = "button returned:Yes" ]; then
	echo "Yes, I do want to."
	else
	echo "No, I do not want to."
fi

exit 0