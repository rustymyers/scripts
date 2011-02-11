#!/bin/bash
# Rusty Myers
# Pennsylvania State University
# Feburary 2010
# rzm102@psu.edu
# Contact me directly with questions

# Changes
# Script to add computer MAC and name to csv file. Should search and edit existing MAC and computername
# Added ability to enter variables at command line with a option to overwrite it all

# Rename file!!

# To Do
# ADD001 - 20100210
# 	Delete old backups.
# ADD002 - 20100212
#	Ability to import from csv file.
# ADD003 - 20100215
#	Listing of current entries based on critera given. Full mac, partial mac, full name, partial name.

# Suggestions
# SUG001 - 20100215
#	Should I change the variables to something more generic, then allow people to configure which variables are set
#	and what their names would be. Then this script would basically edit and csv delimitated file.


#Set Variables
#Full path to csv file you wish to edit
educcsv=/Volumes/Delorean/WebServer/Documents/management/educcomputernames/educcomputernames.csv
#Date - Format as needed
logdate=`date -u "+%Y%m%d%H%M%S"`
#Blank out runchecks to be sure it's not accidently set
runchecks=0


if [ "$(id -u)" != "0" ]; then
	#Run as root if linking files
	echo "This script must be run as root"
	exit
fi

function linkcoefile {
#For depreciated coe name and scripts, links current educcomputernames files to coecopmuternames
#This function should be completley removed for any other installation. It's only use is for when the csv file is renamed or moved.
sudo ln -f /Volumes/Delorean/WebServer/Documents/management/educcomputernames/educcomputernames.csv /Volumes/Delorean/WebServer/Documents/management/coecomputernames/coecomputernames.csv
echo "backup file"
}

function backupfile {
cp $educcsv "$educcsv.backup.$logdate"
}

function insertintofile {
echo "Inserting $macaddress and $computername"
echo "$macaddress,$computername,$computername,,,,,,,,," >> $educcsv
}

function gatherinfo {

if [ "$computername" = "" ]
then
echo -e "#################################################################### \r"
echo -e "####	You can run this script with command line options too!  #### \r"
echo -e "####       Check the help for more information -- cni -h        ####\r"
echo -e "#################################################################### \r"
echo -e "##               Insert computername (all lowercase)              ## \r"
echo -e "#################################################################### \r"
echo ""
echo -e "Computer Name: \c"
read computername
fi
echo ""
if [ "$macaddress" = "" ]
then
echo -e "#################################################################### \r"
echo -e "##         Insert macaddress (lowercase and no punctuation)       ## \r"
echo -e "#################################################################### \r"
echo ""
echo -e "MAC Address: \c"
read macaddress
fi
echo ""
existname=`cat "$educcsv" | awk -F, "/$computername/ "'{ print $2 }'`
existmac=`cat "$educcsv" | awk -F, "/$macaddress/ "'{ print $1 }'`
oldname=`cat "$educcsv" | awk -F, "/$macaddress/ "'{ print $2 }'`
oldmac=`cat "$educcsv" | awk -F, "/$computername/ "'{ print $1 }'`
oldmacline=`cat "$educcsv" | awk -F, "/$macaddress/ "`
oldnameline=`cat "$educcsv" | awk -F, "/$computername/ "`
}

function checkname {
echo ""
echo -e "#################################################################### \r"
echo -e "##                  Is this the correct information?              ## \r"
echo -e "#################################################################### \r"
echo ""
echo "Computer Name: $computername MAC: $macaddress "
echo -e "Yes/No (y/n): \c"
echo ""

if [ "$runchecks" = 0 ]
then
	read answer
else
	answer=y
	echo "Skip checks"
fi

if [ $answer = "n" ]
then
	echo -e "#################################################################### \r"
	echo -e "##                   Would you like to re-try it?                 ## \r"
	echo -e "#################################################################### \r"
	echo -e "Yes/No (y/n): \c"
	echo ""
	
	if [ "$runchecks" = 0 ]
	then
		read answer
	else
		answer=n
		echo "Skiping checks"
	fi

	if 	[ $answer = "y" ]
	then
		retryentry
		
	else
		echo -e "#################################################################### \r"
		echo -e "##                       INNCORRECT INFORMATION                   ## \r"
		echo -e "##                  EXITING SCRIPT, PLEASE RUN AGAIN              ## \r"
		echo -e "#################################################################### \r"
		exit
	fi
elif [ $answer = "y" ]
then
	insertdata
else
	echo -e "#################################################################### \r"
	echo -e "##                          NO CHOICE MADE                        ## \r"
	echo -e "##                  EXITING SCRIPT, PLEASE RUN AGAIN              ## \r"
	echo -e "#################################################################### \r"
	exit
fi
}

function insertdata {

if [ "$existname" = "" ];then
		if [ "$existmac" = "" ];then									
			echo -e "#################################################################### \r"
			echo -e "##                    Adding Computer Information                 ## \r"
			echo -e "##          $macaddress,$computername,$computername,,,,,,,,,       \r"
			echo -e "#################################################################### \r"
			backupfile
			insertintofile
			linkcoefile
			exit
		else			
			echo -e "#################################################################### \r"
			echo -e "##                   Computer Information Exists                  ## \r"
			echo -e "##          The MAC address $macaddress already exists              \r"
			echo -e "##          `cat $educcsv | awk -F, /$macaddress/ `              \r"
			echo -e "##                                                                ## \r"
			echo -e "##              Do you want to update the Computer Name?          ## \r"
			echo -e "##                     $oldname -> $computername"
			echo -e "#################################################################### \r"

			echo -e "Yes/No (y/n): \c"
			if [ "$runchecks" = 0 ]
			then
				read updatemac
			else
				echo "Skip checks"
				updatemac=y
			fi

			if [ $updatemac = "y" ]
			then
				backupfile
				perl -i~ -pe "s/$oldname/$computername/g" $educcsv 
				linkcoefile
				exit
			else
				echo -e "#################################################################### \r"
				echo -e "##                      MAC ADDRESS NOT UPDATED!                  ## \r"
				echo -e "##                              EXITING                           ## \r"
				echo -e "#################################################################### \r"
				exit
			fi
		fi
	else
		if [ "$existmac" = "" ]
		then									
			echo -e "#################################################################### \r"
			echo -e "##                   Computer Information Exists                  ## \r"
			echo -e "##          The Computer name $computername already exists              \r"
			echo -e "##              `cat $educcsv | awk -F, /$computername/ `              \r"
			echo -e "##                                                                ## \r"
			echo -e "##              Do you want to update the MAC Address?            ## \r"
			echo -e "##         	'$oldmac -> $macaddress'"
			echo -e "#################################################################### \r"
			echo -e 
			echo -e "Yes/No (y/n): \c"
			if [ "$runchecks" = 0 ]
			then
				read updatename
			else
				echo "Skip checks"
				updatename=y
			fi
			if [ $updatename = "y" ]
			then
				backupfile
				perl -i~ -pe "s/$oldmac/$macaddress/g" $educcsv 
				linkcoefile
				exit
			else
				echo -e "#################################################################### \r"
				echo -e "##                      MAC ADDRESS NOT UPDATED!                  ## \r"
				echo -e "##                              EXITING                           ## \r"
				echo -e "#################################################################### \r"
				exit
			fi
	else	
		echo -e "#################################################################### \r"
		echo -e "##                   Computer Information Exists                  ## \r"
		echo -e "##          The MAC address $macaddress already exists              \r"
		echo -e "##          `cat $educcsv | awk -F, /$macaddress/ `              \r"
		echo -e "##                                                                ## \r"
		echo -e "##          The Computer name $computername already exists              \r"
		echo -e "##          `cat $educcsv | awk -F, /$computername/ `              \r"
		echo -e "##                                                                ## \r"
		echo -e "##              Do you want to update all information?            ## \r"
		echo -e "#################################################################### \r"
		echo -e ""
		echo -e "Yes/No (y/n): \c "

		if [ "$runchecks" = 0 ]
		then
			read updatemac
		else
			echo "Skip checks"
			updatemac=y
		fi
		if [ $updatemac = "y" ]
		then
			backupfile
			echo "Remove old MAC line: $oldmacline"
			perl -i~ -pe "s/$oldmacline//g" $educcsv
			sleep 1
			echo "Remove old Name line: $oldnameline"
			perl -i~ -pe "s/$oldnameline//g" $educcsv 
			
			insertintofile
			linkcoefile
			exit

		else
			echo -e "#################################################################### \r"
			echo -e "##                      NOTHING UPDATED!                          ## \r"
			echo -e "##                          EXITING                               ## \r"
			echo -e "#################################################################### \r"
			exit
		fi
	fi
fi
	
}

function retryentry {
gatherinfo
checkname
insertdata
}

function checkoverwrite {
#Check for overwrites
if [ "$overwriteall" = "1" ]
then
	runchecks=1
else
	runcheck=0
fi
}

function backupcleanup {
echo "Pruning backups"
#ADD001
#Tar old files
#Archive last weeks into one file
#Archive last 4 weeks into one file
#Archive last 6 weeks into file and remove older.

#find older date to xargs and remove each at a timevz
#Find backups files older than 1 day, but less than 7 days
#find . -iname "*.backup" -atime +1 -atime -7 -type f
#Find backup files older than 7 days, but less than 28 days
#find . -iname "*.backup" -atime +30 -atime -60 -type f
#Find backup files older than 60 days
#find . -iname "*.backup" -atime +60 -type f

}

function usage {
	echo "Usage: $0 -R [-n computername] [-m macaddress]"
	echo "Enter the Computer name and MAC Address"
	echo "-R will not ask for any checks. It will replace all data without asking."
	echo "Script will check for existing Computer name and MAC."
	echo "If Computer Name or MAC exist, it will ask you what to do"
	echo ""
	echo "Example: $0 -R -n chm018 -m 012345678901"
	exit 1
}

function importfile {
#ADD002

#set number of lines in file
#head echo line one - awk - regular expresions
#run imports
#loop until lines in file =0
#arrays

}


# Parse Command Line Arguments
while getopts hn:m:r o
do
	case "$o" in
	h)
		usage;;
	R)
		overwriteall="1";;
	n)
		computername="$OPTARG";;
	m)	
		macaddress="$OPTARG";;
	esac
done

#Run Commands
checkoverwrite
backupcleanup
gatherinfo
checkname
insertdata

