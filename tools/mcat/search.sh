#!/bin/bash

while [[ $# -gt 0 ]]; do key="$1"; value="$2"; case ${key} in
	--pm-fasta-file) pm_fasta_file="${value}"; shift; shift; ;;
	--bg-fasta-file) bg_fasta_file="${value}"; shift; shift; ;;
	--output-dir) output_dir="${value}"; shift; shift; ;;
	--motif-length-min) motif_length_min="${value}"; shift; shift; ;;
	--motif-length-max) motif_length_max="${value}"; shift; shift; ;;
	--tool-args) tool_args="${value}"; shift; shift; ;;
	--tmp-dir) tmp_dir="${value}"; shift; shift; ;;
	*) shift; ;;
esac; done

mcat_args="/packages/MCAT/orange_pipeline_refine.py"
mcat_args+=" -ff"
mcat_args+=" -s results/stat"
mcat_args+=" --iter 5"

read -r -d '' param_script << EOM
	#!/bin/bash

	primary="/data/primary/${pm_fasta_file}"
	background="/data/background/${bg_fasta_file}"
	mcat_args="$mcat_args"
	motif_length_min="$motif_length_min"
	motif_length_max="$motif_length_max"
EOM

read -r -d '' run_script << "EOM"
	# set -e # fail whole script if something goes wrong

	cd /packages/MCAT/

	#mkdir -p /data/primary/tmp/
	#file_primary_long="/data/primary/tmp/${pm_fasta_file}.${motif_length_max}.mcat.long"
	#cat ${primary} | awk -v min="30" 'BEGIN {RS = ">" ; ORS = ""} length($2) >= min {print ">"$0}' > $file_primary_long

	# sed -i '/^#.* runDECOD/ s/^#//' /packages/MCAT/orange_pipeline_refine.py
	# sed -i '/^#.* parseDECOD/ s/^#//' /packages/MCAT/orange_pipeline_refine.py

	motif_length=${motif_length_min}
	until [ ${motif_length} -gt ${motif_length_max} ]; do
		rm -rf $(pwd)/results/*
		echo "paraffin_width_info: now working on motif width: ${motif_length} date: $(date)"
		cmd_iter="${mcat_args} -w ${motif_length}"
		motif_length=`expr ${motif_length} + 1`
		${cmd_iter} $primary $background
		cp -r $(pwd)/results /output/w${motif_length}_results
		rm -rf $(pwd)/results/*
	done
EOM

echo "${param_script}" | awk '{$1=$1;print}' > "${output_dir}/_run.sh"
echo "${run_script}" | awk '{$1=$1;print}' >> "${output_dir}/_run.sh"
chmod +x "${output_dir}/_run.sh"
echo "command: /output/_run.sh"
if [ ! -z $tmp_dir ]; then
	# On RCI cluster temp dir is shared between jobs -> broken isolation
	# echo "volume: $tmp_dir:/packages/MCAT/results"
	mkdir -p ${output_dir}/tmp
	echo "volume: ${output_dir}/tmp:/packages/MCAT/results"
fi
