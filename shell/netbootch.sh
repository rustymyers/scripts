#!/bin/bash

##############################################################
#                                                            #
#  NETBOOTCH, by Peter Bukowinski (pmbuko@gmail.com)         #
#  last revised July 31, 2008 at 5:48pm                      #
#                                                            #
#  ABOUT THIS SCRIPT:                                        #
#  This script makes it easy to change the default NetBoot   #
#  image hosted on an Xserve via the command line. It is an  #
#  interactive script so no arguments are necessary. Just    #
#  run it -- don't forget the sudo! -- and it will list the  #
#  available netboot images and prompt you to choose one.    #
#  It will then enable the specified image (if necessary),   #
#  and make it the new default NetBoot image.                #
#                                                            #
#  RECOMMENDED INSTALLATION:                                 #
#  Place this script in /usr/local/bin on your Xserve and    #
#  invoke it from your computer when necessary with ssh.     #
#                                                            #
#  COMPATIBILITY:                                            #
#  This script should work with Tiger and Leopard Server.    #
#                                                            #
##############################################################


# are we running on OS X Server as root?
if [ "$(sw_vers -productName)" == "Mac OS X Server" ]; then
	if [ "$(id -u)" -ne "0" ]; then
		/bin/echo "This script must be run as root."
		exit 1
	fi
else
	/bin/echo "This script can only be run on Mac OS X Server (Tiger or Leopard)."
	exit 1
fi

# set location of temp files
FILE1=/tmp/chnetboot1.txt
FILE2=/tmp/chnetboot2.txt


# friendly usage funtion, called if user supplies arguments
usage ()
{
	/bin/echo "Usage: netbootch"
	/bin/echo ""
	/bin/echo "This is an interactive script so no arguments are necessary."
	exit 1
}

if [ $# == 0 ]; then		# do this block if no arguments are given (which is what we want)

	# grab netboot image names (need to made sure spaces are recognized.
	netBootImages=$(/usr/sbin/serveradmin settings netboot:netBootImagesRecordsArray | /usr/bin/awk -F/ '/pathToImage/ {print $(NF-1)"\n"}')
	
	# grab index of current default image
	defaultImage=$(/usr/sbin/serveradmin settings netboot:netBootImagesRecordsArray | /usr/bin/awk -F: '/IsDefault = yes/ {print $4}')
	
	# declare an array to hold the netBoot image names
	declare -a nbARRAY
	let index=0
	
	# we want newlines to separate the image names, not spaces, so we will
	# back up the current input file/field separator and then change it.
	OLDIFS="$IFS"
	IFS=$'\n'

	# put netboot names into an array and show them to the user
	for image in $netBootImages; do
		if [ "$index" == "$defaultImage" ]; then
			/bin/echo "* [$index]: $image"
			nbARRAY[$index]="$image"
			((index++))
		else
			/bin/echo "  [$index]: $image"
			nbARRAY[$index]="$image"
			((index++))
		fi
	done
	((index--))
	
	# restore the default IFS value
	IFS="$OLDIFS"
	
	# prompt user to select desired default
	/bin/echo -n "Select a new default image [0-$index]: "
	read -n 2 choice
	
	# check choice for sanity
	if [ "0" -le "$choice" ] && [ "$choice" -le "$index" ]; then		# proceed if choice is within expected range

		# provide feedback
		/bin/echo -n "Making '${nbARRAY[$choice]}' the default image. "
		
		# dump serveradmin netboot settings to temp file
		/usr/sbin/serveradmin settings netboot:netBootImagesRecordsArray > $FILE1
		/bin/echo -n ". "

		# edit the file to undefault the current default netboot image
		/usr/bin/sed 's/IsDefault = yes/IsDefault = no/' $FILE1 > $FILE2
		/bin/echo -n ". "
		
		# edit the file to make the chosen image the default netboot image
		/usr/bin/sed "s/$choice:IsEnabled = no/$choice:IsEnabled = yes/" $FILE2 > $FILE1
		/bin/echo -n ". "
		/usr/bin/sed "s/$choice:IsDefault = no/$choice:IsDefault = yes/" $FILE1 > $FILE2
		/bin/echo "."
		
		# send changes back to serveradmin
		/bin/stty -echo
		/usr/sbin/serveradmin settings < $FILE2 > /dev/null
		/bin/stty echo
		/bin/echo "Done."

		# clean up temp files
		/bin/rm $FILE1 $FILE2
		exit
		
	else		# report choice as invalid if no index with that value exists
		/bin/echo "Invalid choice."
		exit 1
	fi
else		# if arguments are given, show usage
	usage
fi
