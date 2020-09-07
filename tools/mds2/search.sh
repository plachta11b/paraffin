#!/bin/bash

step=1
while [[ $# -gt 0 ]]; do key="$1"; value="$2"; case ${key} in
	--pm-fasta-file) pm_fasta_file="${value}"; shift; shift; ;;
	--bg-fasta-file) bg_fasta_file="${value}"; shift; shift; ;;
	--output-dir) output_dir="${value}"; shift; shift; ;;
	--motif-length-min) motif_length_min="${value}"; shift; shift; ;;
	--motif-length-max) motif_length_max="${value}"; shift; shift; ;;
	--tool-args) tool_args="${value}"; shift; shift; ;;
	--step) step="${value}"; shift; shift; ;;
	*) shift; ;;
esac; done

# add background flag if background exist
background=""
if [ ! -z "${bg_fasta_file}" ]; then
	echo "background set used"
	is_background="True"
fi

read -r -d '' param_script << EOM
	#!/bin/bash

	mcat_args="$mcat_args"
	motif_length_min="$motif_length_min"
	motif_length_max="$motif_length_max"
	pm_fasta_file="$pm_fasta_file"
	bg_fasta_file="$bg_fasta_file"
	is_background="$is_background"
	tool_args="$tool_args"
	package="/source/MDS2"
	alphabet="ACGT"
	step=$step
EOM

read -r -d '' run_script << "EOM"

	cd /source/MDS2

	# aborting a shell script if any command returns value other than zero
	set -e

	cp /data/primary/${pm_fasta_file} /output/userInput.fa

	if [ ${is_background} = "True" ]; then
		cp /data/background/${bg_fasta_file} /output/negSeq.fa
	fi

	motif_length=${motif_length_min}
	until [ ${motif_length} -gt ${motif_length_max} ]; do
		# args -> baseDir, maxMotifLength, alphabet, samplingFreq, enableMiRSampling, enableNegSeq
		python GraphBasedMotifFinding.py /output ${motif_length} ${alphabet} 100 False ${is_background} ${tool_args}
		motif_length=`expr ${motif_length} + $step`
	done
EOM

echo "${param_script}" | awk '{$1=$1;print}' > "${output_dir}/_run.sh"
echo "${run_script}" | awk '{$1=$1;print}' >> "${output_dir}/_run.sh"
chmod +x "${output_dir}/_run.sh"
echo "command: /output/_run.sh"
