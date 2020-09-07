#!/bin/bash

while [[ $# -gt 0 ]]; do key="$1"; value="$2"; case ${key} in
	--pm-fasta-file) pm_fasta_file="${value}"; shift; shift; ;;
	--bg-fasta-file) bg_fasta_file="${value}"; shift; shift; ;;
	--output-dir) output_dir="${value}"; shift; shift; ;;
	--motif-length-min) motif_length_min="${value}"; shift; shift; ;;
	--motif-length-max) motif_length_max="${value}"; shift; shift; ;;
	--tool-args) tool_args="${value}"; shift; shift; ;;
	*) shift; ;;
esac; done

args="-od /output"
args+=" -d /data/primary/${pm_fasta_file}"
args+=" -ks $motif_length_min"
args+=" -kl $motif_length_max"
args+=" -debug t"

read -r -d '' run_script << EOM
	#!/bin/bash
	# aborting a shell script if any command returns value other than zero
	set -e

	ulimit -s unlimited;
	multi_motif_sampler ${args} ${tool_args}
EOM

echo "${run_script}" | awk '{$1=$1;print}' > "${output_dir}/_run.sh"
chmod +x "${output_dir}/_run.sh"
echo "command: /output/_run.sh"