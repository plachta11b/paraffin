#!/bin/bash

script_directory=`dirname "$0"`; script_name=`basename "$0"`; root_dir="$script_directory/../"

prefix=$1

find_motifs="$(${root_dir}/get_project_data_dir.sh)/find_motifs/$prefix"
tmp_folder="$(${root_dir}/get_project_data_dir.sh)/tmp/convert_consensus"

if [[ $# -lt 1 ]] ; then
	echo "not enough arguments"
	echo "call: ./$script_name \$prefix"
	exit 1
fi

if [ ! -d "$find_motifs" ]; then
	echo "convert_converted.sh: folder with given prefix ($prefix) does not exist"
	exit 1
fi

mkdir -p ${tmp_folder}

read -r -d '' run_script << "EOM"
	#!/bin/ash

	result_files="$(find /data/motifs/ -name "result_converted.pwm")"

	if [ -z "$result_files" ]; then echo "nothing to convert (exit)"; exit 1; fi

	for file in ${result_files}; do
		echo "${file}"
		if [ -s "${file}" ]; then
			python -m lead2gold \
				--motif-in meme \
				--motif-out consensus \
				--file-in "${file}" \
				--file-out "${file/.pwm/.consensus.txt}"
			python -m lead2gold \
				--motif-in meme \
				--motif-out transfac \
				--file-in "${file}" \
				--file-out "${file/.pwm/.transfac.txt}" \
				--fix \
				--filter
			python -m lead2gold \
				--motif-in meme \
				--motif-out transfac \
				--file-in "${file}" \
				--file-out "${file/.pwm/.transfac.best5.txt}" \
				--fix \
				--filter \
				--best 5
		else
			echo "empty file: ${file}"
		fi
	done
EOM

echo "${run_script}" | awk '{$1=$1;print}' > "${tmp_folder}/_run.sh"
chmod +x "${tmp_folder}/_run.sh"

switches="--init --rm --tty"
volumes="-v ${tmp_folder}:/output/ -v ${find_motifs}:/data/motifs/"
tool_container="lead2gold"
execute="ash /output/_run.sh"
working_dir="$tmp_folder"

${root_dir}/run_daemon.sh "${switches}" "${volumes}" "${tool_container}" "${execute}" "${working_dir}"; exit_code=$?
