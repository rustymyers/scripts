#!/bin/sh
################################################################################
#	UninstallBESAgent.sh
#
#	Completely uninstall the BESAgent
################################################################################


#
# Shell function to match for a PID, then strip out matches to remove similarly
# named items.
# $1 - string to match
# $2+  strings to match and remove
# $sPIDLine - line from ps matching what is left
#
sPIDLine=0
GetPIDLine()
{{
	# Use ps to get our process list then filter out only those matching $1
	psLine="ps -axww | grep \"$1\" | sed -e '/grep/d'"
	shift

	# Now loop through any other args, adding sed lines to stripping matching lines from the matched set
	while [ $# -gt 0 ]; do
		psLine="$psLine -e '/$1/d'"
		shift
	done

	sPIDLine=`sh -c "$psLine"`
}

#
# Strip a PID line to just its PID
# $1 - line from ps (ps -axww)
# $sPID - pid, stripped from that line.  Assumes PID is the first token.
#
sPID=0
GetPID()
{{
	sPID=`echo "$1" | awk '{{print $1}'`
}

sAgentPIDLine=""
GetAgentPIDLine()
{{
	GetPIDLine "MacOS/BESAgent" "BESAgentUI" "BESAgentDaemon" "BESAgentControlPanel" "BESAgent Uninstaller"
	sAgentPIDLine="$sPIDLine"
}


# Stop the service
echo "Stopping the BESAgent"
# Search for PIDS matching BESAgent, but then exclude the older AgentUI and daemon
GetAgentPIDLine

if [ "$sAgentPIDLine" != "" ]; then
	clientLoc=`expr "$sAgentPIDLine" : '[^\/]*\(\/.*\)\/[^\/]*'`

	if [ "$clientLoc" == "/Library/StartupItems/BESAgent/BESAgent.app/Contents/MacOS" ]; then
		# If we are a StartupItem, use SystemStarter to stop us
		/sbin/SystemStarter stop BESAgent 2>&1 >> /dev/console
	else
		# Otherwise, our agent is located in /Library/BESAgent we should be a
		# launchd daemon, so use launchctl.  If the path is neither
		# /Library/StartupItems/BESAgent or /Library/BESAgent then it is unclear
		# what is running.
		if [ "$clientLoc" == "/Library/BESAgent/BESAgent.app/Contents/MacOS" ]; then
			launchctl unload /Library/LaunchDaemons/BESAgentDaemon.plist 2>&1 >> /dev/console
		fi
	fi
	
	# Wait while the client cleanly exits
	waitCount=10
	while [ $waitCount -gt 0 ]; do
		echo -n "$waitCount... "
		sleep 1
		GetAgentPIDLine
		if [ "$sAgentPIDLine" == "" ]; then
			waitCount=1
		fi
		waitCount=`expr "$waitCount" - 1`
	done
	echo
fi

#
# Make sure the BESClientUI has stopped.  It should stop when the service exits,
# but we want to make sure otherwise it can't be removed.
#
echo "Making sure BESClientUI is dead"
GetPIDLine "BESClientUI"
if [ "$sPIDLine" != "" ]; then
	GetPID "$sPIDLine"
	echo "Killing ClientUI $sPID"
	kill -9 $sPID
fi

echo "Removing the app from /Library/StartupItems"
rm -rf /Library/StartupItems/BESAgent

echo "Removing the app from /Library and /Library/LaunchDaemons"
rm -rf /Library/BESAgent
rm -rf /Library/LaunchDaemons/BESAgentDaemon.plist

echo "Removing the data directory: /Library/Application Support/BigFix"
rm -rf "/Library/Application Support/BigFix"

echo "Removing our preferences"
rm -rf /Library/Preferences/com.bigfix.BESAgent.plist

echo "Removing user specific preferences"
rm -rf /Users/*/Library/Preferences/com.bigfix.*

echo "Removing our log"
rm -rf /Library/Logs/BESAgent.log

echo "Removing our install receipt"
rm -rf /Library/Receipts/BESAgent*.pkg

echo "Removing the TriggerBESClientUI app"
rm -rf /Applications/TriggerBESClientUI.app

#
# Remove our icon from the docks of all users
# If we are cleaning up after a messed up install and $clientLoc is unset
# because the client files are missing or already deleted, passing the label
# to the DockUtil remove command will still remove the item from the dock
#
dockUtilPath=`expr "$0" : '\(.*\)\/[^\/]*$'`
"$dockUtilPath/DockUtil" -a remove "$clientLoc/BigFixSupportCenter.app" "BigFixSupportCenter"
rm -rf /tmp/besclientuninstall.sh
