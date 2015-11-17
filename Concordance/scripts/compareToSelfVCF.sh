#!/usr/bin/env bash

###@StandardDocs
###@EndDocs
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


usage (){
cat << EOF

This script is designed to measure the concordance between two samples.

Script Options:
    -v      path to the 1st VCF to compare     [required]
    -V      path to the 2nd VCF to compare     [required]
    -n      name of sample in VCF1 [required]
    -N      name of sample in VCF2 [required]
    -c      name of the config to use (tool_info.txt is included therein) [required]
	-s		do SNPs only 
	-i 		do insertions of X size only [1-30]
	-d		do insertions of X size only [1-30]
	-A		do all variants
    -h      Display this usage/help text
    -k      keep intermediate output for review
    -x      debug mode (verbose output)
    env:NGS_CORE_PROFILE set this enviornment variable to use the given profile instead of trying to find it

    Example:
    compareToControlVcf.sh -c trio1 -v variants.phased.vcf.gz
EOF
}

while getopts "v:V:n:N:c:si:d:Ahkx" OPTION; do
    case $OPTION in
        v) inputVCF1=$OPTARG ;;
        V) inputVCF2=$OPTARG ;;
        n) name1=$OPTARG ;;
        N) name2=$OPTARG ;;
		c) toolInfo="${CONFIG_HOME}/${OPTARG}/tool_info.txt" ;;
		s) SNPonly="TRUE" ;;
		i) INSonly=$OPTARG ;;
		d) DELonly=$OPTARG ;;
		A) ALL=$OPTARG ;;
        h) usage ; exit ;;
        k) KEEP=YES ;;
        x) set -x ;;
        \?) echo "Invalid option: -$OPTARG. See output file for usage." >&2 ; usage ; exit ;;
        :) echo "Option -$OPTARG requires an argument. See output file for usage." >&2 ; usage ; exit ;;
    esac
done

targetBED=$(grep "^ONTARGET=" "${toolInfo}" | cut -d= -f2 | sed 's/"//g')

if [ ! -f "$toolInfo" ] ; then
    echo "Tool info is not specified: $toolInfo"
    exit 1
fi

if [ -z "$inputVCF1" -o -z "$inputVCF2" -o -z "$name1" -o -z "$name2"  ] ; then
    echo "missing one of your required inputs!"
    usage
    exit 1
fi

if [[ "$inputVCF1" == *"vcf.gz" ]] ; then
    CAT1="zcat"
else
    CAT1="cat"
fi

if [[ "$inputVCF2" == *"vcf.gz" ]] ; then
    CAT2="zcat"
else
    CAT2="cat"
fi

if [ ! -z "$SNPonly"  -a ! -z "$INSonly" ]|| [ ! -z "$DELonly" -a ! -z "$INSonly" ] || [ ! -z "$SNPonly" -a ! -z "$INSonly" ] ; then
    echo "You can only set 1 of -s -i or -d "
    usage
    exit 1
fi

#Make sure bior is in path
RES=`which bior_pretty_print`
if [ -z "$RES" ]; then echo "you need to have bior in your path";exit 1; fi

#Check that each VCF contains that sampleID
CHECK1=`$CAT1 $inputVCF1|bior_pretty_print |grep -w $name1`
CHECK2=`$CAT2 $inputVCF2|bior_pretty_print |grep -w $name2`
if [ -z "$CHECK1" -o -z "$CHECK2" ]; then 
	echo "missing Sample IDs:" 
	echo -e "\t$inputVCF1\t$name1"
	echo -e "\t$inputVCF2\t$name2"
	usage
	exit 1
fi

if [ ! -s "$targetBED" ] ; then
    echo "Target bed is empty"
    exit 1
fi

PREFIX=$RANDOM
TYPE=All
Size=All

#Subset to interesting only
if [ "$SNPonly" == "TRUE" ]
then
	"$CAT1" "$inputVCF1"|"$VCFLIB/vcfkeepsamples" "$inputVCF1" "${name1}" |"$VCFLIB/vcffixup" -| "$VCFLIB/vcffilter" -f "AC > 0"| awk '((length($4)==1 && length($5)==1)||($1~/^#/))' > ${PREFIX}.1.out
	"$CAT2" "$inputVCF2"|"$VCFLIB/vcfkeepsamples" "$inputVCF2" "${name2}" |"$VCFLIB/vcffixup" -| "$VCFLIB/vcffilter" -f "AC > 0"| awk '((length($4)==1 && length($5)==1)||($1~/^#/))' > ${PREFIX}.2.out
	TYPE=SNPS
	SIZE=1
fi

if [ "$INSonly" ]
then
	"$CAT1" "$inputVCF1"|"$VCFLIB/vcfkeepsamples" "$inputVCF1" "${name1}" |"$VCFLIB/vcffixup" -| "$VCFLIB/vcffilter" -f "AC > 0"| awk -v len=$INSonly '((length($4)==1 && length($5)>=len && $5!~/,/)||($1~/^#/))' > ${PREFIX}.1.out
	"$CAT2" "$inputVCF2"|"$VCFLIB/vcfkeepsamples" "$inputVCF2" "${name2}" |"$VCFLIB/vcffixup" -| "$VCFLIB/vcffilter" -f "AC > 0"| awk -v len=$INSonly '((length($4)==1 && length($5)>=len && $5!~/,/)||($1~/^#/))' > ${PREFIX}.2.out
	TYPE=INS
	SIZE=$INSonly
fi

if [ "$DELonly" ]
then
	"$CAT1" "$inputVCF1"|"$VCFLIB/vcfkeepsamples" "$inputVCF1" "${name1}" |"$VCFLIB/vcffixup" -| "$VCFLIB/vcffilter" -f "AC > 0"| awk -v len=$DELonly '((length($4)>=len && length($5)==1 && $5!~/,/)||($1~/^#/))' > ${PREFIX}.1.out
	"$CAT2" "$inputVCF2"|"$VCFLIB/vcfkeepsamples" "$inputVCF2" "${name2}" |"$VCFLIB/vcffixup" -| "$VCFLIB/vcffilter" -f "AC > 0"| awk -v len=$DELonly '((length($4)>=len && length($5)==1 && $5!~/,/)||($1~/^#/))' > ${PREFIX}.2.out
	TYPE=DEL
	SIZE=$DELonly
fi

if [ "$ALL" ]
then
	"$CAT1" "$inputVCF1"|"$VCFLIB/vcfkeepsamples" "$inputVCF1" "${name1}" |"$VCFLIB/vcffixup" -| "$VCFLIB/vcffilter" -f "AC > 0" > ${PREFIX}.1.out
	"$CAT2" "$inputVCF2"|"$VCFLIB/vcfkeepsamples" "$inputVCF2" "${name2}" |"$VCFLIB/vcffixup" -| "$VCFLIB/vcffilter" -f "AC > 0" > ${PREFIX}.2.out
	TYPE=ALL
	SIZE=1
fi




CONCORDANCE=$("$BEDTOOLS/intersectBed" -u -a ${PREFIX}.1.out -b ${PREFIX}.2.out |grep -v "#"|wc -l)

COUNT1=`grep -v "#" ${PREFIX}.1.out|wc -l`
COUNT2=`grep -v "#" ${PREFIX}.2.out|wc -l`

if [ "$COUNT1" -gt "$COUNT2" ]; then
	MAX="$COUNT1"
	else
	MAX="$COUNT1"
fi

CONCORDANCE=$(echo "scale=3;$CONCORDANCE / $MAX" | bc)

name2="2_"$name2
name1="1_"$name1

echo -e "$name1\t$name2\tConcordance\t$TYPE\t$SIZE\t$CONCORDANCE\t$COUNT1\t$COUNT2"

if [ -z $KEEP ] ; then
	rm "${PREFIX}.1.out" "${PREFIX}.2.out"
fi

