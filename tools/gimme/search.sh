#!/bin/bash
#author: plachta11b (janholcak@gmail.com)

# output_information_file keeps information about tool and generated motif for conversion
# exe_file is made by command that have to be executed in gimme container

script_directory=`dirname "$0"`

native="false"
step=1
while [[ $# -gt 0 ]]; do key="$1"; value="$2"; case ${key} in
	--primary-file) primary_file="${value}"; shift; shift; ;;
	--background-file) background_file="${value}"; shift; shift; ;;
	--pm-fasta-file) pm_fasta_file="${value}"; shift; shift; ;;
	--bg-fasta-file) bg_fasta_file="${value}"; shift; shift; ;;
	--genome-file) genome_file="${value}"; shift; ;;
	--output-dir) output_dir="${value}"; shift; ;;
	--motif-length-min) motif_length_min="${value}"; shift; shift; ;;
	--motif-length-max) motif_length_max="${value}"; shift; shift; ;;
	--number-of-motifs) motif_count="${value}"; shift; shift; ;;
	--tool-args) tool_args="${value}"; shift; shift; ;;
	--framework-tools) framework_tools="${value}"; shift; shift; ;;
	--step) step="${value}"; shift; shift; ;;
	--native) native="true"; shift; ;;
	*) shift; ;;
esac; done
iteration_steps="`seq $motif_length_min $step $motif_length_max`"

tools="$framework_tools"

if [ -z "${tools}" ]; then
	echo "error: --framework_tools option required"
	echo "example: --framework_tools <tool>,[<tool>],[<tool>] (warning: HUGE memmory demands)"
	echo "example: --framework_tools MEME[,DREME][,BioProspector] (warning: HUGE memmory demands)"
	echo "example: --native --framework_tools <tool>"
	echo "example: --native --framework_tools MEME"
	echo "example: --native --framework_tools DREME"
	echo "type './run_tool.sh \$prefix gimme -h' for more info"
	exit 1
fi

if [ $native = "true" ]; then
	if [[ $tools == *","* ]]; then
		echo "multiple tools not supported yet with --native option"
		exit 1
	fi
	tools="native_$tools"
fi

# add background flag if background exist
background=""
if [ ! -z "$bg_fasta_file" ]; then
	echo "background set used"
	background="-b /data/background/$bg_fasta_file"
fi

genome="/data/genome/$genome_file"
motif_type="" # empty for both, --denovo for unknown, --known for known

gimme_tools="$tools"
if [[ $tools != *"native_"* ]]; then
	tools="run_gimme_framework"
fi

# gimme,MDmodule,MEME,MEMEW,DREME,Weeder,GADEM,MotifSampler,Trawler,Improbizer,BioProspector,Posmo,ChIPMunk,AMD,HMS,Homer,XXmotif,ProSampler,DiNAMO
included_dir="/usr/local/lib/python3.7/site-packages/gimmemotifs/included_tools"

#
# params
#

# primary fasta sequence
p_primary="/data/primary/$pm_fasta_file"
# background fasta sequence only if not empty
if [ ! -z "$bg_fasta_file" ]; then p_background="-b /data/background/$bg_fasta_file"; else p_background=""; fi
p_width="${motif_length_min}"
p_width_min="${motif_length_min}"
p_width_max="${motif_length_max}"
p_out_dir="/output"
p_strands_count=2
p_strand=1
p_mem_mb=1024
# ${var//string_old/string_new}

output_information_file="${output_dir}/execution_info.txt"
exe_file="${output_dir}/_run.sh"
echo "#!/bin/bash" > $exe_file
chmod +x $exe_file

tool=${tools#native_}
# lowercase()
tool_lowercase=$(echo "$tool" | tr '[:upper:]' '[:lower:]')
case $tool_lowercase in
	run_gimme_framework)
		echo "gimme" > ${output_information_file}

		file_out="/output/gimme.denovo.pfm"

		tools_available="MDmodule,MEME,MEMEW,DREME,Weeder,GADEM,MotifSampler,Trawler,Improbizer,BioProspector,Posmo,ChIPMunk,AMD,HMS,Homer,XXmotif,ProSampler,DiNAMO"
		if [ -z "$gimme_tools" ]; then tools_input="MEME,BioProspector,Homer"; else tools_input="$gimme_tools"; fi

		items_available=($(echo "$tools_available" | tr "," "\n"))
		items_input=($(echo "$tools_input" | tr "," "\n"))

		for input in "${items_input[@]}"; do
			in="false"
			for available in "${items_available[@]}"; do
				if [[ "$input" == *"$available"* ]]; then
					in="true"
				fi
			done
			if [ $in = "false" ]; then echo "$input not in list of available tools (case sensitive)"; echo "$tools_available"; exit 1; fi
		done

		parrams="gimme motifs"
		parrams+=" -t $gimme_tools"
		parrams+=" $motif_type"
		# parrams+=" --nthreads 3"
		parrams+=" -f 1.0"
		# --analysis small (5-8), medium (5-12), large (6-15) or xl (6-20)
		if [ $motif_length_max -gt 20 ]; then
			echo "maximum gimme motif size for analysis is 20nt"
			exit 1
		elif [ $motif_length_max -gt 15 ]; then
			parrams+=" -a xl"
		elif [ $motif_length_max -gt 12 ]; then
			parrams+=" -a large"
		elif [ $motif_length_max -gt 8 ] && [ $motif_length_min -ge 5 ]; then
			parrams+=" -a medium"
		elif [ $motif_length_max -ge 5 ] && [ $motif_length_min -ge 5 ]; then
			parrams+=" -a small"
		else
			echo "minimum gimme motif size for analysis is 5nt"
		fi
		parrams+=" -a xl"
		parrams+=" --noreport"
		parrams+=" -g $genome"
		parrams+=" $background"
		parrams+=" $p_primary"
		parrams+=" /output"

		echo "$parrams ${tool_args}" >> $exe_file

		# replace container path with real path
		echo "${file_out/\/output/${output_dir#*find_motifs}}" >> ${output_information_file}
		;;
	mdmodule) #execute="$included_dir/MDmodule"
		echo "mdmodule" > ${output_information_file}

		for motif_length in $iteration_steps; do
			echo "echo \"run to find motifs of length: ${motif_length}\"" >> $exe_file
			file_out="/output/w${motif_length}_result.txt"

			parrams="$included_dir/MDmodule"
			parrams+=" -i $p_primary"
			parrams+=" $p_background"
			parrams+=" -o $file_out"
			if [ ! -z "${motif_count}" ]; then parrams+=" -r ${motif_count}"; fi
			parrams+=" -w ${p_width}"
			parrams+=" -a 1"

			echo "$parrams ${tool_args}" >> $exe_file

			# replace container path with real path
			echo "${file_out/\/output/${output_dir#*find_motifs}}" >> ${output_information_file}
		done
		;;
	meme) # execute="meme --help"
	# memew) who knows what this is doing
		echo "meme" > ${output_information_file}

		parrams="$p_primary"
		parrams+=" $background"
		parrams+=" -text"
		parrams+=" -dna"
		parrams+=" -nostatus"
		parrams+=" -mod zoops"
		if [ ! -z "${motif_count}" ]; then parrams+=" -nmotifs ${motif_count}"; fi
		# parrams+=" -w ${p_width}"
		parrams+=" -minw ${motif_length_min} -maxw ${motif_length_max}"
		parrams+=" -maxsize 10000000"
		# allow sites on + or - DNA strands
		if [ $p_strands_count = 2 ]; then parrams+=" -revcomp"; fi #both strands sometime cause issues

		docker_switches+=" -e OMPI_MCA_plm_rsh_agent=sh"
		echo "meme $parrams ${tool_args}" >> $exe_file

		echo "${output_dir}/daemon.stdout.log" >> ${output_information_file}
		;;
	dreme)
		echo "dreme" > ${output_information_file}

		# p_width: -mink -maxk -k
		parrams="-p $p_primary"
		parrams+=" -dna"
		parrams+=" ${background/-b/-n}"
		if [ $p_strands_count = 1 ]; then parrams+=" -norc"; fi
		parrams+=" -mink ${motif_length_min} -maxk ${motif_length_max}"
		if [ ! -z "${motif_count}" ]; then parrams+=" -m ${motif_count}"; fi
		parrams+=" -oc ${p_out_dir}"

		echo "$parrams ${tool_args}"
		echo "/usr/local/bin/dreme-py3 $parrams ${tool_args}" >> $exe_file

		echo "${output_dir}/dreme.txt" >> ${output_information_file}
		;;
	weeder)
		# no length params
		echo "weeder" > ${output_information_file}

		# TODO add -W argument for motif width specification
		parrams="-f /output/$pm_fasta_file"
		parrams+=" -O HS"
		if [ $p_strands_count = 1 ]; then parrams+=" -ss"; fi
		if [ ! -z "${motif_count}" ]; then parrams+=" -maxm ${motif_count}"; fi

		cp $primary_file ${output_dir}

		echo "/usr/local/bin/weeder2 $parrams ${tool_args}" >> $exe_file

		echo "${output_dir}/${pm_fasta_file}.matrix.w2" >> ${output_information_file}
		;;
	gadem)
		# no length params
		echo "gadem" > ${output_information_file}
		file_out="/output/observedPWMs.txt"

		parrams="-fseq $p_primary"
		parrams+=" -fpwm $file_out" # Name of output PWM file in STAMP format
		parrams+=" -fout gadem.txt" # Name of main GADEM output file

		echo "/usr/local/bin/gadem $parrams ${tool_args}" >> $exe_file

		echo "${file_out/\/output/${output_dir#*find_motifs}}" >> ${output_information_file}
		;;
	motifsampler)
		echo "motifsampler" > ${output_information_file}
		bg_file="-b /output/bg.model"
		arg="cd /output; $included_dir/CreateBackgroundModel -f $p_primary $bg_file"

		for motif_length in $iteration_steps; do
			echo "echo \"run to find motifs of length: ${motif_length}\"" >> $exe_file
			file_out_stdout="/output/w${motif_length}_motifsampler.txt"
			file_out_matrix="/output/w${motif_length}_matrixFile.txt"
			file_out=$file_out_stdout

			parrams="-f $p_primary"
			parrams+=" $bg_file"
			parrams+=" -m $file_out_matrix"
			parrams+=" -w ${motif_length}"
			parrams+=" -o $file_out_stdout"
			parrams+=" -s $p_strand"
			if [ ! -z "${motif_count}" ]; then parrams+=" -n ${motif_count}"; fi

			# require -b File containing the background model description
			echo "$arg && $included_dir/MotifSampler $parrams ${tool_args}" >> $exe_file

			echo "${file_out/\/output/${output_dir#*find_motifs}}" >> ${output_information_file}
		done
		;;
	trawler)
		# only minimum motif length default 6
		echo "trawler" > ${output_information_file}
		parrams="-sample $p_primary"
		parrams+=" ${background/-b/-background}"
		parrams+=" -directory /output"
		parrams+=" -strand single" #single or double [DEFAULT = double]
		parrams+=" -wildcard 2" #number of wild card in motifs TODO
		parrams+=" -mlength ${motif_length_min}" #number of wild card in motifs TODO

		echo "/usr/local/bin/trawler $parrams ${tool_args}" >> $exe_file

		echo "${output_dir}/tmp*/result/*pwm" >> ${output_information_file}
		;;
	improbizer)
		# no length params
		echo "improbizer" > ${output_information_file}

		# todo provide background model

		parrams="good=$p_primary"
		# can not contain space
		parrams+=" bad=${background/-b /}"
		if [ ! -z "${motif_count}" ]; then parrams+=" numMotifs=${motif_count}"; fi

		echo "cd /output; $included_dir/ameme $parrams ${tool_args}" >> $exe_file

		echo "${output_dir}/daemon.stdout.log" >> ${output_information_file}
		;;
	bioprospector)
		echo "bioprospector" > ${output_information_file}
		for motif_length in $iteration_steps; do
			echo "echo \"run to find motifs of length: ${motif_length}\"" >> $exe_file
			file_out="/output/w${motif_length}_bioprospector.out"

			parrams="-i $p_primary"
			parrams+=" ${background}"
			parrams+=" -W ${motif_length}"
			if [ ! -z "${motif_count}" ]; then parrams+=" -r ${motif_count}"; fi
			parrams+=" -d $p_strands_count"
			parrams+=" -o $file_out"

			echo "$included_dir/BioProspector $parrams ${tool_args}" >> $exe_file

			echo "${file_out/\/output/${output_dir#*find_motifs}}" >> ${output_information_file}
		done
		;;
	posmo)

		echo "got Segmentation fault"
		exit 1

		echo "posmo" > ${output_information_file}

		# getting segfault

		binary="$included_dir"
		fasta="${output_dir}/posmo.fa"

		cp $primary_file $fasta

		out_file=$($script_directory/supporting/posmo.sh ${output_dir} $binary $p_mem_mb $p_width "/output/posmo.fa")

		echo "/output/posmo.sh" >> $exe_file

		echo "${out_file/\/output/${output_dir}}" >> ${output_information_file}
		;;
	chipmunk)

		file_peaks=""
		echo "need peaks"
		exit 1

		echo "chipmunk" > ${output_information_file}

		echo "$included_dir/ChIPMunk/ChIPMunk.sh $parrams ${tool_args}" >> $exe_file

		echo "${output_dir}/daemon.stdout.log" >> ${output_information_file}
		;;
	amd)
		# no length params
		if [ -z "$background_file" ]; then
			echo "amd require background sequence"
			exit 1
		fi

		echo "amd" > ${output_information_file}

		# found reverse complement motifs

		out_file="/output/amd.fa.Matrix"

		fasta="${output_dir}/amd.fa"
		fasta_bg="${output_dir}/amd.bg.fa"

		cp $primary_file $fasta
		cp $background_file $fasta_bg

		parrams="-F /output/amd.fa"
		parrams+=" -B /output/amd.bg.fa"

		echo "$included_dir/AMD.bin $parrams ${tool_args}" >> $exe_file

		echo "${out_file/\/output/${output_dir}}" >> ${output_information_file}
		;;
	hms)

		file_peaks=""
		echo "need peaks"
		exit 1

		# 8 Segmentation fault when no peakfile provided

		echo "hms" > ${output_information_file}

		parrams="-i $p_primary"
		parrams+=" -w ${p_width}"
		parrams+=" -dna 4"
		parrams+=" -iteration 50"
		parrams+=" -chain 20"
		parrams+=" -seqprop -0.1"
		parrams+=" -t_dof 3"
		parrams+=" -dep 2"
		parrams+=" -peaklocation $file_peaks"

		echo "$included_dir/HMS/hms $parrams ${tool_args}" >> $exe_file

		echo "${output_dir}/daemon.stdout.log" >> ${output_information_file}
		;;
	homer)
		echo "homer" > ${output_information_file}

		iteration_steps="`seq $motif_length_min $step $motif_length_max`"
		iteration_steps_comma="${iteration_steps//$'\n'/,}"
		iteration_steps_us="${iteration_steps//$'\n'/_}"

		echo "echo \"run to find motifs of length: ${iteration_steps_comma}\"" >> $exe_file
		out_file="/output/w${iteration_steps_us}_result.txt"

		parrams="-i $p_primary"
		parrams+=" $background"
		parrams+=" -len ${iteration_steps_comma}"
		if [ ! -z "${motif_count}" ]; then parrams+=" -S ${motif_count}"; fi
		if [ $p_strands_count = 1 ]; then parrams+=" -strand +"; fi
		parrams+=" -o $out_file"

		echo "homer2 denovo $parrams ${tool_args}" >> $exe_file

		echo "${out_file/\/output/${output_dir}}" >> ${output_information_file}

		;;
	xxmotif)
		echo "xxmotif" > ${output_information_file}
		out_file="/output/result.pwm"

		parrams="/output" # OUTDIR:  output directory for all results
		parrams+=" $p_primary"
		parrams+=" ${background/-b/--negSet}"

		# this option leads to errors in StartPosUpdater.cpp
		# In no man's land: pos = 3572 error without --localization option
		# --localization (sequences should have all the same length)
		# if [ $p_strands_count = 2 ]; then parrams+=" --revcomp"; fi

		# can cause other problems not suited for not same length sequences
		# parrams+=" --localization"
		parrams+=" --batch"
		parrams+=" --max-motif-length ${motif_length_max}"

		# without number motifs option
		# --max-motif-length DEFAULT 17, maximum possible length is 26
		echo "/usr/local/bin/XXmotif $parrams ${tool_args}" >> $exe_file

		echo "${output_dir}/${pm_fasta_file/.*/.pwm}" >> ${output_information_file}
		;;
	prosampler)
		echo "prosampler" > ${output_information_file}
		out_file="/output/prosampler.out"

		parrams="-i $p_primary"
		parrams+=" $background"
		parrams+=" -o $out_file"
		parrams+=" -p $p_strands_count"

		echo "/usr/local/bin/ProSampler $parrams ${tool_args}" >> $exe_file

		echo "${out_file/\/output/${output_dir}}" >> ${output_information_file}
		;;
	dinamo)
		echo "dinamo" > ${output_information_file}

		for motif_length in $iteration_steps; do
			echo "echo \"run to find motifs of length: ${motif_length}\"" >> $exe_file
			out_file="/output/w${motif_length}_result.txt"

			parrams="-pf $p_primary"
			parrams+=" ${background/-b/-nf}"
			parrams+=" -l ${p_width}"
			parrams+=" --output-file ${out_file}"

			echo "/usr/local/bin/dinamo $parrams ${tool_args}" >> $exe_file

			echo "${out_file/\/output/${output_dir}}" >> ${output_information_file}
		done
		;;
	*)
		echo "search.sh (gimme): Error not implemented!"
		exit 1
		;;
esac

execute="/output/_run.sh"
echo "command: $execute"
echo "$execute" > ${output_dir}/execute.log

mkdir -p $script_directory/temp/config/gimmemotifs
echo "volume: $(realpath $script_directory/temp/config/gimmemotifs):/root/.config/gimmemotifs"

