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
## Last Modified:       Nov 16 2015
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
	echo -e "\n\n\n[$(date)] Loading config file\n"
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
	exit
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
	echo -e "\n\n[$(date)] Loading sample info\n"

	LINENUM=0

	MAJORCOUNT=0
	MINORCOUNT=0
	MOSAICCOUNT=0

	while read line || [ -n "$line" ] ; do
		LINENUM=$(( $LINENUM + 1 ))

		echo -e "$line"

		SAMPLETYPE=$( echo $line | tr -s ' ' | cut -f1 -d ' ' ); #echo -e "ST: $SAMPLETYPE"
		SAMPLENAME=$( echo $line | tr -s ' ' | cut -f2 -d ' ' ); #echo -e SN: $SAMPLENAME
		VCFPATH=$( echo $line | tr -s ' ' | cut -f3 -d ' ' | sed 's/ *$//g' ); #echo -e "VCF: $VCFPATH"

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

 fi
 echo -e "\n\n"




# Create outdir if it does not exist #

 if [[ ! -d ${outdir} ]]
 then
	mkdir -p ${outdir}
 else
	echo -e "\n${outdir} already exists - contents will be overwritten..."
	rm -r ${outdir}/concordance_out
	rm -r ${outdir}/config
	rm -r ${outdir}/figures
	rm -r ${outdir}/logs
	rm -r ${outdir}/concordance.sample.info.txt
 fi




# Copy config and sample info files to output/config directory #

 mkdir -p "${outdir}/config"
 mkdir -p "${outdir}/logs"
 cp $config ${outdir}/config
 cp $sampleInfo ${outdir}/config

 cd $outdir
 mkdir -p "concordance_out"
 #rm -r ${outdir}/concordance_out/concordance.sample.info.txt
 export PATH=$PATH:$BIN_PATH




echo -e "\n\n[$(date)] Preparing samples"




# Identify only homozygous variants seen in minor sample and not in the major sample #

 #echo -e $MINOR
 #echo -e $MINOR_VCF
 #echo -e $MAJOR
 #echo -e $MAJOR_VCF

 #echo -e "\n\n\n*Identifying only homozygous variants seen in the minor sample and not in the major sample"
 zcat $MINOR_VCF| vcfkeepsamples - "${MINOR}-2" |vcffixup -|vcffilter -f "AC = 2" > homoTargetsA.vcf
 zcat $MAJOR_VCF| vcfkeepsamples - "${MAJOR}-2" |vcffixup -| grep -v 'AC=0' > AllTargetsB.vcf
 intersectBed -a homoTargetsA.vcf -b AllTargetsB.vcf -header -v > homoTargetsAonly.vcf

 zcat $MINOR_VCF| vcfkeepsamples - "${MINOR}-2" |vcffixup -|vcffilter -f "AC = 1" > hetTargetsA.vcf
 intersectBed -a hetTargetsA.vcf -b AllTargetsB.vcf -header -v > hetTargetsAonly.vcf




# Restrict the comparison to the possible sites #

 #echo -e "*Restricting the comparison to the possible sites..."

 for i in "${!MOSAICSAMPLES[@]}"
 do
	#echo -e "*${MOSAICSAMPLES[$i]}"
	#echo -e "*${MOSAICSAMPLEVCFS[$i]}"

	zcat ${MOSAICSAMPLEVCFS[$i]}| vcfkeepsamples - ${MOSAICSAMPLES[$i]} |vcffixup -|vcffilter -f "AC > 0"|intersectBed -a - -b homoTargetsAonly.vcf -header > "${MOSAICSAMPLES[$i]}.vcf"
	mkdir -p "${MOSAICSAMPLES[$i]}_hom"

	#qsub -V -cwd -q $QUEUE -l h_vmem=${H_VMEM} -l h_stack=${H_STACK} -m ae -M $EMAIL "${CONCORDANCE_PATH}/FiguresForConcordance.sh" homoTargetsAonly.vcf "${MOSAICSAMPLES[$i]}.vcf" ${MINOR} ${MOSAICSAMPLES[$i]} "${MOSAICSAMPLES[$i]}_hom"

	# Generate figures 
	 #${CONCORDANCE_PATH}/FiguresForConcordance.sh homoTargetsAonly.vcf ${MOSAICSAMPLES[$i]}.vcf ${MINOR} ${MOSAICSAMPLES[$i]} ${MOSAICSAMPLES[$i]}_hom

	# Create concordance config file
	 mkdir -p concordance_out
	 #${PYTHON_PATH}/python ${CONCORDANCE_PATH}/PrepareConcordanceConfigFile.py -i ${BEDFILE} -a $(pwd)/homoTargetsAonly.vcf -b $(pwd)/${MOSAICSAMPLES[$i]}.vcf -o CONCORDANCE/VCFs -t InterAssay -c $(pwd)/${MOSAICSAMPLES[$i]}_hom/concordance.config.txt
	 #echo -e "IntraLibrary $(pwd)/homoTargetsAonly.vcf $(pwd)/${MOSAICSAMPLES[$i]}.vcf homoTargetsAonly ${MOSAICSAMPLES[$i]}" > $(pwd)/${MOSAICSAMPLES[$i]}_hom/concordance.config.txt
	 echo -e "Intralibrary	$(pwd)/homoTargetsAonly.vcf	$(pwd)/${MOSAICSAMPLES[$i]}.vcf	homoTargetsAonly	${MOSAICSAMPLES[$i]}" >> ${outdir}/concordance_out/concordance.sample.info.txt

	## Launch concordance jobs
 	 #${PYTHON_PATH}/python ${CONCORDANCE_PATH}/SubmitConcordance.py -c $(pwd)/${MOSAICSAMPLES[$i]}_hom/concordance.config.txt -r ${CONCORDANCE_PATH}/Run.sh -o $(pwd)
	 #cp IntraLibrary_homoTargetsAonly_${MOSAICSAMPLES[$i]}/* ${MOSAICSAMPLES[$i]}_hom
	 #rm -r IntraLibrary_homoTargetsAonly_${MOSAICSAMPLES[$i]}

 done




# Now do Heterozygous variants #

 #echo -e "*Heterozygous variants..."

 for i in "${!MOSAICSAMPLES[@]}"
 do

	mkdir -p "${MOSAICSAMPLES[$i]}_het"
	zcat ${MOSAICSAMPLEVCFS[$i]}| vcfkeepsamples - ${MOSAICSAMPLES[$i]} |vcffixup -|vcffilter -f "AC > 0"|intersectBed -a - -b hetTargetsAonly.vcf -header > "${MOSAICSAMPLES[$i]}.het.vcf"

	#qsub -V -cwd -q $QUEUE -l h_vmem=${H_VMEM} -l h_stack=${H_STACK} -m ae -M $EMAIL $CONCORDANCE_PATH/FiguresForConcordance.sh hetTargetsAonly.vcf "${MOSAICSAMPLES[$i]}.het.vcf" ${MINOR} ${MOSAICSAMPLES[$i]} "${MOSAICSAMPLES[$i]}_het"

	# Generate figures
	 #${CONCORDANCE_PATH}/FiguresForConcordance.sh hetTargetsAonly.vcf "${MOSAICSAMPLES[$i]}.het.vcf" ${MINOR} ${MOSAICSAMPLES[$i]} "${MOSAICSAMPLES[$i]}_het"

	# Create concordance config file
	 #echo -e "IntraLibrary $(pwd)/hetTargetsAonly.vcf $(pwd)/${MOSAICSAMPLES[$i]}.het.vcf hetTargetsAonly ${MOSAICSAMPLES[$i]}" > $(pwd)/${MOSAICSAMPLES[$i]}_het/concordance.config.txt
	 echo -e "Intralibrary	$(pwd)/hetTargetsAonly.vcf	$(pwd)/${MOSAICSAMPLES[$i]}.het.vcf	hetTargetsAonly	${MOSAICSAMPLES[$i]}" >> ${outdir}/concordance_out/concordance.sample.info.txt


	## Launch concordance jobs
 	 #${PYTHON_PATH}/python ${CONCORDANCE_PATH}/SubmitConcordance.py -c $(pwd)/${MOSAICSAMPLES[$i]}_het/concordance.config.txt -r ${CONCORDANCE_PATH}/Run.sh -o $(pwd)
	 #cp IntraLibrary_hetTargetsAonly_${MOSAICSAMPLES[$i]}/* ${MOSAICSAMPLES[$i]}_het
	 #rm -r IntraLibrary_hetTargetsAonly_${MOSAICSAMPLES[$i]}


	
#	perl ${MOSAIC_PATH}/Format_extract.pl "${MOSAICSAMPLES[$i]}.het.vcf" -q AD|grep -v "#"|cut -f11|tr "," "\t"|cut -f1-2 > ${MOSAICSAMPLES[$i]}_het/AD.out
	perl ${MOSAIC_PATH}/Format_extract.pl "${MOSAICSAMPLES[$i]}.het.vcf" -q AD|grep -v "#"|cut -f10 | cut -f 2 -d ':'|tr "," "\t"|cut -f1-2 > ${MOSAICSAMPLES[$i]}_het/AD.out

#	perl ${MOSAIC_PATH}/Format_extract.pl "${MOSAICSAMPLES[$i]}.vcf" -q AD|grep -v "#"|cut -f11|tr "," "\t"|cut -f1-2 > ${MOSAICSAMPLES[$i]}_hom/AD.out
	perl ${MOSAIC_PATH}/Format_extract.pl "${MOSAICSAMPLES[$i]}.vcf" -q AD|grep -v "#"|cut -f10 | cut -f 2 -d ':'|tr "," "\t"|cut -f1-2 > ${MOSAICSAMPLES[$i]}_hom/AD.out


 done




# Launch concordance jobs

 cp ${outdir}/concordance_out/concordance.sample.info.txt ${outdir}/concordance.sample.info.txt

 bash /dlmp/sandbox/cgslIS/CGSL-scripts/Concordance/Concordance.sh -i ${outdir}/concordance_out/concordance.sample.info.txt -o ${outdir}/concordance_out > ${outdir}/logs/concordance.log
 

 

# Wait for concordance jobs to complete

 jobIDArray=($(cat "${outdir}/logs/concordance.log" | awk -F 'Your job ' '{print $2}' | cut -d ' ' -f 1 | awk 'length'))

 if [ "${#jobIDArray[@]}" -eq 0 ]
 then
	echo -e "Error running concordance - no jobs were submitted"
	exit
 fi
 
 jobIDString=$(printf ",%s" "${jobIDArray[@]}")

 jobIDString=${jobIDString:1}
 
 echo "touch ${outdir}/logs/concordance.complete" | qsub -N sentinel_concordance -hold_jid $jobIDString >> ${outdir}/logs/pipeline.log

 echo -e "[$(date)] Calculating concordance"
 echo -e "          JobIDs: ${jobIDString}"


 echo -ne "[$(date)] Waiting for concordance jobs to complete  "

 busyCircle=( '-' '\' '|' '/' )

 i=0
 while [ ! -f "${outdir}/logs/concordance.complete" ]
 do

	echo -ne "\b${busyCircle[$i]}"
	if [ $i -eq 3 ]
	then
		i=0
	else
		((i++))
	fi	
	sleep 0.1

 done
 



# Check and copy concordance output to respective folders

 echo -e "\n\n[$(date)] Copying concordance output"
 cd ${outdir}/concordance_out/*
 error_flag=0
 find . -maxdepth 1 -name 'Intralibrary*' -type d -exec basename {} \; | while read concordanceOutDir
 do 
	#echo $concordanceOutDir
	IFS='_' read -a dirNameElements <<< "$concordanceOutDir"
	sampleName=${dirNameElements[2]}; #echo -e "$sampleName"
	type=${dirNameElements[1]}; 
	#echo -e "$type" 

	if [ $type == 'homoTargetsAonly' ];
	then
		if [ ! -f ./${concordanceOutDir}/concordance.out ] && [ ! -s ./${concordanceOutDir}/concordance.out ]
		then
			echo -e "./${concordanceOutDir}/concordance.out is missing/empty"
			error_flag=1
		else
			cp ./${concordanceOutDir}/concordance.out ${outdir}/${sampleName}_hom
		fi
	else
		if [ ! -f ./${concordanceOutDir}/concordance.out ] && [ ! -s ./${concordanceOutDir}/concordance.out ]
		then
			echo -e "./${concordanceOutDir}/concordance.out is missing/empty"
			error_flag=1
		else
			cp ./${concordanceOutDir}/concordance.out ${outdir}/${sampleName}_het		
		fi
	fi
 done
 
 if [ $error_flag -eq 1 ]
 then
	echo -e "\nConcordance output missing/empty. Exiting...\n\n"
	exit
 fi




# Run mosaic analyses

 echo -e "\n[$(date)] Running mosaic analyses"
 mkdir -p ${outdir}/figures
 ${MOSAIC_PATH}/generateMosaicFigures.sh -c $config -i ${outdir} -s $sampleInfo -o ${outdir}/figures > ${outdir}/logs/mosaicAnalyses.stdout.log 2> ${outdir}/logs/mosaicAnalyses.stderr.log




# Check output from mosaic wrapper

 rm -r ${outdir}/figures/config
 error_flag=0
 for i in "${!MOSAICSAMPLES[@]}"
 do

	if [ ! -f "${outdir}/figures/${MOSAICSAMPLES[$i]}_het_concordanceVsSize.png" ] && [ ! -s "${outdir}/figures/${MOSAICSAMPLES[$i]}_het_concordanceVsSize.png" ]
	then
		error_flag=1
		echo -e "${outdir}/figures/${MOSAICSAMPLES[$i]}_het_concordanceVsSize.png is missing/empty"
	fi

	if [ ! -f "${outdir}/figures/${MOSAICSAMPLES[$i]}_hom_concordanceVsSize.png" ] && [ ! -s "${outdir}/figures/${MOSAICSAMPLES[$i]}_hom_concordanceVsSize.png" ]
	then
		error_flag=1
		echo -e "${outdir}/figures/${MOSAICSAMPLES[$i]}_hom_concordanceVsSize.png is missing/empty"
	fi

	if [ ! -f "${outdir}/figures/${MOSAICSAMPLES[$i]}_varCountDist.png" ] && [ ! -s "${outdir}/figures/${MOSAICSAMPLES[$i]}_varCountDist.png" ]
	then
		error_flag=1
		echo -e "${outdir}/figures/${MOSAICSAMPLES[$i]}_varCountDist.png is missing/empty"
	fi

	if [ ! -f "${outdir}/figures/Mosaic.png" ] && [ ! -s "${outdir}/figures/Mosaic.png" ]
	then
		error_flag=1
		echo -e ": ${outdir}/figures/Mosaic.png is missing/empty"
	fi
 done


 if [ $error_flag -eq 1 ]
 then
	echo -e "Error generating figures. Exiting...\n\n"
	exit
 fi 




echo -e "\n\n[$(date)] All done."






