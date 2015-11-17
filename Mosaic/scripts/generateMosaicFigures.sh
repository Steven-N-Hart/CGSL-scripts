#!/bin/sh




####################
## Script Options ##
####################

usage ()
{
cat << EOF


###########################################################################################################################
##      wrapper script to generate mosaic plots
##
## Script Options:
##	-c	<config file>		-	/full path/to configuration file
##	-i	<indir>			-	/full path/to directory containing concordance output folders
##	-s	<sample info file>	-	/full path/to sample info file
##	-o	<outdir>		-	/full path/to output directory
##	-h				-	Display this usage/help text
##
###########################################################################################################################
##
## Authors:             Steve Hart, Nipun Mistry
## Creation Date:       Oct 19 2015
## Last Modified:       Oct 19 2015
##
## For questions, comments, or concerns, contact Steve Hart (hart.steve@mayo.edu)
##
###########################################################################################################################


EOF

}




# Check args #

 echo "Options specified: $@"

 c_flag=0
 i_flag=0
 s_flag=0
 o_flag=0

 while getopts "c:i:s:o:h" OPTION; do
 	case $OPTION in
		c) config=$OPTARG
		   c_flag=1;;
		i) indir=$OPTARG
		   indir=${indir%/}
		   i_flag=1;;
		s) sampleInfo=$OPTARG
		   s_flag=1;;
		o) outdir=$OPTARG 
		   outdir=${outdir%/}
		   o_flag=1;;
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

 if [ $((c_flag + i_flag + s_flag + o_flag)) -ne 4 ]
 then
	echo -e "\nERROR: Insufficient arguments."
	usage
	exit
 fi  




###################
##  Check Input  ##
###################

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
	echo -e "\n\n\nLoading config file ...\n"
	cat $config
	. $config
	echo -e "done"
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
 MINOR=''
 MOSAICSAMPLES=()

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

		SAMPLETYPE=$( echo $line | cut -f1 -d ' ' )
		SAMPLENAME=$( echo $line | cut -f2 -d ' ' ); echo -e "$SAMPLENAME"
		VCFPATH=$( echo $line | cut -f3 -d ' ' )

		if [ "$SAMPLETYPE" = "MAJOR" ]
		then
			MAJORCOUNT=$(( $MAJORCOUNT + 1 ))

			if [ $MAJORCOUNT -gt 1 ]
			then
				echo -e "\nCannot have >1 major sample. Please check sample info file ${sampleInfo}"
				exit
			fi

			MAJOR=$SAMPLENAME

		elif [ "$SAMPLETYPE" = "MINOR" ]
		then	
			MINORCOUNT=$(( $MINORCOUNT + 1 ))
	
			if [ $MINORCOUNT -gt 1 ]
			then
				echo -e "\nCannot have >1 minor sample. Please check sample info file ${sampleInfo}"
				exit
			fi

			MINOR=$SAMPLENAME

		elif [[ $SAMPLETYPE =~ $REGEX ]]
		then
			MOSAICCOUNT=$(( $MOSAICCOUNT + 1 ))
			MOSAICSAMPLES+=($SAMPLENAME)
		else
			echo "Unrecognized sample type ${SAMPLETYPE}. Accepted sample types: MAJOR, MINOR, MOSAIC<index>"
		fi 

	done < $sampleInfo

	if [ ! $MOSAICCOUNT -gt 0 ]
	then
		echo -e "\nNeed at least 1 mosaic sample. Please check sample info file ${sampleInfo}"
		exit

	fi

	echo -e "done\n\n"
 fi




# Check folders for AD.out and concordance.out

 error_flag=0
 for i in "${!MOSAICSAMPLES[@]}"
 do

	 if [ ! -f ${indir}/${MOSAICSAMPLES[$i]}_het/AD.out ] && [ ! -s ${indir}/${MOSAICSAMPLES[$i]}_het/AD.out ]
	 then
		echo -ne "\nERROR:\t ${indir}/${MOSAICSAMPLES[$i]}_het/AD.out is empty/missing"
		error_flag=1
	 fi


	 if [ ! -f ${indir}/${MOSAICSAMPLES[$i]}_het/concordance.out ] && [ ! -s ${indir}/${MOSAICSAMPLES[$i]}_het/concordance.out ]	
	 then
		echo -ne "\nERROR:\t ${indir}/${MOSAICSAMPLES[$i]}_het/concordance.out is empty/missing"
		error_flag=1
	 fi
	


	 if [ ! -f ${indir}/${MOSAICSAMPLES[$i]}_hom/AD.out ] && [ ! -s ${indir}/${MOSAICSAMPLES[$i]}_hom/AD.out ]
	 then
		echo -ne "\nERROR:\t ${indir}/${MOSAICSAMPLES[$i]}_hom/AD.out is empty/missing"
		error_flag=1
	 fi


	 if [ ! -f ${indir}/${MOSAICSAMPLES[$i]}_hom/concordance.out ] && [ ! -s ${indir}/${MOSAICSAMPLES[$i]}_hom/concordance.out ]	
	 then
		echo -ne "\nERROR:\t ${indir}/${MOSAICSAMPLES[$i]}_hom/concordance.out is empty/missing"
		error_flag=1
	 fi

 done

 if [ $error_flag -ne 0 ] 
 then
	exit
 fi




###############################
##   Run Mosaic_analysis.R   ##
###############################


# Create outdir if it does not exist #

 if [[ ! -d ${outdir} ]]
 then
	mkdir -p ${outdir}
 fi
 cd $outdir


# Copy config and sample info files to output/config directory #

 mkdir -p "${outdir}/config"
 cp $config ${outdir}/config
 cp $sampleInfo ${outdir}/config


export PATH=$PATH:$BIN_PATH


# run mosaic analyses R script

 #sampleString=join , "${MOSAICSAMPLES[@]}"
 #sampleString=echo ${MOSAICSAMPLES// /,}; echo $sampleString 
 sampleString=$(IFS=,; echo "${MOSAICSAMPLES[*]}")
 ${R_PATH}/Rscript ${MOSAIC_PATH}/Mosaic_analysis.R $indir $outdir $sampleString



















