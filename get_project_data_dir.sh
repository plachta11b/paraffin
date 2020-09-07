#!/bin/bash

script_directory=`dirname "$0"`

if [[ -z $HOME ]]; then
	echo "WARNING: \$HOME variable is not set"
fi

dir_from_conf="$($script_directory/read_config.sh 'project_data_directory')"
if [ ! $? -eq 0 ]; then echo $dir_from_conf; exit 1; fi
dir_from_conf="${dir_from_conf/\~/$HOME}"

# read and test value from config
if [[ -d "$dir_from_conf" ]]; then
	echo "$(realpath $dir_from_conf)"
	exit 0
fi

# use environment variable when config value is set incorrectly

if [[ -z "$MF_PROJECT_DATA_DIR" ]]; then
	echo "set \$MF_PROJECT_DATA_DIR first (/path/to/project/data/dir)" && \
	echo "example: echo 'export MF_PROJECT_DATA_DIR=/media/exhdd_2T/project_data' >> ~/.bashrc # and relog then" && \
	exit 1
fi

if [[ ! -d "$MF_PROJECT_DATA_DIR" ]]; then
	echo "project data dirctory: $MF_PROJECT_DATA_DIR not found!" && \
	exit 1
fi

echo "$(realpath $MF_PROJECT_DATA_DIR)"
exit 0
