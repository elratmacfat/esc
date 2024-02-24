#!/bin/bash
#
# Finds duplicate files across multiple subdirectories. 
#
# usage: 
# 	./find_duplicates.sh [options]* <filetype1[,filetype2]*>
#
# examples: 
# 	./find_duplicates --help
# 	./find_duplicates txt
# 	./find_duplicates --silent txt,md,doc
# 	./find_duplicates jpg,jpeg
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

# ---------------------------------------------------------------------------------------------------------
# Function definitions
# ---------------------------------------------------------------------------------------------------------

# Echo the number of fields in the string $1. Fields are separated by a newline (\n) and only
# by a newline. IFS is required to exclude spaces.
#
function field_count () {
	local n=0
	for dummy in $1; do ((++n)); done
	echo $n
}

# Print help message. Provide an unrecognized argument as first and only parameter to 
# let the user know that his input was invalid.
#
function print_usage_and_exit() {
	if [[ $1 ]]; then
		echo "unrecognized parameter \"$1\""
		echo ""
	fi
	echo "usage: $0 [option]* <filetype1[,filetype2]*>"
	echo "  filetype:     Filetypes separated by a ',' e.g. jpg,jpeg,png"
	echo "  options:"
	echo "    --help      Prints this help message and exits."
	echo "    --silent    Suppresses additional progress information."
	echo "                Should be used when output is redirected"
	echo "                into a file or pipe."
	echo ""
	echo "examples:"
	echo "  $0 jpg,jpeg"
	echo "  $0 --silent jpg > my_results"
	exit
}

function conditional_printf() {
	if [[ $silent -eq 0 ]]; then
		printf "$1"
	fi
}

function conditional_printf_progress() {
	if [[ $silent -eq 0 ]]; then
		p=$((100 * $1 / $2))
		printf "\r$p%%"
	fi
}

# ---------------------------------------------------------------------------------------------------------
# Parsing arguments and creating file list
# ---------------------------------------------------------------------------------------------------------

silent=0

if [[ $# -eq 0 ]]; then
	print_usage_and_exit
fi
((i=1))
for arg in "$@"; do
	if [[ $arg = "--help" ]]; then print_usage_and_exit
	elif [[ $i -eq $# ]]; then 
		backup=$IFS
		IFS=','
		filetype=$arg
		find_command="find . ";
		((k=0))
		for ext in $arg; do
			if [[ k -gt 0 ]]; then or=" -or "; fi
			find_command="${find_command}${or}-iname \"*.${ext}\""
			((k++))
		done
		IFS=$backup

	elif [[ $arg = "--silent" ]]; then silent=1
	else print_usage_and_exit $arg
	fi
	((++i))
done

# The default 'internal field separator' (IFS) yields space, tab and newline. The filenames this
# script is going to deal with could possibly contain spaces. Concatenating multiple filenames
# with spaces in between would therefore be errorprone.
#
IFS=$'\n'

files=($(eval "$find_command"))


# ---------------------------------------------------------------------------------------------------------
# Taking partial fingerprints of all files
# ---------------------------------------------------------------------------------------------------------

# Definition of associative arrays, that will be used to map filenames to MD5 checksums.
#
declare -A partial_fingerprints
declare -A full_fingerprints


i=0
n=${#files[@]}

conditional_printf "\n\ttaking partial fingerprints of $n files..."

for file in ${files[@]}
do
	((++i))
	conditional_printf_progress $i $n

	tmp=$(dd status=none if="${file}" bs=100 count=1 | md5sum)
	checksum=${tmp:0:32}

	partial_fingerprints[$checksum]+="${file}${IFS}"
done

# ---------------------------------------------------------------------------------------------------------
# Taking full fingerprints of possible duplicates 
# ---------------------------------------------------------------------------------------------------------

i=0
n=${#partial_fingerprints[@]}

conditional_printf "\n\ttaking full fingerprints of $n possible duplicates"

for key in "${!partial_fingerprints[@]}"
do
	((++i))
	conditional_printf_progress $i $n

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

conditional_printf "\n\tremoving false positives"

i=0
n=${#full_fingerprints[@]}

for key in "${!full_fingerprints[@]}"
do
	((++i))
	conditional_printf_progress $i $n

	number_of_possible_duplicates=$(field_count "${full_fingerprints[$key]}")

	if [[ $number_of_possible_duplicates -eq 1 ]]
	then
		unset full_fingerprints[$key]
	fi
done

conditional_printf "\n\nResults\n-------\n"

for key in "${!full_fingerprints[@]}"
do
	echo $key
	
	for f in ${full_fingerprints[$key]}; do
		echo "    $f"
	done

done



