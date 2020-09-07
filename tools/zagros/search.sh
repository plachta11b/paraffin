#!/bin/bash

step=1
while [[ $# -gt 0 ]]; do key="$1"; value="$2"; case ${key} in
	--pm-fasta-file) pm_fasta_file="${value}"; shift; shift; ;;
	--bg-fasta-file) bg_fasta_file="${value}"; shift; shift; ;;
	--output-dir) output_dir="${value}"; shift; shift; ;;
	--motif-length-min) motif_length_min="${value}"; shift; shift; ;;
	--motif-length-max) motif_length_max="${value}"; shift; shift; ;;
	--step) step="${value}"; shift; shift; ;;
	--tool-args) tool_args="${value}"; shift; shift; ;;
	--number-of-motifs) number_of_motifs="${value}"; shift; shift; ;;
	*) shift; ;;
esac; done

if [ $motif_length_max -gt 12 ]; then
	echo "maximum motif size is 12 (exiting)"
	motif_length_max=12

	if [ $motif_length_min -gt $motif_length_max ]; then
		echo "motif length error (exiting)"
		exit 1
	fi
fi

iteration_steps="`seq $motif_length_min $step $motif_length_max`"

# -w, -width width of motifs to find (4 <= w <= 12; default: 6) 
# -t, -structure          structure information file
# -n, -number             number of motifs to output

if [ ! -z "$number_of_motifs" ]; then
	nm="-number $number_of_motifs"
fi

read -r -d '' run_script << EOM
	#!/bin/bash

	pm_fasta_file="${pm_fasta_file}"
	motif_length_min="${motif_length_min}"
	motif_length_max="${motif_length_max}"
	iteration_steps="$iteration_steps"
	nm="$nm"
EOM

read -r -d '' run_script_loop << "EOM"
	echo "generating structure file..."
	thermo -o /data/primary/${pm_fasta_file}.str /data/primary/${pm_fasta_file}
	echo "generated structure file!"
	for motif_length in $iteration_steps; do
		echo "paraffin_width_info: now working on motif width: ${motif_length} date: $(date)"
		zagros /data/primary/${pm_fasta_file} -w ${motif_length} -output /output/w${motif_length}_result.txt -structure /data/primary/${pm_fasta_file}.str $nm
	done
EOM

echo "${run_script}" | awk '{$1=$1;print}' > "${output_dir}/_run.sh"
echo "${run_script_loop}" | awk '{$1=$1;print}' >> "${output_dir}/_run.sh"
echo "${sizes_script}" | sed 's/^TAB//g' > "${output_dir}/sizes.py"
chmod +x "${output_dir}/_run.sh"
echo "command: /output/_run.sh"
