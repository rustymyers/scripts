#!/bin/sh
#This is a "hard" uninstall. There will be no prompt to save or backup settings. This will only
#remove the user settings for the currently logged in user. Adapt as necessary for your environment

launchctl unload ~/Library/LaunchAgents/com.identityfinder.launchagent.plist;
rm -f ~/Library/LaunchAgents/com.identityfinder.launchagent.plist;
rm -f ~/Library/Preferences/com.identityfinder.macedition.plist;
rm -rf ~/Library/Application\ Support/Identity\ Finder/;
rm -rf /Applications/Identity\ Finder.app/;
rm -rf /Library/Application\ Support/Identity\ Finder/;
rm -f /Library/Preferences/com.identityfinder.macedition.plist;
rm -rf /Users/Shared/.identityfinder