#!/bin/bash

script_directory=`dirname "$0"`

lock_daemon="$(${script_directory}/read_config.sh "lock_daemon")"
if [ ! $? -eq 0 ]; then echo "$lock_daemon"; exit 1; fi

if [ "$lock_daemon" = "true" ] && [ -f "$script_directory/daemon.lock" ]; then
	cat $script_directory/daemon.lock
	exit
fi

COMMAND_DOCKER="${COMMAND_DOCKER:-docker}"
COMMAND_SINGULARITY="${COMMAND_SINGULARITY:-singularity}"

$COMMAND_DOCKER -v > /dev/null 2>&1

if [ $? -eq 0 ];
then
	echo "daemon=\"docker\"; daemon_command=\"$COMMAND_DOCKER\"" > "$script_directory/daemon.lock"
	echo "daemon=\"docker\"; daemon_command=\"$COMMAND_DOCKER\""
	exit 0
fi

$COMMAND_SINGULARITY --version > /dev/null 2>&1

if [ $? -eq 0 ];
then
	echo "daemon=\"singularity\"; daemon_command=\"$COMMAND_SINGULARITY\"" > "$script_directory/daemon.lock"
	echo "daemon=\"singularity\"; daemon_command=\"$COMMAND_SINGULARITY\""
	exit 0
fi

echo "daemon=\"error\"; daemon_command=\"echo "invalid daemon command"; exit 1;\""
exit 1
