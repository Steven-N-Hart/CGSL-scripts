DIR=$1
OUTDIR=$2
CONFIG=$3
perl -p -i -e 's/\t\t/\t.\t/g' $DIR/$OUTDIR/concordance.out
#rm $CONFIG
#rm $DIR/*.vcf

