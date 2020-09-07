#!/bin/bash
#author: plachta11b (janholcak@gmail.com)

script_directory=`dirname "$0"`

while [[ $# -gt 0 ]]; do key="$1"; value="$2"; case ${key} in
	--output-dir) output_dir="${value}"; shift; ;;
	--motif-length-min) motif_length_min="${value}"; shift; shift; ;;
	--motif-length-max) motif_length_max="${value}"; shift; shift; ;;
	*) shift; ;;
esac; done

trap 'echo "call SIGINT"; exit' INT

mkdir -p ${output_dir}
echo "out: ${output_dir}"

# echo "out: ${output_dir#*find_motifs}"

project_directory_data="$($script_directory/../../get_project_data_dir.sh)"; if [ ! $? -eq 0 ]; then echo $project_directory_data; exit 1; fi
find_motifs_dir="$project_directory_data/find_motifs"

read -r -d '' run_script_variables << EOM
	#!/bin/bash
	ml_restriction="out_${motif_length_min}to${motif_length_max}"
	ignore_if_temporary_path="s/_part/*/"
	match_replace_path_to_relative="s|.*/result_motifs/gimme/||"
EOM

read -r -d '' run_script << "EOM"
	data_dir="/data/motifs"

	convert_motif() {
		motif_out="$1/result_converted.pwm"
		motif_in="$2"
		tool_name="$3"
		motif_format="meme"

		echo "convert.sh motif_in: $motif_in"

		cat $motif_in | python /code/parse_motifs.py $tool_name $motif_format | tee -a $motif_out
	}

	parse_tool() {
		tool_working_directory="$1" info_tool="$2" info_path="$3"

		echo "convert.sh (parse_tool): $tool_working_directory $info_tool $info_path"

		info_path_relative=$(echo $info_path | sed "$match_replace_path_to_relative")
		if [ -z "$info_path_relative" ]; then echo "convert.sh (parse_tool): no output motif file found for: $info_tool (skipping)"; return 1; fi

		if [ -z "$(find $data_dir -wholename "*$info_path_relative")" ]; then
			echo "convert.sh (parse_tool): not found file: $info_path_relative"
			return 1
		fi

		motif_files="$(find $data_dir -wholename "*$info_path_relative")"

		while IFS= read -r motif_file; do
			if [ -z "$motif_file" ]; then continue; fi
			# do not escape - $motif_file contains wildcards
			abs_path_motif_file=$(ls $motif_file)
			if [ $? -ne 0 ]; then echo "convert.sh: motif path error"; continue; fi
			if [ ! -f $abs_path_motif_file ]; then echo "convert.sh: motif file without wildcards not found"; continue; fi
			convert_motif "$tool_working_directory" "$abs_path_motif_file" "$info_tool" < /dev/null;
		done <<< "$motif_files"
	}

	parse_info_files() {

		tool_working_directory="$(dirname $1)"
		info_tool="$(cat $1 | awk 'NR==1')"
		info_paths="$(cat $1 | awk 'NR>=2' | sed "$ignore_if_temporary_path")"

		rm -f $tool_working_directory/result_converted.pwm

		while IFS= read -r info_path; do
			parse_tool $tool_working_directory $info_tool $info_path
		done <<< "$info_paths"
	}

	files="$(find $data_dir -name "execution_info.txt" | grep "$ml_restriction")"

	if [ -z "$files" ]; then echo "no execution_info.txt files found in $data_dir (skipping)"; return 1; fi

	echo "found for conversion:"
	echo "$files"
	echo ""

	# for debug filter tools this way
	#files="$(echo "$files" | grep impro)"

	while IFS= read -r info_file; do parse_info_files "$info_file" < /dev/null; done <<< "$files"

	echo "Conversion done!"
EOM

echo "${run_script_variables}" | awk '{$1=$1;print}' > "${output_dir}/_run.sh"
echo "${run_script}" | awk '{$1=$1;print}' >> "${output_dir}/_run.sh"
chmod +x "${output_dir}/_run.sh"

echo "command: /output/_run.sh"
folder_with_motifs=$(echo $output_dir | sed "s|/result_motifs/gimme/.*|/result_motifs/gimme/|")
if [ ! -d "$folder_with_motifs" ]; then echo "convert.sh: folder with motifs does not exist"; exit 1; fi

echo "volume: $(realpath $folder_with_motifs):/data/motifs/"
echo "volume: $(realpath $script_directory/supporting/code):/code/"
echo "volume: $(realpath $script_directory/config/gimmemotifs):/home/gimmemotifs/.config/gimmemotifs"
mkdir -p "$output_dir/tmp/"
echo "volume: $(realpath "$output_dir/tmp/"):/home/gimmemotifs/.cache/gimmemotifs"
