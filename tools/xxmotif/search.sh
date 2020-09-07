#!/bin/bash

while [[ $# -gt 0 ]]; do key="$1"; value="$2"; case ${key} in
	--pm-fasta-file) pm_fasta_file="${value}"; shift; shift; ;;
	--bg-fasta-file) bg_fasta_file="${value}"; shift; shift; ;;
	--tool-args) tool_args="${value}"; shift; shift; ;;
	--motif-length-max) motif_length_max="${value}"; shift; shift; ;;
	*) shift; ;;
esac; done

# add background flag if background exist
background=""
if [ ! -z "${bg_fasta_file}" ]; then
	echo "background set used"
	background="--negSet /data/background/${bg_fasta_file}"
fi

# --max-motif-length max 17
if [ ! -z "${motif_length_max}" ]; then motif_length_max="17"; fi

# need update
# echo "command: XXmotif /output/ /data/primary/${pm_fasta_file} --zoops ${background} --max-motif-length ${motif_length_max} ${tool_args}"
echo "command: XXmotif /output/ /data/primary/${pm_fasta_file} --zoops ${background} ${tool_args}"
