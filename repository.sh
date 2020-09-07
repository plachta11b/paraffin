#!/bin/bash

script_directory=`dirname "$0"`

read -r -d '' containers <<- EOM
	gimme plachta11b/gimme_motifs:0.2-dev ~/singularity/gimme_0_2.simg
	mcat plachta11b/mcat:0.2 ~/singularity/mcat_0_2.simg
	dynamit plachta11b/dynamit:0.1-compute ~/singularity/dynamit.simg
	emd plachta11b/emd:0.1 ~/singularity/emd_0_1.simg
	memesuite biowardrobe2/memesuite:v0.0.1 ~/singularity/memesuite.simg
	latest_memesuite memesuite/memesuite:latest ~/singularity/latest_memesuite.simg
	homer biowardrobe2/homer:v0.0.2 ~/singularity/homer.simg
	xxmotif quay.io/biocontainers/xxmotif:1.6--h2d50403_2 ~/singularity/xxmotif.simg
	bedtools quay.io/biocontainers/bedtools:2.29.2--hc088bd4_0 ~/singularity/bedtools.simg
	weeder2 quay.io/biocontainers/weeder:2.0--h6bb024c_3 ~/singularity/weeder.simg
	bamm soedinglab/bamm-suite:1.0.0 ~/singularity/bammsuite.simg
	alignace plachta11b/alignace:0.1 ~/singularity/alignace.simg
	cmfinder plachta11b/cmfinder:0.1 ~/singularity/cmfinder.simg
	discrover plachta11b/discrover:0.1 ~/singularity/discrover.simg
	graphprot plachta11b/graphprot:0.1 ~/singularity/graphprot.simg
	hellerd_sshmm hellerd/sshmm ~/singularity/sshmm.simg
	mds2 plachta11b/mds2:0.1 ~/singularity/mds2.simg
	rck plachta11b/rck:0.1 ~/singularity/rck.simg
	rnacontext plachta11b/rnacontext:0.1 ~/singularity/rnacontext.simg
	rpmcmc plachta11b/rpmcmc:0.1 ~/singularity/rpmcmc.simg
	sshmm plachta11b/sshmm:0.1 ~/singularity/mod_sshmm.simg
	zagros plachta11b/zagros:0.1 ~/singularity/zagros.simg
	busybox busybox:1.32-glibc ~/singularity/busybox_glibc.simg
	bash bash:4.4.23 ~/singularity/bash.simg
	lead2gold plachta11b/lead2gold:0.1 ~/singularity/lead2gold_0_1.simg
	motifsim plachta11b/motifsim:0.1 ~/singularity/motifsim_0_1.simg
	latest_memesuite memesuite/memesuite:latest ~/singularity/latest_memesuite.simg
EOM

config_file="$script_directory/repository.config"

if [ ! -f $config_file ]; then
	echo "$containers" | awk '{$1=$1;print}' | tee $config_file
else
	cat $config_file
fi
