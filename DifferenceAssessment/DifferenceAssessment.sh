#!/bin/sh

usage (){
cat << EOF
##########################################################################################################
##
## Script Options:
##   Required:
##      -v	VCF file from CLC pipeline
##      -V	VCF file from GGPS pipeline
##      -b	BAM file from CLC pipeline
##      -B	BAM file from GGPS pipeline
##
##   Optional:
##	-s	Sample name from clcVCF (choose this sample from mulisample VCF)
##	-S	Sample name from ggpsVCF (choose this sample from mulisample VCF)
##	-l	enable logging
##	-c	config file [defaults to the place where the script was run]
##	-T	BED file of the regions to restrict the analysis to
##	-k	Flag set to keep temporary files (for debugging only)
##
##
## 	This script is designed to find out why variant calls are discordant between the CLC and genomeGPS 
##	pipelines.  The final output is a summary html document that classifies the contribution of variants
##	to one pipeline or the other by comparing the total and alternate alle variants for pipeline-specific
##	variants.  This same pipeline could be used to compare the results of difference versions of the 
##	same workflow.
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
while getopts "v:V:b:B:lc:T:ks:S:h" OPTION; do
  case $OPTION in
    v) clcVCF=$OPTARG ;;
    V) ggpsVCF=$OPTARG ;;
	b) clcBAM=$OPTARG ;;
	B) ggpsBAM=$OPTARG ;;
	l) set -x ;;
	c) configFile=$OPTARG ;;
	T) targetBed=$OPTARG ;;
	k) keepTemp="TRUE" ;;
	s) clcSample=$OPTARG ;;
	s) ggpsSample=$OPTARG ;;
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
if [ ! -s "$clcVCF" -o ! -s "$ggpsVCF"  -o ! -s "$clcBAM"  -o ! -s "$ggpsBAM" ]
then
	echo "ERROR: Check the input files!  One of them is not valid!"
	echo "clcVCF = " $clcVCF
	echo "clcBAM = " $clcBAM
	echo "ggpsVCF = " $ggpsVCF
	echo "ggpsBAM = " $ggpsBAM
	usage
	exit 100
fi

#Validate CONFIG
source $configFile
if [ ! -d "$JAVA_PATH" ]; then echo "JAVA_PATH is not set in your config file"; exit 100; fi
if [ ! -d "$BEDTOOLS_PATH" ]; then echo "BEDTOOLS_PATH is not set in your config file"; exit 100; fi
if [ ! -d "$GATK_PATH" ]; then echo "GATK_PATH is not set in your config file"; exit 100; fi
if [ ! -f "$REF_GENOME" ]; then echo "REF_GENOME is not set in your config file"; exit 100; fi
if [ ! -d "$R_PATH" ]; then echo "R_PATH is not set in your config file"; exit 100; fi

#Determine if the VCF files are compressed or not
if [[ "$clcVCF" == *gz ]] ;
then
	zcat $clcVCF > clc.vcf
else
	ln -s $clcVCF clc.vcf
fi

if [[ "$ggpsVCF" == *gz ]] ;
then
	zcat $ggpsVCF > ggps.vcf
else
	ln -s $ggpsVCF ggps.vcf
fi


##################################################################################
###
###     Subset to samples of interest
###
##################################################################################
#Check to see if samples are present in VCF
if [[ ! -z "$clcSample" ]]
then
	SAMPLE_NAME=`$VCFLIB_PATH/vcfsamplenames $clcVCF |grep $clcSample`
	if [ -z "$SAMPLE_NAME" ]
	then
		echo "I could not find $clcSample in $clcVCF"
		exit 100
	fi
	$VCFLIB_PATH/vcfkeepsamples clc.vcf $clcSample |$VCFLIB_PATH/vcffixup - |$VCFLIB_PATH/vcffilter -f "AC > 0" > tmp
	mv tmp clc.vcf
fi

#Check to see if samples are present in VCF
if [[ ! -z "$ggpsSample" ]]
then
	SAMPLE_NAME=`$VCFLIB_PATH/vcfsamplenames $ggpsVCF |grep $ggpsSample`
	if [ -z "$SAMPLE_NAME" ]
	then
		echo "I could not find $ggpsSample in $ggpsVCF"
		exit 100
	fi
	$VCFLIB_PATH/vcfkeepsamples ggps.vcf $ggpsSample |$VCFLIB_PATH/vcffixup - |$VCFLIB_PATH/vcffilter -f "AC > 0" > tmp
	mv tmp ggps.vcf
fi


##################################################################################
###
###     Identify unique variants
###
##################################################################################

#If a BED file is specified, only look at those regions
if [ -f "$targetBed" ]
then
	$BEDTOOLS_PATH/bedtools intersect -a clc.vcf -b ggps.vcf -v -header |$BEDTOOLS_PATH/bedtools intersect -a - -b $targetBed -header  > clc.only.vcf
	$BEDTOOLS_PATH/bedtools intersect -b clc.vcf -a ggps.vcf -v -header |$BEDTOOLS_PATH/bedtools intersect -a - -b $targetBed -header  > ggps.only.vcf
else
	$BEDTOOLS_PATH/bedtools intersect -a clc.vcf -b ggps.vcf -v -header > clc.only.vcf
	$BEDTOOLS_PATH/bedtools intersect -b clc.vcf -a ggps.vcf -v -header > ggps.only.vcf
fi


##################################################################################
###
###     Merge & Annotate read counts
###
##################################################################################
$JAVA_PATH/java -jar $GATK_PATH/GenomeAnalysisTK.jar -T UnifiedGenotyper \
 -out_mode EMIT_ALL_SITES -gt_mode GENOTYPE_GIVEN_ALLELES \
 -alleles clc.only.vcf -L clc.only.vcf -R $REF_GENOME \
 -I $ggpsBAM -o ggpsMissed.vcf

$JAVA_PATH/java -jar $GATK_PATH/GenomeAnalysisTK.jar -T UnifiedGenotyper \
 -out_mode EMIT_ALL_SITES -gt_mode GENOTYPE_GIVEN_ALLELES \
 -alleles clc.only.vcf -L clc.only.vcf -R $REF_GENOME \
 -I $clcBAM -o clcNotMissed.vcf
 
 $JAVA_PATH/java -jar $GATK_PATH/GenomeAnalysisTK.jar -T UnifiedGenotyper \
 -out_mode EMIT_ALL_SITES -gt_mode GENOTYPE_GIVEN_ALLELES \
 -alleles ggps.only.vcf -L ggps.only.vcf -R $REF_GENOME \
 -I $clcBAM -o clcMissed.vcf
 
  $JAVA_PATH/java -jar $GATK_PATH/GenomeAnalysisTK.jar -T UnifiedGenotyper \
 -out_mode EMIT_ALL_SITES -gt_mode GENOTYPE_GIVEN_ALLELES \
 -alleles ggps.only.vcf -L ggps.only.vcf -R $REF_GENOME \
 -I $ggpsBAM -o ggpsNotMissed.vcf
 
perl ${DIR}/scripts/Format_extract.pl clcMissed.vcf -q GQ,AD|perl -ane 'next if $F[0]=~/^#/;chomp;$GQ=$F[scalar(@F-1)];if($GQ=="."){$GQ=0};@var=split(/,/,$F[scalar(@F)-2]);if (@var[0]=~/\./){@var=(0,0)};print join ("\t",@var[0,1],$GQ)."\n"' > clcMissed.AD 
perl ${DIR}/scripts/Format_extract.pl ggpsMissed.vcf -q GQ,AD|perl -ane 'next if $F[0]=~/^#/;chomp;$GQ=$F[scalar(@F-1)];if($GQ=="."){$GQ=0};@var=split(/,/,$F[scalar(@F)-2]);if (@var[0]=~/\./){@var=(0,0)};print join ("\t",@var[0,1],$GQ)."\n"' > ggpsMissed.AD 

perl ${DIR}/scripts/Format_extract.pl clcNotMissed.vcf -q GQ,AD|perl -ane 'next if $F[0]=~/^#/;chomp;$GQ=$F[scalar(@F-1)];if($GQ=="."){$GQ=0};@var=split(/,/,$F[scalar(@F)-2]);if (@var[0]=~/\./){@var=(0,0)};print join ("\t",@var[0,1],$GQ)."\n"' > clcNotMissed.AD 
perl ${DIR}/scripts/Format_extract.pl ggpsNotMissed.vcf -q GQ,AD|perl -ane 'next if $F[0]=~/^#/;chomp;$GQ=$F[scalar(@F-1)];if($GQ=="."){$GQ=0};@var=split(/,/,$F[scalar(@F)-2]);if (@var[0]=~/\./){@var=(0,0)};print join ("\t",@var[0,1],$GQ)."\n"' > ggpsNotMissed.AD 

$R_PATH/Rscript ${DIR}/scripts/plotResults.R
if [ -z "$keepTemp" ]
then
	rm clcNotMissed.vcf clcNotMissed.vcf.idx ggpsNotMissed.vcf ggpsNotMissed.vcf.idx clcNotMissed.AD ggpsNotMissed.AD clcMissed.AD ggpsMissed.AD clcMissed.vcf.idx clcMissed.vcf ggpsMissed.vcf.idx ggpsMissed.vcf ggps.only.vcf.idx clc.only.vcf.idx ggps.only.vcf clc.only.vcf ggps.vcf clc.vcf 
fi
