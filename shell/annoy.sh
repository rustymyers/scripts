#!/bin/bash

#This is the biggest waste of time I have ever decided to partake in starts here. 
#I want to anoy you.

cd /usr/local/bin/

# if [ -d touch /usr/local/bin/balk/ ]; then
# 	echo "No Home"
# else
# 	mkdir /usr/local/bin/balk/
# fi

#Make noise at a certain interval
#
#Set to run at random times
#afplay ~/Desktop/mosquito-ringtone.mp3


#Dim Display very slowley over a few months
#
#start at 1, work your way down daily

if [ -a /usr/local/bin/balk/today.dat ]; then
	todaybright=`cat today.dat`
else
	touch today.dat
	echo "1">today.dat
fi

setbright=`echo '$todaybright'-.001 | bc`
echo $setbright
brightness $setbright
echo $setbright>today.dat
