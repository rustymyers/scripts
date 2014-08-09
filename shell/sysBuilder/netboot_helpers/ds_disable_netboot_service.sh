#!/bin/sh

SCRIPT_NAME=`basename "${0}"`
VERSION=1.0

########################################################
# Main
########################################################

echo "Running ${SCRIPT_NAME} v${VERSION} ("`date`")"

# Disable tftpd service
echo "  Disabling tftp service..."
launchctl unload -w /System/Library/LaunchDaemons/tftp.plist >/dev/null 2>&1

# Disable bootpd service
echo "  Disabling bootpd service..."
launchctl unload -w /System/Library/LaunchDaemons/bootps.plist >/dev/null 2>&1

echo "Exiting ${SCRIPT_NAME} v${VERSION} ("`date`")"

exit 0
