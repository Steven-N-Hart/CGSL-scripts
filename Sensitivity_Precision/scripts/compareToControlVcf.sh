#!/usr/bin/env bash

###@StandardDocs
#
# Whole exome analysis for trio samples test, uses raw base call files from hiseq
# to implement the bioinformatics workflow and generates VCF files with the trio
# samples. There are a number of Quality control tests to be performed on the VCF
# file prior to importing it to VCF-Miner for review. One of the tertiary QC steps
# involved is to check for the sensitivity and specificity of the control sample used.
#
# This script takes the final VCF from the genomeGPS
# run is considered as input and necessary information like false positive values,
# False negative values, True positives, True negatives, Sensitivity, Specificity,
# Precision and Accuracy.
#
# The script takes
#   1) final VCF file from genomeGPS run as input along with some parameters like path to
#   2) tool_info file(required) and additional parameters that are not default like
#   3) control name(assumed control name in the VCF is CONTROL/NA12878; if VCF has
#       a different control name that can be given with an option –n )
#   4) Additional optional parameters include – bed file used in pipeline, Master
#       BED file used for truth VCF file, truth VCF file, path to ngs_core.profile file
#
# @input param -v is the inputVcf file for the control sample that we want to to compare
#     to the reference file.  If the file is not found then expect a message.
# @input param -n is the name of the control sample defaulting to 'CONTROL' other samples
#     within the inputVcf are ignored, if the sample is not found in the vcf then a nasty error
#     message is displayed
# @input param -c is the config within core:CONFIG_HOME that we should use to find the
#     tool_info containing further details (ref as 'tools')
#
# @input tools:ONTARGET is the 'targetBED' path to the bed file that represents our target region
#     used to subset the vcf files we are comparing
# @input tools:STANDARDVCF is the 'offocialVCF' we need to compare the inputVCF too
# @input tools:STANDARDBED is the 'officialBED' used to create the officialVCF
#
# @input env:NGS_CORE_PROFILE (ref as 'core') if you want to use a different profile file to get
#     environment details from set the env variable.  Otherwise we will scan up towards
#     root looking for an ngs_core.profile file and use that.
# @input core:BEDTOOLS is the path to the bedtools installation we should use
# @input core:VCFLIB is the path to the vcflib package we should use
#
# @output stdout: tab delimited header/column data that can be imported to excel
#
###@EndDocs

#set -x
NGS_CORE_PROFILE=/dlmp/prod/scripts/ngs_core/ngs_core.profile

__file="$(test -L "$0" && readlink "$0" || echo "$0")"
__dir="$(cd "$(dirname "${__file}")"; pwd;)"

#NGS_CORE_PROFILE may be an environment variable, use that if defined
if [ -z "${NGS_CORE_PROFILE}" ]; then
    __parent_dir="$__dir"
    NGS_CORE_PROFILE=$(find "$__parent_dir" -maxdepth 1 -name "ngs_core.profile")
    while [ ! -f "$NGS_CORE_PROFILE" -a "$__parent_dir" != "/" ]; do
        NGS_CORE_PROFILE=$(find "$__parent_dir" -maxdepth 1 -name "ngs_core.profile")
        __parent_dir=$(dirname "$__parent_dir")
    done
    unset __parent_dir
fi

if [ -f "$NGS_CORE_PROFILE" ]; then
  >&2 echo STDERR "Using configuration file at $NGS_CORE_PROFILE"
  source "$NGS_CORE_PROFILE"
else
  echo "ngs_core.profile was not found. Unable to continue."
  exit 1
fi

usage () {
cat << EOF

This script is designed to create a central analysis program to use when comparing VCF outputs to the controlSample reference VCF.

Script Options:
    -v      path to the VCF to compare     [required]
    -c      name of the config to use (tool_info.txt is included therein) [required]
    -n      name of controlSample [CONTROL]
	-s		do SNPs only 
	-i 		do insertions of X size only [1-50]
	-d		do insertions of X size only [1-50]
    -h      Display this usage/help text
    -k      keep intermediate output for review
    -x      debug mode (verbose output)
    env:NGS_CORE_PROFILE set this enviornment variable to use the given profile instead of trying to find it

    Example:
    compareToControlVcf.sh -c trio1 -v variants.phased.vcf.gz
EOF
}

while getopts "hkxv:c:n:si:d:" OPTION; do
    case $OPTION in
        h) usage ; exit ;;
        k) KEEP=YES ;;
        x) set -x ;;
        v) inputVCF=$OPTARG ;;
		s) SNPonly="TRUE" ;;
		i) INSonly=$OPTARG ;;
		d) DELonly=$OPTARG ;;
        c) toolInfo="${CONFIG_HOME}/${OPTARG}/tool_info.txt" ;;
        n) controlSample=$OPTARG ;;
        \?) echo "Invalid option: -$OPTARG. See output file for usage." >&2 ; usage ; exit ;;
        :) echo "Option -$OPTARG requires an argument. See output file for usage." >&2 ; usage ; exit ;;
    esac
done

targetBED=$(grep "^ONTARGET=" "${toolInfo}" | cut -d= -f2 | sed 's/"//g')
officialBED=$(grep "^STANDARDBED=" "${toolInfo}" | cut -d= -f2 | sed 's/"//g')
officialVCF=$(grep "^STANDARDVCF=" "${toolInfo}" | cut -d= -f2 | sed 's/"//g')

if [ ! -f "$toolInfo" ] ; then
    echo "Tool info is not specified: $toolInfo"
    exit 1
fi

if [ -z "$inputVCF" ] ; then
    echo "I don't see your inputVCF=$inputVCF"
    usage
    exit 1
fi

if [[ "$inputVCF" == *"vcf.gz" ]] ; then
    CAT="zcat"
else
    CAT="cat"
fi

if [ ! -z "$SNPonly"  -a ! -z "$INSonly" ]|| [ ! -z "$DELonly" -a ! -z "$INSonly" ] || [ ! -z "$SNPonly" -a ! -z "$INSonly" ] ; then
    echo "You can only set 1 of -s -i or -d "
    usage
    exit 1
fi


if [ -z "$controlSample" ] ; then
    >&2 echo STDERR "I don't see a name for controlSample, using WESTA_NA12878_CTRL"
    controlSample="WESTA_NA12878_CTRL"
fi

if [ ! -s "$targetBED" ] ; then
    echo "Target bed is empty"
    exit 1
fi

PREFIX=$RANDOM
TYPE=All
Size=All


"$BEDTOOLS/intersectBed" -a "$targetBED" -b "$officialBED" > ${PREFIX}.onTarget.5bp.cds.nochr.Exome.bed
targetBED=${PREFIX}.onTarget.5bp.cds.nochr.Exome.bed

zcat "$officialVCF" |perl -ne 'if ($_!~/^#/){print "chr$_"}else{print}'| "$BEDTOOLS/intersectBed" -a - -b "$targetBED" -header > ${PREFIX}.Truth.vcf

#Subset official to interesting only
if [ "$SNPonly" == "TRUE" ]
then
	awk '((length($4)==1 && length($5)==1)||($1~/^#/))' ${PREFIX}.Truth.vcf > ${PREFIX}.tmp
	TYPE=SNPS
	SIZE=1
fi

if [ "$INSonly" ]
then
	awk -v len=$INSonly '((length($4)==1 && length($5)>=len && $5!~/,/)||($1~/^#/))' ${PREFIX}.Truth.vcf > ${PREFIX}.tmp
	TYPE=INS
	SIZE=$INSonly
fi

if [ "$DELonly" ]
then
	awk -v len=$DELonly '((length($4)>=len && length($5)==1 && $5!~/,/)||($1~/^#/))' ${PREFIX}.Truth.vcf > ${PREFIX}.tmp
	TYPE=DEL
	SIZE=$DELonly
fi
officialVCF=${PREFIX}.tmp

#Subset the VCF file to only controlSample
"$VCFLIB/vcfkeepsamples" "$inputVCF" "${controlSample}" |"$VCFLIB/vcffixup" -| "$VCFLIB/vcffilter" -f "AC > 0" > ${PREFIX}.VCF.tokeep.vcf
#Subset to interesting only
if [ "$SNPonly" == "TRUE" ]
then
	awk '((length($4)==1 && length($5)==1)||($1~/^#/))' ${PREFIX}.VCF.tokeep.vcf > ${PREFIX}.out
fi

if [ "$INSonly" ]
then
	awk -v len=$INSonly '((length($4)==1 && length($5)>=len && $5!~/,/)||($1~/^#/))' ${PREFIX}.VCF.tokeep.vcf > ${PREFIX}.out
fi

if [ "$DELonly" ]
then
	awk -v len=$DELonly '((length($4)>=len && length($5)==1 && $5!~/,/)||($1~/^#/))' ${PREFIX}.VCF.tokeep.vcf > ${PREFIX}.out
fi
comparator=${PREFIX}.out



TRUE_POS=$(cat "$officialVCF"|"$BEDTOOLS/intersectBed" -a - -b "$targetBED" -header|"$BEDTOOLS/intersectBed" -a - -b ${PREFIX}.out |wc -l)
#echo "TP=$TRUE_POS"

FALSE_POS=$(cat ${PREFIX}.out| "$BEDTOOLS/intersectBed" -a - -b $targetBED -header|"$BEDTOOLS/intersectBed" -a - -b "$officialVCF"  -v|wc -l)
#echo "FP=$FALSE_POS"

#How many entries in Truth.vcf in our targets and not in our VCF ?
FALSE_NEG=$(cat "$officialVCF"|"$BEDTOOLS/intersectBed" -a - -b "$targetBED" -header|"$BEDTOOLS/intersectBed" -a - -b ${PREFIX}.out -v|wc -l)
#How many did we call?
#echo "FN=$FALSE_NEG"

#Calculate total measurable size
TOTAL_SIZE=$("$BEDTOOLS/sortBed" -i "$targetBED" | "$BEDTOOLS/mergeBed" -i stdin | awk '{size+=$3-$2}END{print size}')
#echo "TOTAL SIZE=$TOTAL_SIZE"
TRUE_NEG=$((TOTAL_SIZE-TRUE_POS-FALSE_POS-FALSE_NEG))

#echo "TN=$TRUE_NEG"
TMP_VAL=$((TRUE_POS + FALSE_NEG))
SNS=$(echo "scale=3;$TRUE_POS / $TMP_VAL" | bc)
#echo  "SNS=$SNS"

TMP_VAL=$((FALSE_POS + TRUE_NEG))
SPC=$(echo "scale=3;$TRUE_NEG / $TMP_VAL" | bc)
#echo  "SPC=$SPC"

TMP_VAL=$((TRUE_POS + FALSE_POS))
PPV=$(echo "scale=3;$TRUE_POS / $TMP_VAL" | bc)
#echo  "Precision=$PPV"

TMP_VAL=$((TRUE_POS + TRUE_NEG))
ACC=$(echo "scale=3;$TMP_VAL / $TOTAL_SIZE" | bc)
#echo  "Accuracy=$ACC"

#write tab delimitted file
#echo -e "TP\tFP\tFN\tTN\tTOTAL_SIZE\tSNS\tSPC\tPrecision\tAccuracy\tType\tSize"
echo -e "$TRUE_POS\t$FALSE_POS\t$FALSE_NEG\t$TRUE_NEG\t$TOTAL_SIZE\t$SNS\t$SPC\t$PPV\t$ACC\t$TYPE\t$SIZE"

if [ -z $KEEP ] ; then
    rm ${PREFIX}.out ${PREFIX}.tmp ${PREFIX}.onTarget.5bp.cds.nochr.Exome.bed ${PREFIX}.Truth.vcf ${PREFIX}.VCF.tokeep.vcf
fi


