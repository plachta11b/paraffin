#!/bin/bash

while [[ $# -gt 0 ]]; do key="$1"; value="$2"; case ${key} in
	--output-dir) output_dir="${value}"; shift; shift; ;;
	*) shift; ;;
esac; done

read -r -d '' run_script << "EOM"
	#!/bin/bash

	result_files="$(find /data/motifs/ -name "result.txt")"

	while IFS= read -r info_file; do
		cp ${info_file} ${info_file/result.txt/result_converted.pwm}
	done <<< "$result_files"

EOM

echo "${run_script}" | awk '{$1=$1;print}' > "${output_dir}/_run.sh"
chmod +x "${output_dir}/_run.sh"

echo "command: bash /output/_run.sh"
echo "container: bash"
if [ ! -d "$output_dir/../" ]; then echo "convert.sh: folder with bamm motifs does not exist"; exit 1; fi
echo "volume: $(realpath "$output_dir/../"):/data/motifs/"
