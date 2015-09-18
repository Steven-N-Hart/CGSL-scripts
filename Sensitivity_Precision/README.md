### Making Analytical Sensitivity and Precision Plots (ASAP)

Enter description here


Note: This can only be run on cgsl01 in its current form because it traverses directories to find config files

##### Make the input config file
The config file has 1 column
> /path/to/vcf
* Column 1:     The full path to the VCF file

Note: this script needs configured so that it can be more generalizeable to other projects.  Users will need to specify the BED file of their target region and thier VCF.

We also need to modify this so that we are not always looking for the sample name being NA12878, since many different controls may be run.



##### Loop over all lines in your config file to generate data
```
#Now make accuracy plots
EMAIL=`finger $USER|head -1|perl -pne 's/;/\t/g;s/ +/\t/g'|tr "\t" "\n"|grep "@"`

NUM_RUNS=`wc -l config2.txt | awk '{print $1}'`
for x in `seq 1 $NUM_RUNS`
do
 RUN=$(awk -v var=$x '(NR==var)' config2.txt)
 DIR=ASAS_${x}
 if [ ! -d "$DIR" ]
 then
  mkdir $DIR
 fi
 qsub -V -cwd -q sandbox.q -l h_vmem=3G -l h_stack=10M -m ae -M $EMAIL ./scripts/FiguresForASAS.sh ${RUN} ${DIR}
done

# Replace missing data with "."
perl -p -i -e 's/\t\t/\t.\t/g' */concordance.out
```

##### Now load R or Rstudio to generate figures
scripts/ASAS_Results.Rmd


Note: There needs to be more generalized chages to accept differnt samples, not just NA12878


Note: This is an R Markdown document that needs to be updated so that it can be more generalizeable to other projects.  Currently, it looks for "Proband" or "Prob" to iodentify the samples.
