#!/bin/bash

mode_dmd="false";
while [[ $# -gt 0 ]]; do key="$1"; value="$2"; case ${key} in
	--pm-fasta-file) pm_fasta_file="${value}"; shift; shift; ;;
	--bg-fasta-file) bg_fasta_file="${value}"; shift; shift; ;;
	--motif-length-min) motif_length_min="${value}"; shift; shift; ;;
	--motif-length-max) motif_length_max="${value}"; shift; shift; ;;
	--number-of-motifs) motif_count="${value}"; shift; shift; ;;
	--output-dir) output_dir="${value}"; shift; shift; ;;
	--tool-args) tool_args="${value}"; shift; shift; ;;
	--dmd) mode_dmd="true"; shift; ;;
	*) shift; ;;
esac; done

# add background flag if background exist
background=""
if [ ! -z "${bg_fasta_file}" ]; then
	echo "background set used"
	background="-b /output/meme.bg"
fi

# All sequences must be at least 8 characters long.  Set '-w' or '-minw' or remove shorter sequences and rerun.
# motif_length_min=$(( $motif_length_min  > 8 ? $motif_length_min : 8 )) # this does not help
# motif_length_max=$(( $motif_length_max  > 8 ? $motif_length_max : 8 )) # this does not help

primary="/data/primary/${pm_fasta_file}"
if [ -z ${motif_count} ]; then nmotifs=""; else nmotifs="-nmotifs ${motif_count}"; fi
params="-minw ${motif_length_min} -maxw ${motif_length_max} ${nmotifs} -objfun de"

read -r -d '' run_script << EOM
	#!/bin/bash
	# aborting a shell script if any command returns value other than zero
	set -e
	if [ ! -z "${bg_fasta_file}" ]; then
		fasta-get-markov /data/background/${bg_fasta_file} /output/meme.bg
		if [ "${mode_dmd}" = "true" ]; then
			negative="-neg /data/background/${bg_fasta_file}"
		fi
	fi

	mkdir -p /data/primary/tmp/
	cat ${primary} | awk -v min="9" 'BEGIN {RS = ">" ; ORS = ""} length(\$2) >= min {print ">"\$0}' > /data/primary/tmp/${pm_fasta_file}.short9

	meme -dna -oc /output/ /data/primary/tmp/${pm_fasta_file}.short9 \${negative} ${background} ${params} ${tool_args} -revcomp -objfun de
	if [ \$? -ne 0 ]; then echo "cat the file"; cat /data/primary/tmp/${pm_fasta_file}.short9; fi # not active due to set -e
EOM

echo "$run_script" | awk '{$1=$1;print}' > "$output_dir/_run.sh"
chmod +x "$output_dir/_run.sh"
echo "command: /output/_run.sh"
# require meme version 5.1.1 or newer
echo "container: memesuite"
