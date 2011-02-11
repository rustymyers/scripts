#!/bin/bash

#This script will create a user of your choice using your credentials. The user will not show up in the login window until a restart.

#Function to check the current usernames against the new username.

function checkusername {
local testun=$(dscl . -list /Users | grep $userA)
if [ "$testun" == "$userA" ]; 
then
echo "The username "$userA" already exists"
exit
else
echo "Username is unique!"
fi
}

#Function to check the current userID's against the new userID.

function checkuserid {
local testuid=$(dscl . -list /Users UniqueID | grep "$userid" | awk '{print $2}' )
if [ "$testuid" == "$userid" ];
then
echo "The userid "$userid" already exists"
exit
else
echo "UserID is unique!"
fi
}

#Funtion to check that both passwords are the same.

function chkpasswd {
if [ $password != $password2 ]
then
echo "Passwords do not match or are blank. Passwords can't be blank. Exiting..."
exit 0
else
echo "Passwords Match!"
fi
}

#Function checks to see if your in single user mode.

function chksum {
if [ $sum = y -o $sum = Y ];
then
echo "Loading Directory Services"
launchctl load /System/Library/LaunchDaemons/com.apple.DirectoryServices.plist
else
echo "Skipping launchctl load"
fi
}

#Checks to see if your in single user mode. If you are, it loads the directory services plist.

echo "Are you in Single User Mode? (Default N)"
read sum 
chksum

#Enter new credentials to create user with.

echo "Enter Real Name"
read realname
echo "Enter Username"
read userA
checkusername
echo "Enter Password"
read password
echo "Re-Enter Password"
read password2
chkpasswd

#Check to see if your sure you want to use the entered credentials.

echo "Use these creds?"
echo "Real Name: "$realname
echo "Username: "$userA
echo "Password: "$password

echo "Y or N:"
read creds

if [ $creds = y -o $creds = Y ];
then
	echo "Let's make a user named "$userA" with the password "$password


#Asks if you need to see all the userID's already used.

	echo "Making user..."
	echo "Do you know what userID is availible? (Default Y)"
	read existuserid
	
		if [ $existuserid = n -o $existuserid = N ];
		then
			#Prints the existing user account records and inserts them to users.out.
			dsexport users.out /Local/Default dsRecTypeStandard:Users
			#Prints users.out to screen.
			tail -n 5 users.out
			echo "Find the next userID available."
			#Removes users.out to clean up after printing to screen.
			rm users.out
		fi 

#Asks for the new userID. Checks if userID exists using checkuserid function.

	echo "OK, Enter new userID number:"
	read userid
	checkuserid

#The meat of the script. These are the commands that create the user with your specified credentials.

	dscl . -create /Users/""$userA""
	dscl . -create /Users/""$userA"" UserShell /bin/bash
	dscl . -create /Users/""$userA"" RealName "$realname"
	dscl . -create /Users/""$userA"" UniqueID $userid
	dscl . -create /Users/""$userA"" PrimaryGroupID 80
	dscl . -create /Users/""$userA"" NFSHomeDirectory /Users/""$userA"" 
	dscl . -passwd /Users/""$userA"" $password
	dscl . -append /Groups/admin GroupMembership ""$userA""

	echo "All Done, "$userA" was created!"
	sleep 2
	#This last step creates the setup done file so you don't have to go through the setup assistant.
	touch /var/db/.AppleSetupDone
	exit
else
	echo "Please Try Script Again!"
	exit 1
fi
