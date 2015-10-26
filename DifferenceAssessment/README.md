##Usage
```
##########################################################################################################
##
## Script Options:
##   Required:
##      -v      VCF file from CLC pipeline
##      -V      VCF file from GGPS pipeline
##      -b      BAM file from CLC pipeline
##      -B      BAM file from GGPS pipeline
##
##   Optional:
##      -s      Sample name from clcVCF [if set, will only compare that sample]
##      -S      Sample name from ggpsVCF [if set, will only compare that sample]
##      -l      enable logging
##      -c      config file [defaults to the place where the script was run]
##      -T      BED file of the regions to restrict the analysis to
##      -k      Flag set to keep temporary files (for debugging only)
##
##
##      This script is designed to find out why variant calls are discordant between the CLC and genomeGPS
##      pipelines.  The final output is a summary html document that classifies the contribution of variants
##      to one pipeline or the other by comparing the total and alternate alle variants for pipeline-specific
##      variants.  This same pipeline could be used to compare the results of difference versions of the
##      same workflow.
##
#########################################################################################################

```

### Script Inputs:
This script takes as inputs two VCF and two BAM files for comparison.  An example would be if you wanted to compare the results of the CLC results to GenomeGPS - but can work on comparing any two variant call sets.  It starts by comparing the variants in the first VCF (hereafter referred to as the CLC VCF) to those in the second (i.e. the GGPS VCF).  Once the differences are identified, it uses a GATK module to annotate alternate allele depth and genotype quality - since these are typically the main culprits.  Optionally, a user can provide a BED file to restrict the analysis to particular regions.  An example would be coding regions that are targeted in the assay.  This way, you will not be looking at just the differences that exists in the comparison, but only those that are relevant.  

**_Important Notes_**
* This does not say which variants are correctly called in each, just identifying and describing the differences.
* Assumes the VCF files are single sample only

### Script Outputs:
![An image should be displayed here](https://github.com/Steven-N-Hart/CGSL-scripts/blob/master/DifferenceAssessment/images/DifferenceAssessment.png "Output image file")
The results are output into 4 different quadrants of a single image file.  In the upper left, we plot the [AF] alternate Allele Frequency (i.e. fraction of reads supported the alternate allele) as a function of total Depth [DP].  The size of the plot character represents the Genotype Quality [GQ], a measure of confidence about the stated genotype.  Bigger circles mean higher confidence.  The colours differentiate those that were present only in the first VCF (ggpsMissed) or the second (clcMissed).

The top left image displays how many genotypes were discordant.  As before, clcMissed refers to variants that were present only in the 2nd VCF File, whereas the ggpsMised are the number of events tat were found only in the 1st VCF file.

The bottom row displays the density distributions for how divergent the data actually were in terms of the AF (left) and DP (right).  To generate these data, variants that were called in 1 sample were annotated with AF and DP from both BAM files.  Then the difference in AF (deltaAF) or DP (deltaDP) was computed.  The way to interpret these two graphs are similar.  If the AF or DP is very similar from both BAM files, then the difference should centered be around 0.  If most of the data is < 0, that means there was a higher value in the GGPS dataset than CLC.  Larger numbers mean the values were higher in the CLC dataset.

**_Important Notes_**
* Keep the number of events in mind, as this will alter the shape of the distributions.  Fewer data points means more instability in the measurement.


