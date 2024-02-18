#!/bin/bash

files=$(find . -iname "*.txt" -or -iname "*.md")

declare -A hashtable

for file in $files
do
	checksum=$(dd status=none if=$file bs=100 count=1 | md5sum | sed 's/[^a-f0-9]//g')
	if [[ ${#checksum} -ne 32 ]];
	then
		echo "Something went wrong. Could not get MD5 checksum for $file." 
		exit
	fi

	echo "$checksum: $file"
	
	unset delimiter
	if [[ ${hashtable[$checksum]} ]]
	then 
		delimiter=":"; 
	fi
	hashtable[$checksum]+="${delimiter}${file}"
	echo ${hashtable[$checksum]}

done

echo "---------------------------------------------"

echo "Number of redundant files: ${#hashtable[@]}"

for key in "${!hashtable[@]}";
do
	echo $key
	echo "${hashtable[$key]}" | sed 's/^/\t/g' | sed 's/:/\n\t/g'
done
