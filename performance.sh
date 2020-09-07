#!/bin/bash

POSITIONAL=()
while [[ $# -gt 0 ]]; do key="$1"; value="$2"; case $key in
		-o|--output) output="$value"; shift; shift; ;;
		# *) echo "performance.sh: unknown argument: $key"; shift; ;;
		*) POSITIONAL+=("$1"); shift; ;;
	esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

# default TIMEFORMAT $'\nreal\t%3lR\nuser\t%3lU\nsys\t%3lS'

if [ -z "${output}" ]; then
	{ TIMEFORMAT=$'\nreal_perf_time\t%3R\nuser_perf_time\t%3U\nsys_perf_time\t%3S'; time "$@"; }
else
	{ TIMEFORMAT=$'\nreal_perf_time\t%3R\nuser_perf_time\t%3U\nsys_perf_time\t%3S'; time "$@"; } 2> >(tee ${output} >&2 );
fi
