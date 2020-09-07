#!/bin/bash

mkdir -p /data/temporary/holcajan/

echo "$@"

{ eval "$@"; }

