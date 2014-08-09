#!/bin/sh

SCRIPT_NAME=`basename "${0}"`
VERSION=1.0

########################################################
# Main
########################################################

echo "Running ${SCRIPT_NAME} v${VERSION} ("`date`")"

# Update configuration file
if [ -e /tmp/dss-bootpd.plist ]
then
  echo "  Moving new bootpd configuration file to /etc/..."
  if [ -e /etc/bootpd.plist ]
  then
    rm /etc/bootpd.plist
  fi
  cp /tmp/dss-bootpd.plist /etc/bootpd.plist
  if [ ${?} -eq 0 ]
  then
    chmod 644 /etc/bootpd.plist
    chown root:wheel /etc/bootpd.plist
    rm /tmp/dss-bootpd.plist
  else
	echo "  Operation failed!"
	echo "Exiting ${SCRIPT_NAME} v${VERSION} ("`date`")"
	exit 1  
  fi
fi

echo "Exiting ${SCRIPT_NAME} v${VERSION} ("`date`")"

exit 0