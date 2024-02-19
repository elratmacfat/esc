#!/bin/bash
#
# This script is work-in-progress (as of 2024/02/18)
#
# Finds duplicate files across multiple subdirectories. 
#
# ---------------------------------------------------------------------------------------------------------
#
# The approached solution and the dimensions of its parameters are chosen for an image collection, which
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
# ---------------------------------------------------------------------------------------------------------

# Echo the number of fields in the string $1. Fields are separated by a newline (\n) and only
# by a newline. IFS is required to exclude spaces.
#
function field_count () {
	local n=0
	for dummy in $1; do ((++n)); done
	echo $n
}

function print_files() {
	for f in $1; do
		echo "    $f"
	done
}


# The default 'internal field separator' (IFS) yields space, tab and newline. The filenames this
# script is going to deal with could possibly contain spaces. Concatenating multiple filenames
# with spaces in between would therefore be errorprone.
#
IFS=$'\n'

files=($(find . -iname "*.txt" -or -iname "*.md")) 


# Definition of associative arrays, that will be used to map filenames to MD5 checksums.
#
declare -A partial_fingerprints
declare -A full_fingerprints


i=0
n=${#files[@]}

printf "\ttaking partial fingerprints of $n files..."

for file in ${files[@]}
do
	((++i))
	p=$((100 * $i / $n))
	printf "\r$p%%"

	tmp=$(dd status=none if="${file}" bs=100 count=1 | md5sum)
	checksum=${tmp:0:32}

	partial_fingerprints[$checksum]+="${file}${IFS}"
done

i=0
n=${#partial_fingerprints[@]}

printf "\n\ttaking full fingerprints of $n possible duplicates"

for key in "${!partial_fingerprints[@]}"
do
	((++i))
	p=$((100 * $i / $n))
	printf "\r$p%%"

	number_of_possible_duplicates=$(field_count "${partial_fingerprints[$key]}")

	if [[ $number_of_possible_duplicates -gt 1 ]]
	then
		for file in ${partial_fingerprints[$key]};
		do
			tmp=$(md5sum "$file")
			checksum=${tmp:0:32}

			full_fingerprints[$checksum]+="${file}${IFS}"
		done
	fi
done

printf "\n\tremoving false positives"

for key in "${!full_fingerprints[@]}"
do
	number_of_possible_duplicates=$(field_count "${full_fingerprints[$key]}")

	if [[ $number_of_possible_duplicates -eq 1 ]]
	then
		unset full_fingerprints[$key]
	fi
done

printf "\n\nResults\n-------\n"

for key in "${!full_fingerprints[@]}"
do
	echo $key
	print_files "${full_fingerprints[$key]}"
done



