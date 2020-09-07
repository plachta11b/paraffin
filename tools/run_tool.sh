#!/bin/bash
#author: plachta11b (janholcak@gmail.com)

script_directory=`dirname "$0"`; script_name=`basename "$0"`; root_dir="$script_directory/../"

prefix=$1; tool=$2; motif_length_min=$3; motif_length_max=$4

if [[ $# -lt 4 ]] ; then
	args="$@"
	while [[ $# -gt 0 ]]; do key="$1"; case $key in
		-h|--help)
		# search all args to ignore fixed position
		for arg in $args; do
			echo "${script_directory}/${arg}/help.sh"
			if [ -f "${script_directory}/${arg}/help.sh" ]; then
				echo ${script_directory}/${arg}/help.sh
				help_out="$(bash "${script_directory}/${arg}/help.sh")"
				if [ ! $? -eq 0 ]; then
					echo "${help_out}"; exit 1;
				else
					echo "${help_out}"; exit 0;
				fi
			fi
		done
		shift; ;;
		*) shift; ;;
	esac; done

	echo "not enough arguments"
	echo "call: ./$script_name \$prefix \$tool \$motif_length_min \$motif_length_max [--threads \$thread_count] [--number-of-motifs \$motif_count]"
	echo "call: ./$script_name default tool 8 8"
	echo "optional xxmotif arg as example: [--args \"--startMotif AGTCCCCTM]\""
	echo "call help if exist: ./$script_name \$tool -h"
	exit 1;

elif ! [[ "$motif_length_min" =~ ^[0-9]+$ ]]; then
	echo "motif length min has to be integer"
	exit 1;
elif ! [[ "$motif_length_max" =~ ^[0-9]+$ ]]; then
	echo "motif length max has to be integer"
	exit 1;
fi

stage=""
no_bg="false"
start_clean="false"
start_force="false"
tool_args=""
convert="false"
# https://stackoverflow.com/a/14203146/3982760
POSITIONAL=()
for i in {1..4}; do shift; done

# save args without positionals
ARGS=''; for i in "$@"; do i="${i//\\/\\\\}"; ARGS="$ARGS \"${i//\"/\\\"}\""; done

while [[ $# -gt 0 ]]
do
key="$1"

case ${key} in
	--args|--tool-args)
	tool_args="$2"
	shift # past argument
	shift # past value
	;;
	-n|--number-of-motifs|--motif-count)
	motif_count="$2"
	shift # past argument
	shift # past value
	;;
	-t|--threads)
	thread_count="$2"
	shift # past argument
	shift # past value
	;;
	--stage)
	stage="$2"
	shift # past argument
	shift # past value
	;;
	--convert)
	convert="true"
	shift
	shift
	;;
	--no-bg)
	no_bg="true"
	shift # past argument
	;;
	--clean-start)
	start_clean="true"
	shift # past argument
	;;
	--force-start)
	start_force="true"
	shift # past argument
	;;
	--framework-tools|--step)
	POSITIONAL+=("$1")
	shift # past argument
	POSITIONAL+=("$1")
	shift # past value
	;;
	--native|--dmd)
	POSITIONAL+=("$1")
	shift # past argument
	;;
	*)
	echo "run_tool.sh: unknown option $1"
	POSITIONAL+=("$1") # save it in an array for later
	shift # past argument
	;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

genome_source="ensembl"

if [ "${genome_source}" = "ensembl" ]; then
	genome_dir="$(${root_dir}/get_project_data_dir.sh)/reference/fasta/ensembl"
	if [ ! $? -eq 0 ]; then echo ${genome_dir}; exit 1; fi

	genome_file="Homo_sapiens.GRCh38.dna.primary_assembly.fa"
else
	echo "not implemented genome_source: ${genome_source}"
	exit 1
fi

output_dir="$(${root_dir}/get_output_dir.sh ${tool} ${prefix})"
if [ ! $? -eq 0 ]; then echo ${output_dir}; exit 1; fi
mkdir -p "$output_dir"

#motif_length_min="$($root_directory/read_config.sh 'motif_min_length')"
#if [ ! $? -eq 0 ]; then echo $motif_length_min; exit 1; fi

# https://stackoverflow.com/a/2704760/3982760
# [ ! -z "${num##*[!0-9]*}" ] && echo "is a number" || echo "is not a number";
[ ! -z "${thread_count##*[!0-9]*}" ] && thread_count_int=thread_count || thread_count_int=1;
#[ ! -z "${motif_length_min##*[!0-9]*}" ] || motif_length_min=6;

args=""
if [ ! -z "$motif_length_min" ]; then args+=" --motif-length-min \"$motif_length_min\""; fi
if [ ! -z "$motif_length_max" ]; then args+=" --motif-length-max \"$motif_length_max\""; fi
if [ ! -z "$motif_count" ]; then args+=" --number-of-motifs \"$motif_count\""; fi
if [ ! -z "$thread_count" ]; then args+=" --thread-count \"$thread_count\""; fi
if [ ! -z "$tool" ]; then args+=" --tool \"$tool\""; fi

readonly="$(${root_dir}/read_config.sh "readonly")"
tmpdir="$(${root_dir}/read_config.sh "tmpdir")"
if [ $readonly = "true" ]; then
	args+=" --tmp-dir $tmpdir";
fi

if [ "$convert" = "true" ]; then
	echo "Convert motifs in folder: $output_dir/convert"
	bash -c "${script_directory}/container.sh ${ARGS} ${args} --output-dir \"$output_dir/convert\""
	echo "prefix:$prefix tool:$tool done!"
	exit 0
fi

function is_motif_len_exact_finder() {
	tool=$1
	echo "true"
}

function run() {
	name="$(sed -e 's/^"//'  -e 's/"$//' <<< $1)" primary="$2" background="$3"

	if [ "$no_bg" = "true" ]; then background=""; fi

	if [ -z "$background" ]; then
		output="${output_dir}/out_${motif_length_min}to${motif_length_max}_nobg_${name}"
	else
		output="${output_dir}/out_${motif_length_min}to${motif_length_max}_withbg_${name}"
	fi

	if [ "$start_clean" = "true" ]; then rm -rf "${output}"; fi

	if [ "$convert" != "true" ]; then
		if [ -f "${script_directory}/${tool}/tag.sh" ]; then
			tag_out="$(bash -c "${script_directory}/${tool}/tag.sh ${ARGS} $args")"
			if [ ! $? -eq 0 ]; then echo "$tag_out"; exit 1; fi
			tag="$(echo "$tag_out" | grep "tag:" | sed 's/tag: //')"
			if [ -z "$tag" ]; then echo "tag can not be empty (exit)"; exit 1; fi
			output="${output}/tag_$tag"
		fi
	fi

	if [ -z "$stage" ] || [ "$stage" = "all" ]; then
		if [ -d "${output}" ] && [ "$start_force" = "false" ]; then echo "output already exists ${output}"; return 0; fi
	fi

	#if [ ! -d "${output}" ]; then temp_output="${output}_part"; else temp_output="${output}"; fi

	args_iter="$args"
	if [ ! -z "$background" ]; then args_iter+=" --primary-file \"$primary\""; fi
	if [ ! -z "$background" ]; then args_iter+=" --background-file \"$background\""; fi
	if [ ! -z "${output}" ]; then args_iter+=" --output-dir \"$output\""; fi
	if [ ! -z "$genome_dir" ]; then args_iter+=" --genome-dir \"$genome_dir\""; fi
	if [ ! -z "$genome_file" ]; then args_iter+=" --genome-file \"$genome_file\""; fi

	if [ "$stage" != "all" ]; then
		bash -c "${script_directory}/container.sh ${ARGS} ${args_iter}"
		script_result_int=$?
	else
		for stage_iter in "get_command" "execute" "postprocess"; do
			bash -c "${script_directory}/container.sh ${ARGS} ${args_iter} --stage $stage_iter"
			script_result_int=$?

			if [ $script_result_int -ne 0 ] && [ "$stage_iter" != "postprocess" ]; then return $script_result_int; fi
		done
	fi

	# if { [ "${tool}" != "dynamit" ] || [ "${stage}" = "postprocess" ]; } && [ ${script_result_int} -eq 0 ] && [ -d "${output}_part" ]; then
	# 	rm -r "${output}" 2>/dev/null
	# 	mv "${output}_part/" "${output}/"
	# else

	if [ "$stage" = "postprocess" ]; then script_result_int=0; fi

	return ${script_result_int}
	# fi
}

datasets="$(${root_dir}/get_fasta.sh ${prefix})"
if [ ! $? -eq 0 ]; then echo "${datasets}"; exit 1; fi

trap 'echo "call SIGINT"; kill $(jobs -p); exit' INT
while IFS= read -r dataset; do

	if [ -z "$dataset" ]; then echo "no data for prefix ${prefix} found"; continue; fi

	if [ ${thread_count_int} -eq 1 ]; then
		# variable ${datasets} escaped in get_fasta.sh
		run ${dataset} < /dev/null
		if [ $? -ne 0 ]; then break; fi
	else
		# multiple proceses for multiple threads
		((i=i%thread_count_int)); ((i++==0)) && wait
		# variable ${datasets} escaped in get_fasta.sh
		run ${dataset} & < /dev/null
		if [ $? -ne 0 ]; then break; fi
	fi

done <<< "$datasets"

wait && echo "prefix:$prefix tool:$tool done!"
