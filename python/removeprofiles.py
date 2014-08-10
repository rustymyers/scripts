#!/usr/local/bin/python
 
import os
import subprocess
# import subprocess
# import re

ProfileInstalled = False
getprofile='/usr/bin/profiles -C'
print("GetProfile: "+getprofile)
profileDump = os.popen("/usr/bin/profiles -C")
for line in profileDump:
    if "com.meraki." in line:
        ProfileInstalled = True
        # Split the line into three parts
        lineSplit = line.rsplit(":")
        # Set the third element as variable
        profileName = lineSplit[2]
        if ":" in line:
            print("Found profile: {0}".format(profileName))
            # subprocess.call(["/usr/bin/profiles","-R","-p",profileName])
            subprocess.call(["/usr/bin/profiles","-L",profileName])
            #os.system("/usr/bin/profiles -R -p "+profileName)
            
if ProfileInstalled == False:
    print("There are no Apple Profile Manager Profiles installed on the system.  Uninstall not Required.")