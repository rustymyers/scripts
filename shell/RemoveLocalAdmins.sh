#!/bin/bash

# Written by Rusty Myers
# 20100611
# Remove admin rights from all local users except etcadmin, root, other system accounts

# Read all local admins except for root and etcadmin
LocalAdmins=`sudo dscl . read /Groups/admin GroupMembership | sed 's/GroupMembership\:\ //g;s/root//g;s/etcadmin//g'`

# If LocalAdmins is empty or one space
if [[ $LocalAdmins == "" || $LocalAdmins == " " ]]; then
	# Write to log: No Local Admins
	echo "No Local Admins Present"
	defaults write /Library/ETC/BigFix/edu.psu.educ.RemoveLocalAdmins Admins "None"
else
	echo "Local Admins Present: "$LocalAdmins
	# Write to log: Local Admins Present
	defaults write /Library/ETC/BigFix/edu.psu.educ.RemoveLocalAdmins Admins "$LocalAdmins"
	# Clear any old array so we don't get duplicate names
	defaults write /Library/ETC/BigFix/edu.psu.educ.RemoveLocalAdmins REMOVEDADMINS -array
	# For each local admin, do the following
	for i in $LocalAdmins; do
		echo "Removing admin rights for $i"
		# Write to log: Each user that is removed
		defaults write /Library/ETC/BigFix/edu.psu.educ.RemoveLocalAdmins REMOVEDADMINS -array-add $i
		# Remove User from Admin Group
		sudo dscl . delete /Groups/admin GroupMembership $i	
	done
	# Write array of users in format BigFix can read
	RemovedAdmins=`defaults read /Library/ETC/BigFix/edu.psu.educ.RemoveLocalAdmins REMOVEDADMINS | sed 's/[(),]//g' | tr -d '\n'`
	defaults write /Library/ETC/BigFix/edu.psu.educ.RemoveLocalAdmins RemovedAdmins "$RemovedAdmins"
fi
# Fix permissons so BES can see it
chmod -R 755 /Library/ETC/
exit 0