#!/bin/bash

step=1
while [[ $# -gt 0 ]]; do key="$1"; value="$2"; case ${key} in
	--pm-fasta-file) pm_fasta_file="${value}"; shift; shift; ;;
	--bg-fasta-file) bg_fasta_file="${value}"; shift; shift; ;;
	--output-dir) output_dir="${value}"; shift; shift; ;;
	--motif-length-min) motif_length_min="${value}"; shift; shift; ;;
	--motif-length-max) motif_length_max="${value}"; shift; shift; ;;
	--step) step="${value}"; shift; shift; ;;
	--tool-args) tool_args="${value}"; shift; shift; ;;
	*) shift; ;;
esac; done

iteration_steps="`seq $motif_length_min $step $motif_length_max`"

# --motif_length ${motif_length} (default 6)

read -r -d '' run_script << EOM
	#!/bin/bash

	pm_fasta_file="$pm_fasta_file"
	bg_fasta_file="$bg_fasta_file"
	output_dir="$output_dir"
	motif_length_min="$motif_length_min"
	motif_length_max="$motif_length_max"
	tool_args="$tool_args"
	iteration_steps="$iteration_steps"

	WORKING_DIR="/output"
	DATASET_NAME="dataset"

	if [ ! -z "${bg_fasta_file}" ]; then
		echo "background set used"
		is_background="True"
	fi
EOM

read -r -d '' run_script_loop << "EOM"

	all_files="/output/fasta/${DATASET_NAME}/positive.fasta"
	all_files+=" /output/structures/${DATASET_NAME}/positive.txt"

	#python /output/sizes.py ${GENOME_SEQ}
	#rm /output/sizes.py

	mkdir -p /output/fasta/${DATASET_NAME}/

	cp /data/primary/${pm_fasta_file} /output/fasta/${DATASET_NAME}/positive.fasta

	# if [ "${is_background}" = "True" ]; then
		# does not take background
		# cp /data/background/${bg_fasta_file} /output/fasta/${DATASET_NAME}/negative.fasta
	# fi

	# RNAshapes need constant for number of shapes per sequence
	preprocess_fasta_dataset "${WORKING_DIR}" "${DATASET_NAME}" "" "" "" --disable_RNAshapes 
	# --skip_check
	echo "preprocess done!"

	for motif_length in $iteration_steps; do
		echo "paraffin_width_info: now working on motif width: ${motif_length} date: $(date)"
		mkdir -p /output/w${motif_length}
		train_seqstructhmm ${all_files} --motif_length ${motif_length} -o /output/w${motif_length} ${tool_args}
	done
EOM

read -r -d '' sizes_script << EOM
	from pyfaidx import Fasta
	import os
	import sys

	def sizes_file(fname):
		if not os.path.exists(fname+".sizes"):
			generate_fa_sizes(fname, fname+".sizes")

	def generate_fa_sizes(fname, outname):
		f = Fasta(fname)
		with open(outname, "w") as sizes:
			for seqname, seq in f.items():
				sizes.write(f"{seqname}\t{len(seq)}\n")

	sizes_file(sys.argv[1])
EOM

echo "${run_script}" | awk '{$1=$1;print}' > "${output_dir}/_run.sh"
echo "${run_script_loop}" | awk '{$1=$1;print}' >> "${output_dir}/_run.sh"
# echo "${sizes_script}" | sed 's/^TAB//g' > "${output_dir}/sizes.py"
chmod +x "${output_dir}/_run.sh"
echo "command: /output/_run.sh"

mkdir -p "$output_dir/tmp/"
echo "volume: $(realpath "$output_dir/tmp/"):/tmp"
