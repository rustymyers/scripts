#!/bin/bash

# Find battery capacity information

# ioreg -l | grep Capacity

##Find Battery Information
# Cycle Count
# ioreg -l | grep "Cycle Count"| cut -d, -f6 |sed -e s/\"//g | sed -e s/}//g
# OR
# ioreg -l | grep "Cycle Count" | cut -d, -f5 |sed -e s/\"//g | sed -e s/}//g

# Max Capacity
# ioreg -l | grep MaxCapacity | sed s/\"//g| awk '{print $3,$4,$5}'
# Current Capacity
# ioreg -l | grep CurrentCapacity | sed s/\"//g| awk '{print $3,$4,$5}'
# Design Capacity
# ioreg -l | grep DesignCapacity | sed s/\"//g | awk '{print $3,$4,$5}'


# Cycle Count Number Variable
cyclecount=`ioreg -l | grep Capacity | grep "Cycle Count"| cut -d, -f3 |sed -e s/\"Cycle\ Count\"=//g | sed -e s/}//g`
#echo "Cycle Count: "$cyclecount

if [[ "$cyclecount" -le 125 ]]; then
	echo "Battery is good. Cycle count is less then 125 of 500."
	echo "Cycle Count: "$cyclecount
elif [ "$cyclecount" -ge 126 -o "$cyclecount" -le 249 ]; then
	echo "Battery is in  early life. Cycle count is between 126 and 249 of 500."
	echo "Cycle Count: "$cyclecount
elif [ "$cyclecount" -ge 250 -o "$cyclecount" -le 449 ]; then
	echo "Battery is at mid-life. Cycle count is between 250 and 449 of 500."
	echo "Cycle Count: "$cyclecount
elif [[ $cyclecount -ge 450 ]]; then
	echo "Battery is exhausted. Replace soon.  Cycle count is greater than 500 of 500."
	echo "Cycle Count: "$cyclecount
	# warn someone
fi


# echo Max Capacity Number Only
# ioreg -l | grep MaxCapacity | sed s/\"//g | awk '{print $5}'
# echo Current Capacity Number Only
# ioreg -l | grep CurrentCapacity | sed s/\"//g | awk '{print $5}'
# echo Design Capacity Number Only
# ioreg -l | grep DesignCapacity | sed s/\"//g | awk '{print $5}'
