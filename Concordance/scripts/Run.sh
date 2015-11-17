CONFIG=$1
OUTPUTPATH=$2
SCRIPTPATH=$3
R_PATH=$4
JOB_PATH=$5
EMAIL=`finger $USER|head -1|perl -pne 's/;/\t/g;s/ +/\t/g'|tr "\t" "\n"|grep "@"`
#Make concordance plots
NUM_TEST=`wc -l $CONFIG`
NUM_RUNS=`wc -l $CONFIG | awk '{print $1}'`
SAMPLENAME="1"
for x in `seq 1 $NUM_RUNS`
do
 RUN=$(awk -v var=$x '(NR==var)' $CONFIG)
 DIR=`echo $RUN | awk '{print $1"_"$4"_"$5}'`
 SAMPLENAME=$(awk -F'\t' -v var=$x '{if(NR==var){print $4}}' $CONFIG)
 
 if [ ! -d "$DIR" ]
  then
	mkdir $OUTPUTPATH/$DIR
 fi
 SUBMISSION=`echo ${RUN}|cut -f1 --complement -d" "`
 FILE_PREFIX=$RANDOM
 qsub -V -q sandbox.q -N Concordance -l h_vmem=3G -l h_stack=10M -m ae -M $EMAIL -e $JOB_PATH/Concordance"_"$FILE_PREFIX.error -o $JOB_PATH/Concordance"_"$FILE_PREFIX.out $SCRIPTPATH/./FiguresForConcordance.sh ${SUBMISSION} ${DIR} ${OUTPUTPATH} ${SCRIPTPATH} ${CONFIG}
 qsub -hold_jid Concordance -V -q sandbox.q -N RemoveInter -l h_vmem=3G -l h_stack=10M -m ae -M $EMAIL -e $JOB_PATH/RemoveIntermediates"_"$FILE_PREFIX.error -o $JOB_PATH/RemoveIntermediates"_"$FILE_PREFIX.out $SCRIPTPATH/./RemoveIntermediates.sh ${OUTPUTPATH} ${DIR} ${CONFIG} 
done
qsub -hold_jid RemoveInter -V -q sandbox.q -N Rscript -l h_vmem=3G -l h_stack=10M -m ae -M $EMAIL -e $JOB_PATH/Plot"_"$FILE_PREFIX.error -o $JOB_PATH/Plot"_"$FILE_PREFIX.out $SCRIPTPATH/./Plot.sh $SAMPLENAME $OUTPUTPATH $SCRIPTPATH $R_PATH