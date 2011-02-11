#!/bin/bash

function notify {
	dialogdays=`/usr/bin/osascript << EOT
	tell application "System Events"
		display dialog "$message" buttons ["OK"] default button "OK" with icon caution
	end tell
	EOT`
	echo $dialogdays
}

function AreYouSure {
yourSure=`/usr/bin/osascript << EOT
tell application "System Events"
	display dialog "Are you sure you want to try this fix? Type 'yes' to continue" default answer "no" buttons ["OK"] default button "OK"  with icon caution
	set result to text returned of result
end tell
EOT`
}

mailOpen=`/bin/ps -ax | /usr/bin/grep "Mail.app" | /usr/bin/grep -v grep`
if [ "$mailOpen" != "" ]; then
	message="Please quit mail before running this application."
	notify
	exit 0
fi

message="This app may help fix an Apple Mail issue that keeps messages from being downloaded. It will cause all messages stored on the PSU servers to be re-downloaded. This may cause duplicates to appear in your Inbox."
notify
AreYouSure
if [ "$yourSure" = "yes" ]; then
	echo "Move File"
	mv ~/Library/Mail/MessageUidsAlreadyDownloaded3 ~/Library/Mail/"MessageUidsAlreadyDownloaded3.`date -u "+%Y%m%d%H%M%S"`"
	message="Fix applied. Starting Mail."
	notify
	open -a /Applications/Mail.app
	exit 0
	
else
	echo "exiting"
	message="You have exited this application without making any changes."
	notify
fi