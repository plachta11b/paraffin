#!/bin/bash

script_directory=`dirname "$0"`

while [[ $# -gt 0 ]]; do key="$1"; value="$2"; case ${key} in
	--pm-fasta-file) pm_fasta_file="${value}"; shift; shift; ;;
	--bg-fasta-file) bg_fasta_file="${value}"; shift; shift; ;;
	--motif-length-min) motif_length_min="${value}"; shift; shift; ;;
	--motif-length-max) motif_length_max="${value}"; shift; shift; ;;
	--output-dir) output_dir="${value}"; shift; shift; ;;
	--tool-args) tool_args="${value}"; shift; shift; ;;
	*) shift; ;;
esac; done

bp_bg="genomebg -i /data/background/$bg_fasta_file -o bp.bg"
ms_bg="CreateBackgroundModel -f /data/background/$bg_fasta_file -b ms.bg"

read -r -d '' param_script << EOM
	#!/bin/sh

	pf="$pm_fasta_file"
	bf="$bg_fasta_file"
	motif_length_min="${motif_length_min}"
	motif_length_max="${motif_length_max}"
	tool_args="$tool_args"
	bp_bg="$bp_bg"
	ms_bg="$ms_bg"
EOM


read -r -d '' run_script << "EOM"

	set -e # fail whole script if something goes wrong
	cd /output # change working directory to mounted folder

	$bp_bg
	$ms_bg

	motif_length=${motif_length_min}
	until [ ${motif_length} -gt ${motif_length_max} ]; do
		echo "paraffin_width_info: now working on motif width: ${motif_length}"
		out="w_${motif_length}"
		mkdir -p $out; cd $out
		mkdir -p step5regulon
		cp /packages/EMD/runmotif.sh .
		cp /packages/EMD/emd.cfg .
		chmod +x runmotif.sh
		echo ">oneline combined" > step5regulon/$pf
		# grep --invert-match ">" /data/primary/$pf >> step5regulon/$pf
		cp /data/primary/$pf step5regulon/
		cp /packages/EMD/bg_seq/*.bg .
		perl /packages/EMD/emdrunPX.pl -f emd.cfg -w ${motif_length} -n 5
		perl /packages/EMD/emdMotif.pl -f step5regulon/$pf -c emd.cfg -n 5 > result.txt
		cd ../
	motif_length=`expr ${motif_length} + 1`; done
EOM


cat $script_directory/emd.cfg > "${output_dir}/emd.cfg"
echo "${param_script}" | awk '{$1=$1;print}' > "${output_dir}/_run.sh"
echo "${run_script}" | awk '{$1=$1;print}' >> "${output_dir}/_run.sh"
chmod +x "${output_dir}/_run.sh"
echo "command: /output/_run.sh"
