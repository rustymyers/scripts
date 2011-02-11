#!/bin/bash

adminusername=admin		##Use your admin username that you want ARD to use to access your system.

/System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -configure -allowAccessFor -specifiedUsers
/System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -targetdisk "$3" -activate -configure -access -on -users "$adminusername" -privs -all -restart -agent -menu


