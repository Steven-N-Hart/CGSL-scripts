#!/bin/sh
#Usage: sh FiguresForConcordance.sh variants.phased.vcf.gz /dlmp/prod/runs/WESTA/HBFTWADXX_ProbA-Lib3/trio/OUTPUT/PI/exome/HBFTWADXX_ProbA-Lib3/variants/variants.phased.vcf.gz ProbA ProbA-Lib3

VCF1=$1
VCF2=$2 
SAMPLE1=$3
SAMPLE2=$4
OUTDIR=$5
START=$PWD
if [ -z "$OUTDIR" ]
then
        OUTDIR=$START
fi
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
SCRIPT=${DIR}/compareToSelfVcf.sh

for x in `seq 0 30`
do
	echo $x of 30
	if [ "$x" == 0 ]
	then
		sh $SCRIPT -c trio1 -v $VCF1 -V $VCF2 -n $SAMPLE1 -N $SAMPLE2 -s > $OUTDIR/concordance.out
	else
		sh $SCRIPT -c trio1 -v $VCF1 -V $VCF2 -n $SAMPLE1 -N $SAMPLE2 -i ${x} >> $OUTDIR/concordance.out
		sh $SCRIPT -c trio1 -v $VCF1 -V $VCF2 -n $SAMPLE1 -N $SAMPLE2 -d ${x} >> $OUTDIR/concordance.out
	fi
done
