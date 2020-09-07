#!/bin/bash
root_dir="$1"; prefix="$2"; motif_size="$3 $4 --number-of-motifs 5"

run_tool=$root_dir/tools/run_tool.sh

$run_tool $prefix alignace $motif_size --convert &
$run_tool $prefix bamm $motif_size --convert &
$run_tool $prefix discrover $motif_size --convert &
$run_tool $prefix dreme $motif_size --convert &
$run_tool $prefix dynamit $motif_size --convert &
$run_tool $prefix emd $motif_size --convert &
$run_tool $prefix gimme $motif_size --convert &
$run_tool $prefix graphprot $motif_size --convert &
$run_tool $prefix homer $motif_size --convert &
$run_tool $prefix mcat $motif_size --convert &
$run_tool $prefix mds2 $motif_size --convert &
$run_tool $prefix meme $motif_size --convert &
$run_tool $prefix rpmcmc $motif_size --convert &
$run_tool $prefix sshmm $motif_size --convert &
$run_tool $prefix weeder2 $motif_size --convert &
$run_tool $prefix xxmotif $motif_size --convert &
$run_tool $prefix zagros $motif_size --convert &

wait

sleep 1

$root_dir/tools/convert_converted.sh $prefix
