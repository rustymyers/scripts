#!/bin/sh

SCRIPT_NAME=`basename "${0}"`
VERSION=1.0

########################################################
# Functions
########################################################

print_usage() {
  echo "Usage: ${SCRIPT_NAME} <netboot set name>"
  echo "       ${SCRIPT_NAME} DSR-1065"
}

########################################################
# Main
########################################################

echo "Running ${SCRIPT_NAME} v${VERSION} ("`date`")"

if [ ${#} -ne 1 ]
then
  print_usage
  exit 1
fi

DEFAULT_NETBOOT_SET_NAME=`echo "${1}" | tr ' ' '-'`.nbi
if [ -z "${DEFAULT_NETBOOT_SET_NAME}" ]
then
  print_usage
  exit 1
fi

for SYSTEM_VOLUME in /Volumes/*
do
  for NETBOOT_SET_PATH in "${SYSTEM_VOLUME}"/Library/NetBoot/NetBootSP?/*.nbi
  do
    if [ -e "${NETBOOT_SET_PATH}/NBImageInfo.plist" ]
    then
      NETBOOT_SET_NAME=`basename "${NETBOOT_SET_PATH}"`
      if [ "${NETBOOT_SET_NAME}" = "${DEFAULT_NETBOOT_SET_NAME}" ]
      then
        echo "Enabling DeployStudio NetBoot set '${NETBOOT_SET_NAME}'..."
        defaults write "${NETBOOT_SET_PATH}/NBImageInfo" IsEnabled -bool YES
      else
        echo "Disabling NetBoot set '${NETBOOT_SET_NAME}'..."
        defaults write "${NETBOOT_SET_PATH}/NBImageInfo" IsEnabled -bool NO
        defaults write "${NETBOOT_SET_PATH}/NBImageInfo" IsDefault -bool NO
      fi
      plutil -convert xml1 "${NETBOOT_SET_PATH}/NBImageInfo.plist"
    fi
  done
done

echo "Exiting ${SCRIPT_NAME} v${VERSION} ("`date`")"

exit 0
