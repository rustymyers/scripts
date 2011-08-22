#!/bin/sh

PASSWORD_HASH="$1/Contents/Resources/password_hash"
TARGET_DIR="$3"

        #user specific
SHORTNAME="localadmin"
LONGNAME="Local Admin"

        # verify we can find the local node
DSLocalDB="${TARGET_DIR}/var/db/dslocal/nodes/Default"

        if [ ! -e "$DSLocalDB" ]; then
            echo "Can't find target ${DSLocalDB}"
            exit 2
        fi
        echo "found the local node"

check_uid()
{
    
        # search for unused uid after 500
        for ((uid=501; uid<600; uid++)); do
            output=`dscl . -search /Users UniqueID $uid`
            if [ "$output" == "" ]; then
                break
            fi
        echo "Next free uid is $uid"
        done
}

check_uid

/usr/bin/dscl . -create /Users/$SHORTNAME
/usr/bin/dscl . -create /Users/$SHORTNAME
/usr/bin/dscl . -create /Users/$SHORTNAME realname "${LONGNAME}"
/usr/bin/dscl . -create /Users/$SHORTNAME gid 20
/usr/bin/dscl . -create /Users/$SHORTNAME UniqueID $uid
/usr/bin/dscl . -create /Users/$SHORTNAME home /Users/$SHORTNAME
/usr/bin/dscl . -create /Users/$SHORTNAME picture "/Library/User Pictures/Fun/Beach Ball.tif"
/usr/bin/dscl . -create /Users/$SHORTNAME passwd "*"
/usr/bin/dscl . -create /Users/$SHORTNAME shell "/bin/bash"
/usr/bin/dscl . -merge /Users/$SHORTNAME authentication_authority ";ShadowHash;"
/usr/bin/dscl . -merge /Groups/admin GroupMembership $SHORTNAME

    #get the auto-generated genUID 
genUID=`/usr/bin/dscl . -read /Users/$SHORTNAME generateduid|awk '{print $2}'`


#create shadow hash file(escaping newline) and set perms
`/bin/cat "${PASSWORD_HASH}">"${TARGET_DIR}/var/db/shadow/hash/$genUID"` || exit 1
echo "Dumped contents of stored password hash in to users associated shadowhash file"
/bin/chmod 600 "${TARGET_DIR}/var/db/shadow/hash/$genUID"

exit 0