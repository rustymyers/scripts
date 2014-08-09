#!/bin/bash

# Written by Rusty Myers
# 2012-08-31

# This script is designed to move images into subfolders based on their creation date.
# A file created on February 21st, 2013 will be filed under:
#	./2013/02/21/file.name

# Get files
# get exif data
# create directories
# Move files
# Rename file if needed

if [[ -z $1 ]]; then
	echo "Missing Path to images. Need help?"
	echo "Use: photoorg -h"
fi

# Get path to files as input 1
pathToPhotos="$1"

exiftool "-FileName<CreateDate" -d "%Y%m%d_%H%M%S.%%e" DIR

exiftool "-Directory<DateTimeOriginal" -d "%Y/%m/%d" DIR
# Check "Create Date". Watch out for "Create Date: 0000:00:00 00:00:00"
# File Modification Date/Time: 2011:09:16 20:13:46-04:00
# http://www.sno.phy.queensu.ca/~phil/exiftool/filename.html

exit 0
