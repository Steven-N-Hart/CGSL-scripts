##########################################################################################################
##
## USAGE EXAMPLE: ./Concordance.sh -i examples/input_file.tsv
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
##		InterAssay /path/to/vcf1 /path/to/vcf2 sampleName1 samplename2
##		IntraFlowcell /path/to/vcf1 /path/to/vcf2 sampleName1 samplename2
##
##	Note: Because some CLC names have spaces, this file must be tab seperated!
##	
#########################################################################################################