#!/bin/bash

while [[ $# -gt 0 ]]; do key="$1"; value="$2"; case ${key} in
	--pm-fasta-file) pm_fasta_file="${value}"; shift; shift; ;;
	--bg-fasta-file) bg_fasta_file="${value}"; shift; shift; ;;
	--output-dir) output_dir="${value}"; shift; ;;
	--motif-length-min) motif_length_min="${value}"; shift; shift; ;;
	--motif-length-max) motif_length_max="${value}"; shift; shift; ;;
	--tool-args) tool_args="${value}"; shift; shift; ;;
	*) shift; ;;
esac; done

# Input files in classification
# "-fasta" (binding sites)
# "-negfasta" (unbound sites).
# Input files in regression
# "-fasta" sequence file
# "-affinities" sequence scores file (For each sequence - one value per line)
gp_train_args="-fasta /data/primary/$pm_fasta_file"
gp_train_args+=" -negfasta /data/background/$bg_fasta_file"

# GraphProt.pl --action motif --model CLIP.model --fasta CLIP_bound.fa
# no idea if this can be abused for our noCLIP data
gp_motif_args="-fasta /data/primary/$pm_fasta_file"
gp_ls_args="$gp_motif_args"

# -motif_len set length of motifs (default: 12)
# -motif_top_n use use n top-scoring subsequences for motif creation (default: 1000)

read -r -d '' param_script << EOM
	#!/bin/bash

	gp_motif_args="$gp_ls_args"
	gp_train_args="$gp_train_args"
	gp_motif_args="$gp_motif_args"
	motif_length_min="$motif_length_min"
	motif_length_max="$motif_length_max"
EOM

read -r -d '' run_script << "EOM"
	set -e # fail whole script if something goes wrong

	# change working directory to mounted folder
	cd /output

	#echo "paraffin_execute: GraphProt.pl -action ls ${gp_ls_args}"
	#GraphProt.pl -action ls ${gp_ls_args}

	if [ ! -f GraphProt.model ]; then
		echo "paraffin_execute: GraphProt.pl -action train ${gp_train_args}"
		GraphProt.pl -action train ${gp_train_args}
	else
		echo "using existing model"
	fi

	for ((motif_length=${motif_length_min};motif_length<=${motif_length_max};motif_length++)); do
		gp_motif_args_iteration="${gp_motif_args} -motif_len ${motif_length}"
		echo "paraffin_width_info: now working on motif width: ${motif_length} date: $(date)"
		echo "paraffin_execute: GraphProt.pl -action motif ${gp_motif_args_iteration}"
		GraphProt.pl --prefix "w${motif_length}" -mode classification -model GraphProt.model -action motif ${gp_motif_args_iteration}
	done
EOM

echo "${param_script}" | awk '{$1=$1;print}' > "${output_dir}/_run.sh"
echo "${run_script}" | awk '{$1=$1;print}' >> "${output_dir}/_run.sh"
chmod +x "${output_dir}/_run.sh"
echo "command: /output/_run.sh"
