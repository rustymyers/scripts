#!/bin/bash
# =====================================================
# This script creates ARD and InstaDMG ready pkg files
# It also creates puppet ready dmg files
#
# Created by 
# Hannes Juutilainen
# University of Jyväskylä, Finland
# Information Management Centre
# hannes.juutilainen@jyu.fi
# 
# Version 1.0b1 05/2009
#
# Copyright (C) 2009  Hannes Juutilainen
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
# =====================================================

# =======================
# = Start configuration =
# =======================

# Path to PackageMaker
PM_LOCATION="/Developer/Applications/Utilities/PackageMaker.app/Contents/MacOS/PackageMaker"

# Organization. Final id will be $ORGANIZATION.$INSTALL_NAME-$VERSION
ORGANIZATION="com.mycompany"

# Package target
TARGET_SYSTEM="10.4"

# Additional arguments for PackageMaker
#FLAGS="--root-volume-only --no-recommend --install-to / --verbose --discard-forks --temp-root"
FLAGS="--no-recommend"

# Output directories for pkg and dmg files
DMG_OUTPUT="/Volumes/data/temp/outputdir"
PKG_OUTPUT="/Volumes/data/temp/outputdir"


# Paths to required folders (No need to change these)
CURRENT_DIR=`pwd`
ROOT="$CURRENT_DIR/component"
RESOURCES="$CURRENT_DIR/resources"
SCRIPTS="$CURRENT_DIR/scripts"
DMG="$CURRENT_DIR/disk"
TMP="$CURRENT_DIR/tmp"
OUTPUT="$CURRENT_DIR/output"

# =====================
# = End configuration =
# =====================


function usage {
	echo ""
	echo "Usage: $0 [-t PACKAGE_TITLE] [-n PACKAGE_VERSION] [-c]"
	echo "		-t PACKAGE_TITLE, optional, should not contain spaces, special characters or version number"
	echo "		-n PACKAGE_VERSION, optional, the version of the application included"
	echo "		-c, Create the needed directory structure in this directory"
	echo ""
	echo "Example: $0 -t mysuperapp -n 5.1.4"
	echo ""
	echo "1.) Run this script with -c option to create the following directory structure:"
	echo "		./component"
	echo "			- Copy the installable files here."
	echo "			- Example: ./component/Applications/MySuperApp.app"
	echo "		./resources"
	echo "			- Read Me files etc."
	echo "			- Can be left empty"
	echo "		./scripts"
	echo "			- Scripts to run before or after the installation (preflight, postflight, etc.)"
	echo "			- Can be left empty"
	echo ""
	echo "	This script will also create the following directories while running packagemaker:"
	echo "		./disk (resulting .dmg file is created based on this directory)"
	echo "		./tmp (temporary files)"
	echo "		./output (resulting output files are placed here (both .pkg and .dmg))"
	echo ""
	echo "2.) Copy the items to the ./component directory."
	echo "		- ditto --norsrc --noqtn --noacl --noextattr /source/MySuperApp.app /dest/MySuperApp.app"
	echo ""
	echo "3.) Clean the component directory"
	echo "		.DS_Store etc. unwanted files should be removed"
	echo ""
	echo "4.) Run this script in the source directory as root"
	echo "		- If run without any options, this script will use current directory name as a title for the project."
	echo "		  Script will also look for a \"version\" text file in current directory and use the contents of that"
	echo "		  file as package version string"
	echo ""
	echo ""
	exit
}


# ===================
# = Parse arguments =
# ===================
INIT_NEW=0
while getopts :ht:n:c o
do
	case "$o" in
	h)
		usage;;
	t)
		INSTALL_NAME="$OPTARG"
		;;
	n)	
		INSTALL_VERSION="$OPTARG"
		;;
	c)
		INIT_NEW=1
		;;
	[?])
		usage;;
	esac
done
shift $(($OPTIND - 1))

# =========================
# = Make sure we are root =
# =========================
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

setup_new_project ()
{
	# Create directory structure
	if [[ ! -d $ROOT ]]; then
		mkdir $ROOT $ROOT/Applications
		chown root:admin $ROOT $ROOT/Applications
		chmod g+w $ROOT $ROOT/Applications
		echo "Created directory: $ROOT"
		echo "Created directory: $ROOT/Applications"
	fi
	if [[ ! -d $RESOURCES ]]; then
		mkdir $RESOURCES
		chown root:admin $RESOURCES
		chmod g+w $RESOURCES
		echo "Created directory: $RESOURCES"
	fi
	if [[ ! -d $SCRIPTS ]]; then
		mkdir $SCRIPTS
		chown root:admin $SCRIPTS
		chmod g+w $SCRIPTS
		echo "Created directory: $SCRIPTS"
	fi
	echo -e "\n# Done\n"
}


# =======================================
# = Make sure PackageMaker is installed =
# =======================================
if [[ ! -x $PM_LOCATION ]]; then
	echo "Error: Check the path to PackageMaker" 1>&2
	exit 1
fi


# ==========================================
# = Are we creating a directory structure? =
# ==========================================
if [[ $INIT_NEW = 1 ]]; then
	echo -e "\n# Creating a new project\n"
	setup_new_project
	exit 0
fi


# ===========================================
# = Check that we have a name and a version =
# ===========================================
if [[ -z $INSTALL_NAME ]] && [[ -z $INSTALL_VERSION ]]; then
	INSTALL_NAME_AUTO=`pwd | awk -F"/" '{print $NF}'`
	INSTALL_VERSION_AUTO=`cat $CURRENT_DIR/version`
	INSTALL_NAME=$INSTALL_NAME_AUTO
	INSTALL_VERSION=$INSTALL_VERSION_AUTO
fi


check_directory_structure ()
{
	# Check if the folder structure is correct
	echo "--"
	echo "Checking directory structure..."
	if [ ! -d $ROOT ] || [ ! -d $RESOURCES ] || [ ! -d $SCRIPTS ]; then
		echo "Directory structure is not correct. Bailing out..."
		usage
		exit 1
	else
		echo "Directory structure ok"
	fi
	echo ""
}

create_temp_directories ()
{
	# Create output directories
	if [ ! -d $OUTPUT ] || [ ! -d $DMG ]; then
			mkdir $OUTPUT $DMG
		else
			rm -rf $OUTPUT $DMG
			mkdir $OUTPUT $DMG
	fi
}


repair_applications ()
{
	# Set the correct permissions and remove extended attributes in $ROOT/Applications/*
	if [[ -d $ROOT/Applications ]]; then
		echo "--"
		echo "Removing extended attributes from $ROOT/Applications/*"
		xattr -d com.apple.quarantine $ROOT/Applications/*
		xattr -d com.apple.FinderInfo $ROOT/Applications/*
		echo "Setting owner and mode to root:admin, rwxrwxr-x"
		chown -R root:admin $ROOT/Applications/*
		chmod -R u+rw $ROOT/Applications/*
		chmod -R g+rw $ROOT/Applications/*
		chmod -R o-w $ROOT/Applications/*
		chmod -R o+r $ROOT/Applications/*
		echo ""
	fi
}

create_package ()
{
	# Create the package
	echo "--"
	FULL_INSTALL_NAME=$INSTALL_NAME-$INSTALL_VERSION
	INSTALL_ID=$ORGANIZATION.$FULL_INSTALL_NAME
	PM_COMMAND="$PM_LOCATION --root $ROOT --resources $RESOURCES --scripts $SCRIPTS --id \"$INSTALL_ID\" --title \"$FULL_INSTALL_NAME\" --version $INSTALL_VERSION --target $TARGET_SYSTEM $FLAGS --out $DMG/$FULL_INSTALL_NAME.pkg"
	echo "Creating package with command:"
	echo -e "\n$PM_COMMAND\n"
	$PM_COMMAND
	
	# Remove TokenDefinitions.plist from the package
	# This disables diverting when installing
	rm -f $DMG/$FULL_INSTALL_NAME.pkg/Contents/Resources/TokenDefinitions.plist
	echo""
}

create_dmg ()
{
	# Create the disk image
	echo "--"
	if [[ -e $DMG/$FULL_INSTALL_NAME.pkg ]]; then
			echo "Creating disk image..."
			hdiutil create -srcfolder $DMG -format UDBZ -volname "$FULL_INSTALL_NAME" -uid 99 -gid 99 -mode 444 -noscrub $OUTPUT/$FULL_INSTALL_NAME.dmg
			if [[ -e $DMG_OUTPUT/$FULL_INSTALL_NAME.pkg.dmg ]]; then
				rm -f $DMG_OUTPUT/$FULL_INSTALL_NAME.pkg.dmg
			fi
			echo "Image created"
		else
			echo "Error: No package. Can not create disk image!"
			exit 1
	fi
	echo ""
}

copy_files ()
{
	# Copy the packages and dmgs to output folders
	echo "--"
	echo "Copying files..."
	if [[ -e $DMG_OUTPUT ]]; then
		cp $OUTPUT/$FULL_INSTALL_NAME.dmg $DMG_OUTPUT/$FULL_INSTALL_NAME.pkg.dmg
		echo "Copied $FULL_INSTALL_NAME.pkg.dmg to $DMG_OUTPUT/$FULL_INSTALL_NAME.pkg.dmg"
	fi
	if [[ -e $PKG_OUTPUT ]]; then
		ditto $DMG/$FULL_INSTALL_NAME.pkg $PKG_OUTPUT/$FULL_INSTALL_NAME.pkg
		echo "Copied $FULL_INSTALL_NAME.pkg to $PKG_OUTPUT/$FULL_INSTALL_NAME.pkg"
	fi
	echo "Done"
	echo ""
}

clean_up ()
{
	# Clean up temp files etc.
	echo "--"
	if [[ -e $DMG/$FULL_INSTALL_NAME.pkg ]]; then
			echo "Cleaning up..."
			mv $DMG/$FULL_INSTALL_NAME.pkg $OUTPUT/$FULL_INSTALL_NAME.pkg
			rm -f $DMG/*
	else
			echo "Nothing to clean"
	fi
	echo ""
}


# ==============================
# = We have everything we need =
# = Start running the script   =
# ==============================
check_directory_structure
create_temp_directories
repair_applications
create_package
create_dmg
copy_files
clean_up
exit 0
