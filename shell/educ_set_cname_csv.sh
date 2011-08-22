#!/bin/bash

# Written by Rusty Myers
# 20110408

# Script to get computer name for computer and adding it into educcomputernames.csv file

echo "educ_update_educ_csv.sh - v0.1 ("`date`")"

# Set variables for MAC address and Serial Number
MAC=`/sbin/ifconfig en0 | awk '/ether/ { gsub(":", ""); print $2 }'`

echo $MAC

# Set Serial Number as ARD Field 1
CName=`/usr/libexec/PlistBuddy -c "Print :cn"  /tmp/DSNetworkRepository/Databases/ByHost/"$MAC".plist`
/usr/libexec/PlistBuddy -c "Set :cn string $CName"  /tmp/DSNetworkRepository/Databases/ByHost/"$MAC".plist

echo "educ_update_educ_csv.sh - done"

exit 0
