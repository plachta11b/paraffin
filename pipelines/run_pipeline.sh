#!/bin/bash

script_directory=`dirname "$0"`; root_dir="$script_directory/../"; script_name=`basename "$0"`
project_directory_data="$($root_dir/get_project_data_dir.sh)"; if [ ! $? -eq 0 ]; then echo $project_directory_data; exit 1; fi

action=$1; prefix_input_arg=$2; mmin=$3; mmax=$4;

if [[ $# -lt 4 ]]; then
	#echo "not enough arguments"
	echo "action argument missing"
	echo "call: ./$script_name \$action \$prefix \$motif_length_min \$motif_length_max"
	echo "call: ./$script_name (search|convert|command) load_prefix_file 8 8"
	echo "call: ./$script_name search default 8 8"
	echo "call: ./$script_name search load_prefix_file 8 8"
	echo "load_prefix_file as prefix will load prefixes from file"
	exit 1;
fi

sequence_source="bt_bams"
while [[ $# -gt 0 ]]; do key="$1"; value="$2"; case ${key} in
	--biomart) sequence_source="biomart"; shift; ;;
	-h|--help) ./$script_directory/help.sh; exit 0; shift; ;;
	*) shift; ;;
esac; done

prefix_file="$project_directory_data/generate_fasta/pipelines/prefix_filter"
if [ ! -f $prefix_file ]; then echo "no prefix file (exit)"; exit 1; fi
if [ "$prefix_input_arg" = "load_prefix_file" ]; then
	prefixes="$(cat $prefix_file)"
else
	# just test given prefix
	datasets="$(${root_dir}/get_fasta.sh ${prefix_input_arg})"
	if [ ! $? -eq 0 ]; then echo "${datasets}"; exit 1; fi

	prefixes="$prefix_input_arg"
fi

if [ "${action}" != "search" ] && [ "${action}" != "convert" ] && [ "${action}" != "command" ]; then
	echo "action ${action} not implemented! (exit)"
	exit 1
fi

trap 'echo "call SIGINT"; exit' INT
while IFS= read -r prefix; do
	if [ -z "${prefix}" ]; then continue; fi

	if [ "${prefix_input_arg}" = "load_prefix_file" ]; then
		prefix="${prefix}_${sequence_source}";
	else
		prefix="${prefix_input_arg}";
	fi

	# check if prefix already exists
	if [ ! -d $project_directory_data/find_motifs/${prefix} ]; then
		# just check fasta prefix
		datasets="$(${root_dir}/get_fasta.sh ${prefix})"
		if [ ! $? -eq 0 ]; then echo "${datasets}"; exit 1; fi
	fi

	echo "start $prefix $action"
	if [ "$action" = "search" ]; then
		$script_directory/scripts/search.sh $root_dir $prefix $mmin $mmax < /dev/null
		if [ $? -ne 0 ]; then exit 1; fi
	elif [ "$action" = "convert" ]; then
		$script_directory/scripts/convert.sh $root_dir $prefix $mmin $mmax < /dev/null
	elif [ "$action" = "command" ]; then

		if [ ! -f "$script_directory/scripts/command.sh" ]; then
			echo '#!/bin/bash' >> $script_directory/scripts/command.sh
			echo 'root_dir="$1"; prefix="$2"; motif_len_min="$3" motif_len_max="$4"' >> $script_directory/scripts/command.sh
			echo 'echo $prefix' >> $script_directory/scripts/command.sh
			chmod +x $script_directory/scripts/command.sh
		fi

		$script_directory/scripts/command.sh $root_dir $prefix $mmin $mmax < /dev/null
	else
		echo "not implemented yet!"; exit 1;
	fi
	echo "$action $prefix done!"

done <<< "$prefixes"
