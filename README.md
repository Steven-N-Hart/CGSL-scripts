# CGSL-scripts

### Coding Best Practices
* Each directory should contain the following structure
  * Script.sh (This should be renamed to something that is intuitive)
    *   This should be the *only* script in this directory
    *   Running this script without options (or -h) should display an infromative usage statement with clear descriptions of all variables
    *   Any optional arguments that are needed in ancillary scripts must be captured here
  
  * scripts/
    * Any script that is needed to support the primary wrapper should be placed here

  * images/
    *  This is where you should put any images you need for this website
    *  We may need to rename this to be outputs so that we can keep example outfut files
  
  *  config/
    * Should contain at least 1 file named config.cfg
    * This is where you should define all of the tool paths necessary to run all the script
      * An example would look like this:  

>                   JAVA_PATH=/biotools/biotools/java/jdk1.7.0_72/bin
>                   BEDTOOLS_PATH=/usr/local/biotools/bedtools/2.20.1/bin
>                   VCFLIB_PATH=/usr/local/biotools/vcflib/2015_3_20/bin
>                   GATK_PATH=/biotools/biotools/gatk/3.3.0
>                   REF_GENOME=/dlmp/misc-data/reference/ggpsReferences/genomes/withMT/hs37d5.chr.fa
>                   R_PATH=/usr/local/biotools/r/3.1.1/bin


  
