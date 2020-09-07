#!/bin/bash

# works on GNU/linux able execute 64 binary files

script_directory=`dirname "$0"`

docker cp $(docker create plachta11b/perf:0.1):/perf $script_directory/perf
chmod +x $script_directory/perf
