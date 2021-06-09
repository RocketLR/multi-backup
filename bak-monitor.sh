#!/bin/bash

#Todays date
Today=$(/bin/date "+%y%m%d")
test=$?
if [[ $test -ne 0 ]];
then 
	echo "Getting todays date failed!"
	exit 1
fi

#Backup directory - backup script should be in the same directory for simplicity. 
DIRECTORY=`dirname $0`

#########################################################################
############### Add Devices to the devices.json file in json format. ###########
declare -a Devices=()
declare -a Rotate=()


###
# ROTATION FUNCTION
###
_rotate()
{
	filename=$(_jqs '.dstfile')
	ext=$(_jqs '.ext')
	rotatefile="$filename""$ext"
	
	if [[ -f "$DIRECTORY/$rotatefile" ]]; then

					echo "Rotating ${filename}${ext} to ${filename}""_""${Today}${ext}"
					# add todays date between filename and the extention. ex: From name.cfg To name_20210105.cfg 
					find "$DIRECTORY""/" -type f -maxdepth 1 -name "$rotatefile" -exec mv {} "$DIRECTORY""/""${filename}""_""${Today}${ext}" \;
				else
					echo "   "
					echo "No $rotatefile in directory"
					echo "   "
	fi
}


### Build Switches list
backuplist=$(jq -r '.backup' "$DIRECTORY""/""devices.json")

for row in $(echo "${backuplist}" | jq -r '.[] | @base64'); do
    _jqs()
    {
     echo ${row} | base64 --decode | jq -r ${1}
    }

    if [[ "yes" == $(_jqs '.enabled') ]]; then
    		
    		Devices+=("$(_jqs '.dstfile')")

    		if [[ "yes" ==  $(_jqs '.rotate') ]]; then
    			_rotate
    		fi

    fi
done

# Declare config/log retention amount. X number of files will be kept at all time.
retention=30

######################## DONT TOUCH UNLESS BROKEN #########################
##########################################################################
# Will be used to compare against list with still not found device logs.
declare -a foundDevices=()
# Creating a list and filling it with the devices that need to be deleted upon being found.
declare -a missingDevices=(${Devices[@]})
echo "Todays Date $Today"
echo "   "
echo "LOOKING FOR  ${Devices[@]}"

for device in "${Devices[@]}"; do

	# Place every file that begins with a name from the Devices list
	FILES=$(find $DIRECTORY"/" -maxdepth 1 -name "$device*.*")
	printf "______"
	printf "looking for $device configuration file"
	printf "______\n"
	for FILE in $FILES; do

		#echo "in the loop :  $FILE"

	if [[ $(/bin/date -r "$FILE" "+%y%m%d") -lt "$Today" ]]; then
	#statements
	 
	 	#echo "$device""_""$(/bin/date -r "$FILE" "+%y%m%d"): PRESENT: YES"
		echo "$FILE :"
	elif [[ $(/bin/date -r "$FILE" "+%y%m%d") -eq "$Today" ]]; then
		#statements
		#echo "$device""_""$(/bin/date -r "$FILE" "+%y%m%d"): TODAYS FILE PRESENT: YES"
		echo "$FILE : TODAYS FILE PRESENT: YES"
		found="true"
		foundDevices+=("$device")

		# Can be used to exit loop as soon as todays device configuration file is found.	
		#break
	
	else
		echo "ERROR: The date is wrong on the server or config files are from the future"
		exit 1
	fi

		#miss="true"
		#missingDevices+=("$device")
		#unset found
	done

# Needs to go through the missing list and delete the devices that have been found.
# If all is well, every device will be deleted from the missing list.
if [[ ${missingDevices[@]} ]]; then
			for d in "${foundDevices[@]}"; do
					for i in "${!missingDevices[@]}"; do
						#echo "want to delete $d"
						#echo "Deleting $i from missing list"
						#echo "looking at " ${missingDevices[i]}
    					if [[ "${missingDevices[i]}" == "$d" ]]; then
    					#Deletes the found device from the missing list.
      					unset 'missingDevices[i]'
      					#echo "${missingDevices[i]} has been deleted"
    					fi
  					done
  			done
else
echo "Nothing"				
fi

if [ $found ]; then
		#Resetting the missing flag - telling the script that it finally found todays file.
		printf "\n \n"
		unset miss
fi
	#else
		#echo "Missing2 ${missingDevices[@]}"
	#fi  
	


done





#echo "Missing ${missingDevices[@]}"
if [[ ${missingDevices[@]} ]]; then
	echo "missing files from the following devices: ${missingDevices[@]}" 1>&2
	exit 1
fi

####
## DELETE FILES OLDER THAN 30 DAYS ONLY IF THERE IS MORE THAN 30 FILES SAVED FOR THAT DEVICE.
####

echo "---------------------------------------------"

echo "----- CLEANING UP FILE OLDER THAN $retention --------"
echo "---------------------------------------------"
echo " "

for device in "${Devices[@]}"; do
FILES=$(find $DIRECTORY"/" -name "$device*.*" -maxdepth 1 -type f | sort )

# Count how many times the device name occures in every line from $FILES
occurrences=$( echo $FILES | grep -o "$device*" | wc -l)

#echo $occurrences

for occurrence in ${occurrences[@]}; do
	
	# If there are more files with that specific device name than the retention number, list the files, sort them 
	# and delete the oldest ones. 
	if [[ $occurrence -gt $retention ]]; then
		
		echo "$device is greater than $retention"
		echo "Count - $occurrence"
		echo "Cleaning up files older than 30 days for Device: $device"
			# determin how much to delete. ex. If retention is 30 and the files are 32. then 32 - 30 = 2. That means there are two files that need to be deleted.
			over=$(($occurrence-$retention))
			echo "Skimming off: "$over
			# List the files, sort them and return only the oldest overflowing files. 
			oldFILES=$(find "$DIRECTORY""/" -name "$device*.*" -type f -maxdepth 1 | sort | head -$over)
				for oldfile in ${oldFILES[@]}; do
					echo "Moving $oldfile To $DIRECTORY""/deleted folder"
					mv $oldfile "$DIRECTORY""/deleted/"
				done


	else
		echo "$device is not greater than $retention"
		echo "Count - $occurrence"
	fi

done


done

exit 0
