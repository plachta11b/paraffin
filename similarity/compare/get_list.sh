#/bin/bash

script_directory=`dirname "$0"`; script_name=`basename "$0"`; root_dir="$script_directory/../../";

prefix=$1

if [[ $# -lt 1 ]] ; then
	echo "not enough arguments"
	echo "call: ./$script_name \$prefix"
	exit 1
fi

sim_directory="$(${root_dir}/get_project_data_dir.sh)/similarity_test/$prefix"

if [[ $# -lt 1 ]] ; then
	echo "not enough arguments"
	echo "call: ./$script_name \$prefix"
	exit 1
fi

if [ ! -d "$sim_directory" ]; then
	echo "get_list.sh: folder with given prefix ($prefix) does not exist"
	exit 1
fi

similarity_files="$(find $sim_directory -name "similarity_score.txt")"

while IFS= read -r similarity_file; do
	cat $similarity_file
done <<< "$similarity_files"

