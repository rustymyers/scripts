#!/bin/zsh
#
# Battery
#
# MacOS X/Darwin command line tool showing battery status.
#
# Version 1.0   2003-03-16    Initial release.
# Version 1.1   2003-10-14    Changes to handle Panther.
# Version 1.2   2004-11-16    Fix bug causing divide by zero. Output changes for long form.
# Version 1.3   2005-02-11    Support for four more flag bits (bits 9, 10, 11 and 12).
#                             Support new ioreg format in Mac OS X 10.3.8.
#                             Display battery cycles and new battery capacity (new in 10.3.8).
#
# http://www.mitt-eget.com/
#

IOREG="/usr/sbin/ioreg"
VERSION="1.3"

#
# Usage
# -----
#
# battery          (long form)
# battery long     (long form)
# battery short    (short form)
# battery compact  (compact form)
# battery csv      (csv form)
#
#  Long form:
#
#   Battery <battery>
#     Battery:  <battery flags>
#     Charger:  <charger flags>
#     UPS:      <UPS flags>
#     Voltage:  <voltage>V
#     Current:  <current>A (approx <time>)
#     Capacity: <capacity>Ah of <capacity>Ah (<percent>%)
#
#  Short form:
#
#   <date> <time> <battery> <flags> <voltage>V <current>A <capacity>Ah of <capacity>Ah (<percent>%)
#
#  Compact form:
#
#   <date> <time> <battery> <flags> <voltage> <current> <capacity> <capacity> <percent>
#
#  CSV form:
#
#   <date>,<time>,<battery>,<flags>,<voltage>,<current>,<capacity>,<capacity>,<percent>
#
# Examples (12 inch 800MHz iBook, Dec 2002) taken in Mar 2003 with version 1.0
# ----------------------------------------------------------------------------
#
# $ battery
# Battery 1
#   Battery:  battery installed, above warning level
#   Charger:  charger not connected, not charging
#   UPS:      UPS not installed
#   Voltage:  12.380V
#   Current:  0.658A (approx 5:58)
#   Capacity: 3.922Ah of 4.149Ah (94.5%)
# $ battery
# Battery 1
#   Battery:  battery installed, above warning level
#   Charger:  charger not connected, not charging
#   UPS:      UPS not installed
#   Voltage:  10.617V
#   Current:  1.115A (approx 0:23)
#   Capacity: 0.430Ah of 4.149Ah (10.4%)
# $ battery
# Battery 1
#   Battery:  battery installed, below warning level, raw LOW signal
#   Charger:  charger not connected, not charging
#   UPS:      UPS not installed
#   Voltage:  10.304V
#   Current:  1.144A (approx 0:10)
#   Capacity: 0.188Ah of 4.149Ah (4.5%)
# $ battery
# Battery 1
#   Battery:  battery installed, above warning level
#   Charger:  charger connected, charging
#   UPS:      UPS not installed
#   Voltage:  12.576V
#   Current:  1.200A (approx 3:17)
#   Capacity: 3.944Ah of 4.149Ah (95.1%)
# $ battery
# Battery 1
#   Battery:  battery installed, above warning level
#   Charger:  charger connected, not charging
#   UPS:      UPS not installed
#   Voltage:  12.596V
#   Current:  1.200A (approx 3:27)
#   Capacity: 4.149Ah of 4.149Ah (100.0%)
# $ 
# $
# $ battery short
# 2003-03-16 22:30:02 1 _____i__ 11.420V 1.069A 2.888Ah of 4.149Ah (69.6%)
# $ battery short
# 2003-03-17 00:51:57 1 _____i__ 10.617V 1.098A 0.453Ah of 4.149Ah (10.9%)
# $ battery short
# 2003-03-17 01:06:29 1 L__W_i__ 10.284V 1.140A 0.188Ah of 4.149Ah (4.5%)
# $ battery short
# 2003-03-17 01:10:21 1 _____i+c 11.499V 1.200A 0.249Ah of 4.149Ah (6.0%)
# $ battery short
# 2003-03-17 01:33:10 1 _____i+c 11.832V 1.200A 0.959Ah of 4.149Ah (23.1%)
# $ battery short
# 2003-03-17 02:32:13 1 _____i+c 12.282V 1.200A 2.773Ah of 4.149Ah (66.8%)
# $
# $
# $ battery compact
# 20030317 124528 1 00000101 12.556 1.200 4.134 4.149 99.6
# $
# $
# $ battery csv
# 20030317,124530,1,00000101,12.556,1.200,4.134,4.149,99.6
# $
#
# Examples (12 inch 800MHz iBook, Dec 2002) taken in Feb 2005 with version 1.3
# ----------------------------------------------------------------------------
#
# $ battery
# Battery 1
#   Battery:  battery installed, above warning level
#   Charger:  charger connected, not charging
#   UPS:      UPS not installed
#   System:   
#   Voltage:  12.478V
#   Current:  0.000A
#   Charge:   3.581Ah of 3.612Ah (99.1%)
#   Capacity: 3.612Ah of 4.200Ah (86.0%)
#   Cycles:   56
# $ 
#

#
# check_for_ioreg			- Check that the ioreg program
#					  is available.
#
# input:	nothing
#
# output:	nothing
#		return code		- status
#
check_for_ioreg ()
{
	if [ ! -x $IOREG ]; then
		echo "battery: can not execute $IOREG" >&2
		exit 1
	fi

	return 0
}

#
# get_battery_info			- Get battery information.
#
# input:	nothing
#
# output:	stdout			- battery info
#		return code		- status
#
get_battery_info ()
{
	local line
	local line1
	local line2

	$IOREG -p IODeviceTree -n "battery" -w 0 | grep IOBatteryInfo | {
		read line
		line1=${line:s/IOBatteryInfo/ BATTERY 1 /}
		line2=${line1:s/\}\,\{/ BATTERY 2 /}
		echo "${line2//[|\"=\(\{\}\),]/ }"
	}

	return 0
}

#
# display_battery_info			- Display battery information.
#
# input:	$1			- how to display
#		stdin			- battery info
#
# output:	stdout			- battery info in long or short form
#		return code		- status
#
display_battery_info ()
{
	local how=$1
	local line
	local name
	local value
	local battery
	local voltage1 flags1 amperage1 capacity1 current1 cyclecount1 absolutemaxcapacity1
	local voltage2 flags2 amperage2 capacity2 current2 cyclecount2 absolutemaxcapacity2

	read line
	echo ${=line} | sed 's/Cycle Count/CycleCount/g' | xargs -n 2 echo | while read name value; do
		case ${name:l} in
		battery)
			battery=$value
			;;
		voltage|flags|amperage|capacity|current)
			eval ${name:l}$battery=$value
			;;
		cyclecount|absolutemaxcapacity)
			eval ${name:l}$battery=$value
			;;
		esac
	done

	display_one_battery_$how 1 $voltage1 $flags1 $amperage1 $capacity1 $current1 $cyclecount1 $absolutemaxcapacity1
	[ ! -z "$voltage2" ] && display_one_battery_$how 2 $voltage2 $flags2 $amperage2 $capacity2 $current2 $cyclecount2 $absolutemaxcapacity2

	return 0
}

#
# display_one_battery_long		- Display information about one battery,
#					  long form.
#
# input:	$1			- battery number
#		$2			- voltage in mV
#		$3			- flags
#		$4			- amperage in mA
#		$5			- max capacity in mAh
#		$6			- current capacity in mAh
#		$7			- number of discharge cycles
#		$8			- absolute max capacity for battery in mAh
#
# output:	stdout			- battery info in long form
#		return code		- status
#
display_one_battery_long ()
{
	typeset -i battery=$1
	typeset -F 3 voltage=$2
	typeset -i 2 flag_byte=$3
	typeset -F 3 amperage=$4
	typeset -F 3 capacity=$5
	typeset -F 3 current=$6
	typeset -i cycles=$7
	typeset -F 3 maxcapacity=$8

	typeset -Z 16 zero_filled_flag_byte=${flag_byte/2#/}
	typeset flags=$zero_filled_flag_byte

	print "Battery $battery"

	print "  Battery:  $(display_flag_bits_long $flags       14   12 11    9        )"
	print "  Charger:  $(display_flag_bits_long $flags 16 15            10         5)"
	print "  UPS:      $(display_flag_bits_long $flags          13                  )"
	print "  System:   $(display_flag_bits_long $flags                       8 7 6  )"

	#
	# Print battery voltage, current, and capacity.
	#
	# Convert mV, mA, and mAh to V, A, and Ah.
	# Also calculate the current capacity as a percentage
	# of the full battery capacity.
	#
	(( voltage  /= 1000 ))
	(( amperage /= 1000 ))
	(( capacity /= 1000 ))
	(( current  /= 1000 ))
	(( maxcapacity /= 1000 ))

	print "  Voltage:  ${voltage}V"

	if [[ $flags[16] = 1 ]]; then		# if charger is connected
		if [[ $flags[15] = 1 ]]; then	# if battery is charging
			print "  Current:  ${amperage}A (charging)"
		else
			if [[ $amperage = 1.200 ]]; then
				print "  Current:  ${amperage}A (bogous consumption)"
			else
				print "  Current:  ${amperage}A"
			fi
		fi
	else					# else no charger connected
		if [[ $amperage = 1.200 ]]; then
			print "  Current:  ${amperage}A (bogous discharge rate)"
		else
			if [[ $amperage != 0.000 ]]; then
				typeset -i mins hours
				typeset -Z 2 minutes
				if [[ $amperage < 0 ]]; then
					(( mins = 60 * current / -amperage ))
				else
					(( mins = 60 * current / amperage ))
				fi
				(( hours = mins / 60 ))
				(( minutes = mins - hours * 60 ))
				print "  Current:  ${amperage}A (discharge rate giving ${hours} hours and ${minutes} minutes)"
			else
				print "  Current:  ${amperage}A"
			fi
		fi
	fi

	if [[ $capacity != 0.000 ]]; then
		typeset -F 1 percentage
		(( percentage = 100 * current / capacity ))
		print "  Charge:   ${current}Ah of ${capacity}Ah ($percentage%)"
	else
		print "  Charge:   ${current}Ah of ${capacity}Ah"
	fi

	if [[ $maxcapacity != 0.000 ]]; then
		typeset -F 1 percentage
		(( percentage = 100 * capacity / maxcapacity ))
		print "  Capacity: ${capacity}Ah of ${maxcapacity}Ah ($percentage%)"
	fi
	if [[ $cycles != 0 ]]; then
		print "  Cycles:   ${cycles}"
	fi

	return 0
}

#
# display_flag_bits_long		- Display the flag bits, long form.
#
#
# input:	$1			- flags
#		$2 ...			- bits to display
#
# output:	stdout			- selected flag bits in long text form
#		return code		- status
#
display_flag_bits_long ()
{
	local flags="$1"; shift

	#
	#   mask         bit index meaning
	#   0x00000001    0    16  charger is connected
	#   0x00000002    1    15  battery is charging
	#   0x00000004    2    14  battery is installed
	#   0x00000008    3    13  UPS is installed
	#   0x00000010    4    12  battery at or below warning level
	#   0x00000020    5    11  battery depleted
	#   0x00000040    6    10  no charging capability (15V aircraft power adapter?)
	#   0x00000080    7     9  raw low battery signal from battery
	#   0x00000100    8     8  low speed forced
	#   0x00000200    9     7  clamshell is closed
	#   0x00000400   10     6  clamshell was closed on wake up
	#   0x00000800   11     5  wrong charger connected (PowerBook with 45W iBook charger?)
	#   0x00001000   12     4
	#   0x00002000   13     3
	#   0x00004000   14     2
	#   0x00008000   15     1
  	#
	typeset -A states
	states[160]="charger not connected"
	states[161]="charger connected"
	states[150]="not charging"
	states[151]="charging"
	states[140]="battery not installed"
	states[141]="battery installed"
	states[130]="UPS not installed"
	states[131]="UPS installed"
	states[120]="above warning level"
	states[121]="below warning level"
	states[110]=""
	states[111]="DEPLETED"
	states[100]=""
	states[101]="no charging capability"
	states[90]=""
	states[91]="raw LOW signal"
	states[80]=""
	states[81]="LOW SPEED forced"
	states[70]=""
	states[71]="clamshell is closed"
	states[60]=""
	states[61]="clamshell was closed on wake up"
	states[50]=""
	states[51]="wrong charger connected"
	states[40]=""
	states[41]="bit 12 on"
	states[30]=""
	states[31]="bit 13 on"
	states[20]=""
	states[21]="bit 14 on"
	states[10]=""
	states[11]="bit 15 on"

	local ix
	local text=""
	local part=""
	for ix in $*; do
		part="$states[$ix$flags[$ix]]"
		if [ -z "$text" ]; then
			text="$part"
		else
			if [ ! -z "$part" ]; then
				text="$text, $part"
			fi
		fi
	done
	print "$text"

	return 0
}

#
# display_one_battery_short		- Display information about one battery,
#					  short form.
#
# input:	$1			- battery number
#		$2			- voltage in mV
#		$3			- flags
#		$4			- amperage in mA
#		$5			- max capacity in mAh
#		$6			- current capacity in mAh
#		$7			- number of discharge cycles
#		$8			- absolute max capacity for battery in mAh
#
# output:	stdout			- battery info in short form
#		return code		- status
#
display_one_battery_short ()
{
	typeset -i battery=$1
	typeset -F 3 voltage=$2
	typeset -i 2 flag_byte=$3
	typeset -F 3 amperage=$4
	typeset -F 3 capacity=$5
	typeset -F 3 current=$6
	typeset -i cycles=$7
	typeset -F 3 maxcapacity=$8

	typeset -Z 16 zero_filled_flag_byte=${flag_byte/2#/}
	typeset flags=$zero_filled_flag_byte
	typeset -F 1 percentage
	typeset -F 1 maxpercent

	#
	# Print battery battery number, flags, voltage, current, and capacity.
	#
	# Convert mV, mA, and mAh to V, A, and Ah.
	# Also calculate the current capacity as a percentage
	# of the full battery capacity.
	#
	(( voltage  /= 1000 ))
	(( amperage /= 1000 ))
	(( capacity /= 1000 ))
	(( current  /= 1000 ))
	(( maxcapacity /= 1000 ))

	if [[ $capacity != 0.000 ]]; then
		(( percentage = 100 * current / capacity ))
	else
		(( percentage = 0 ))
	fi
	if [[ $maxcapacity != 0.000 ]]; then
		(( maxpercent = 100 * capacity / maxcapacity ))
		print "$(date +'%Y-%m-%d %H:%M:%S')" 			\
		      "$battery"					\
		      "$(display_flag_bits_short $flags)"		\
		      "${voltage}V ${amperage}A"			\
		      "${current}Ah of ${capacity}Ah ($percentage%)"	\
		      "of ${maxcapacity}Ah ($maxpercent%)"		\
		      "$cycles cycles"
	else
		print "$(date +'%Y-%m-%d %H:%M:%S')" 			\
		      "$battery"					\
		      "$(display_flag_bits_short $flags)"		\
		      "${voltage}V ${amperage}A"			\
		      "${current}Ah of ${capacity}Ah ($percentage%)"
	fi

	return 0
}

#
# display_flag_bits_short		- Display the flag bits, short form.
#
#
# input:	$1			- flags
#
# output:	stdout			- flag bits in short text form
#		return code		- status
#
display_flag_bits_short ()
{
	local flags="$1"; shift

	#
	#   mask         bit index meaning
	#   0x00000001    0    16  charger is connected
	#   0x00000002    1    15  battery is charging
	#   0x00000004    2    14  battery is installed
	#   0x00000008    3    13  UPS is installed
	#   0x00000010    4    12  battery at or below warning level
	#   0x00000020    5    11  battery depleted
	#   0x00000040    6    10  no charging capability (15V aircraft power adapter?)
	#   0x00000080    7     9  raw low battery signal from battery
	#   0x00000100    8     8  low speed forced
	#   0x00000200    9     7  clam shell is closed
	#   0x00000400   10     6  clamshell was closed on wake up
	#   0x00000800   11     5  wrong charger connected (PowerBook with 45W iBook charger?)
	#   0x00001000   12     4
	#   0x00002000   13     3
	#   0x00004000   14     2
	#   0x00008000   15     1
	#
	typeset states_on="____w?CSLxDWui+c"
	typeset states_off="________________"

	local ix
	local text=""
	for ix in 5 6 7 8 9 10 11 12 13 14 15 16; do
		if [ $flags[$ix] = "1" ]; then
			text="${text}${states_on[$ix]}"
		else
			text="${text}${states_off[$ix]}"
		fi
	done
	print "$text"

	return 0
}

#
# display_one_battery_compact		- Display information about one battery,
#					  compact form.
#
# input:	$1			- battery number
#		$2			- voltage in mV
#		$3			- flags
#		$4			- amperage in mA
#		$5			- max capacity in mAh
#		$6			- current capacity in mAh
#		$7			- number of discharge cycles
#		$8			- absolute max capacity for battery in mAh
#
# output:	stdout			- battery info in compact form
#		return code		- status
#
display_one_battery_compact ()
{
	typeset -i battery=$1
	typeset -F 3 voltage=$2
	typeset -i 2 flag_byte=$3
	typeset -F 3 amperage=$4
	typeset -F 3 capacity=$5
	typeset -F 3 current=$6
	typeset -i cycles=$7
	typeset -F 3 maxcapacity=$8

	typeset -Z 16 zero_filled_flag_byte=${flag_byte/2#/}
	typeset flags=$zero_filled_flag_byte
	typeset -F 1 percentage
	typeset -F 1 maxpercent

	#
	# Print battery battery number, flags, voltage, current, and capacity.
	#
	# Convert mV, mA, and mAh to V, A, and Ah.
	# Also calculate the current capacity as a percentage
	# of the full battery capacity.
	#
	(( voltage  /= 1000 ))
	(( amperage /= 1000 ))
	(( capacity /= 1000 ))
	(( current  /= 1000 ))
	(( maxcapacity /= 1000 ))

	if [[ $capacity != 0.000 ]]; then
		(( percentage = 100 * current / capacity ))
	else
		(( percentage = 0 ))
	fi
	if [[ $maxcapacity != 0.000 ]]; then
		(( maxpercent = 100 * capacity / maxcapacity ))
		print "$(date +'%Y%m%d %H%M%S')"	\
		      "$battery"			\
		      "$flags"				\
		      "$voltage $amperage"		\
		      "$current $capacity $percentage"	\
		      "$maxcapacity $maxpercent"	\
		      "$cycles"
	else
		print "$(date +'%Y%m%d %H%M%S')"	\
		      "$battery"			\
		      "$flags"				\
		      "$voltage $amperage"		\
		      "$current $capacity $percentage"
	fi

	return 0
}

#
# display_one_battery_csv		- Display information about one battery,
#					  csv form.
#
# input:	$1			- battery number
#		$2			- voltage in mV
#		$3			- flags
#		$4			- amperage in mA
#		$5			- max capacity in mAh
#		$6			- current capacity in mAh
#		$7			- number of discharge cycles
#		$8			- absolute max capacity for battery in mAh
#
# output:	stdout			- battery info in csv form
#		return code		- status
#
display_one_battery_csv ()
{
	typeset -i battery=$1
	typeset -F 3 voltage=$2
	typeset -i 2 flag_byte=$3
	typeset -F 3 amperage=$4
	typeset -F 3 capacity=$5
	typeset -F 3 current=$6
	typeset -i cycles=$7
	typeset -F 3 maxcapacity=$8

	typeset -Z 16 zero_filled_flag_byte=${flag_byte/2#/}
	typeset flags=$zero_filled_flag_byte
	typeset -F 1 percentage
	typeset -F 1 maxpercent

	#
	# Print battery battery number, flags, voltage, current, and capacity.
	#
	# Convert mV, mA, and mAh to V, A, and Ah.
	# Also calculate the current capacity as a percentage
	# of the full battery capacity.
	#
	(( voltage  /= 1000 ))
	(( amperage /= 1000 ))
	(( capacity /= 1000 ))
	(( current  /= 1000 ))
	(( maxcapacity /= 1000 ))

	if [[ $capacity != 0.000 ]]; then
		(( percentage = 100 * current / capacity ))
	else
		(( percentage = 0 ))
	fi
	if [[ $maxcapacity != 0.000 ]]; then
		(( maxpercent = 100 * capacity / maxcapacity ))
		print "$(date +'%Y%m%d,%H%M%S'),$battery,$flags,$voltage,$amperage,$current,$capacity,$percentage,$maxcapacity,$maxpercent,$cycles"
	else
		print "$(date +'%Y%m%d,%H%M%S'),$battery,$flags,$voltage,$amperage,$current,$capacity,$percentage"
	fi

	return 0
}

#
# main					- Display battery info.
#
# input:	$1			- how to display
#
# output:	stdout			- battery info in selected text form
#		return code		- status
#
main ()
{
	local how

	case $# in
	0)
		how="long"
		;;
	1)
		case $1 in
		version|-v)
			print "battery version $VERSION"
			return 0
			;;
		long|short|compact|csv)
			how=$1
			;;
		*)
			usage
			;;
		esac
		;;
	*)
		usage
		;;
	esac

	check_for_ioreg
	get_battery_info | display_battery_info $how

	return 0
}

#
# usage					- Display usage.
#
# input:	none
#
# output:	none
#
usage ()
{
	echo "usage: battery"
	echo "       battery -v"
	echo "       battery version"
	echo "       battery long"
	echo "       battery short"
	echo "       battery compact"
	echo "       battery csv"

	exit 1
}

#
# Start main.
#
main ${1+$@}; exit $?
