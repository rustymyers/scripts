#!/bin/bash

# Written by Rusty Myers
# 20100611
# List any extra admins and all local users

# dscl . append /Groups/admin GroupMembership rzm102admin
# dscl . append /Groups/admin GroupMembership rzm102

# # the echo command works in the terminal, so I want to make it a variable but it doesn't work
# StripUsers1=`echo `dscl . -list /users | grep -v \_ | sed "s/children//g;s/daemon//g;s/etcadmin//g;s/nobody//g;s/root//g"``
# # So I split the echo and dscl commands so it will work
# StripUsers=`dscl . -list /users | grep -v \_ | sed "s/children//g;s/daemon//g;s/etcadmin//g;s/nobody//g;s/root//g"`
# LocalUsers=`echo $StripUsers`
# # Is there a better way?

# Are you a local admin? List All local admins except for root and etcadmin
LocalAdmins=`sudo dscl . read /Groups/admin GroupMembership | sed 's/GroupMembership\:\ //g;s/root//g;s/etcadmin//g;s/amavisd//g;s/appowner//g;s/appserver//g;s/clamav//g;s/cyrusimap//g;s/eppc//g;s/jabber//g;s/lp//g;s/mailman//g;s/mysql//g;s/postfix//g;s/qtss//g;s/securityagent//g;s/sshd//g;s/tokend//g;s/unkown//g;s/windowserver//g;s/www//g;s/xgridagent//g;s/xgridcontroller//g;s/cyrus//g;s/smmsp//g;s/unknown//g'`
# List all users on the system except for the _* accounts, system accounts, and etcadmin
StripUsers=`dscl . -list /users | grep -v \_ | sed "s/children//g;s/daemon//g;s/etcadmin//g;s/nobody//g;s/root//g;s/amavisd//g;s/appowner//g;s/appserver//g;s/clamav//g;s/cyrusimap//g;s/eppc//g;s/jabber//g;s/lp//g;s/mailman//g;s/mysql//g;s/postfix//g;s/qtss//g;s/securityagent//g;s/sshd//g;s/tokend//g;s/unkown//g;s/windowserver//g;s/www//g;s/xgridagent//g;s/xgridcontroller//g;s/cyrus//g;s/smmsp//g;s/unknown//g"`
# echo of the StripUsers
LocalUsers=`echo $StripUsers`

# Testing echos
# echo \"$LocalAdmins\"
# echo \"$StripUsers\"
# echo \"$LocalUsers\"

# If $LocalAdmins returns empty or with a soace
if [[ "$LocalAdmins" == "" || "$LocalAdmins" == " " ]]; then
	echo "No Local Admins Present"
	# Write to log: if no users are admin
	defaults write /Library/ETC/BigFix/edu.psu.educ.admins Admin "None"
else
	echo "Local Admins Present: "$LocalAdmins
	# Write to log: the Local Admin users
	defaults write /Library/ETC/BigFix/edu.psu.educ.admins Admin "$LocalAdmins"
fi

# If computer has no users other than etcadmin
if [[ "$LocalUsers" == "" ]]; then
 	# Write to Log: No Users are Present
	defaults write /Library/ETC/BigFix/edu.psu.educ.admins Users "None"
else
	# Write to Log: List of Local Users 
	defaults write /Library/ETC/BigFix/edu.psu.educ.admins Users "$LocalUsers"
fi
# Fix permissons so BES can see it
chmod -R 755 /Library/ETC/
exit 0