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
##	-o	OUput directory
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
TIMESTAMP=$(date | cut -f5,4,2 -d " " | sed 's/ /_/g' | sed 's/:/_/g')
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
cp $inputFile $OUTDIR
ConfigName=$(echo $inputFile | rev | cut -f1 -d '/' | rev)
ConfigLoc=$OUTDIR/$ConfigName
inputFile=$ConfigLoc	
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
	SAMPLE1=$(awk -F'\t' -v var=$x '{if(NR==var){print $4}}' $inputFile)
	
	SAMPLE2=$(awk -F'\t' -v var=$x '{if(NR==var){print $5}}' $inputFile)
	#CHECK VCF1
	if [ ! -s "$VCF1" ] || [ ! -s "$VCF1" ]
	then
		echo "Please check these VCF Files!"
		echo "VCF1="$VCF1
		echo "VCF2="$VCF2
	fi
	TEST1=`${VCF_LIB}/vcfsamplenames $VCF1 |grep "$SAMPLE1"`
	TEST2=`${VCF_LIB}/vcfsamplenames $VCF2 |grep "$SAMPLE2"`
	Original_SampleName1=`${VCF_LIB}/vcfsamplenames $VCF1`
	Original_SampleName2=`${VCF_LIB}/vcfsamplenames $VCF2`
	if [ -z "$TEST1" ] || [ -z "$TEST2" ]
	then
		echo "Please check these sample names in these VCF Files!"
		echo "VCF1=$VCF1 should be $SAMPLE1"
		echo "VCF2=$VCF2 should be $SAMPLE2"
	fi
done
#echo $SampleNameinInputVCF1
#echo $SampleNameinInputVCF2
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
	VCF1Name=$(echo $VCF1 | rev | cut -f1 -d '/' | rev)
	VCF2Name=$(echo $VCF2 | rev | cut -f1 -d '/' | rev)
	if [ -f "$OUTDIR/$VCF1Name" ] && [ -f "$OUTDIR/$VCF2Name" ]; then continue; fi
	Prefix1="1_"
	Prefix2="2_"
	VCF1Name=$Prefix1$VCF1Name
	VCF2Name=$Prefix2$VCF2Name
	

	if [ -z "$targetBed" ] ;
	then
		#Get a local copy of each VCF
		if [[ "$VCF1" == *gz ]] ;
		then
			zcat $VCF1 > $OUTDIR/$VCF1Name
		else
			cp $VCF1 $OUTDIR/$VCF1Name
		VCF1Loc=$(readlink -f $VCF1Name)
		sed -i 's|'$VCF1'|'$VCF1Loc'|g' $inputFile
		fi
		if [[ "$VCF2" == *gz ]] ;
		then
			zcat $VCF2 > $OUTDIR/$VCF2Name
		else
			cp $VCF2 $OUTDIR/$VCF2Name
		VCF2Loc=$(readlink -f $VCF2Name)
		sed -i 's|'$VCF2'|'$VCF2Loc'|g' $inputFile
		fi
		
		sed -i "s/$Original_SampleName1/$SAMPLE1/g" $OUTDIR/$VCF1Name
		sed -i "s/$Original_SampleName2/$SAMPLE2/g" $OUTDIR/$VCF2Name
	fi
	#If Target BED file is specified, restrict analysis to those regions
	if [ ! -z "$targetBed" ] 
	then	
		$BEDTOOLS_PATH intersect -a $VCF1 -b $targetBed -u > tmp
		grep "#" $VCF1 | sed "s/$Original_SampleName1/$SAMPLE1/g" > $OUTDIR/$VCF1Name
		cat tmp >> $OUTDIR/$VCF1Name
		VCF1Loc=$(readlink -f $VCF1Name)
		sed -i 's|'$VCF1'|'$VCF1Loc'|g' $inputFile
		$BEDTOOLS_PATH intersect -a $VCF2 -b $targetBed -u > tmp
		grep "#" $VCF2 | sed "s/$Original_SampleName2/$SAMPLE2/g" > $OUTDIR/$VCF2Name
		cat tmp >> $OUTDIR/$VCF2Name
		VCF2Loc=$(readlink -f $VCF2Name)
		sed -i 's|'$VCF2'|'$VCF2Loc'|g' $inputFile
	fi
	
	##################################################################################
	###
	###     Jag & Saranya to insert functions here
	###
	##################################################################################
	
	$DIR/scripts/Run.sh $inputFile $OUTDIR/$RESULTDIR/ $DIR/scripts/ $SAMPLE1 ${R_PATH} $DIR/jobs/
		
done

echo "CONCORDANCE SUBMITTED"
