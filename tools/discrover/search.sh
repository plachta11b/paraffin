#!/bin/bash

while [[ $# -gt 0 ]]; do key="$1"; value="$2"; case ${key} in
	--pm-fasta-file) pm_fasta_file="${value}"; shift; shift; ;;
	--bg-fasta-file) bg_fasta_file="${value}"; shift; shift; ;;
	--motif-length-min) motif_length_min="${value}"; shift; shift; ;;
	--motif-length-max) motif_length_max="${value}"; shift; shift; ;;
	--output-dir) output_dir="${value}"; shift; shift; ;;
	--tool-args) tool_args="${value}"; shift; shift; ;;
	*) shift; ;;
esac; done

# --revcomp
# --threads

# files
# --nopdf
# --nopng

# require to specify motif to search (can be length) or hmm
# --motif $motif_length
# --load $some_path

discrover_args="discrover /data/primary/$pm_fasta_file /data/background/$bg_fasta_file  $tool_args"

read -r -d '' param_script << EOM
	#!/bin/sh

	discrover_args="${discrover_args}"
	motif_length_min="${motif_length_min}"
	motif_length_max="${motif_length_max}"
EOM


read -r -d '' run_script << "EOM"

	set -e # fail whole script if something goes wrong
	cd /output # change working directory to mounted folder

	motif_length=${motif_length_min}
	until [ ${motif_length} -gt ${motif_length_max} ]; do
		echo "paraffin_width_info: now working on motif width: ${motif_length}"
		cmd_iter="$discrover_args --output w${motif_length} --motif ${motif_length}"
		motif_length=`expr ${motif_length} + 1`
		$cmd_iter
	done
EOM


echo "${param_script}" | awk '{$1=$1;print}' > "${output_dir}/_run.sh"
echo "${run_script}" | awk '{$1=$1;print}' >> "${output_dir}/_run.sh"
chmod +x "${output_dir}/_run.sh"
echo "command: /output/_run.sh"
