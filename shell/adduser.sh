#!/bin/bash

#
# Script to generate a dsimportexport
# import file to replicate the function
# of an adduser script
#

#
# Rev. 1 7/3/04 - Joel Rennich - WWDC
# Rev. 2 7/27/04 - Joel Rennich - ATL
# Rev. 3 8/4/04 - Joel Rennich - SE Summer Camp
#

#
# Some definitions
#

IMPORT_FILE=/tmp/importfile.txt
GROUP=20
SHELL=/bin/bash
MY_UID=
IMPORT=NO
DSIMPORTEXPORT_PATH="/Applications/Server/Workgroup Manager.app/Contents/Resources/dsimportexport"

#
# check for root privs
#

check_root() {
    if [ `whoami` != "root" ]
    then
        echo "you need to be root to do this"
        exit 0;
    fi
}

#
# Check for an admin passsword
# and quit if there isn't one
#

check_admin(){
    if [ ! -z "LDAP_ADMIN_PASS" ]
    then
        echo "How very smart of you to not put your password in an option"
        echo "Please type it now: "
        stty_orig=`stty -g` 
        stty -echo 
        read LDAP_ADMIN_PASS 
        stty $stty_orig
    fi
}

#
# Get the options
#

while getopts s:n:p:h:l:g:f:A:P:NL SWITCH
do
    case $SWITCH in
        s) SHORT=$OPTARG;;
        n) NAME=$OPTARG;;
        p) PASS=$OPTARG;;
        h) MYHOSTNAME=$OPTARG;;
        l) SHELL=$OPTARG;;
        g) GROUP=$OPTARG;;
        f) IMPORT_FILE=$OPTARG;;
        N) NI=YES;;
        L) LDAP=YES;;
        A) ADMIN_NAME=$OPTARG;;
        P) LDAP_ADMIN_PASS=$OPTARG;;
        *) echo "usage goes here"
            exit 1;;
    esac
done

# build header file on the import file

echo "0x0A 0x25 0x3A 0x2C dsRecTypeStandard:Users 9 dsAttrTypeStandard:RecordName dsAttrTypeStandard:AuthMethod dsAttrTypeStandard:Password dsAttrTypeStandard:UniqueID dsAttrTypeStandard:PrimaryGroupID dsAttrTypeStandard:RealName dsAttrTypeStandard:HomeDirectory dsAttrTypeStandard:NFSHomeDirectory dsAttrTypeStandard:UserShell" > $IMPORT_FILE

# set Long Name to short if Long Name hasn't been defined

if [ ! -z $NAME ]
then
    NAME=$SHORT
fi

# Find out if we have a home

if [ ! -z $MYHOSTNAME ]
then
    HOMEURL="<home_dir><url>afp%://${MYHOSTNAME}</url><path>${SHORT}</path></home_dir>"
    HOMEFSPATH="/Network/Servers/${MYHOSTNAME}/Users/${SHORT}"
else
    HOMEURL=""
    HOMEFSPATH="/Users/${SHORT}"
fi

# Generate a user record

echo "$SHORT:dsAuthMethodStandard%:dsAuthClearText:$PASS:$MY_UID:$GROUP:$NAME:$HOMEURL::$SHELL" >> $IMPORT_FILE

if [ ! -z $NI ]
then
    check_admin
    "$DSIMPORTEXPORT_PATH" -g $IMPORT_FILE /NetInfo/root/ $ADMIN_NAME $LDAP_ADMIN_PASS -O
fi

if [ ! -z $LDAP ]
then
    check_admin
    "$DSIMPORTEXPORT_PATH" -g $IMPORT_FILE /LDAPv3/127.0.0.1/ $ADMIN_NAME $LDAP_ADMIN_PASS -O
fi