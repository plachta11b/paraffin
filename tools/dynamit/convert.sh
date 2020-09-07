#!/bin/bash

while [[ $# -gt 0 ]]; do key="$1"; value="$2"; case ${key} in
	--output-dir) output_dir="${value}"; shift; shift; ;;
	--framework-tools) framework_tools="${value}"; shift; shift; ;;
	*) shift; ;;
esac; done


read -r -d '' run_script_variables << EOM
	#!/bin/ash
	framework_tools="$framework_tools"
EOM


read -r -d '' run_script << "EOM"

	# convert file to parrent directory
	get_dirnames() { for result_filename in $1; do echo "$(dirname $result_filename)"; done; }

	# find result files and test if any found
	result_files="$(find /data/motifs/ -name "Cluster_*_PFM.txt" -wholename "*$framework_tools*")"
	if [ -z "$result_files" ]; then echo "nothing to convert (exit)"; exit 1; fi

	# keep only uniq directories
	result_dirs="$(get_dirnames "$result_files" | sort | uniq)"

	# for all dirs and convert motifs
	for result_dir in ${result_dirs}; do

		# find root directory by its tag_
		echo "results in: $result_dir"
		root_out_dir=$(echo "$result_dir" | sed "s|/motifs/\(.*tag_[^/]*\)/.*|/motifs/\1|")
		echo "convert into: $root_out_dir/motifs"

		# create dir and copy results
		mkdir -p $root_out_dir/motifs
		cd ${result_dir}
		for result_file in Cluster_*_PFM.txt; do
			cp $result_file $root_out_dir/motifs/
		done

		# convert results
		python -m lead2gold \
			--motif-in pfm_horizontal \
			--motif-out meme \
			--folder-in ${root_out_dir}/motifs \
			--file-out $root_out_dir/result_converted.pwm
	done
EOM

echo "${run_script_variables}" | awk '{$1=$1;print}' > "${output_dir}/_run.sh"
echo "${run_script}" | awk '{$1=$1;print}' >> "${output_dir}/_run.sh"
chmod +x "${output_dir}/_run.sh"

echo "command: ash /output/_run.sh"
echo "container: lead2gold"
if [ ! -d "$output_dir/../" ]; then echo "convert.sh: folder with motifs does not exist"; exit 1; fi
echo "volume: $(realpath $output_dir/../):/data/motifs/"
