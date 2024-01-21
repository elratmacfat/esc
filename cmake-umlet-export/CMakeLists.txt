# An older version might be sufficient... Not tested.
cmake_minimum_required(VERSION 3.21) 

project(umlet_export)

find_package(Java REQUIRED)

include(UseJava)

# As of CMake version 3.21 the documentation of find_jar is a bit poor. It does not 
# state that the jar-extension must be omitted when searching for jar-file. So the
# part 'NAMES umlet.jar' would not find the given jar, but 'NAMES umlet' would.
#
find_jar(path_to_umlet_jar NAMES umlet PATHS ENV "PATH")
if (${path_to_umlet_jar} STREQUAL "path_to_umlet_jar-NOTFOUND")
	message(FATAL_ERROR "Could not locate \"umlet.jar\". Skipping diagram conversion.")
endif()


# List all source uxf-files that are to be converted. A relative path is required. Do not
# prepend CMAKE_CURRENT_SOURCE_DIR.
# 
set(input_files
	overview.uxf
	dir1/classes.uxf
	dir1/subdir/classes.uxf
	dir2/sequence.uxf)

# Defines the output format. This is not merely a filename extension, but also the format
# specifier passed to the Umlet converter. Possible formats are bmp, eps, gif, jpg, pdf, 
# png and svg. There could be more. Refer to the Umlet documentation.
#
set(output_format "svg")

# Initialize an empty list that will yield the output file names.
#
set(output_files "")


foreach(current_input_file ${input_files})
	
	set(absolute_path ${CMAKE_CURRENT_SOURCE_DIR}/${current_input_file})

	if (NOT EXISTS ${absolute_path})
		message(FATAL_ERROR "File not found: ${absolute_path}") 
	endif()

	get_filename_component(directory ${current_input_file} DIRECTORY)
	get_filename_component(filename ${current_input_file} NAME_WLE)

	# Todo: find more elegant way of handling the case where "directory" is an empty string.
	if (directory STREQUAL "")
		set(current_output_file "${CMAKE_CURRENT_BINARY_DIR}/${filename}.${output_format}")
	else()
		set(current_output_file "${CMAKE_CURRENT_BINARY_DIR}/${directory}/${filename}.${output_format}")
	endif()
	
	list(APPEND output_files ${current_output_file})

	# Mirror the source directories into the build directory.
	file(MAKE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/${directory})

	add_custom_command(OUTPUT ${current_output_file}
		COMMAND ${Java_JAVA_EXECUTABLE} 
			-jar ${path_to_umlet_jar} 
			-action=convert 
			-format=${output_format} 
			-filename=${CMAKE_CURRENT_SOURCE_DIR}/${current_input_file} 
			-output=${current_output_file}
		DEPENDS ${current_input_file})
endforeach()


# Building this target results in calling all the custom commands created in the foreach loop.
#
add_custom_target(docs
	DEPENDS ${output_files})
