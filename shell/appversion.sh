#!/bin/bash

# Written by Rusty Myers
# 20110815

# Script to determine the version of the installed app by name

AppName="$1"
if [[ "$AppName" == ".app" ]]; then
	echo "$AppName"
fi
	
system_profiler SPApplicationsDataType|grep -i -A 8 "$AppName":

exit 0
