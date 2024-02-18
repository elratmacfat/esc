#!/bin/bash
#
# This script is work-in-progress (as of 2024/02/18)
#
# Finds duplicate files across multiple subdirectories. 
#
# The approached solution and the dimensions of its parameter are chosen for an image collection, which
# has grown for years. Thousands of jpg-images have piled up and have been copied around in most chaotic 
# ways.
#
# Duplicate files may exist under different names. Therefore the filename must not be considered when
# searching for those.
# The script starts off by reading only the first few bytes of each file. These bytes are used to 
# generate a partial fingerprint. All files with the same partial fingerprint go into the same bucket.
# This could potentially result in a lots of buckets, but since only a small chunk of each file is read, 
# this should not too bad (run-time-wise).
# In a next step, every bucket that contains more than one file possibly contains duplicates. For each of 
# these pre-filtered files, the full fingerprint is generated. Files with the same full fingerprint go
# into the same bucket. In the end those buckets are kept that contain more than one file.
#

# The default 'internal field separator' (IFS) yields space, tab and newline. The filenames this
# script is going to deal with could possibly contain spaces. Concatenating multiple filenames
# with spaces in between would therefore be errorprone.
#
IFS_backup=$IFS
IFS_newline_only=$'\n'
IFS=$IFS_newline_only

# Definition of associative arrays, that will be used to map filenames to MD5 checksums.
#
declare -A possible_duplicates
declare -A actual_duplicates

echo "=== stage 1 - taking partial fingerprints  ==="

for file in $(find . -iname "*.txt" -or -iname "*.md")
do
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

echo "=== stage 2 - taking full fingerprints of possible duplicates ==="

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

echo "=== stage 3 - removing false positives ==="

for key in "${!actual_duplicates[@]}"
do
	number_of_actual_duplicates=0
	for dummy in ${actual_duplicates[$key]}; do ((++number_of_actual_duplicates)); done
	if [[ $number_of_actual_duplicates -eq 1 ]]
	then
		echo "    ${actual_duplicates[$key]} is unique."
		unset actual_duplicates[$key]
	fi
done

echo "=== stage 4 ==="

for key in "${!actual_duplicates[@]}"
do
	echo $key
	for file in ${actual_duplicates[$key]};
	do
		echo "    $file"
	done
	done
