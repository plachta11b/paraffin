#!/bin/bash

script_directory=`dirname "$0"`; script_name=`basename "$0"`; root_dir="$script_directory/../../";

prefix=$1

if [[ $# -lt 1 ]] ; then
	echo "not enough arguments"
	echo "call: ./$script_name \$prefix"
	exit 1
fi

find_motifs="$(${root_dir}/get_project_data_dir.sh)/find_motifs/$prefix"
sim_directory="$(${root_dir}/get_project_data_dir.sh)/similarity_test/$prefix"
compareto="$(realpath ${script_directory}/../data/$prefix)"

if [ ! -d "$find_motifs" ]; then
	echo "compare.sh: folder with given prefix ($prefix) does not exist"
	exit 1
fi

if [ ! -d "$compareto" ]; then
	echo "compare.sh: comparison folder similarity/data/$prefix/ does not exist"
	exit 1
fi

mkdir -p ${sim_directory}

echo "
#!/bin/bash
prefix=${prefix}
" > ${sim_directory}/_run.sh
cat ${script_directory}/script.sh >> ${sim_directory}/_run.sh
cat ${script_directory}/parse_output.py > ${sim_directory}/_parse_output.py
chmod +x ${sim_directory}/_run.sh
chmod +x ${sim_directory}/_parse_output.py

switches="--init --rm --tty"
volumes="-v ${sim_directory}:/output/ -v ${find_motifs}:/data/motifs/ -v ${compareto}:/data/compareto/"
tool_container="motifsim"
execute="bash /output/_run.sh"
working_dir="$sim_directory"

${root_dir}/run_daemon.sh "${switches}" "${volumes}" "${tool_container}" "${execute}" "${working_dir}"; exit_code=$?

echo "Done. Enjoy $prefix motif similarity results!"
