### Making concordance plots

Enter description here

```
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
```

##### Make the input config file
The config file has 5 tab-separated columns
> IntraFlowcell sample1.vcf.gz sample2.vcf.gz Sample1Name Sample2Name
* Column 1:	Type of comparison.  Can be IntraFlowcell,IntraLibrary,InterAssay,LowInput, or Reproducibility
* Column 2:     path to the 1st vcf [can be compressed or uncompressed]
* Column 3:     path to the 2nd vcf [can be compressed or uncompressed]
* Column 4:     Sample name in 1st vcf
* Column 5:     Sample name in 2nd vcf



##### Output files
[example Image]https://raw.githubusercontent.com/Steven-N-Hart/CGSL-scripts/master/Concordance/result/OverallConcordance.png

