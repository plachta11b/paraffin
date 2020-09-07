#!/bin/bash

script_directory=`dirname "$0"`

program="$1"
prefix="$2"

data="$($script_directory/get_project_data_dir.sh)"

# output_dir="$data/find_motifs/$program/result_motifs/$prefix"
output_dir="$data/find_motifs/$prefix/result_motifs/$program"

if ! echo x"$output_dir" | grep '*' > /dev/null; then
	# realpath needs existing output dir
	# mkdir -p "$output_dir"
	# echo "$(realpath "$output_dir")"
	echo "$output_dir"
	exit $?
else

	# output with wildcards
	# echo "$(realpath $output_dir)"
	echo "wildcards in output dir not supported anymore"
	exit 1
fi

