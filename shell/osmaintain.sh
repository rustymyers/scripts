#! /bin/bash

##
# This Script is an Platform Dependent Script. It needs OS X 10.3 to work.
# Asks if you want to Run Disk Utility and Fixed Permissions?
# If you do, it will display a choice of possible partitions. Choose one.
# It fixes permissions then continues on.
# If not, it will skip it and go strait to maintainence:
# Rebinding Files from /
# Daily, Weekly, Monthly Maintainence
# 
# Creates the Log Folder if it's not there.
# Have you tried Tech Tool Pro?
# Backup!!
##
if [ $USER != root ]
	then
	echo -e "You must be root to run this program! \r"
	exit 1
fi

##
# Check for logs directory and make it if it's not!
##

##
# Where is the log folder located?
##
	echo -e "#################################################################### \r"
	echo -e "##              Where is the log folder located?                  ## \r"
	echo -e "#################################################################### \r"
	echo -e "Absolute Path. Do not include trailing slash: \c"
	read OSMAIN
	
#OSMAIN=/Users/rusty/Logs/osmaintain

if  test -d "$OSMAIN"
	then
	echo -e " \r"
	else
	mkdir $OSMAIN
fi

##
# Asks if they want to repair disk permissions now or not.
# If not, it continues to maintainence.
# If yes, prompts for desired partition to fix.
# With the input of disk it fixes permissions.
##
	echo -e "#################################################################### \r"
	echo -e "##           Do you want to run the Disk Utility Now?             ## \r"
	echo -e "##                                                                ## \r"
	echo -e "##      If Not, It will take you to the Maintainence Script.      ## \r"
	echo -e "##     This Script is recommended to be run weekly or monthly     ## \r"
	echo -e "##  depending on the activity. (Servers: Weekly, Desktop:Monthly) ## \r"
	echo -e "##        Or you can have this utility open the Disk Utility      ## \r"
	echo -e "##             by typing \"o\" as your answer.                      ## \r"
	echo -e "#################################################################### \r"
	echo -e " \r"
	echo -e "\a Enter your Answer(y/n/o): \c"
	read answer
if [ $answer = "n" ]
	then
	echo -e "############################################################## \r"
	echo -e "##                                                          ## \r"
	echo -e "##        Use Disk Utility to Repair Disk Permissions       ## \r"	
	echo -e "##               or this script.                            ## \r"
	echo -e "##      Then and Only then run the Periodic Maintenance     ## \r"
	echo -e "##                                                          ## \r"
	echo -e "############################################################## \r"
elif [ $answer = "y" ]
	then
	echo -e "############################################################## \r"
	echo -e "##       Disk Utility will run the Repair Permissions       ## \r"
	echo -e "##        on the volume you select. Choose your volume      ## \r"
	echo -e "##        by typing your choice in the prompt.              ## \r"
	echo -e "##         Choices are provided above the prompt.           ## \r"
	echo -e "############################################################## \r"
	sleep 2
	echo -e "It may take a moment for these Choices appear: \r"
	diskutil list | grep Apple_HFS | tr -s '  ' ' ' | cut -f7 -d ' '
	echo -e "Enter your choice: \c"
	read DISKWHAT
	echo -e "The disc partition "$DISKWHAT" is being repaired\c"
	echo -e ". Please Wait\r"
	diskutil repairPermissions $DISKWHAT
	echo -e "Disk "$DISKWHAT" has been repaired. \r"
	sleep 3
elif [ $answer = "o" ]
	then
	open -a 'disk utility'
	exit 0
else
	echo -e "You Must Enter a \"y\" or a \"n\""
fi
	
##
# Asks if you have run Fix Disk Permissions. If not, it exits.
# If yes, it asks where to start pre-binding.
# Also asks if you have tried Disk Utility or Tech tool Pro
##
	echo -e "############################################################### \r"
	echo -e "##                                                           ## \r"
	echo -e "##    Have you run the \"Fix Disk Permissions\" with           ## \r"
	echo -e "##          The Disk Utility located in the                  ## \r"
	echo -e "##                /Applications/Utilities folder?            ## \r"
	echo -e "##                           or                              ## \r"
	echo -e "##                     Tech Tool Pro?                        ## \r"
	echo -e "##                                                           ## \r"
	echo -e "##  This Script Should Only be Run AFTER Fixing Permissions. ## \r"
	echo -e "##                                                           ## \r"
	echo -e "##  You must BACKUP your files BEFORE Running this Script!!  ## \r"
	echo -e "##                                                           ## \r"
	echo -e "############################################################### \r"
	echo -e " \r"
	echo -e "\a Enter your Answer(y/n): \c"
	read answer

if [ $answer = "n" ]
	then
	echo -e "############################################################## \r"
	echo -e "##                                                          ## \r"
	echo -e "##  Use Disk Utility or this Script to                      ## \r"	
	echo -e "##            Repair Disk Permissions                       ## \r"
	echo -e "##  Then and Only then run the Periodic Maintenance         ## \r"
	echo -e "##                                                          ## \r"
	echo -e "##              REMEMBER TO BACKUP DAILY!!                  ## \r"
	echo -e "############################################################## \r"
	exit 1

elif [ $answer = "y" ]
	then

##
# Binds locations of Application files for faster startup
##
	echo -e "############################################################## \r"
	echo -e "## Enter the location of where you want pre-binding started ## \r"
	echo -e "############################################################## \r"
	echo -e "Enter your answer (usually /):\c"
	read START
	echo -e " \r"
	echo -e "Pre-binding "$START" Files. Please Wait... \c"
	update_prebinding -root $START >$OSMAIN/prebind.log 2>&1
	sleep 2
	echo -e "Pre-binding Finished. \r"

##
# System Maintenance from OS X Set to run at 3 am.
# If the computer is never on then, this runs that maintenance.
##
	echo -e "Periodic Maintenance Starting...\r"
	echo -e " \t Daily Maintenance...\c"
	periodic daily >$OSMAIN/daily.log 2>&1
	sleep 1
	echo -e "Finished \r"
	echo -e " \t Weekly Maintenance...\c"
	periodic weekly >$OSMAIN/weekly.log 2>&1
	sleep 1
	echo -e "Finished \r"
	echo -e " \t Monthly Maintenance...\c"
	periodic monthly >$OSMAIN/monthly.log 2>&1
	sleep 1
	echo -e "Finished \r"
	echo "Periodic Maintenance Done."
	sleep 1

##
# Displays Finish.
##
	echo -e "######################################################## \r"
	echo -e "##      Thank You for Maintaining your system.        ## \r"
	echo -e "##      You are now finished with this script.        ## \r"
	echo -e "##           REMEMBER TO BACKUP DAILY!!               ## \r"
	echo -e "######################################################## \r"

	sleep 1

else
	echo -e "You Must Enter a \"y\" or a \"n\""
fi

########################################################################
## Created on May 28, 2004 by Rusty Myers with Help from OSXHints.com ##
########################################################################
