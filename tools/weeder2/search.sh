#!/bin/bash

while [[ $# -gt 0 ]]; do key="$1"; value="$2"; case ${key} in
	--pm-fasta-file) pm_fasta_file="${value}"; shift; shift; ;;
	--output-dir) output_dir="${value}"; shift; shift; ;;
	--tool-args) tool_args="${value}"; shift; shift; ;;
	*) shift; ;;
esac; done

# TODO http://159.149.160.88/weederaddons/weeder2freq.html
read -r -d '' run_script << EOM
	#!/bin/bash
	weeder2 -f /data/primary/${pm_fasta_file} -O HS ${tool_args}
	mv /data/primary/${pm_fasta_file}.w2 /output/result.w2
	mv /data/primary/${pm_fasta_file}.matrix.w2 /output/result.matrix.w2
EOM

echo "${run_script}" | awk '{$1=$1;print}' > "${output_dir}/_run.sh"
chmod +x "${output_dir}/_run.sh"

echo "command: /output/_run.sh"
