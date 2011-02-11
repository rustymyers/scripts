#!/bin/bash

for i in `ls -d /Applications/Microsoft\ Office\ * | cut -d " " -f 3`
do 
/usr/libexec/PlistBuddy -c 'print :CFBundleShortVersionString' /Applications/Microsoft\ Office\ $i/Office/MicrosoftComponentPlugin.framework/Resources/Info.plist
done