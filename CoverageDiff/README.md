##Usage
```
##########################################################################################################
##
## Script Options:
##   Required:
##      -b      BAM file1 (ex: from CLC pipeline)
##      -B      BAM file2 (ex: from GGPS pipeline)
##      -T      BED file of the regions to restrict the analysis to
##
##   Optional:
##      -d      minDepth at which to report out failed regions [default=100]
##      -l      enable logging
##      -c      config file [defaults to the place where the script was run]
##      -k      Flag set to keep temporary files (for debugging only)
##
##
##      This script is designed to identify and report coverage differences from multiple pipelines.  As an
##      example, one could compare the coverage for a particular panel between CLC and genomeGPS.
##
#########################################################################################################
```

### Script Inputs
This set of scripts is designed to compare the coverage between two different assays.  As an example, We could 
be comparing coverage between CLC and GenomeGPS.  It requires 2 BAM files as inputs as well as a BED file of 
target regions.  An optional parameter [-d] can be set to declare what is the minimum depth that is acceptable.
Any region that fails that minimum depth in either sample will be output in a table for further follow-up.

**_Important Notes_**
* If you do not specify a -d parameter, 100 will be used

### Script Outputs
There are 2 files that are ouptut from these scripts, an image file (CoverageDiff.png) and table (CoverageDifference.xls).

Example CoverageDiff.png file:
![An image should be displayed here](https://raw.githubusercontent.com/Steven-N-Hart/CGSL-scripts/master/CoverageDiff/images/CoverageDiff.png "Output image file")
The left panel summarizes the density distribution of how the coverage differs for every base in the capture region (deltaCov).  Numbers < 0 indicate more coverage in the 2nd BAM file, while numbers > 0 indicate more coverage in the 1st BAM file.
The right panel shows the coverage for each position in the target region from both BAM files.  A linear relationship is expected.

The CoverageDifference.xls file is actually just a tab-separated file.  It is labeled as ".xls", so it will open in Excel without users doing anything special.
An example file will look like this:
```
#Chrom  Start   Stop    MeanDP_1        MeanDP_2
chr1    65826   65847   93      168
chr1    65955   65988   86      129
chr1    69471   69620   55      25
chr1    721376  721511  61      52
chr1    721736  721821  64      60
chr1    721846  721857  64      60
chr1    721937  721957  64      62
chr1    762226  762580  57      52
chr1    777254  777364  56      52
```
The `#Chrom`, `Start`, and `Stop` columns define the locations that had less than the minimum depth [default=100].
`MeanDP_1` is the average coverage in that region from the first BAM file, and `MeanDP_2` is the mean coverage from the 2nd BAM file.
