#!/bin/bash
#--------------------------------------------------------------------------------------------------
#-- shellshock.sh
#--------------------------------------------------------------------------------------------------
# Program    : shellshock.sh
# To Complie : n/a
#
# Purpose    : detect, build, fix, package shellshock for OS X
#
# Called By  :
# Calls      : xcodebuild, tar, pkgbuild
#
# Author     : Rusty Myers <rzm102@psu.edu>
# Based Upon : http://apple.stackexchange.com/questions/146849/how-do-i-recompile-bash-to-avoid-shellshock-the-remote-exploit-cve-2014-6271-an
#
# Note       : Shellshock is the nickname for CVE-2014-6271, lumping in the similar issue CVE-2014-7168 with it.
#
# Revisions  : 
#           2014-09-26 <rzm102>   Initial Version
#
# Version    : 1.0
#--------------------------------------------------------------------------------------------------
PATH=/usr/local/bin:/usr/local/sbin:/usr/libexec:/Developer/usr/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin

function try6271 () {
	echo "#### "
	echo "#### We are going to run the command to test"
	echo "#### Between these lines is the output"
	echo "#### If the output has \"vulnerable\", your "
	echo "#### bash is vulnerable (CVE-2014-6271)"
	echo "#### "
	echo "#### "
	echo "#### "
	env x='() { :;}; echo vulnerable' bash -c 'echo hello'
	echo "#### "
	echo "#### "
	echo "#### "
	echo "#### If you don't see vulnerable, you're safe!"
	if [[ $(bash --version | grep "3.2.53(1)") ]]; then
		echo "#### Bash is safe, updated to 3.2.53(1)"
	fi
	echo "#### "
}

function try7168 () {
	echo "#### "
	echo "#### We are going to run the command to test"
	echo "#### Between these lines is the output"
	echo "#### If the output has the full time stamp & date "
	echo "#### at the end, your bash is vulnerable (CVE-2014-7168)"
	echo "#### "
	echo "#### "
	echo "#### "
	rm -f echo
	env X='() { (a)=>\' sh -c "echo date"; cat echo
	echo "#### "
	echo "#### "
	echo "#### "
	echo "#### If you don't see the date output, you're safe!"
	if [[ $(bash --version | grep "3.2.53(1)") ]]; then
		echo "#### Bash is safe, updated to 3.2.53(1)"
	fi
	echo "#### "
}

function detectBADBASH () {
	try6271
	try7168
}

function package () {
	if [[ ! -e "/tmp/build/Release/bash" ]]; then
		build
	fi
	
	####################################################################################################
	# Create Package
	####################################################################################################
	# Generate Temp directory
	package_root_tmp="$/tmp/ROOT"
	bin_root_tmp="${package_root_tmp}/bin/"

	/bin/mkdir -p $bin_root_tmp

	# Copy  into package root
	/bin/cp -pR /tmp/build/Release/bash "$bin_root_tmp"
	/bin/cp -pR /tmp/build/Release/sh "$bin_root_tmp"

	# Remove old packages
	if [[ -e "/tmp/bash-fix-CVE-2014-6271-CVE-2014-7168.pkg" ]]; then
		/bin/rm -R "/tmp/bash-fix-CVE-2014-6271-CVE-2014-7168.pkg"
	fi

	# Set output path for Package and create it
	/usr/bin/pkgbuild --quiet --root "$package_root_tmp" --id edu.psu.bash.fix.CVE.2014.6271.CVE.2014.7168 "bash-fix-CVE-2014-6271-CVE-2014-7168.pkg"
	open "/tmp/"

}

function fix () {
	if [[ ! -e "/tmp/build/Release/bash" ]]; then
		build
	fi
	
	if [[ $(bash --version | grep "3.2.53(1)") ]]; then
		echo "Bash is safe, updated to 3.2.53(1)"
	else
		sudo cp /bin/bash /bin/bash.old
		sudo cp /bin/sh /bin/sh.old

		sudo cp /tmp/build/Release/bash /bin
		sudo cp /tmp/build/Release/sh /bin 	
		echo "We've moved /bin/bash and /bin/sh to:"
		echo "/bin/bash.old & /bin/sh.old"
		echo "Restart to have the change take effect"
	fi
}

function build () {
	if [[ -e "/tmp/bash-fix" ]]; then
		echo "Cleaning out old builds"
		rm -R "/tmp/build"
		rm -R "/tmp/bash-fix"
	fi
	
	if [[ ! -e /usr/bin/xcodebuild ]]; then
		echo "Install Xcode first."
		exit 2
	fi
	
	cd /tmp/
	mkdir bash-fix
	cd bash-fix
	curl https://opensource.apple.com/tarballs/bash/bash-92.tar.gz | tar zxf -
	cd bash-92/bash-3.2
	curl https://ftp.gnu.org/pub/gnu/bash/bash-3.2-patches/bash32-052 | patch -p0    
	curl https://ftp.gnu.org/pub/gnu/bash/bash-3.2-patches/bash32-053 | patch -p0
	cd ..
	xcodebuild
	build/Release/bash --version # GNU bash, version 3.2.53(1)-release
	build/Release/sh --version   # GNU bash, version 3.2.53(1)-release
	
}

function buildFix () {
	build
	fix
}

options=( pkg build fix detect try7168 try6271 )
echo "Hello. What do you want to do?"
for i in "${options[@]}"; do
	echo "Option: $i"
done

echo -n "Enter your choice: "
read UserOption
echo "You Chose: ${UserOption:=help}"

case "$UserOption" in
	"build" )
	echo "You Chose: $UserOption"
	echo "You want to build a fix?"
	build;;
	"fix" )
	echo "You Chose: $UserOption"
	echo "You want to fix it?"
	fix;;
	"pkg" )
	echo "You Chose: $UserOption"
	echo "You want to pkg it?"
	package;;
	"detect" )
	echo "You Chose: $UserOption"
	detectBADBASH;;
	"try7168" )
	echo "You Chose: $UserOption"
	try7168;;
	"try6271" )
	echo "You Chose: $UserOption"
	try6271;;
	"help" )
	echo "Run this script to test & fix your system, build a new bash binary, or pacakage a binary for deployment."
	* )
	echo "You Chose: $UserOption"
	echo "That's not an option, sir. I said Good Day, sir!"
	exit;;
esac