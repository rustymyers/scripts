#!/bin/sh

# source: http://pastebin.com/8XWCdxxk
# Written by XWordy
# https://twitter.com/xwordy/status/290893424108904448
# Checks for presence of JavaAppletPlugin.plugin.
# No plugin = exit result of "nonpresent"
# If present, evaluates the major release number and update number
# Editions prior to 7 return a result of "safe" and exit.
# Editions of 7 prior to u11 return a result of "patch" and exit.
# update 11 and later return a result of "current" and exit.

set -x

if [ -d /Library/Internet\ Plug-Ins/JavaAppletPlugin.plugin ]; then
		echo Java Plugin Present
		javaVersion=`/usr/bin/defaults read /Library/Internet\ Plug-Ins/JavaAppletPlugin.plugin/Contents/Enabled.plist CFBundleVersion`
		echo "Full version is $javaVersion"
	else
		echo "<result>nonpresent</result>"
		exit 0
fi

javaRelease=$(/usr/bin/defaults read /Library/Internet\ Plug-Ins/JavaAppletPlugin.plugin/Contents/Enabled.plist CFBundleVersion | awk -F'.' '{print $2}')
javaUpdate=$(/usr/bin/defaults read /Library/Internet\ Plug-Ins/JavaAppletPlugin.plugin/Contents/Enabled.plist CFBundleVersion | awk -F'.' '{print $3}')

if [ $javaRelease -lt 7 ]; then
		echo "<result>safe</result>"
		exit 0
	else
		if [ $javaUpdate -lt 11 ]; then
				echo "<result>patch</result>"
				exit 0
		else
				echo "<result>current</result>"
				exit 0
		fi
fi

exit 0