#!/bin/bash

step=1
while [[ $# -gt 0 ]]; do key="$1"; value="$2"; case ${key} in
	--pm-fasta-file) pm_fasta_file="${value}"; shift; shift; ;;
	--bg-fasta-file) bg_fasta_file="${value}"; shift; shift; ;;
	--output-dir) output_dir="${value}"; shift; ;;
	--motif-length-min) motif_length_min="${value}"; shift; shift; ;;
	--motif-length-max) motif_length_max="${value}"; shift; shift; ;;
	--number-of-motifs) motif_count="${value}"; shift; shift; ;;
	--tool-args) tool_args="${value}"; shift; shift; ;;
	--step) step="${value}"; shift; shift; ;;
	*) shift; ;;
esac; done
iteration_steps="`seq $motif_length_min $step $motif_length_max`"
iteration_steps_comma="${iteration_steps//$'\n'/,}"
iteration_steps_us="${iteration_steps//$'\n'/_}"

# add background flag if background exist
background=""
if [ ! -z "${bg_fasta_file}" ]; then
	echo "background set used"
	background="-b /data/background/${bg_fasta_file}"
fi

if [ -z "${motif_count}" ]; then nmotifs=""; else nmotifs="-S ${motif_count}"; fi

# TODO what is -p 2

# -len ${motif_length} (default 10)

homer_command="homer2 denovo -i /data/primary/${pm_fasta_file} ${background} ${nmotifs} ${tool_args}"

read -r -d '' param_script << EOM
	#!/bin/bash

	homer_command="${homer_command}"
	motif_length_min="${motif_length_min}"
	motif_length_max="${motif_length_max}"
	iteration_steps_comma="${iteration_steps_comma}"
	iteration_steps_us="${iteration_steps_us}"
EOM

read -r -d '' run_script << "EOM"
	set -e # fail whole script if something goes wrong
	cd /output # change working directory to mounted folder

	# motif_length=${motif_length_min}
	# until [ ${motif_length} -gt ${motif_length_max} ]; do
	# 	echo "paraffin_width_info: now working on motif width: ${motif_length} date: $(date)"
	# 	cmd_iter="$homer_command -o /output/w${motif_length}_result.txt -len ${motif_length}"
	# 	motif_length=`expr ${motif_length} + $step`
	# 	$cmd_iter
	# done

	echo "$homer_command -o /output/w${iteration_steps_us}_result.txt -len ${iteration_steps_comma}"
	$homer_command -o /output/w${iteration_steps_us}_result.txt -len ${iteration_steps_comma}
EOM

echo "${param_script}" | awk '{$1=$1;print}' > "${output_dir}/_run.sh"
echo "${run_script}" | awk '{$1=$1;print}' >> "${output_dir}/_run.sh"
chmod +x "${output_dir}/_run.sh"
echo "command: /output/_run.sh"

# echo "command: homer2 denovo -i /data/primary/${pm_fasta_file} ${background} -o /output/result.txt ${nmotifs} ${tool_args}"
