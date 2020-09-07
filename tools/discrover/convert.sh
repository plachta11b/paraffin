#!/bin/bash

while [[ $# -gt 0 ]]; do key="$1"; value="$2"; case ${key} in
	--output-dir) output_dir="${value}"; shift; shift; ;;
	*) shift; ;;
esac; done


read -r -d '' run_script_variables << EOM
	#!/bin/bash
EOM


read -r -d '' run_script << "EOM"

	function skip_first_n {
		if [ ! -t 0 ]; then INPUT="$(cat)"; else INPUT=""; fi
		echo "$INPUT" | awk '{if (NR>n) print}' n=$1
	}

	result_files="$(find /data/motifs/ -name "*.table.gz")"
	if [ -z "$result_files" ]; then echo "nothing to convert (exit)"; exit 1; fi 
	while IFS= read -r info_file; do
		directory="$(dirname ${info_file/.table.gz/.table.sequences})"
		filename="$(basename ${info_file/.table.gz/.table.sequences})"

		# ignore files starting with ._
		if [[ "$filename" != *"._"*  ]]; then
			echo "unzip and convert: $info_file"
			mkdir -p $directory/motifs
			gzip -dc "$info_file" | cut -f 6 | skip_first_n 1 > ${info_file/.table.gz/.table.sequences}
			cp ${info_file/.table.gz/.table.sequences} $directory/motifs/$filename.txt
			sites2meme $directory/motifs/ > $directory/result_converted.pwm
		fi
	done <<< "$result_files"

EOM

echo "${run_script_variables}" | awk '{$1=$1;print}' > "${output_dir}/_run.sh"
echo "${run_script}" | awk '{$1=$1;print}' >> "${output_dir}/_run.sh"
chmod +x "${output_dir}/_run.sh"

echo "command: bash /output/_run.sh"
echo "container: memesuite"
folder_with_motifs=$(echo $output_dir | sed "s|/result_motifs/\(.*\)/.*|/result_motifs/\1|")
if [ ! -d "$output_dir" ]; then echo "convert.sh: folder with motifs does not exist"; exit 1; fi
echo "volume: $(realpath $folder_with_motifs):/data/motifs/"