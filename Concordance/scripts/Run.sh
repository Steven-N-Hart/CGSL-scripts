CONFIG=$1
OUTPUTPATH=$2
SCRIPTPATH=$3
SAMPLENAME="1_"$4
R_PATH=$5
JOB_PATH=$6
EMAIL=`finger $USER|head -1|perl -pne 's/;/\t/g;s/ +/\t/g'|tr "\t" "\n"|grep "@"`
#Make concordance plots
NUM_TEST=`wc -l $CONFIG`
NUM_RUNS=`wc -l $CONFIG | awk '{print $1}'`
for x in `seq 1 $NUM_RUNS`
do
 RUN=$(awk -v var=$x '(NR==var)' $CONFIG)
 DIR=`echo $RUN | awk '{print $1"_"$4"_"$5}'`
 if [ ! -d "$DIR" ]
  then
	mkdir $OUTPUTPATH/$DIR
 fi
 SUBMISSION=`echo ${RUN}|cut -f1 --complement -d" "`
 echo $DIR
 echo "\n"
 
 echo $SUBMISSION
 FILE_PREFIX=$RANDOM
 qsub -V -q sandbox.q -N Concordance -l h_vmem=3G -l h_stack=10M -m ae -M $EMAIL -e $JOB_PATH/Concordance"_"$FILE_PREFIX.error -o $JOB_PATH/Concordance"_"$FILE_PREFIX.out $SCRIPTPATH/./FiguresForConcordance.sh ${SUBMISSION} ${DIR} ${OUTPUTPATH} ${SCRIPTPATH} ${CONFIG}
done


for x in `seq 1 $NUM_RUNS`
do
 RUN=$(awk -v var=$x '(NR==var)' $CONFIG)
 DIR=`echo $RUN | awk '{print $1"_"$4"_"$5}'`
 FILE_PREFIX=$RANDOM
 qsub -hold_jid Concordance -V -q sandbox.q -N RemoveInter -l h_vmem=3G -l h_stack=10M -m ae -M $EMAIL -e $JOB_PATH/RemoveIntermediates"_"$FILE_PREFIX.error -o $JOB_PATH/RemoveIntermediates"_"$FILE_PREFIX.out $SCRIPTPATH/./RemoveIntermediates.sh ${OUTPUTPATH} ${DIR} ${CONFIG}
done

FILE_PREFIX=$RANDOM
qsub -hold_jid RemoveInter -V -q sandbox.q -N Rscript -l h_vmem=3G -l h_stack=10M -m ae -M $EMAIL -e $JOB_PATH/Plot"_"$FILE_PREFIX.error -o $JOB_PATH/Plot"_"$FILE_PREFIX.out $SCRIPTPATH/./Plot.sh $SAMPLENAME $OUTPUTPATH $SCRIPTPATH $R_PATH
