args <- commandArgs(TRUE)
library("ggplot2")
library("gridExtra")
sample1=gsub(".bam","",args[1])
sample2=gsub(".bam","",args[2])
minDP<-as.numeric(args[3])

Coverage<-read.csv("coverage.out",header=F,sep="\t")
names(Coverage)<-c("chrom","start","stop","BAM1count","BAM2count")
Coverage$deltaCov<-Coverage$BAM1count-Coverage$BAM2count
#Plot summary of differences
a<-ggplot(data=Coverage,aes(x=deltaCov,fill="red"))+geom_density()+xlab("deltaCov")+ theme(legend.position="none")
b<-ggplot(data=Coverage,aes(x=BAM1count,y=BAM2count,colour=1))+geom_point()+ theme(legend.position="none")+xlab(sample1)+ylab(sample2)

png(file="CoverageDiff.png",units="in",res=300,height=8,width=16)
grid.arrange(a,b,ncol=2)
dev.off()

# Make a consolidated BED file of regions
#Set a lag variable to even out potentially overlapping regions 
lag=10
#get start position
tmp<-Coverage[which(Coverage$BAM1count< minDP | Coverage$BAM2count < minDP),]
#Write output file header
write(c("#Chrom","Start","Stop","MeanDP_1","MeanDP_2"),sep="\t",file="CoverageDifference.xls",ncolumns=5)
#Initialize variables
chrom=tmp[1,1]
startPos=tmp[1,2]
stopPos=startPos+lag
dp1<-NULL
dp2<-NULL
for (i in 1:length(tmp$chrom)){
	#If chrom is same and I'm less that lag away, merge into same block
	if (tmp$chrom[i]==chrom & tmp$stop[i]<stopPos){
		dp1<-c(dp1,tmp$BAM1count[i])
		dp2<-c(dp2,tmp$BAM2count[i])
		stopPos=tmp$stop[i]+lag
	} else {
		# reset the values and print the block
		mean1<-round(mean(dp1),digits=0)
		mean2<-round(mean(dp2),digits=0)
		write(c(as.character(chrom),startPos,stopPos,mean1,mean2),sep="\t",file="CoverageDifference.xls",ncolumns=5,append=TRUE)
		chrom=tmp$chrom[i]
		startPos=tmp$start[i]
		stopPos=tmp$stop[i]+lag		
	}
}

