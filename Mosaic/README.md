### Running Mosaic analyses


##### Make the input config file
 The config file is simply a list of key value pairs separated by '='.
> PARAMETER=VALUE
The following parameters must be set:
* BIN_PATH:		paths to pre-requisite binaries
* CONCORDANCE_PATH:     path to the concordance scripts
* MOSAIC_PATH:     	path to the mosaic scripts
* RLIB_PATH:     	path to R libraries
* R_PATH:     		path to Rscript
* EMAIL:     		email address to which SGE notifications should be sent. If unspecified, this defaults to the user's email address.
* QUEUE:     		SGE job queue
* H_VMEM:     		amount of virtual memory for job
* H_STACK:    		stack space for binary execution


##### Make the sample info file
 The sample info file has 3 space-separated columns
> MOSAIC1	ProbBProbA10	/testDir/variants/variants.phased.vcf.gz
* Column 1:	Sample type.  Can be MAJOR, MINOR or MOSAIC<N>. 1 major and 1 minor sample need to be specified and at least 1 mosaic sample is required. Mosaic sample names need to be prefixed with 'MOSAIC'.
* Column 2:     Sample name.
* Column 3:     Path to the corresponding vcf.gz file.


##### Run script
```
performMosaicAnalyses.sh -c </full path/to configuration file> -s </full path/to sample info file> -o </full path/to output directory>

```





