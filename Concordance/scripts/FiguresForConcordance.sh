#!/bin/bash
#Usage: sh FiguresForConcordance.sh variants.phased.vcf.gz /dlmp/prod/runs/WESTA/HBFTWADXX_ProbA-Lib3/trio/OUTPUT/PI/exome/HBFTWADXX_ProbA-Lib3/variants/variants.phased.vcf.gz ProbA ProbA-Lib3

VCF1=$1
VCF2=$2 
SAMPLE1=$3
SAMPLE2=$4
OUTDIR=$5
DIR=$6
SCRIPTPATH=$7
CONFIG=$8
START=$PWD
if [ -z "$OUTDIR" ]
then
        OUTDIR=$START
fi
SCRIPT=${SCRIPTPATH}/compareToSelfVCF.sh
#echo $SCRIPT
for x in `seq 0 30`
do
	echo $x of 30
	if [ "$x" == 0 ]
	then
		sh $SCRIPT -c trio1 -v $VCF1 -V $VCF2 -n $SAMPLE1 -N $SAMPLE2 -s > $DIR/$OUTDIR/concordance.out
	else
		sh $SCRIPT -c trio1 -v $VCF1 -V $VCF2 -n $SAMPLE1 -N $SAMPLE2 -i ${x} >> $DIR/$OUTDIR/concordance.out
		sh $SCRIPT -c trio1 -v $VCF1 -V $VCF2 -n $SAMPLE1 -N $SAMPLE2 -d ${x} >> $DIR/$OUTDIR/concordance.out
	fi
done

