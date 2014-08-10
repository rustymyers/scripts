#!/bin/bash

osascript -e "set Volume 10"
ipadd=`ifconfig | grep 'broadcast' | awk '{print $2}'`
say $ipadd &
~/scripts/BigHonkingText $ipadd
