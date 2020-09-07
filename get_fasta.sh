#!/bin/bash

script_directory=`dirname "$0"`

prefix="$1"

data="$($script_directory/get_project_data_dir.sh)"
data_dir="$data/generate_fasta/fasta/$prefix"

if [[ -z "$prefix" ]]; then
	echo "prefix argument missing"
	exit 1
fi

if [[ ! -d "$data_dir" ]]; then
	echo "fasta data missing for prefix: $prefix"
	echo "prefix available: $(ls "$data/generate_fasta/fasta")"
	exit 1
fi

# fasta
# [primary,background]_[properties_source].fasta

if [ -f "$data_dir/_dataset.list" ]; then
	cat "$data_dir/_dataset.list"
	exit 0
fi

# only files with .fasta allowed
datasets="$(ls "$data_dir" | grep '.fasta$' | grep 'primary' | grep --invert-match ".filtered" | grep --invert-match ".marked" | sed 's/.fasta//')"

while IFS= read -r dataset; do

	if [[ "$dataset" == *".w2"* ]]; then continue; fi
	if [[ -z "$dataset" ]]; then continue; fi

	primary_file="$data_dir/$dataset.fasta"
	background_file="$data_dir/$(echo $dataset | sed 's/primary/background/').fasta"
	if [ ! -f "$background_file" ]; then background_file=""; fi

	echo "\"$dataset\" \"$primary_file\" \"$background_file\"" | tee -a "$data_dir/_dataset.list"

done <<< "$datasets"

