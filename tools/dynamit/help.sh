#!/bin/bash

echo "You wanna play with dynamite? Try something like this:"

echo "------------------------------------"
echo "only one framework tool can run in single dynamit container (containers can be executed in paralel)"
echo "example: ./run_tool.sh \$prefix dynamit \$motif_length_min \$motif_length_max --framework-tools GraphProtSearcher [--tool-args \"GraphProt additional arg\"] --stage get_command"
echo "example: ./run_tool.sh \$prefix dynamit \$motif_length_min \$motif_length_max --framework-tools GraphProtSearcher [--tool-args \"GraphProt additional arg\"] --stage execute"
echo "example: ./run_tool.sh \$prefix dynamit \$motif_length_min \$motif_length_max --framework-tools GraphProtSearcher [--tool-args \"GraphProt additional arg\"] --stage postprocess"


echo "------------------------------------"
echo "dynamit tools results can be merged:"
echo "./$script_name \$prefix dynamit \$motif_length_min \$motif_length_max --framework-tools PreviousResultsLoaderSearcher --tool-args \" --strategy 'AlignmentStrategy' --printer TablePrinter --printer WebLogoPrinter\""


echo "------------------------------------"
echo "available searchers:"
echo "WeederSearcher
RNAprofileSearcher
RNAhybridSearcher
RNAforesterSearcher
RegionsIntersectionSearcher
PreviousResultsLoaderSearcher
MEMERISSearcher
MEMESearcher
MDscanSearcher
MatrixSearcher
KnownSitesSearcher
HOMERSearcher
GraphProtSearcher
GLAM2Searcher
GibbsSearcher
CMfinderSearcher"