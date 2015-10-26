###Usage
##########################################################################################################
##
## Script Options:
##   Required:
##      -v    VCF file from CLC pipeline
##      -V    VCF file from GGPS pipeline
##      -b    BAM file from CLC pipeline
##      -B    BAM file from GGPS pipeline
##   Optional:
##      -l    enable logging
##	-c    config file [defaults to the place where the script was run]
##	-T    BED file of the regions to restrict the analysis to
##
## 	This script is designed to find out why varaint calls are
##	discordant between the CLC and genome GPS pipelines.  The
##	final output is a summary html document that classifies the
##	contribution of variants to one pipeline or the other by comparing
## 	the total and alternate alle variants for pipeline-specific variants.
## 	This same pipeline could be used to compare the results of difference versions
##	of the same workflow.
#########################################################################################################

Script Inputs:


Script Outputs:
