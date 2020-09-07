#!/bin/bash

while [[ $# -gt 0 ]]; do key="$1"; value="$2"; case ${key} in
	--output-dir) output_dir="${value}"; shift; shift; ;;
	*) shift; ;;
esac; done

if [ ! -d "$output_dir" ]; then echo "convert.sh: folder with motifs does not exist"; exit 1; fi

folder_with_motifs=$(echo $output_dir | sed "s|/result_motifs/\(.*\)/.*|/result_motifs/\1|")

result_files="$(find "$folder_with_motifs" -name "meme.txt")"

if [ -z "$result_files" ]; then echo "nothing to convert (exit)"; exit 1; fi

while IFS= read -r info_file; do
	echo "$info_file"
	cwd="$(dirname $info_file)"
	cat $cwd/meme.txt > $cwd/result_converted.pwm
done <<< "$result_files"

echo "command: do_not_execute"
