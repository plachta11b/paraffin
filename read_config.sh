#!/bin/bash

script_directory=`dirname "$0"`

config_key=$1

# "EOM" dissalow param expansion
# EOM alow param expansion
read -r -d '' default_config << "EOM"
	# project
	project_data_directory: /path/to/project/data
	# container daemon (WORKDIR IS COMPUTATION OUTPUT DIR)
	# docker_run_cmd: performance.sh -o time.stat $daemon_command run $docker_switches $docker_volumes $container $executable
	# singularity_run_cmd: srun --job-name=utr_motif_benchmark --time 30 --quit-on-interrupt /home/holcajan/perf stat -o perf.stat singularity run -C $docker_volumes $container -c $executable
	timer: performance.sh -o time.stat
	docker_run_cmd: $daemon_command run $docker_switches $docker_volumes $container $executable
	singularity_run_cmd: $daemon_command run -C $docker_volumes $container -c "$executable"
	# show what container command is executed
	verbosity: true
	# show running container stdout
	verbosity_stdout: false
	# make this true on readonly containers
	readonly: false
	# check only once for installed daemon and remember it if true
	lock_daemon: false
	# tools - this is deprecated
	motif_min_length: 6
EOM

default_config=$(echo "$default_config")

config_file="$script_directory/project.config"

if [ ! -f $config_file ]; then
	echo "$default_config" | awk '{$1=$1;print}' > $config_file
fi

config_value="$(cat $config_file | grep "^[^#;]" | grep -m 1 -F "$config_key: " | sed "s/$config_key: *//")"
if [ ! $? -eq 0 ] || [ -z "$config_value" ]; then
	config_value="$(echo "$default_config" | grep "^[^#;]" | grep -m 1 -F "$config_key: " | sed "s/$config_key: *//")"
	if [ ! $? -eq 0 ] || [ -z "$config_value" ]; then
		echo "$config_value"; exit 1;
	fi
fi

# awk to trim whitespace from start
echo "$config_value" | awk '{$1=$1;print}'

