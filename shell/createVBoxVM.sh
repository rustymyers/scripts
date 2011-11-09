#!/bin/bash

# Written by Rusty Myers
# 20111108

# Setup and Configure VirtualBox machine

# Variables

# Name of Virtual Machine to use
VMName="BIO230WLinux"
# Name of Disk Image that contains a VDI file.
# In this case we have a VDI with Ubuntu pre-installed.
VMDMGPath="/Users/Shared/2011_SEA_Linux_VM.dmg"
# Path to install VDI to
VDIInstall="$HOME/Desktop/"

#Functions

StartVM () {

# $1 = Name of VM

# Start the VM

# Open the VirtualBox Application, Disabled
# open /Applications/VirtualBox.app 

# VBoxManage startvm gui "$1" # gui not necessary

/usr/bin/VBoxManage startvm "$1"
}

GenerateVM () {

# $1 = Name of VM Machine
# $2 = Path of Disk Image with VDI

# Open DMG with VM and copy to the Desktop

# Mount disk image with full path
/usr/bin/hdiutil mount -nobrowse "$2"

# Set Name of Volume
VolumeName=`/usr/bin/basename $2|/usr/bin/awk -F. '{print $1}'`
# Set mount path of the volume
VolumeMount=`/sbin/mount|grep 2011_SEA_Linux_VM|/usr/bin/awk '{print $3}'`
# Set name of VDI from dmg
VDIName=`/bin/ls $VolumeMount`

# Copy VDI from disk image to Desktop if it's not there
if [[ ! -e "$VDIInstall/$VDIName" ]]; then
	/bin/echo "Copying system image. Please be patient..."
	/bin/cp "$VolumeMount/$VDIName" "$VDIInstall"
	/bin/echo "Almost done..."
	/bin/sleep 2
else
	echo "VDI \"$VDIName\" already exists"
fi
# Unmount the Volume
/usr/bin/hdiutil unmount "$VolumeMount"

# Configure VBox with new Machine and Hard Disk

/usr/bin/VBoxManage createvm --name "$VMName" --ostype Ubuntu --register

/usr/bin/VBoxManage modifyvm "$VMName" --memory 2048 --vram 16 --usb on --audio coreaudio --acpi on --boot1 dvd --nic1 nat

/usr/bin/VBoxManage storagectl "$VMName" --name "SATA Controller" --add sata

/usr/bin/VBoxManage storageattach "$VMName" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "$VDIInstall/$VDIName"

}

CheckVM () {

# $1 = Name of VM Machine

# Check for existing VM
if [[ `VBoxManage list vms|grep $1` ]]; then
	# VM exists
	StartVM "$VMName"
else
	# No VM here
	GenerateVM "$VMName" "$VMDMGPath"
	StartVM "$VMName"
fi
}

CheckVM "$VMName"

exit 0
