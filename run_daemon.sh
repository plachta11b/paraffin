#!/bin/bash

script_directory=`dirname "$0"`

docker_switches="$1" docker_volumes="$2" container="$3" executable="$4" working_directory="$5" timer="$6"

containers="$(${script_directory}/repository.sh)"

eval $(bash ${script_directory}/get_daemon.sh) # return values daemon, daemon_command
container="$(echo "${containers}" | grep "^${container}")"

if [ -z "${container}" ]; then
	echo "container not available in repository"
	exit 1
fi

if [[ ${daemon} == "singularity" ]]; then
	container="$(echo "${container}" | awk '{print $3}')"
	container=${container/\~/$HOME}
	echo "run_daemon.sh: singularity daemon detected, run: ${container}"

	if [[ ! -f ${container} ]]; then
		echo "build ${container} container first"
		exit 1
	fi

	docker_volumes=$(echo "${docker_volumes}" | sed 's/-v  */-B\ /g')
elif [[ ${daemon} == "docker" ]]; then
	container="$(echo "${container}" | awk '{print $2}')"
	echo "run_daemon.sh: docker daemon detected, run: ${container}"

	# prevent multiple parallel pull calls
	if [[ "$(docker images -q ${container} 2> /dev/null)" == "" ]]; then
		if ! docker info > /dev/null 2>&1 ; then
			echo "Container not found. Is the docker daemon running?"
		else
			echo "ERROR: container not found. Pull ${container} container and try again."
			echo "tip: docker pull ${container}"
			echo "or use pull_containers.sh to pull them all!"
		fi
		exit 1
	fi
else
	echo "ERROR: no container daemon detected (exit)"
	echo "${daemon} ${daemon_command}"
	exit 1
fi

# for better security no user input should be processed after next line
echo "run_daemon.sh: create run script"
echo "#!/bin/sh" > $working_directory/_run_daemon_script.sh
echo "$executable" >> $working_directory/_run_daemon_script.sh
chmod +x $working_directory/_run_daemon_script.sh
executable="/output/_run_daemon_script.sh"

time_cmd=""
if [ "$timer" = "true" ]; then
	time_cmd="$(${script_directory}/read_config.sh "timer")"
	if [ ! $? -eq 0 ]; then echo "$run_cmd"; exit 1; fi
fi

run_cmd="$(${script_directory}/read_config.sh "${daemon}_run_cmd")"
if [ ! $? -eq 0 ]; then echo "$run_cmd"; exit 1; fi

exec_cmd="$(eval echo $run_cmd)"

exec_cmd="$(echo "$exec_cmd" | sed "s#__TIMER__#$time_cmd#")"

if [[ "${daemon}" == "singularity" ]] && [[ "${executable}" =~ .*\.sh.* ]]; then
	run_cmd=$(echo $run_cmd | sed 's/run/exec/')
fi

verbosity="$(${script_directory}/read_config.sh "verbosity")"
verbosity_stdout="$(${script_directory}/read_config.sh "verbosity_stdout")"
if [ "$verbosity" = "true" ]; then
echo "<run_container_cmd>"
echo "$exec_cmd";
echo "</run_container_cmd>"
fi

# add project src dir into path temporarily
export PATH="$PATH:$(realpath ${script_directory})/"

pushd "${working_directory}" > /dev/null
# expand parameters and run command
echo "run_daemon.sh: run!"
if [ "$verbosity_stdout" = "true" ]; then
	eval ${exec_cmd} 1> >(tee -a "${working_directory}/daemon.stdout.log" ) 2> >(tee -a "${working_directory}/daemon.stderr.log" >&2 ); exit_code=$?
else
	eval ${exec_cmd} 1>> "${working_directory}/daemon.stdout.log" 2>> "${working_directory}/daemon.stderr.log"; exit_code=$?
fi
popd > /dev/null
if [ ! ${exit_code} -eq 0 ]; then echo "ERROR: script run statuscode not equal 0"; echo "<failed>${exec_cmd}<failed>"; exit 1; fi
