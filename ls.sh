#!/bin/bash

script_directory=`dirname "$0"`

data="$($script_directory/get_project_data_dir.sh)"

>&2 echo "prefixes available:"
echo "$(ls "$data/generate_fasta/fasta")"
