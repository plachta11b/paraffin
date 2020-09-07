#!/bin/bash

clean_start="false"
step=1
while [[ $# -gt 0 ]]; do key="$1"; value="$2"; case ${key} in
	--pm-fasta-file) pm_fasta_file="${value}"; shift; shift; ;;
	--bg-fasta-file) bg_fasta_file="${value}"; shift; shift; ;;
	--tool-args) tool_args="${value}"; shift; shift; ;;
	--stage) stage="${value}"; shift; shift; ;;
	--searcher) searcher="${value}"; shift; shift; ;;
	--framework-tools) framework_tools="${value}"; shift; shift; ;;
	--motif-length-min) motif_length_min="${value}"; shift; shift; ;;
	--motif-length-max) motif_length_max="${value}"; shift; shift; ;;
	--output-dir) output_dir="${value}"; shift; ;;
	--step) step="${value}"; shift; shift; ;;
	--number-of-motifs) number_of_motifs="${value}"; shift; shift; ;;
	--clean-start) clean_start="true"; shift; ;;
	*) shift; ;;
esac; done

# generate steps sequence inclusive
iteration_steps="`seq $motif_length_min $step $motif_length_max`"
iteration_steps_comma="${iteration_steps//$'\n'/,}"
iteration_steps_us="${iteration_steps//$'\n'/_}"

if [ "$framework_tools" != "PreviousResultsLoaderSearcher" ]; then
	if { [ "${stage}" != "get_command" ] && [ "${stage}" != "execute" ] && [ "${stage}" != "postprocess" ]; }; then
		echo "'--stage (get_command|execute|postprocess|all)' option required"
		exit 1
	fi
fi

if [ $clean_start = "true" ] && { [ "${stage}" = "execute" ] || [ "${stage}" = "postprocess" ]; }; then
	echo "options '--cleen-start' and '--stage (execute|postprocess)' are incompatible"
	exit 1
fi

if [ -z "$framework_tools" ]; then echo "--framework-tools option required"; exit 1; fi

echo "#!/bin/bash" > $output_dir/_run_single_tool.sh
echo "#!/bin/bash" > $output_dir/_run_compute_script.sh
do_not_add_command="false"

if [ "$framework_tools" = "WeederSearcher" ]; then
	if [ -z "$tool_args" ]; then
		tool_args="HS large"
	fi
	single_call_args="--searcher 'WeederSearcher $tool_args'"
elif [ "$framework_tools" = "RNAprofileSearcher" ]; then
	# structure
	single_call_args="--searcher 'RNAprofileSearcher $tool_args'"
elif [ "$framework_tools" = "RNAhybridSearcher" ]; then
	# structure
	single_call_args="--searcher 'RNAhybridSearcher -d 1,1 -q /data/background/$bg_fasta_file $tool_args'"
elif [ "$framework_tools" = "RNAforesterSearcher" ]; then
	# structure
	single_call_args="--searcher 'RNAforesterSearcher -l;/data/background/$bg_fasta_file $tool_args'"
elif [ "$framework_tools" = "MEMERISSearcher" ]; then
	# sequence
	# fixed length
	if [ ! -z "$number_of_motifs" ]; then
		nm="-nmotifs $number_of_motifs"
	fi
	do_not_add_command="true"
	for motif_length in $iteration_steps; do
		single_call_args="--searcher 'MEMERISSearcher -dna $nm -w ${motif_length} $tool_args'"
		echo "#!/bin/bash" > $output_dir/_run_single_w_${motif_length}tool.sh
		echo "/compute/run_single.sh --width ${motif_length} --fasta /data/primary/${pm_fasta_file} --output-dir /output $single_call_args" >> $output_dir/_run_single_w_${motif_length}tool.sh
		echo "mkdir -p /output/w_${motif_length}" >> $output_dir/_run_compute_script.sh
		echo "bash -c \"/compute/run_compute.sh /output/_run_single_w_${motif_length}tool.sh ${stage} /output/w_${motif_length}\"" >> $output_dir/_run_compute_script.sh
		chmod +x $output_dir/_run_single_w_${motif_length}tool.sh
		chmod +x $output_dir/_run_compute_script.sh
	done
elif [ "$framework_tools" = "MEMESearcher" ]; then
	# sequence
	single_call_args="--searcher 'MEMESearcher $tool_args'"
elif [ "$framework_tools" = "MDscanSearcher" ]; then
	# noarg
	# sequence
	single_call_args="--searcher 'MDscanSearcher $tool_args'"
elif [ "$framework_tools" = "HOMERSearcher" ]; then
	# sequence
	# fixed length multiple
	# deal with odd motif_length_max argument (better one longer than shorter :)

	if [ ! -z "$number_of_motifs" ]; then
		nm="-S $number_of_motifs"
	fi

	single_call_args="--searcher 'HOMERSearcher /data/background/$bg_fasta_file, -len $iteration_steps_comma $nm $tool_args'"
elif [ "$framework_tools" = "GraphProtSearcher" ]; then
	# sequence
	single_call_args="--searcher 'GraphProtSearcher /data/background/$bg_fasta_file, -percentile 95 $tool_args'"
elif [ "$framework_tools" = "GLAM2Searcher" ]; then
	# noarg
	# sequence
	single_call_args="--searcher 'GLAM2Searcher $tool_args'"
elif [ "$framework_tools" = "GibbsSearcher" ]; then
	motifs_sizes=""
	for motif_length in $iteration_steps; do
		motifs_sizes+="${motif_length},"
	done
	motifs_sizes="$(echo $motifs_sizes | sed 's/,$//')"
	single_call_args="--searcher 'GibbsSearcher $motifs_sizes $tool_args'"
elif [ "$framework_tools" = "CMfinderSearcher" ]; then
	# noarg
	# structure
	single_call_args="--searcher 'CMfinderSearcher $tool_args'"
elif [ "$framework_tools" = "PreviousResultsLoaderSearcher" ]; then
	# noarg
	# structure
	searcher="--searcher 'PreviousResultsLoaderSearcher --dmpath /output/motifSearchesResults.txt'"
	if [ -z "$tool_args" ]; then
		echo "--strategy and --printer options in --tool-args have to be specified"
		exit 1
	fi

	args="$searcher $tool_args"

	function skip_first_n {

		if [ ! -t 0 ]; then INPUT="$(cat)"; else INPUT=""; fi

		echo "$INPUT" | awk '{if (NR>n) print}' n=$1
	}

	rm -f $output_dir/motifSearchesResults.txt
	result_files="$(find $output_dir/../ -name "motifSearchesResults.txt")"

	# merge all results files skip headers
	first=true
	while IFS= read -r result_file; do
		if [ "$first" = "true" ]; then
			cat $result_file > $output_dir/motifSearchesResults.txt
		else
			cat $result_file | skip_first_n 1 >> $output_dir/motifSearchesResults.txt
		fi
		first=false
	done <<< "$result_files"

	mkdir -p $output_dir/PreviousResultsLoader

	echo "#!/bin/bash" > $output_dir/_run_compute_script.sh
	echo "cd /output/PreviousResultsLoader" >> $output_dir/_run_compute_script.sh
	echo "bash -c \"dynamit /data/primary/${pm_fasta_file} $args --print -o /output/PreviousResultsLoader\"" >> $output_dir/_run_compute_script.sh
	chmod +x $output_dir/_run_compute_script.sh
	echo "command: /output/_run_compute_script.sh"
	exit 0
else
	echo "--framework-tools $framework_tools not implemented!"
	echo "--framework-tools (PreviousResultsLoaderSearcher|WeederSearcher|RNAprofileSearcher|RNAhybridSearcher|RNAforesterSearcher|MEMERISSearcher|MEMESearcher|MDscanSearcher|HOMERSearcher|GraphProtSearcher|GLAM2Searcher|GibbsSearcher|CMfinderSearcher)"
	exit 1
fi


if [ "$do_not_add_command" = "false" ]; then
	# this script execute dynamit command with arguments
	# TODO for in tool_args for width and mkdir width folder
	echo "/compute/run_single.sh --fasta /data/primary/${pm_fasta_file} --output-dir /output $single_call_args" >> $output_dir/_run_single_tool.sh
	
	# this script takes care of get_command,execute,postprocess schema
	echo "bash -c \"/compute/run_compute.sh /output/_run_single_tool.sh ${stage} /output\"" >> $output_dir/_run_compute_script.sh
fi

chmod +x $output_dir/_run_single_tool.sh
chmod +x $output_dir/_run_compute_script.sh

echo "command: /output/_run_compute_script.sh"
