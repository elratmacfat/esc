#!/bin/bash


files=$(find . -iname "*.txt" -or -iname "*.md")

# A white-space must not be interpreted as delimiting character,
# because there could be files and directories containing spaces.
# We're assuming here that there are no new-line characters
#
IFS_backup=$IFS
IFS_newline_only=$'\n'
IFS=$IFS_newline_only

# Associative array that is used to map each file to the MD5-checksum 
# that's generated from the file's first 100 bytes.
# Multiple files being mapped to the same checksum are considered 
# possible duplicates.
#
declare -A possible_duplicates
declare -A actual_duplicates

echo "----------------------------------------------------"
echo "Partially calculating MD5 checksums for all files..."
echo "----------------------------------------------------"

for file in $files; do

	# md5sum produces a string starting with the 32 byte wide MD5 sum followed
	# by some additional information, separated by spaces
	#
	IFS=$IFS_backup
	partial_checksum=($(dd status=none if="${file}" bs=100 count=1 | md5sum))
	IFS=$IFS_newline_only

	# Append current filename. If it is the first filename to be mapped
	# to the partial checksum the delimiter is omitted.
	#
	unset delimiter
	if [[ ${possible_duplicates[$partial_checksum]} ]]; then 
		delimiter=${IFS};
	fi
	possible_duplicates[$partial_checksum]+="${delimiter}${file}"
done


echo "--------------------------------------------------------"
echo "Calculating MD5 checksums for all possible duplicates..."
echo "--------------------------------------------------------"

for key in "${!possible_duplicates[@]}"
do
	number_of_possible_duplicates=0
	for dummy in ${possible_duplicates[$key]}; do ((++number_of_possible_duplicates)); done

	if [[ $number_of_possible_duplicates -gt 1 ]]
	then
		#echo "$key: $number_of_possible_duplicates"
		
		for file in ${possible_duplicates[$key]};
		do
			IFS=$IFS_backup
			full_checksum=($(md5sum "$file"))
			IFS=$IFS_newline_only

			echo "    $full_checksum : $file"


			unset delimiter
			if [[ ${actual_duplicates[$full_checksum]} ]]; then 
				delimiter=${IFS};
			fi
			actual_duplicates[$full_checksum]+="${delimiter}${file}"
		done
	fi
done

echo "-------"
echo "Results"
echo "-------"

for key in "${!actual_duplicates[@]}"
do
	number_of_actual_duplicates=0
	for dummy in ${actual_duplicates[$key]}; do ((++number_of_actual_duplicates)); done
	if [[ $number_of_actual_duplicates -gt 1 ]]
	then
		echo "$key: $number_of_actual_duplicates"
		for file in ${actual_duplicates[$key]};
		do
			echo "    $file"
		done
	fi
done
