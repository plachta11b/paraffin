script_out_dir=$1
bin_dir=$2
p_mem_mb=$3
motif_length=$4
fasta=$5


seed=$(echo "11111111111" | head -c $motif_length)
out_file=$fasta.$seed.out

# <MB.mem> <pattern> <fasta.ifn> <nZ.len> <nZ.scr> <flank> <peakc>

read -r -d '' posmo_script << EOM
	#!/bin/bash

	# posmo <MB.mem> <pattern> <fasta.ifn> <nZ.len> <nZ.scr> <flank> <peakc>
	$bin_dir/posmo $p_mem_mb $seed $fasta 1.6 2.5 $motif_length 20

	# clusterwd <context.ifn> <ofn> <score.ofn> <f.pcc.Cut> <n.ICLen> <n.max.offset> <n.alignLength>
	$bin_dir/clusterwd /output/context.posmo.fa.$seed.txt $out_file simi.txt 0.88 10 2 10

EOM

mkdir -p $script_out_dir
echo "$posmo_script" | awk '{$1=$1;print}' > $script_out_dir/posmo.sh
chmod +x $script_out_dir/posmo.sh

echo "$out_file"
