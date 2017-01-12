#!/usr/bin/python
#--------------------------------------------------------------------------------------------------
#-- 
#--------------------------------------------------------------------------------------------------
# Program    : 
# To Complie : n/a
#
# Purpose    : 
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
#           2016-10-04 <rzm102>   Initial Version
#
# Version    : 1.0
#--------------------------------------------------------------------------------------------------



import base64

with open("/Users/rzm102/Desktop/SelfService/Terminal.png", "rb") as image_file:
    encoded_string = base64.b64encode(image_file.read())
print encoded_string