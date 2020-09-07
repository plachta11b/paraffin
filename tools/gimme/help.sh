#!/bin/bash

echo "You want to run gimme motifs? Try something like this:"

echo "gimme example call: run_tool.sh \$prefix gimme \$motif_length_min \$motif_length_max --framework-tools MEME,DREME,BioProspector"
echo "gimme example call: run_tool.sh \$prefix gimme \$motif_length_min \$motif_length_max --native --framework-tools DREME"
echo "./run_tool.sh \$prefix gimme 10 10 --framework-tools <tool1><,tool2><,toolN>"
echo "./run_tool.sh \$prefix gimme 10 10 --framework-tools MEME,DREME"

echo "only one tool can be run in native form"
echo "./run_tool.sh \$prefix gimme 10 10 --native --framework-tools <tool>"
echo "./run_tool.sh \$prefix gimme 10 10 --native --framework-tools MEME"
echo "./run_tool.sh \$prefix gimme 10 10 --native --framework-tools DREME"
