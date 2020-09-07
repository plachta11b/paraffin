#!/bin/bash

while [[ $# -gt 0 ]]; do key="$1"; value="$2"; case ${key} in
	--output-dir) output_dir="${value}"; shift; shift; ;;
	--number-of-motifs) motif_count="${value}"; shift; shift; ;;
	*) shift; ;;
esac; done


read -r -d '' run_script_variables << EOM
	#!/bin/ash
	number_of_motifs=$motif_count
EOM

read -r -d '' run_script << "EOM"

	if [ ! -z "$number_of_motifs" ]; then args="--best $number_of_motifs"; fi

	get_dirnames() {
		for result_filename in $1; do
			echo "$(dirname $result_filename)"
		done
	}

	result_files="$(find /data/motifs/ -name "w*_result.txt")"

	if [ -z "$result_files" ]; then echo "nothing to convert (exit)"; exit 1; fi

	result_dirs="$(get_dirnames "$result_files" | sort | uniq)"

	for result_dir in ${result_dirs}; do
		cd ${result_dir}
		for result_file in *_result.txt; do
			echo "${result_dir} ${result_file}"
			file=${result_dir}/${result_file}
			python -m lead2gold \
				--motif-in homer \
				--motif-out meme \
				--file-in ${file} \
				--file-out ${file/.txt/.meme} $args
		done



		# todo implement multiple motif merging in python instead of this
		# meme2meme $cwd/*.meme > $cwd/result_converted.pwm
		first="true"
		for file in *.meme; do
			if [ $first = "true" ]; then
				cat ${file} > result_converted.pwm
			else
				echo " " >> result_converted.pwm
				cat ${file} | \
				grep -v "MEME version" | \
				grep -v "ALPHABET" | \
				grep -v "Background letter frequencies" | \
				grep -v "A .*C .*G .*T " \
				>> result_converted.pwm
			fi
			
			first="false"
		done
	done


EOM

echo "${run_script_variables}" | awk '{$1=$1;print}' > "${output_dir}/_run.sh"
echo "${run_script}" | awk '{$1=$1;print}' >> "${output_dir}/_run.sh"
chmod +x "${output_dir}/_run.sh"

echo "command: ash /output/_run.sh"
echo "container: lead2gold"
folder_with_motifs=$(echo $output_dir | sed "s|/result_motifs/\(.*\)/.*|/result_motifs/\1|")
if [ ! -d "$output_dir" ]; then echo "convert.sh: folder with motifs does not exist"; exit 1; fi
echo "volume: $(realpath $folder_with_motifs):/data/motifs/"
