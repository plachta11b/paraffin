#!/bin/bash
root_dir="$1"; prefix="$2"; motif_size="$3 $4"

run_tool=$root_dir/tools/run_tool.sh

trap 'kill $(jobs -p); exit;' EXIT
# SIGINT SIGTERM those have some consequences

# short motif 7
# motif_size="6 8"
# long motif 16
# motif_size="10 25"
args="--number-of-motifs 5"

# $run_tool $prefix dynamit $motif_size --framework-tools WeederSearcher $args --tool-args "HS small" --stage all &
# $run_tool $prefix dynamit $motif_size --framework-tools RNAprofileSearcher $args --stage all & # structure
# $run_tool $prefix dynamit $motif_size --framework-tools RNAhybridSearcher $args --stage all & # structure
# $run_tool $prefix dynamit $motif_size --framework-tools RNAforesterSearcher $args --stage all & # structure
# $run_tool $prefix dynamit $motif_size --framework-tools MEMERISSearcher $args --stage all --step 4 & # poorly generating structure (need fix)
# $run_tool $prefix dynamit $motif_size --framework-tools MEMESearcher $args --stage all & # can not do DMD in current version (meme under 5.1)
$run_tool $prefix dynamit $motif_size --framework-tools MDscanSearcher $args --stage all &
$run_tool $prefix dynamit $motif_size --framework-tools HOMERSearcher $args --stage all --step 4 &
$run_tool $prefix dynamit $motif_size --framework-tools GraphProtSearcher $args --stage all &
# -z minimum sites
$run_tool $prefix dynamit $motif_size --framework-tools GLAM2Searcher $args --stage all & 
$run_tool $prefix dynamit $motif_size --framework-tools GibbsSearcher $args --stage all --step 2 &
# $run_tool $prefix dynamit $motif_size --framework-tools CMfinderSearcher $args --stage all & # structure

$run_tool $prefix gimme $motif_size --native --framework-tools MDmodule $args &
# $run_tool $prefix gimme $motif_size --native --framework-tools MEME $args & # can not do DMD in current version (meme under 5.1)
# $run_tool $prefix gimme $motif_size --native --framework-tools MEMEW $args &
$run_tool $prefix gimme $motif_size --native --framework-tools DREME $args &
$run_tool $prefix gimme $motif_size --native --framework-tools Weeder $args &
$run_tool $prefix gimme $motif_size --native --framework-tools GADEM $args &
$run_tool $prefix gimme $motif_size --native --framework-tools MotifSampler $args --step 1 & # fast
$run_tool $prefix gimme $motif_size --native --framework-tools Trawler $args &
# $run_tool $prefix gimme $motif_size --native --framework-tools Improbizer $args &
$run_tool $prefix gimme $motif_size --native --framework-tools BioProspector $args --step 1 & # no similar motif on small step
# $run_tool $prefix gimme $motif_size --native --framework-tools Posmo $args &
# $run_tool $prefix gimme $motif_size --native --framework-tools ChIPMunk $args &
$run_tool $prefix gimme $motif_size --native --framework-tools AMD $args &
# $run_tool $prefix gimme $motif_size --native --framework-tools HMS $args &
$run_tool $prefix gimme $motif_size --native --framework-tools Homer $args --step 2 & # easly adjust to shorter motifs via ambiguous motif edge
$run_tool $prefix gimme $motif_size --native --framework-tools XXmotif $args &
$run_tool $prefix gimme $motif_size --native --framework-tools ProSampler $args &
$run_tool $prefix gimme $motif_size --native --framework-tools DiNAMO $args --step 3 & # too slow for 1 step iteration

# $run_tool $prefix mcat $motif_size $args & # fails too often (tools should be divided)

$run_tool $prefix alignace $motif_size $args &
$run_tool $prefix bamm $motif_size $args &
$run_tool $prefix discrover $motif_size $args &
$run_tool $prefix dreme $motif_size $args &
$run_tool $prefix dynamit $motif_size $args &
# $run_tool $prefix emd $motif_size $args &
# $run_tool $prefix gimme $motif_size $args & # do not run gimme for memmory reasons
$run_tool $prefix graphprot $motif_size $args & # slow
$run_tool $prefix homer $motif_size $args --step 2 &
# $run_tool $prefix mds2 $motif_size $args & # too many motifs (2k) and no relevant significancy score (p-value 0 or 1)
$run_tool $prefix meme $motif_size --dmd $args &
# $run_tool $prefix rpmcmc $motif_size $args & # only sequences under 3k bp, bad results, non discriminative
$run_tool $prefix sshmm $motif_size $args & # bad results on sequence only
# $run_tool $prefix weeder2 $motif_size $args & # bad results due to GC content
$run_tool $prefix xxmotif $motif_size $args &
$run_tool $prefix zagros $motif_size $args & # only short motifs (6-12)

wait

sleep 1

$run_tool $prefix dynamit $motif_size --framework-tools PreviousResultsLoaderSearcher $args --tool-args "--strategy 'AlignmentStrategy' --printer TablePrinter --printer WebLogoPrinter"

echo "$prefix DONE!"

