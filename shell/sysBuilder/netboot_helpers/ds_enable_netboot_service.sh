#!/bin/sh

SCRIPT_NAME=`basename "${0}"`
VERSION=1.0

########################################################
# Main
########################################################

echo "Running ${SCRIPT_NAME} v${VERSION} ("`date`")"

# Create NetBoot root folders
if [ ! -d /Library/NetBoot ]
then
  echo "  Creating /Library/NetBoot sub-folders..."
  mkdir /Library/NetBoot
  mkdir /Library/NetBoot/NetBootSP0
  mkdir /Library/NetBoot/NetBootClients0
  chown -R root:admin /Library/NetBoot
  chmod -R 775 /Library/NetBoot
fi

if [ ! -e /Library/NetBoot/.sharepoint ]
then
  cd /Library/NetBoot
  ln -s NetBootSP0 /Library/NetBoot/.sharepoint
fi

if [ ! -e /Library/NetBoot/.clients ]
then
  cd /Library/NetBoot
  ln -s NetBootClients0 /Library/NetBoot/.clients
fi

# Create tftp root folders for NetBoot
if [ ! -d /private/tftpboot/NetBoot ]
then
  echo "  Creating tftp NetBoot root folders..."
  mkdir /private/tftpboot/NetBoot
  ln -s /Library/NetBoot/NetBootSP0 /private/tftpboot/NetBoot
fi

# Configure tftpd service
echo "  Configuring tftp service..."
/usr/libexec/PlistBuddy -c "Set :ProgramArguments:1 -i" /System/Library/LaunchDaemons/tftp.plist

# Enable NFS daemon
NFS_READY=`grep NetBootSP0 /etc/exports 2>/dev/null | wc -l`
if [ ${NFS_READY} -lt 1 ]
then
  echo "  Creating NFS exports for NetBoot..."
  echo "/Library/NetBoot/NetBootSP0 -ro -maproot=root" >> /etc/exports
  echo "/Library/NetBoot/NetBootClients0 -ro -maproot=root" >> /etc/exports
fi

# Enable tftpd service
echo "  Enabling tftp service..."
launchctl load -w /System/Library/LaunchDaemons/tftp.plist 

# Enable bootpd service
echo "  Enabling bootpd service..."
launchctl load -w /System/Library/LaunchDaemons/bootps.plist 

echo "Exiting ${SCRIPT_NAME} v${VERSION} ("`date`")"

exit 0