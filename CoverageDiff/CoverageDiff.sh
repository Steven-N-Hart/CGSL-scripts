#!/bin/sh

usage (){
cat << EOF
##########################################################################################################
##
## Script Options:
##   Required:
##      -b	BAM file1 (ex: from CLC pipeline)
##      -B	BAM file2 (ex: from GGPS pipeline)
##	-T	BED file of the regions to restrict the analysis to
##
##   Optional:
##	-d	minDepth at which to report out failed regions [default=100]
##	-l	enable logging
##	-c	config file [defaults to the place where the script was run]
##	-k	Flag set to keep temporary files (for debugging only)
##
##
## 	This script is designed to identify and report coverage differences from multiple pipelines.  As an 
##	example, one could compare the coverage for a particular panel between CLC and genomeGPS.
##
#########################################################################################################

EOF
}

#Set Defaults
#This identifies where the script is located
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
#This sets the default config file
configFile=${DIR}/config/config.cfg
##################################################################################
###
###     Parse Argument variables
###
##################################################################################
echo "Options specified: $@"
##fix
while getopts ":b:B:lc:T:khd:" OPTION; do
  case $OPTION in
	b) clcBAM=$OPTARG ;;
	B) ggpsBAM=$OPTARG ;;
	T) targetBed=$OPTARG ;;
	l) set -x ;;
	c) configFile=$OPTARG ;;
	d) minDepth=$OPTARG ;;
	k) keepTemp="TRUE" ;;
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
###     Validate input values
###
##################################################################################
#Makes sure files exist
if [ -z "$clcBAM"  -o -z "$ggpsBAM" -o -z "$targetBed" ]
then
	echo "ERROR: Check the input files!  One of them is not valid!"
	echo "clcBAM = " $clcBAM
	echo "ggpsBAM = " $ggpsBAM
	echo "targetBed = " $targetBed
	usage
	exit 100
fi

if [ -z "$minDepth" ]
then
	echo "###INFO: minDP option not set. Using 100"
	minDepth=100
fi

#Validate CONFIG
source $configFile
if [ ! -d "$BEDTOOLS_PATH" ]; then echo "BEDTOOLS_PATH is not set in your config file"; exit 100; fi
if [ ! -d "$R_PATH" ]; then echo "R_PATH is not set in your config file"; exit 100; fi


##################################################################################
###
###     Get counts at each base
###
##################################################################################
perl -ane '$i=@F[1];$j=@F[2];$j=~s/\r\n//;while($i<$j){print join("\t",@F[0],$i,$i+1)."\n";$i++}' $targetBed|$BEDTOOLS_PATH/bedtools multicov -bams $clcBAM $ggpsBAM -bed - > coverage.out

$R_PATH/Rscript $DIR/scripts/plotCoverageDiff.R `basename $clcBAM` `basename $ggpsBAM` $minDepth

if [ -z "$keepTemp" ]
then
	rm coverage.out
fi