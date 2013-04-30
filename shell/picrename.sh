#!/bin/bash

# Written by Rusty Myers
# 2013-04-29

# 042004 - Joker Picture - 1.JPG
# 042004 - Joker Picture - 2.JPG 

# loop through folder, set year variable
# loop through subfolder, set event name
# loop through images, set name with year - event - number
cd "Step 3 - Rename/"
for year in *; do
	for month in $year/*; do
		for event in "$month"/*; do
			imageNum=1
			for image in "$event"/*; do
				month="$(basename "$month"|awk '{print $1}'|tr -d :)"
				event="$(basename "$event")"
				imageName="$(basename "$image")"
				imageFolder="$(dirname "$image")"
				imageEx="${imageName##*.}"
				if [ -d "$image" ]; then
					imageNum=1
					for Newimage in "$image"/*; do
						
						imageName="$(basename "$image")"
						imageFolder="$(dirname "$image")"
						Newimage="$(basename "$Newimage")"
						imageEx="${Newimage##*.}"
						# If the image ends up being a stupid subfolder that Bree puts there
						# Drop the Event name and subsitute the directory name
						# echo "Year: $year"
						# echo "Month: $month"
						# echo "Event: $event"
						# echo "ImageName: $imageName"
						# echo "ImageExten: $imageEx"
						# echo "ImageFolder: $imageFolder"
						echo "Old Image Name: $imageFolder/$imageName -+-> $Newimage"
						echo "New Image Name: $imageFolder -+-> $month - $imageName - $imageNum.$imageEx"
						#mv "$imageFolder/$imageName" "$imageFolder/$month - $event - $imageNum.$imageEx"
						imageNum=$(expr $imageNum + 1)
					done
				else 
					# echo "Year: $year"
					# echo "Month: $month"
					# echo "Event: $event"
					# echo "ImageName: $imageName"
					# echo "ImageExten: $imageEx"
					# echo "ImageFolder: $imageFolder"
					echo "Old Image Name: $imageFolder -+-> $imageName"
					echo "New Image Name: $imageFolder -+-> $month - $event - $imageNum.$imageEx"
					#mv "$imageFolder/$imageName" "$imageFolder/$month - $event - $imageNum.$imageEx"
					imageNum=$(expr $imageNum + 1)
				fi
			done
		done
	done
done

exit 0
