#!/bin/sh

if [ ${EUID} -ne 0 ]
then
  echo "You need root privileges to run this script!"
  exit 1
fi

ROOT=/Volumes/DeployStudioRuntime
if [ ! -d "${ROOT}" ]
then
  ROOT=/Volumes/DeployStudioRuntimeHD
fi
if [ ! -d "${ROOT}" ]
then
  echo "${ROOT} volume not found, aborting!"
  exit 1
fi

if [ ! -e "${1}" ]
then
  echo "'${1}' source file not found, aborting!"
  exit 1
fi

ditto --rsrc "${1}" "${ROOT}/${1}"

exit 0
