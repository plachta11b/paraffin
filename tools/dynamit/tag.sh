#!/bin/bash

while [[ $# -gt 0 ]]; do key="$1"; value="$2"; case ${key} in
	--framework-tools) framework_tools="${value}"; shift; shift; ;;
	*) shift; ;;
esac; done

if [ -z "$framework_tools" ]; then echo "--framework-tools option required"; exit 1; fi

echo "tag: $(echo ${framework_tools} | tr '[:upper:]' '[:lower:]' | sed 's/searcher//')"
