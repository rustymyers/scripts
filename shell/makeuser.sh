#!/bin/bash
# Run as root, of course. 
if [ "$UID" -ne "$ROOT_UID" ] 
then 
  echo "Must be root to run this script." 
  exit 0 
fi  
echo "This script will create a user on Leopard"
echo ""
echo "Enter Fullname"
read fullname
echo "Enter username"
read username
echo "Enter usernumber"
read usernumber
echo "Enter Password"
read password
echo "Enter Password again"
read password2
echo ""
if [ $password != $password2 ]
then
echo "Passwords do not match. Exiting..."
exit 0
else
echo "Passwords Match!"
fi

echo ""
echo "Full Name"$fullname
echo "Username:"$username
echo "UID:" $usernumber
echo "Password:" $password
echo "Are these details correct? Y or N?"
read test
echo ""
if [ $test = Y -o $test = y ]
then
echo "Creating User "$username
dscl . -create /Users/$username
dscl . -create /Users/$username UserShell /bin/bash
dscl . -create /Users/$username RealName $fullname
dscl . -create /Users/$username UniqueID $usernumber
dscl . -create /Users/$username PrimaryGroupID 80
dscl . -create /Users/$username NFSHomeDirectory /Users/$username
dscl . -passwd /Users/$username $password
dscl . -append /Groups/admin GroupMembership $username
echo ""
echo $username" created! Enjoy!"
else
echo "Please run script again with correct information."
fi
