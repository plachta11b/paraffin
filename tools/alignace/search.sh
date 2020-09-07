#!/bin/bash

while [[ $# -gt 0 ]]; do key="$1"; value="$2"; case ${key} in
	--pm-fasta-file) pm_fasta_file="${value}"; shift; shift; ;;
	--tool-args) tool_args="${value}"; shift; shift; ;;
	*) shift; ;;
esac; done

echo "command: /packages/AlignACE -i /data/primary/${pm_fasta_file} $tool_args | tee /output/result.txt"
