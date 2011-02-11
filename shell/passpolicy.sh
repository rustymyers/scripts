#!/bin/bash

# Written by Rusty Myers
# 20100616

# pwpolicy

   #   pwpolicy [-h]
   #   pwpolicy [-v] [-a authenticator] [-p password] [-u username | -c computername] [-n nodename] command command-arg
   #   pwpolicy [-v] [-a authenticator] [-p password] [-u username | -c computername] [-n nodename] command "policy1=value1 policy2=value2 ..."
   # 
   #   -a    name of the authenticator
   # 
   #   -c    name of the computer account to modify
   # 
   #   -p    password (omit this option for a secure prompt)
   # 
   #   -u    name of the user account to modify
   # 
   #   -n    use a specific directory node; the search node is used by default.
   # 
   #   -v    verbose
   # 
   #   -h    help
   # 
   # Commands
   #   -getglobalpolicy             Get global policies
   #   -setglobalpolicy             Set global policies
   #   -getpolicy                   Get policies for a user
   #   --get-effective-policy       Gets the combination of global and user policies that apply to the user.
   #   -setpolicy                   Set policies for a user
   #   -setpolicyglobal             Set a user account to use global policies
   #   -setpassword                 Set a new password for a user. Non-administrators can use this command to change their own
   #                                passwords.
   #   -enableuser                  Enable a shadowhash user account that was disabled by a password policy event.
   #   -getglobalhashtypes          Returns the default list of password hashes stored on disk for this system.
   #   -setglobalhashtypes          Edits the default list of password hashes stored on disk for this system.
   #   -gethashtypes                Returns a list of password hashes stored on disk for a user account.
   #   -sethashtypes                Edits the list of password hashes stored on disk for a user account.
   #   -0 through -7                Shortcuts for the above commands (in order).
   # 
   # Global Policies
   #   usingHistory                      0 = user can reuse the current password, 1 = user cannot reuse the current password, 2-15
   #                                     = user cannot reuse the last n passwords.
   #   usingExpirationDate               If 1, user is required to change password on the date in expirationDateGMT
   #   usingHardExpirationDate           If 1, user's account is disabled on the date in hardExpireDateGMT
   #   requiresAlpha                     If 1, user's password is required to have a character in [A-Z][a-z].
   #   requiresNumeric                   If 1, user's password is required to have a character in [0-9].
   #   expirationDateGMT                 Date for the password to expire, format must be: mm/dd/yy
   #   hardExpireDateGMT                 Date for the user's account to be disabled, format must be: mm/dd/yy
   #   maxMinutesUntilChangePassword     user is required to change the password at this interval
   #   maxMinutesUntilDisabled           user's account is disabled after this interval
   #   maxMinutesOfNonUse                user's account is disabled if it is not accessed by this interval
   #   maxFailedLoginAttempts            user's account is disabled if the failed login count exceeds this number
   #   minChars                          passwords must contain at least minChars
   #   maxChars                          passwords are limited to maxChars
   # 
   # Additional User Policies
   #   isDisabled                   If 1, user account is not allowed to authenticate, ever.
   #   isAdminUser                  If 1, this user can administer accounts on the password server.
   #   newPasswordRequired          If 1, the user will be prompted for a new password at the next authentication. Applications
   #                                that do not support change password will not authenticate.
   #   canModifyPasswordforSelf     If 1, the user can change the password.
   # 
   # Stored Hash Types
   #   CRAM-MD5         Required for IMAP.
   #   RECOVERABLE      Required for APOP and WebDAV. Only available on Mac OS X Server edition.
   #   SALTED-SHA1      The default for login window.
   #   SMB-LAN-MANAGER  Required for compatibility with Windows 9.x file sharing.
   #   SMB-NT           Required for compatibility with Windows NT/XP file sharing.
   # 

#Get user policy
pwpolicy -u etcadmin -n /Local/Default -setpolicy "isDisabled 1"
pwpolicy -a etcadmin -u test -setpolicy "isDisabled=1"


exit 0