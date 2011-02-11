#!/bin/sh
#
#
# Create_Email_Account v1 
#
#-------------------------------------------------------------------------
#
#          Created: Feb 2007
#         Modified: 18-06-07
#
#           Author: D Savage
#                   Humanities and Social Science Support
#                   Information Services
#                   University of Edinburgh
#
#-------------------------------------------------------------------------
#   Description:
#
#		Script to setup thunderbird and mail for new staff, runs once
#		by using the users loginwindow.plist, then deletes the file
# 		mac must be bound to AD!
#
#-------------------------------------------------------------------------
#	Disclaimer:
#
#		We accept no responsibility for, nor do we warrant the merchantibility or 
#		fitness of this script. Any use or modification is at your own risk, though 
#		we would request notification of any modification required.
#
#-------------------------------------------------------------------------

#
#Set environ
#
#get user shortname
user=`who | grep console| awk '{print $1}'`


#fetch data from AD
Get_AD_Data ()
{
role=$1
dscl localhost -read "/Active Directory/All Domains/Users/${user}" | grep "^${role}:" | awk '{print $2}'
}

empType=`Get_AD_Data employeeType` 
firstN=`Get_AD_Data FirstName`
lastN=`Get_AD_Data LastName` 

fullN=`echo $firstN $lastN`
#Only students don't use staff mail so
email=`echo ${user}@staffmail.ed.ac.uk`
mailServer="staff.mail.server"
AccountName="Staff M ail Service"
SMTPName="Staff.smtp.server"

#if a student then use sms
if [ "$empType" == "Student" ];
	then
	email=`echo ${user}@sms.ed.ac.uk`
	mailServer="student.mail.server"
	AccountName="Student Mail Service"
	SMTPName="student.smtp.serverk"
fi

#
#End environ
#
thunConf=`find /Users/$user/Library/Thunderbird/Profiles/ -name 'staff.mail.server*' -o -print`
mailConf=`ls /Users/${user}/Library/Mail | grep "staffmail"`
if ! [ -z $mailConf ] && ! [ -z $thunConf ]
	then
	exit 0;
fi


ls /Users/${user}/Library/Thunderbird/Profiles/ | grep -v '^[.*]' > /tmp/thun.txt


#
#Mail.app config done here
#

osascript <<EOF
tell application "Mail"
	set theAccountName to "$AccountName"
	set theMailServer to "$mailServer"
	set theUsername to "$user"
	set theFullName to "$fullN"
	set theEmailAddresses to "$email"
	set theSMTPName to "$SMTPName"
	try
		set theAccount to make new imap account with properties {name:theAccountName, user name:theUsername, server name:theMailServer, full name:theFullName, email addresses:theEmailAddresses, uses ssl:true}
		
	end try
	
	set theSMTPServer to make new smtp server with properties {server name:theSMTPName}
	set smtp server of theAccount to theSMTPServer
end tell
EOF

killall "Mail"



#
#Thunderbird config starts here
#
#server2




end='");'

cat /tmp/thun.txt | ( while read profileName; 
     do
prefFile="/Users/${user}/Library/Thunderbird/Profiles/${profileName}/prefs.js"

cat <<EOF >> $prefFile
user_pref("mail.account.account2.identities", "id1");
user_pref("mail.account.account2.server", "server2");
user_pref("mail.accountmanager.accounts", "account1,account2");
user_pref("mail.accountmanager.defaultaccount", "account2}");
user_pref("mail.identity.id1.doBcc", false);
user_pref("mail.identity.id1.doBccList", "");
user_pref("mail.identity.id1.draft_folder", "mailbox://nobody@Local%20Folders/Drafts");
user_pref("mail.identity.id1.drafts_folder_picker_mode", "0");
user_pref("mail.identity.id1.escapedVCard", "");
user_pref("mail.identity.id1.fcc_folder", "mailbox://nobody@Local%20Folders/Sent");
user_pref("mail.identity.id1.fcc_folder_picker_mode", "0");
user_pref("mail.identity.id1.fullName", "${fullN}");
user_pref("mail.identity.id1.organization", "");
user_pref("mail.identity.id1.reply_to", "");
user_pref("mail.identity.id1.smtpServer", "smtp1");
user_pref("mail.identity.id1.stationery_folder", "mailbox://nobody@Local%20Folders/Templates");
user_pref("mail.identity.id1.tmpl_folder_picker_mode", "0");
user_pref("mail.identity.id1.useremail", "${email}");
user_pref("mail.identity.id1.valid", true);
user_pref("mail.root.imap-rel", "[ProfD]ImapMail");
user_pref("mail.root.none-rel", "[ProfD]Mail");
user_pref("mail.server.server1.directory-rel", "[ProfD]Mail/Local Folders");
user_pref("mail.server.server1.hostname", "Local Folders");
user_pref("mail.server.server1.name", "Local Folders");
user_pref("mail.server.server1.type", "none");
user_pref("mail.server.server1.userName", "nobody");
user_pref("mail.server.server2.capability", 17593141);
user_pref("mail.server.server2.download_on_biff", true);
user_pref("mail.server.server2.hostname", "${mailServer}");
user_pref("mail.server.server2.isSecure", true);
user_pref("mail.server.server2.login_at_startup", true);
user_pref("mail.server.server2.max_cached_connections", 5);
user_pref("mail.server.server2.name", "${AccountName}");
user_pref("mail.server.server2.namespace.personal", "\"\"");
user_pref("mail.server.server2.namespace.public", "\"Shared Folders/\"");
user_pref("mail.server.server2.socketType", 3);
user_pref("mail.server.server2.timeout", 29);
user_pref("mail.server.server2.type", "imap");
user_pref("mail.server.server2.userName", "${user}");
user_pref("mail.smtp.defaultserver", "smtp1");
user_pref("mail.smtpserver.smtp1.auth_method", 1);
user_pref("mail.smtpserver.smtp1.hostname", "${SMTPName}");
user_pref("mail.smtpserver.smtp1.port", 25);
user_pref("mail.smtpserver.smtp1.try_ssl", 0);
user_pref("mail.smtpserver.smtp1.username", "${user}");
user_pref("mail.smtpservers", "smtp1");
EOF

done)

rm -dfr /Users/${user}/Library/Preferences/loginwindow.plist

exit 0;
