#!/bin/bash

while [[ $# -gt 0 ]]; do key="$1"; value="$2"; case ${key} in
	--output-dir) output_dir="${value}"; shift; shift; ;;
	*) shift; ;;
esac; done

read -r -d '' run_script << "EOM"

	#!/bin/ash

	result_files="$(find /data/motifs/ -name "result.txt")"

	for info_file in $result_files; do
		echo "$info_file"
		python -m lead2gold \
			--motif-in alignace \
			--motif-out meme \
			--file-in $info_file \
			--file-out ${info_file/result.txt/result_converted.pwm}
	done

EOM

echo "${run_script}" | awk '{$1=$1;print}' > "${output_dir}/_run.sh"
chmod +x "${output_dir}/_run.sh"

echo "command: /output/_run.sh"
echo "container: lead2gold"
if [ ! -d "$output_dir/../" ]; then echo "convert.sh: folder with alignace motifs does not exist"; exit 1; fi
echo "volume: $(realpath $output_dir/../):/data/motifs/"



