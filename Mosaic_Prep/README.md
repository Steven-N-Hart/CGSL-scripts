### Preparing Mosaic samples for concordance analysis
This description is currently only good for WESTA.  It needs to be re-factored to work in a more generalized manner.

```
export PATH=$PATH:/biotools/biotools/vcflib:/usr/local/biotools/bedtools/2.20.1/bin/
VCF1=/dlmp/prod/runs/WESTA/HBFT9ADXX_ProbBProbA10/trio/OUTPUT/PI/exome/HBFT9ADXX_ProbBProbA10/variants/variants.phased.vcf.gz
VCF2=/dlmp/prod/runs/WESTA/HBFT9ADXX_ProbBProbA25/trio/OUTPUT/PI/exome/HBFT9ADXX_ProbBProbA25/variants/variants.phased.vcf.gz
VCF3=/dlmp/prod/runs/WESTA/HBFT6ADXX_ProbA-Lib1a/trio/OUTPUT/PI/exome/HBFT6ADXX_ProbA-Lib1a/variants/variants.phased.vcf.gz
VCF4=/dlmp/prod/runs/WESTA/HBFTBADXX_ProbB-Lib1a/trio/OUTPUT/PI/exome/HBFTBADXX_ProbB-Lib1a/variants/variants.phased.vcf.gz

#Identify only homozygous variants seen in A and not in B
zcat $VCF3| vcfkeepsamples - ProbA-Lib1a-2 |vcffixup -|vcffilter -f "AC = 2" > homoTargetsA.vcf
zcat $VCF4|vcfkeepsamples - ProbB-Lib1a-2|vcffixup -| grep -v 'AC=0' > AllTargetsB.vcf
intersectBed -a homoTargetsA.vcf -b AllTargetsB.vcf -header -v > homoTargetsAonly.vcf
zcat $VCF3| vcfkeepsamples - ProbA-Lib1a-2 |vcffixup -|vcffilter -f "AC = 1" > hetTargetsA.vcf
intersectBed -a hetTargetsA.vcf -b AllTargetsB.vcf -header -v > hetTargetsAonly.vcf

#restrict the comparison to the possible sites
zcat $VCF1| vcfkeepsamples - ProbBProbA10 |vcffixup -|vcffilter -f "AC > 0"|intersectBed -a - -b homoTargetsAonly.vcf -header > ProbA.10pc.vcf
zcat $VCF2| vcfkeepsamples - ProbBProbA25 |vcffixup -|vcffilter -f "AC > 0"|intersectBed -a - -b homoTargetsAonly.vcf -header > ProbA.25pc.vcf

mkdir ProbBProbA10_hom ProbBProbA25_hom
EMAIL=`finger $USER|head -1|perl -pne 's/;/\t/g;s/ +/\t/g'|tr "\t" "\n"|grep "@"`
CONCORDANCE_PATH=/dlmp/sandbox/cgslIS/CGSL-scripts/Concordance/scripts/

qsub -V -cwd -q sandbox.q -l h_vmem=3G -l h_stack=10M -m ae -M $EMAIL $CONCORDANCE_PATH/FiguresForConcordance.sh homoTargetsAonly.vcf ProbA.10pc.vcf ProbA-Lib1a-2 ProbBProbA10 ProbBProbA10_hom
qsub -V -cwd -q sandbox.q -l h_vmem=3G -l h_stack=10M -m ae -M $EMAIL $CONCORDANCE_PATH/FiguresForConcordance.sh homoTargetsAonly.vcf ProbA.25pc.vcf ProbA-Lib1a-2 ProbBProbA25 ProbBProbA25_hom

#Now do Heterozygous variants
mkdir ProbBProbA10_het ProbBProbA25_het
zcat $VCF1| vcfkeepsamples - ProbBProbA10 |vcffixup -|vcffilter -f "AC > 0"|intersectBed -a - -b hetTargetsAonly.vcf -header > ProbA.10pc.het.vcf
zcat $VCF2| vcfkeepsamples - ProbBProbA25 |vcffixup -|vcffilter -f "AC > 0"|intersectBed -a - -b hetTargetsAonly.vcf -header > ProbA.25pc.het.vcf
qsub -V -cwd -q sandbox.q -l h_vmem=3G -l h_stack=10M -m ae -M $EMAIL $CONCORDANCE_PATH/FiguresForConcordance.sh hetTargetsAonly.vcf ProbA.10pc.het.vcf ProbA-Lib1a-2 ProbBProbA10 ProbBProbA10_het
qsub -V -cwd -q sandbox.q -l h_vmem=3G -l h_stack=10M -m ae -M $EMAIL $CONCORDANCE_PATH/FiguresForConcordance.sh hetTargetsAonly.vcf ProbA.25pc.het.vcf ProbA-Lib1a-2 ProbBProbA25 ProbBProbA25_het

perl ./scripts/Format_extract.pl ProbA.10pc.het.vcf -q AD|grep -v "#"|cut -f11|tr "," "\t"|cut -f1-2 > ProbBProbA10_het/AD.out
perl ./scripts/Format_extract.pl ProbA.10pc.vcf -q AD|grep -v "#"|cut -f11|tr "," "\t"|cut -f1-2 > ProbBProbA10_hom/AD.out
perl ./scripts/Format_extract.pl ProbA.25pc.vcf -q AD|grep -v "#"|cut -f11|tr "," "\t"|cut -f1-2 > ProbBProbA25_hom/AD.out
```

##### Concordance
 Then run it through the concordance analysis from Concordance.Rmd



