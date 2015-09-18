#!/bin/sh
INPUT_VCF=$1
OUTDIR=$2
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
SCRIPT=${DIR}/compareToControlVcf.sh

START=$PWD
if [ -z "$OUTDIR" ]
then
        OUTDIR=$START
fi


for x in `seq 0 30`
do
	echo $x of 30
	if [ "$x" == 0 ]
	then
		sh $SCRIPT -c trio1 -v ${INPUT_VCF} -s > $OUTDIR/results.out
	else
		sh $SCRIPT -c trio1 -v ${INPUT_VCF} -i ${x} >> $OUTDIR/results.out
		sh $SCRIPT -c trio1 -v ${INPUT_VCF} -d ${x}  >> $OUTDIR/results.out
	fi
done

