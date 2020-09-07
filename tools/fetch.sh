#!/bin/bash

script_directory=`dirname "$0"`; script_name=`basename "$0"`; root_dir="$script_directory/../"

prefix=$1 result_dir=$2

if [[ $# -lt 2 ]] ; then
	echo "not enough arguments"
	echo "call: ./$script_name \$prefix \$output_dir"
	echo "call: ./$script_name default /path/to/dir"
	exit 1;
fi

trap 'echo "call SIGINT"; exit' INT

mkdir -p "$result_dir"
result_dir=$(realpath $result_dir)

# meme motif file -> sheet format
function parse_motifs() {

	#abs_path/find_motifs/prefix/result_motifs/gimme/postfix/[tag]/
	out_dir="$1"; dir="${out_dir/*find_motifs\//}"

	tool="$(echo "$dir" | awk -F/ '{print $3}')"
	postfix="$(echo "$dir" | awk -F/ '{print $4}')"
	tag="$(echo "$dir" | awk -F/ '{print $5}')"

	if [ -z "$prefix" ]; then return 0; fi
	if [ -z "$tool" ]; then return 0; fi

	result_motifs="$out_dir/result_converted.consensus.txt"
	result_command="$out_dir/execute.log"
	perf_stat_file="$out_dir/perf.stat"
	perf_data_file="$out_dir/perf.data"
	time_stat_file="$out_dir/time.stat"
	stderr="$out_dir/daemon.stderr.log"
	status="$(cat $out_dir/_run_daemon_script.status | tail -n 1 | grep --only-matching "[0-9]" | tr '\n' '\0')"

	time=0

	motifs_iupac=""
	if [ -f $result_motifs ]; then
		# motifs_iupac=$(cat $result_motifs | grep "MOTIF_IUPAC=" | grep --invert-match "width" | grep -o 'MOTIF_IUPAC=[a-zA-Z]*' | sed 's/MOTIF_IUPAC=//')
		motifs_iupac=$(cat $result_motifs)
		#echo "$motifs_iupac"
	fi
	if [ -f $result_command ]; then
		# cat $result_command
		:
	fi
	time_elapsed=""
	if [ -f $time_stat_file ]; then
		time_elapsed=$(cat $time_stat_file | grep "real_perf_time" | awk '{print $2}')
	fi
	if [ -f $perf_stat_file ]; then
		time_elapsed=$(cat $perf_stat_file | grep "seconds time elapsed" | awk '{print $1}')
	fi
	if [ -z "$time_elapsed" ]; then time_elapsed="NaN"; fi

	if cat $stderr | grep "CANCELLED" | grep -q "DUE TO TIME LIMIT"; then
		time_elapsed="$time_elapsed CANCELLED"
	fi
	if [ -f $perf_data_file ]; then
		ls -al $perf_data_file
	fi

	if [ -z "$tag" ]; then tag="no_tag"; fi

	echo "$tool $postfix $status"
	echo "$tool	$tag	$prefix	$postfix	$status	$time_elapsed	$(echo $motifs_iupac | tr -d '\n')" >> $result_dir/result.txt
}


files="$(find $script_directory -name "convert.sh")"

while IFS= read -r tool; do

	tool="${tool/\/convert.sh//}"
	tool="$(basename ${tool})"

	if [[ "$tool" =~ "^_*" ]]; then continue; fi

	output_dir="$($root_dir/get_output_dir.sh $tool $prefix)"
	if [ ! -d "${output_dir/\/result_motifs*/}" ]; then echo "no output dir for prefix: $prefix (skipping)"; continue; fi
	if [ ! -d "$output_dir" ]; then echo "no output dir for tool: $tool $output_dir (skipping)"; continue; fi

	motifs_runs="$(find "$output_dir" -name "_run_daemon_script.status" -print | grep --invert-match "/convert/")" 

	while IFS= read -r run; do
		if [ ! -z "$run" ]; then
			parse_motifs ${run/\/_run_daemon_script.status/}
		fi
	done <<< "$motifs_runs"

done <<< "$files"



