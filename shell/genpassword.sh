#!/bin/bash

# to set passwords in a username and password file
# Each $line is "username"
# passwords are generated and added as second variable in csv file

# Path to the file with users that need passwords
Users="/Users/rzm102/Desktop/users.txt"
# Path to the file with users and generated passwords
UsersAndPasswords="/Users/rzm102/Desktop/userspass.txt"

while read line
do
new_password=`openssl rand -base64 8`
#/usr/bin/dscl -u diradmin -p password /LDAPv3/127.0.0.1 -passwd /Users/"$line $new_password"
echo "$line, $new_password" >> "$UsersAndPasswords"
done < "$Users"