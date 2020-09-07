#!/bin/bash
#author: plachta11b (janholcak@gmail.com)

script_directory=`dirname "$0"`
ARGS=''; for i in "$@"; do i="${i//\\/\\\\}"; ARGS="$ARGS \"${i//\"/\\\"}\""; done

trap 'echo call SIGINT; exit' INT

convert="false"
while [[ $# -gt 0 ]]; do
	key="$1"; value="$2"
	case $key in
		--primary-file) primary_file="$value"; shift; shift; ;;
		--background-file) background_file="$value"; shift; shift; ;;
		--output-dir) output_dir="$value"; shift; shift; ;;
		--genome-dir) genome_dir="$value"; shift; shift; ;;
		--tool) tool="$value"; shift; shift; ;;
		--convert) convert="true"; shift; ;;
		*) shift; ;;
	esac
done

mkdir -p "${output_dir}"

command_out=""
if [ "$convert" = "true" ]; then
	command_out="$(bash -c "${script_directory}/${tool}/convert.sh $ARGS")"
	if [ ! $? -eq 0 ]; then echo "$command_out"; exit 1; fi
	if [[ "$command_out" == *"do_not_execute"* ]]; then exit 0; fi
else
	# make paths absolute
	pm_fasta=$(realpath $primary_file); output_dir="$(realpath $output_dir)";
	if [ -z "$background_file" ]; then bg_fasta=""; else bg_fasta="$(realpath $background_file)"; fi

	# prepare files for docker volume mount
	pm_fasta_dir=${pm_fasta%/*}; pm_fasta_file=${pm_fasta##*/}
	bg_fasta_dir=${bg_fasta%/*}; bg_fasta_file=${bg_fasta##*/}

	# place as last to increase priority and overwrite older options
	script_args=""
	script_args+=" --pm-fasta-file \"$pm_fasta_file\""
	script_args+=" --bg-fasta-file \"$bg_fasta_file\""

	if [ ! -f ${script_directory}/${tool}/search.sh ]; then echo "tool or tool command not available"; exit 1; fi

	command_out="$(bash -c "${script_directory}/${tool}/search.sh $ARGS $script_args --output-dir '${output_dir}'")"
	if [ ! $? -eq 0 ]; then echo "$command_out"; exit 1; fi
fi

debug="$(echo "$command_out" | grep --invert-match "command: ")"
if [ ! -z "$debug" ]; then echo "$debug"; fi

execute="$(echo "$command_out" | grep "command: " | sed 's/command: //')"
container="$(echo "$command_out" | grep "container: " | sed 's/container: //')"
if [ -z "$execute" ]; then echo "execute can not be empty"; exit 1; fi

if [ ! -z "$container" ]; then tool="$container"; fi

# --rm		Automatically remove the container when it exits
# (-t) --tty	Allocate a pseudo-TTY
# (-i) --interactive	Keep STDIN open even if not attached (not needed here)
switches="--init --rm --tty"
volumes=""

if [ "$convert" != "true" ]; then
	if [ -d "${pm_fasta_dir}" ]; then volumes+=" -v ${pm_fasta_dir}:/data/primary"; fi
	if [ -d "${bg_fasta_dir}" ]; then volumes+=" -v ${bg_fasta_dir}:/data/background"; fi
	if [ -d "${genome_dir}" ]; then volumes+=" -v ${genome_dir}:/data/genome"; fi
fi
if [ -d "${output_dir}" ]; then volumes+=" -v ${output_dir}:/output/"; fi

while IFS= read -r volume; do
	if [ ! -z "$volume" ]; then volumes+=" -v $volume"; fi
done <<< "$(echo "$command_out" | grep "volume: " | sed 's/volume: //')"

if [ -z "$stage" ] || [ "$stage" = "execute" ]; then timer=true; else timer=false; fi

# run_daemon.sh switches volumes tool_container command_to_execute working_directory
${script_directory}/../run_daemon.sh "${switches}" "${volumes}" "${tool}" "${execute}" "${output_dir}" "${timer}"; exit_code=$?
echo "$exit_code" >> "${output_dir}/_run_daemon_script.status"
exit $exit_code
