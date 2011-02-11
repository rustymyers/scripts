#!/bin/bash

Add user to lpadmin group

if [ "`/usr/sbin/dseditgroup -o checkmember -m ${1} lpadmin |
/usr/bin/awk '{print $1}'`" = "no" ]; then
       /usr/sbin/dseditgroup -o edit -n /Local/Default -a ${1} -t user lpadmin
fi

OR

sudo dseditgroup -o edit -a staff -t group lpadmin