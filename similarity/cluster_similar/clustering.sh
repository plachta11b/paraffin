#!/bin/bash

script_directory=`dirname "$0"`; script_name=`basename "$0"`; root_dir="$script_directory/../../";

prefix=$1

find_motifs="$(${root_dir}/get_project_data_dir.sh)/find_motifs/$prefix"
tmp_folder="$(${root_dir}/get_project_data_dir.sh)/similarity_clustering/$prefix"
databases="$(${root_dir}/get_project_data_dir.sh)/databases/"
#compareto="$(realpath ${script_directory}/more)"

if [[ $# -lt 1 ]] ; then
	echo "not enough arguments"
	echo "call: ./$script_name \$prefix"
	exit 1
fi

if [ ! -d "$find_motifs" ]; then
	echo "clustering.sh: folder with given prefix ($prefix) does not exist"
	exit 1
fi

mkdir -p ${tmp_folder}

if [ ! -d $tmp_folder/databases ]; then 
	cp -r $databases/motifsim $tmp_folder/databases
fi

read -r -d '' run_script << "EOM"
	#!/bin/bash

	# THIS HAVE EFFECT ON $CWD/databases/transfac/transfac.txt
	cd /output/

	function get_dataset {
		file="$1"

		# ..../find_motifs/dataset_balance_0008x0008_5utr_bt_bams/result_motifs/mcat/out_6to12_withbg_primary_less_03
		# ----------------------------------------------------------------------mcat/out_6to12_withbg_primary_less_03
		file_short="$(sed 's#.*/result_motifs/##' <<< $file)"

		# after dataset there can be more folders
		# mcat/out_6to12_withbg_primary_less_03
		# -----out_6to12_withbg_primary_less_03
		dataset="$(cut -d '/' -f 2 <<< $file_short)"

		echo $dataset
	}

	motif_files="$(find /data/motifs/ -name "result_converted.transfac.best5.txt")"

	dataset_root_dir="/output/dataset"
	rm -rf $dataset_root_dir; mkdir $dataset_root_dir

	while IFS= read -r motif_file; do
		if [ -z "$motif_file" ]; then continue; fi

		dataset="$(get_dataset $motif_file)"
		file_long_name="$(sed 's#.*/result_motifs/##' <<< $motif_file | sed 's|/|_|g' | sed 's|^_||g')"
		dataset_dir="$dataset_root_dir/$dataset"
		mkdir -p $dataset_dir
		# echo "cp $motif_file $dataset_dir/$file_long_name"
		cp $motif_file $dataset_dir/$file_long_name

		if [[ $motif_file =~ "previousresultsloader" ]]; then
			echo "do not align aligned"
		elif [[ $motif_file =~ "mds2" ]]; then
			echo "too much motifs"
		else
			echo "2 $(basename $file_long_name)">> $dataset_dir/datalist
		fi
	done <<< "$motif_files"

	#
	# This flag --motif-tree results in no output of MOTIFSIM
	#

	#
	# This flag (--database) value (8) Transfac (Free version) is dependent on CWD
	#

	#
	# In case of multiple threads --threads 3
	#

	motifsim_args=" --output-format HTML --top-motifs 5 --best-matches 10 --database 8 --combine-similar"

	for dataset in $dataset_root_dir/*; do
		if [ ! -d $dataset ]; then continue; fi
		results_dir="$(sed 's/dataset/result/' <<< $dataset)"
		mkdir -p $results_dir
		echo "run motifsim on dataset: $dataset"
		/wrapper/motifsim.sh --configuration $dataset/datalist --dataset-dir $dataset --result-dir $results_dir $motifsim_args
	done
EOM

echo "${run_script}" | awk '{$1=$1;print}' > "${tmp_folder}/_run_motifsim.sh"
chmod +x "${tmp_folder}/_run_motifsim.sh"

switches="--init --rm --tty"
#-v ${compareto}:/data/compareto/
volumes="-v ${tmp_folder}:/output/ -v ${find_motifs}:/data/motifs/"
tool_container="motifsim"
execute="/output/_run_motifsim.sh"
working_dir="$tmp_folder"

${root_dir}/run_daemon.sh "${switches}" "${volumes}" "${tool_container}" "${execute}" "${working_dir}"; exit_code=$?
