#!/bin/sh

usage (){
cat << EOF
##########################################################################################################
##
## Script Options:
##   Required:
##	-i	Sample input file
##
##   Optional:
##	-T	BED file of the regions to restrict the analysis to
##	-o	Output directory
##	-c	config file [defaults to the place where the script was run/config]
##
##
## 	This script is designed to identify and report concordance  from 2 variant call sets.  As an 
##	example, one could compare the calls for a particular panel with and without an option (e.g. Mark 
##	Duplicates) set.
##
##
##	An example SAMPLE_INPUT file would look like this:
##		InterAssay /path/to/vcf1 /path/to/vcf2 sampleName1 samplename2
##		InterAssay /path/to/vcf0 /path/to/vcf2 sampleName1 samplename2
##		IntraFlowcell /path/to/vcf1 /path/to/vcf2 sampleName1 samplename2
##
##	Note: Because some CLC names have spaces, this file must be tab seperated!
##	
#########################################################################################################

EOF
}

#Set Defaults
#This identifies where the script is located
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
#This sets the default config file
configFile=${DIR}/config/config.cfg
OUTDIR=$PWD
TIMESTAMP=$(date | cut -f4,5,2 -d " " | sed 's/ /_/g' | sed 's/:/_/g')
RESULTDIR="result"_$TIMESTAMP
OUTDIRFLAG=0
##################################################################################
###
###     Parse Argument variables
###
##################################################################################
echo "Options specified: $@"
##fix
while getopts "i:T:lc:kho:" OPTION; do
  case $OPTION in
	i) inputFile=$OPTARG ;;
	T) targetBed=$OPTARG ;;
	l) set -x ;;
	c) configFile=$OPTARG ;;
	o) OUTDIR=$OPTARG ;;
    h) usage
        exit ;;
	\?) echo "Invalid option: -$OPTARG. See output file for usage." >&2
       usage
       exit ;;
    :) echo "Option -$OPTARG requires an argument. See output file for usage." >&2
       usage
       exit ;;
  esac
done

##################################################################################
###
###     Validate Inputs
###
##################################################################################

if [ -z "$inputFile" ]
then
	usage
	echo "You did not specify an input file!"
	exit 100
fi
OUTDIR=$(readlink -f $OUTDIR)
inputFile=`readlink -f $inputFile`
cd $OUTDIR
mkdir $OUTDIR/$RESULTDIR
cp $inputFile $OUTDIR/$RESULTDIR/
ConfigName=$(echo $inputFile | rev | cut -f1 -d '/' | rev)
source $configFile
#Ensure that there are 5 fields set
INPUT_VALID=`awk -F'\t' '{if(NF!=5){print "Line number", NR,"is not set correctly in your input file\n"}}' $inputFile`
if [ ! -z "$INPUT_VALID" ]
then
	echo "$INPUT_VALID" 
	echo "your input file is not formatted properly!"
	exit 100
fi 

#Now validate each component
LEN=`wc -l $inputFile |cut -f1 -d" "`

for x in `seq 1 $LEN`
do
	LABEL=$(awk -F'\t' -v var=$x '{if(NR==var){print $1}}' $inputFile)
	VCF1=$(awk -F'\t' -v var=$x '{if(NR==var){print $2}}' $inputFile)
	VCF2=$(awk -F'\t' -v var=$x '{if(NR==var){print $3}}' $inputFile)
	
	if [[ "$VCF1" == *gz ]] ;
	then
		VCF1Name=`basename $VCF1 .gz`
	else
		VCF1Name=`basename $VCF1`
	fi
	if [[ "$VCF2" == *gz ]] ;
	then
		VCF2Name=`basename $VCF2 .gz`
	else
		VCF2Name=`basename $VCF2`
	fi
	if [ "$VCF1Name" == "$VCF2Name" ]
	then
		VCF1BaseName=`basename $VCF1Name .vcf`
		VCF2BaseName=`basename $VCF2Name .vcf`
		VCFReName=${VCF1BaseName}_1.vcf
		VCF1Name=${VCF1BaseName}_1.vcf
		cp $VCF1 $OUTDIR/$RESULTDIR/$VCFReName
		sed -i 's| (Variants)||g' $OUTDIR/$RESULTDIR/$VCFReName
		sed -i 's| (paired)||g' $OUTDIR/$RESULTDIR/$VCFReName
		sed -i 's|\t(Variants)||g' $OUTDIR/$RESULTDIR/$VCFReName
		sed -i 's|\t(paired)||g' $OUTDIR/$RESULTDIR/$VCFReName
		VCFReName=${VCF2BaseName}_2.vcf
		VCF2Name=${VCF2BaseName}_2.vcf
		cp $VCF2 $OUTDIR/$RESULTDIR/$VCFReName
		sed -i 's| (Variants)||g' $OUTDIR/$RESULTDIR/$VCFReName
		sed -i 's| (paired)||g' $OUTDIR/$RESULTDIR/$VCFReName
		sed -i 's|\t(Variants)||g' $OUTDIR/$RESULTDIR/$VCFReName
		sed -i 's|\t(paired)||g' $OUTDIR/$RESULTDIR/$VCFReName
	else
		VCF1BaseName=`basename $VCF1Name .vcf`
		VCF2BaseName=`basename $VCF2Name .vcf`
		cp $VCF1 $OUTDIR/$RESULTDIR/
		sed -i 's| (Variants)||g' $OUTDIR/$RESULTDIR/${VCF1BaseName}.vcf
		sed -i 's| (paired)||g' $OUTDIR/$RESULTDIR/${VCF1BaseName}.vcf
		sed -i 's|\t(Variants)||g' $OUTDIR/$RESULTDIR/${VCF1BaseName}.vcf
		sed -i 's|\t(paired)||g' $OUTDIR/$RESULTDIR/${VCF1BaseName}.vcf
		cp $VCF2 $OUTDIR/$RESULTDIR/
		sed -i 's| (Variants)||g' $OUTDIR/$RESULTDIR/${VCF2BaseName}.vcf
		sed -i 's| (paired)||g' $OUTDIR/$RESULTDIR/${VCF2BaseName}.vcf
		sed -i 's|\t(Variants)||g' $OUTDIR/$RESULTDIR/${VCF2BaseName}.vcf
		sed -i 's|\t(paired)||g' $OUTDIR/$RESULTDIR/${VCF2BaseName}.vcf
	fi
	
	
	gunzip $OUTDIR/$RESULTDIR/*.vcf.gz
	
	VCF1=$OUTDIR/$RESULTDIR/$VCF1Name
	VCF2=$OUTDIR/$RESULTDIR/$VCF2Name
	
	SAMPLE1=$(awk -F'\t' -v var=$x '{if(NR==var){print $4}}' $inputFile)
	
	SAMPLE2=$(awk -F'\t' -v var=$x '{if(NR==var){print $5}}' $inputFile)
	
	echo -e 'InterAssay\t'$OUTDIR'/'$RESULTDIR'/'$VCF1Name'\t'$OUTDIR'/'$RESULTDIR'/'$VCF2Name'\t'$SAMPLE1'\t'$SAMPLE2 >> $OUTDIR/$RESULTDIR/inputfile.tsv
	
	#CHECK VCF1
	if [ ! -s "$VCF1" ] || [ ! -s "$VCF1" ]
	then
		echo "Please check these VCF Files!"
		echo "VCF1="$VCF1
		echo "VCF2="$VCF2
	fi
	
	TEST1=`${VCF_LIB}/vcfsamplenames $VCF1 |grep "$SAMPLE1"`
	TEST2=`${VCF_LIB}/vcfsamplenames $VCF2 |grep "$SAMPLE2"`

	if [ -z "$TEST1" ] || [ -z "$TEST2" ]
	then
		echo "Please check these sample names in these VCF Files!"
		echo "VCF1=$VCF1 should be $SAMPLE1"
		echo "VCF2=$VCF2 should be $SAMPLE2"
	fi
	Original_SampleName1=$SAMPLE1
	Original_SampleName2=$SAMPLE2
done

inputFile=$OUTDIR/$RESULTDIR/inputfile.tsv

##################################################################################
###
###     Run Functions
###
##################################################################################
#Go through the config file and run one analysis at a time
for x in `seq 1 $LEN`
do
	LABEL=$(awk -F'\t' -v var=$x '{if(NR==var){print $1}}' $inputFile)
	VCF1=$(awk -F'\t' -v var=$x '{if(NR==var){print $2}}' $inputFile)
	VCF2=$(awk -F'\t' -v var=$x '{if(NR==var){print $3}}' $inputFile)
	
	SAMPLE1=$(awk -F'\t' -v var=$x '{if(NR==var){print $4}}' $inputFile)
	SAMPLE2=$(awk -F'\t' -v var=$x '{if(NR==var){print $5}}' $inputFile)
	
	VCF1Name=`basename $VCF1 .vcf.gz`
	VCF2Name=`basename $VCF2 .vcf.gz`

	#If Target BED file is specified, restrict analysis to those regions
	if [ ! -z "$targetBed" ] 
	then	
		$BEDTOOLS_PATH intersect -a $VCF1 -b $targetBed -u > $OUTDIR/$RESULTDIR/tmp
		grep "#" $VCF1 > $OUTDIR/$RESULTDIR/${VCF1Name}_target.vcf
		cat $OUTDIR/$RESULTDIR/tmp >> $OUTDIR/$RESULTDIR/${VCF1Name}_target.vcf
		
		
		$BEDTOOLS_PATH intersect -a $VCF2 -b $targetBed -u > $OUTDIR/$RESULTDIR/tmp
		grep "#" $VCF2 > $OUTDIR/$RESULTDIR/${VCF2Name}_target.vcf
		cat $OUTDIR/$RESULTDIR/tmp >> $OUTDIR/$RESULTDIR/${VCF2Name}_target.vcf
		echo -e 'InterAssay\t'$OUTDIR'/'$RESULTDIR'/'${VCF1Name}_target.vcf'\t'$OUTDIR'/'$RESULTDIR'/'${VCF2Name}_target.vcf'\t'$SAMPLE1'\t'$SAMPLE2 >> $OUTDIR/$RESULTDIR/inputfile_target.tsv	
	fi
done

if [ ! -z "$targetBed" ]
then
	inputFile=$OUTDIR/$RESULTDIR/inputfile_target.tsv
fi
	


$DIR/scripts/Run.sh $inputFile $OUTDIR/$RESULTDIR/ $DIR/scripts/ ${R_PATH} $DIR/jobs/
echo "CONCORDANCE SUBMITTED"

