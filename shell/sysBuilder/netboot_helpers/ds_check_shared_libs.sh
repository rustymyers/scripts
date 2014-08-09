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

BINS_COUNT=0
LIBS_COUNT=0
MISSING_COUNT=0

LIBS_IN_USE=""

find "${ROOT}" -type f -perm +111 > /tmp/check-bins.${$}
BINS_COUNT=`cat /tmp/check-bins.${$} | wc -l `

find "${ROOT}" -type f -perm +111 -exec otool -L "{}" \; > /tmp/check-libs.${$}
sed -e '/^\//d' /tmp/check-libs.${$} | awk '{ print $1 }' \
    | sed -e '/^@/d' -e '/^\/BinaryCache/d' -e '/^\/var\/tmp/d' -e '/^\/usr\/local/d' \
    | sort -u > /tmp/check-libs-clean.${$}
LIBS_COUNT=`cat /tmp/check-libs-clean.${$} | wc -l`

LIBS_IN_USE=`cat /tmp/check-libs-clean.${$}`
for LIB in ${LIBS_IN_USE}
do
  if [ ! -e "${ROOT}${LIB}" ] && [ -e "${LIB}" ]
  then
    MISSING_COUNT=`expr ${MISSING_COUNT} + 1`
    echo "Missing lib '${LIB}'"
  fi
done

echo "-> ${BINS_COUNT} binaries linked to ${LIBS_COUNT} shared libs (${MISSING_COUNT} missing)."

rm /tmp/check-*

exit 0
