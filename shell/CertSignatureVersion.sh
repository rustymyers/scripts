#!/bin/bash
#--------------------------------------------------------------------------------------------------
#-- findv2certs
#--------------------------------------------------------------------------------------------------
# Program    : findv2certs
# To Complie : n/a
#
# Purpose    : List applications and their codesign signature versions
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
#           2014-08-06 <rzm102>   Initial Version
#
# Version    : 1.0
#--------------------------------------------------------------------------------------------------

find /Applications -maxdepth 3 -name "*.app" -print0 | while read -d '' -r file; do 
echo -n "$file - "
CODEVERSION=$(codesign -vd "$file" 2>&1 | awk '/version/ {print $3}')
echo "${CODEVERSION:-NONE}"
done

exit 0