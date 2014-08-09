#!/usr/bin/python

# Credit Jeremy Reichman

import os
import fnmatch
import subprocess

os.environ['COMMAND_LINE_INSTALL'] = 1
package_filled_directory = '/private/tmp/packages/'
destination_volume = '/'
for file_found in os.listdir(package_filled_directory):
    if fnmatch.fnmatch(file_found, '*.pkg') or fnmatch.fnmatch(file_found, '*.mpkg'):
        subprocess.call(['/usr/sbin/installer', 
                         '-verbose', 
                         '-lang', 
                         'en', 
                         '-package', 
                         file_found, 
                         '-target', 
                         destination_volume])
                         
