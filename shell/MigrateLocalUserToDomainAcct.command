#!/bin/sh
Version=1.0
# Modified 1/14/2009

# MigrateLocalUserToDomainAcct.command
# Patrick Gallagher
# http://macadmincorner.com
#

# This script should not need any modification in most enviornments. 
# If the script does not execute when run, you may need to 'chmod +x /path/to/thisScript' to make it executable

clear

netIDprompt="Please enter the network ID for this user: "
listUsers="$(/usr/bin/dscl . list /Users | grep -v eccsadmin | grep -v _ | grep -v root | grep -v uucp | grep -v amavisd | grep -v nobody | grep -v messagebus | grep -v daemon | grep -v www | grep -v Guest | grep -v xgrid | grep -v windowserver | grep -v unknown | grep -v unknown | grep -v tokend | grep -v sshd | grep -v securityagent | grep -v mailman | grep -v mysql | grep -v postfix | grep -v qtss | grep -v jabber | grep -v cyrusimap | grep -v clamav | grep -v appserver | grep -v appowner) FINISHED"
FullScriptName=`basename "$0"`
ShowVersion="$FullScriptName $Version"
check4AD=`/usr/bin/dscl localhost -list . | grep "Active Directory"`
osversionlong=`sw_vers -productVersion`
osvers=${osversionlong:3:1}

echo "********* Running $FullScriptName Version $Version *********"

# If the machine is not bound to AD, then there's no purpose going any further. 
if [ "${check4AD}" != "Active Directory" ]; then
	echo "This machine is not bound to Active Directory.\nPlease bind to AD first. "; exit 1
fi

RunAsRoot()
{
        ##  Pass in the full path to the executable as $1
        if [[ "${USER}" != "root" ]] ; then
                echo
                echo "***  This application must be run as root.  Please authenticate below.  ***"
                echo
                sudo "${1}" && exit 0
        fi
}

RunAsRoot "${0}"

until [ "$user" == "FINISHED" ]; do

	printf "%b" "\a\n\nSelect a user to convert or select FINISHED:\n" >&2
	select user in $listUsers; do
	
		if [ "$user" = "FINISHED" ]; then
			echo "Finshied converting users to AD"
			break
		elif [ -n "$user" ]; then
			if [ `who | grep console | awk '{print $1}'` == "$user" ]; then
				echo "This user is logged in.\nPlease log this user out and log in as another admin"
				exit 1
			fi
			
			# Determine location of the users home folder
			userHome=`/usr/bin/dscl . read /Users/$user NFSHomeDirectory | cut -c 19-`
			
			# Get list of groups
			echo "Checking group memberships for local user $user"
			lgroups="$(/usr/bin/id -Gn $user)"
			
			
			if [[ $? -eq 0 ]] && [[ -n "$(/usr/bin/dscl . -search /Groups GroupMembership "$user")" ]]; then 
			# Delete user from each group it is a member of
				for lg in $lgroups; 
					do
						/usr/bin/dscl . -delete /Groups/${lg} GroupMembership $user >&/dev/null
					done
			fi
			# Delete the primary group
			if [[ -n "$(/usr/bin/dscl . -search /Groups name "$user")" ]]; then
  				/usr/sbin/dseditgroup -o delete "$user"
			fi
			# Get the users guid and set it as a var
			guid="$(/usr/bin/dscl . -read "/Users/$user" GeneratedUID | /usr/bin/awk '{print $NF;}')"
			if [[ -f "/private/var/db/shadow/hash/$guid" ]]; then
 				/bin/rm -f /private/var/db/shadow/hash/$guid
			fi
			# Delete the user
			/usr/bin/dscl . -delete "/Users/$user"

			
				# Verify NetID
				printf "\e[1m$netIDprompt"
				read netname
				/usr/bin/killall DirectoryService
				sleep 10
				/usr/bin/id $netname
				# Check if there's a home folder there already, if there is, exit before we wipe it
				if [ -f /Users/$netname ]; then
					echo "Oops, theres a home folder there already for $netname.\nIf you don't want that one, delete it in the Finder first,\nthen run this script again."
					exit 1
				else
					/bin/mv $userHome /Users/$netname
					/usr/sbin/chown -R ${netname} /Users/$netname
					echo "Home for $netname now located at /Users/$netname"			
				fi
			break
		else
			echo "Invalid selection!"
		fi
	done
done