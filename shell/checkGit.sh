#!/bin/bash
#--------------------------------------------------------------------------------------------------
#-- checkRepos
#--------------------------------------------------------------------------------------------------
# Program    : checkRepos
# To Complie : n/a
#
# Purpose    : Check all of my .git repos to make sure they are in sync with remotes.
#
# Called By  :
# Calls      :
#
# Author     : Rusty Myers <rzm102@psu.edu>
# Based Upon :
#
# Note       : 
#
# Revisions  : 
#           2014-08-09 <rzm102>   Initial Version
#
# Version    : 1.0
#--------------------------------------------------------------------------------------------------
Recursive="OFF"
SAFETY="ON"

while getopts rs opt; do
	case "$opt" in
		r) Recursive="ON";;
		s) SAFETY="OFF";;
		h) 
			help
			exit 0;;
		\?)
			help
			exit 0;;
	esac
done
shift `expr $OPTIND - 1`

function checkGit () { 
	for file in "${@}"; do
		if [[ $SAFETY == "ON" ]]; then
			if [[ -e "$file"/.git ]]; then 
				echo "$file = True"
				cd  "$file/" && git status -s
			else
				echo "$file = False"
			fi
		else
			if [[ -e "$file"/.git ]]; then 
				echo "$file = True"
				cd  "$file/" && git status -s
				git pull
			fi
		fi
	done
}


# Find git repos on system
if [[ $Recursive == "ON" ]]; then
	for file in "${@}"; do
		checkGit "${file}"/* 
	done
else
	checkGit "${@}"
fi


# Report status (one word at least (preffered)) & Path 

# ADD: Link folder to desktop

# ADD: Pull/Push


exit 0


# function checkGit () { for file in ./"${1}"*; do if [[ -e "$file"/.git ]]; then echo "$file = True"; else echo "$file = False"; fi; done }