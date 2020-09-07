#!/bin/bash

while [[ $# -gt 0 ]]; do key="$1"; value="$2"; case ${key} in
	--pm-fasta-file) pm_fasta_file="${value}"; shift; shift; ;;
	--bg-fasta-file) bg_fasta_file="${value}"; shift; shift; ;;
	--motif-length-min) motif_length_min="${value}"; shift; shift; ;;
	--motif-length-max) motif_length_max="${value}"; shift; shift; ;;
	--tool-args) tool_args="${value}"; shift; shift; ;;
	*) shift; ;;
esac; done

# add background flag if background exist
background=""
if [ ! -z "${bg_fasta_file}" ]; then
	echo "background set used"
	background="-n /data/background/${bg_fasta_file}"
fi

primary="-p /data/primary/${pm_fasta_file}"
if [ -z ${motif_count} ]; then nmotifs=""; else nmotifs="-m ${motif_count}"; fi
params="-mink ${motif_length_min} -maxk ${motif_length_max} ${nmotifs}"


echo "command: dreme -dna -oc /output/ ${primary} ${background} ${params} ${tool_args}"
echo "container: memesuite"
