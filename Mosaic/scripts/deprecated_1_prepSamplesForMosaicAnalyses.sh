#!/bin/bash




####################
## Script Options ##
####################

usage ()
{ cat << EOF


#################################################################################################################
##      Script to prepare mosaic samples for concordance analyses
##
## Script Options:
##	-c	<config file>		-	/full path/to configuration file
##	-s	<sample info file>	-	/full path/to sample info file
##	-o	<outdir>		-	/full path/to output directory
##	-h				-	Display this usage/help text
##
#################################################################################################################
##
## Authors:             Steve Hart, Nipun Mistry
## Creation Date:       Oct 19 2015
## Last Modified:       Oct 19 2015
##
## For questions, comments, or concerns, contact Steve Hart (hart.steve@mayo.edu)
##
#################################################################################################################


EOF

}




# Check args #

 if [ $# -eq 0 ]; then
	echo -e "\nERROR: Check args."
	usage
	exit
 fi

 echo "Options specified: $@"
 
 c_flag=0
 s_flag=0
 o_flag=0

 while getopts ":c:s:o:h" OPTION; do
	case $OPTION in
		h) usage
		   exit ;;
		c) config=$OPTARG 
		   c_flag=1;;
		s) sampleInfo=$OPTARG 
		   s_flag=1;;
		o) outdir=$OPTARG
		   outdir=${outdir%/} 
		   o_flag=1;;
		\?) echo "Invalid option: -$OPTARG. See output file for usage." >&2
		    usage
		    exit ;;
		:) echo "Option -$OPTARG requires an argument. See output file for usage." >&2
		   usage
		   exit ;;
	esac
 done

 if [ $((c_flag + s_flag + o_flag)) -ne 3 ]
 then
	echo -e "\nERROR: Insufficient arguments."
	usage
	exit
 fi  




# Load config values #

 if [ ! -f $config ]
 then
	echo -e "\nERROR: Cannot find $config"
	exit
 elif [ ! -s $config ]
 then
	echo -e "\nERROR: Config file $config is empty"
	exit
 else
	echo -e "\nLoading config file ..."
	cat $config
	. $config
 fi




# Check email address #

 if [ -z $EMAIL ]
 then
	EMAIL=`finger $USER|head -1|perl -pne 's/;/\t/g;s/ +/\t/g'|tr "\t" "\n"|grep "@"`
	echo -e "\nEMAIL has not been set in the config file. Using ${EMAIL}"
 fi




# Check SGE parameters #

 sgeParams=( $QUEUE $H_VMEM $H_STACK )
 echo -e "\n"
 error_flag=0
 for i in "${sgeParams[@]}"
 do
	if [ -z $i ]
	then
		echo -e "\nERROR: Reqd. SGE parameter $i is not set"
		error_flag=1
	fi
 done

 if [ $error_flag -eq 1 ]
 then
	quit
 fi




# Load sample info file and check input files #

 MAJOR=''
 MAJOR_VCF=''
 MINOR=''
 MINOR_VCF=''
 MOSAICSAMPLES=()
 MOSAICSAMPLEVCFS=()

 REGEX='^MOSAIC'

 if [[ ! -f $sampleInfo ]]
 then
	echo -e "\nERROR: Cannot find sample info file $sampleInfo"
	exit
 elif [ ! -s $sampleInfo ]
 then
	echo -e "\nERROR: Sample info file $sampleInfo is empty"
	exit
 else
	echo -e "\nLoading sample info ...\n"

	LINENUM=0

	MAJORCOUNT=0
	MINORCOUNT=0
	MOSAICCOUNT=0

	while read line || [ -n "$line" ] ; do
		LINENUM=$(( $LINENUM + 1 ))

		echo -e "$line"

		SAMPLETYPE=$( echo $line | tr -s ' ' | cut -f1 -d ' ' ); echo -e "ST: $SAMPLETYPE"
		SAMPLENAME=$( echo $line | tr -s ' ' | cut -f2 -d ' ' ); echo -e SN: $SAMPLENAME
		VCFPATH=$( echo $line | tr -s ' ' | cut -f3 -d ' ' | sed 's/ *$//g' ); echo -e "VCF: $VCFPATH"

		if [ "$SAMPLETYPE" = "MAJOR" ]
		then
			MAJORCOUNT=$(( $MAJORCOUNT + 1 ))

			if [ $MAJORCOUNT -gt 1 ]
			then
				echo -e "\nCannot have >1 major sample. Please check sample info file ${sampleInfo}"
				exit
			fi

			if [ ! -f $VCFPATH ] && [ ! -s $VCFPATH ]
			then
				echo -e "\nERROR: ${sampleInfo} line $LINENUM: $VCFPATH does not exist/is zero size"
				exit
			else 
				MAJOR=$SAMPLENAME
				MAJOR_VCF=$VCFPATH
			fi
		elif [ "$SAMPLETYPE" = "MINOR" ]
		then	
			MINORCOUNT=$(( $MINORCOUNT + 1 ))
	
			if [ $MINORCOUNT -gt 1 ]
			then
				echo -e "\nCannot have >1 minor sample. Please check sample info file ${sampleInfo}"
				exit
			fi

			if [ ! -f $VCFPATH ] && [ ! -s $VCFPATH ]
			then
				echo -e "\nERROR: ${sampleInfo} line $LINENUM: $VCFPATH does not exist/is zero size"
				exit
			else 
				MINOR=$SAMPLENAME
				MINOR_VCF=$VCFPATH
			fi
		elif [[ $SAMPLETYPE =~ $REGEX ]]
		then
			MOSAICCOUNT=$(( $MOSAICCOUNT + 1 ))
			MOSAICSAMPLES+=($SAMPLENAME)
			MOSAICSAMPLEVCFS+=($VCFPATH)
		else
			echo "Unrecognized sample type ${SAMPLETYPE}. Accepted sample types: MAJOR, MINOR, MOSAIC<index>"
		fi 

	done < $sampleInfo

	if [ ! $MOSAICCOUNT -gt 0 ]
	then
		echo -e "\nNeed at least 1 mosaic sample. Please check sample info file ${sampleInfo}"
		exit

	fi

	echo -e "done"
 fi




# Create outdir if it does not exist #

 if [[ ! -d ${outdir} ]]
 then
	mkdir -p ${outdir}
 fi




# Copy config and sample info files to output/config directory #

 mkdir -p "${outdir}/config"
 cp $config ${outdir}/config
 cp $sampleInfo ${outdir}/config



cd $outdir
export PATH=$PATH:$BIN_PATH




# Identify only homozygous variants seen in minor sample and not in the major sample #

 echo -e $MINOR
 echo -e $MINOR_VCF
 echo -e $MAJOR
 echo -e $MAJOR_VCF


 echo -e "\n\n\n*Identifying only homozygous variants seen in the minor sample and not in the major sample"
 zcat $MINOR_VCF| vcfkeepsamples - "${MINOR}" |vcffixup -|vcffilter -f "AC = 2" > homoTargetsA.vcf
 zcat $MAJOR_VCF| vcfkeepsamples - "${MAJOR}" |vcffixup -| grep -v 'AC=0' > AllTargetsB.vcf
 intersectBed -a homoTargetsA.vcf -b AllTargetsB.vcf -header -v > homoTargetsAonly.vcf

 zcat $MINOR_VCF| vcfkeepsamples - "${MINOR}" |vcffixup -|vcffilter -f "AC = 1" > hetTargetsA.vcf
 intersectBed -a hetTargetsA.vcf -b AllTargetsB.vcf -header -v > hetTargetsAonly.vcf




# Restrict the comparison to the possible sites #

 echo -e "*Restricting the comparison to the possible sites..."

 for i in "${!MOSAICSAMPLES[@]}"
 do
	echo -e "*${MOSAICSAMPLES[$i]}"
	echo -e "*${MOSAICSAMPLEVCFS[$i]}"

	zcat ${MOSAICSAMPLEVCFS[$i]}| vcfkeepsamples - ${MOSAICSAMPLES[$i]} |vcffixup -|vcffilter -f "AC > 0"|intersectBed -a - -b homoTargetsAonly.vcf -header > "${MOSAICSAMPLES[$i]}.vcf"
	mkdir -p "${MOSAICSAMPLES[$i]}_hom"
	#qsub -V -cwd -q $QUEUE -l h_vmem=${H_VMEM} -l h_stack=${H_STACK} -m ae -M $EMAIL "${CONCORDANCE_PATH}/FiguresForConcordance.sh" homoTargetsAonly.vcf "${MOSAICSAMPLES[$i]}.vcf" ${MINOR} ${MOSAICSAMPLES[$i]} "${MOSAICSAMPLES[$i]}_hom"
 done




# Now do Heterozygous variants #

 echo -e "*Heterozygous variants..."

 for i in "${!MOSAICSAMPLES[@]}"
 do

	mkdir -p "${MOSAICSAMPLES[$i]}_het"
	zcat ${MOSAICSAMPLEVCFS[$i]}| vcfkeepsamples - ${MOSAICSAMPLES[$i]} |vcffixup -|vcffilter -f "AC > 0"|intersectBed -a - -b hetTargetsAonly.vcf -header > "${MOSAICSAMPLES[$i]}.het.vcf"
	#qsub -V -cwd -q $QUEUE -l h_vmem=${H_VMEM} -l h_stack=${H_STACK} -m ae -M $EMAIL $CONCORDANCE_PATH/FiguresForConcordance.sh hetTargetsAonly.vcf "${MOSAICSAMPLES[$i]}.het.vcf" ${MINOR} ${MOSAICSAMPLES[$i]} "${MOSAICSAMPLES[$i]}_het"
	
#	perl ${MOSAIC_PATH}/Format_extract.pl "${MOSAICSAMPLES[$i]}.het.vcf" -q AD|grep -v "#"|cut -f11|tr "," "\t"|cut -f1-2 > ${MOSAICSAMPLES[$i]}_het/AD.out
	perl ${MOSAIC_PATH}/Format_extract.pl "${MOSAICSAMPLES[$i]}.het.vcf" -q AD|grep -v "#"|cut -f10 | cut -f 2 -d ':'|tr "," "\t"|cut -f1-2 > ${MOSAICSAMPLES[$i]}_het/AD.out

#	perl ${MOSAIC_PATH}/Format_extract.pl "${MOSAICSAMPLES[$i]}.vcf" -q AD|grep -v "#"|cut -f11|tr "," "\t"|cut -f1-2 > ${MOSAICSAMPLES[$i]}_hom/AD.out
	perl ${MOSAIC_PATH}/Format_extract.pl "${MOSAICSAMPLES[$i]}.vcf" -q AD|grep -v "#"|cut -f10 | cut -f 2 -d ':'|tr "," "\t"|cut -f1-2 > ${MOSAICSAMPLES[$i]}_hom/AD.out


 done




echo -e "\n\n"




