### Making concordance plots

Enter description here


Note: This can only be run on cgsl01 in its current form because it traverses directories to find config files

##### Make the input config file
The config file has 5 space-sperated columns
> IntraFlowcell sample1.vcf.gz sample2.vcf.gz Sample1Name Sample2Name
* Column 1:	Type of comparison.  Can be IntraFlowcell,IntraLibrary,InterAssay,LowInput, or Reproducibility
* Column 2:     path to the 1st vcf [can be compressed or uncompressed]
* Column 3:     path to the 2nd vcf [can be compressed or uncompressed]
* Column 4:     Sample name in 1st vcf
* Column 5:     Sample name in 2nd vcf

##### Loop over all lines in your config file to generate data
```
EMAIL=`finger $USER|head -1|perl -pne 's/;/\t/g;s/ +/\t/g'|tr "\t" "\n"|grep "@"`

#Make concordance plots
NUM_RUNS=`wc -l newConfig.txt | awk '{print $1}'`
for x in `seq 1 $NUM_RUNS`
do
 RUN=$(awk -v var=$x '(NR==var)' newConfig.txt)
 DIR=`echo $RUN | awk '{print $1"_"$4"_"$5}'`
 if [ ! -d "$DIR" ]
  then
  mkdir $DIR
 fi
 SUBMISSION=`echo ${RUN}|cut -f1 --complement -d" "`
 qsub -V -cwd -q sandbox.q -l h_vmem=3G -l h_stack=10M -m ae -M $EMAIL ./scripts/FiguresForConcordance.sh ${SUBMISSION} ${DIR}
done

# Replace missing data with "."
perl -p -i -e 's/\t\t/\t.\t/g' */concordance.out
```

##### Now load R or Rstudio to generate figures

Note: This is an R Markdown document that needs to be updated so that it can be more generalizeable to other projects.  Currently, it looks for "Proband" or "Prob" to iodentify the samples.
