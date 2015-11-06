#!/usr/bin/Rscript
if (!require("ggplot2")) {
  install.packages("ggplot2", dependencies = TRUE)
  library(ggplot2)
} 
if (!require("gridExtra")) {
  install.packages("gridExtra", dependencies = TRUE)
  library(gridExtra)
}

args <- commandArgs(TRUE)
getsample <- args[1]
getWD <- args[2]
getWD<-normalizePath(getWD) 
setwd(getWD)
prefixes=NULL
Data<-NULL

analyses=list.dirs('.', recursive=FALSE)
analyses=gsub("./", "",analyses )

for (analysis in analyses)
{
	Analysis_prefix<-strsplit(analysis,"_")
	Analysis_prefix<-head(unlist(Analysis_prefix),1)
	
	prefixes<-c(prefixes,Analysis_prefix)
	#print(analysis)
	#tmp<-read.table(paste("C:/Users/m139105/Documents/Projects/CONCORDANCE/concordance.out",sep=""),na.strings = ".")
	tmp<-read.table(paste(analysis,"/concordance.out",sep=""),na.strings = ".",sep="\t")
	names(tmp)<-c("name1","name2","Concordance","Type","Size","CONCORDANCE","COUNT1","COUNT2")
	tmp$CONCORDANCE[which(tmp$CONCORDANCE>1)]<-1
	tmp$Prefix=Analysis_prefix
	Data<-rbind(Data,tmp)
}


##################################################
#Use overlap instead of exact genotype
#Data$CONCORDANCE<-Data$CONCORDANCE2
#Data$COUNT1<-Data$COUNT3
#Data$COUNT2<-Data$COUNT4
##################################################

#label probands
Data$Proband[grep(getsample,Data$name1)]<-getsample

#LAblel standards
Types<-c("SNPS","INS","DEL")

#Create a backup in case I delete the original
Data.backup<-Data
#options(warn=-1)
Table1=NULL
OVERALL_PLOTS=NULL
for (ASSAY in prefixes)
{
	for (TYPE in Types)
	{
		OVERALL=NULL
		replicate=0
		for (PROBAND in getsample)
		{
			replicate=replicate+1
			tmp<-Data[which(Data$Prefix == ASSAY & Data$Proband == PROBAND & Data$Type == TYPE),]
			MEAN_CONCORDANCE=tapply(tmp$CONCORDANCE,tmp$Size,mean)
			MIN_CONCORDANCE=tapply(tmp$CONCORDANCE,tmp$Size,min)
			MAX_CONCORDANCE=tapply(tmp$CONCORDANCE,tmp$Size,max)
			Size<-names(MEAN_CONCORDANCE)
			TOTAL_EVENTS=tapply(tmp$COUNT1,tmp$Size,mean)
			NUM_EVENTS=round(tapply(tmp$COUNT1*tmp$CONCORDANCE,tmp$Size,mean))
			res=data.frame(Size,MEAN_CONCORDANCE,MIN_CONCORDANCE,MAX_CONCORDANCE,ASSAY,PROBAND,TYPE, replicate,NUM_EVENTS,TOTAL_EVENTS)
			OVERALL_PLOTS<-rbind(OVERALL_PLOTS,res)
			#Get number of comparisons made and double it
			NAMES=data.frame(table(tmp$name1,tmp$name2))
			NAMES=NAMES[which(NAMES$Freq>0),]
			NAMES=length(NAMES)*2
			#Get the total number of variants and average concordance
			GROUPS=as.vector(unique(tmp$name1))
			countsA<-NULL
			countsB<-NULL
			for (group in GROUPS)
			{
				tmp2<-tmp[which(tmp$name1 == group),]
				sumA<-sum(tmp2$COUNT1)
				sumB<-sum(tmp2$COUNT2)
				#Make sure B is always larger than A
				if(sumB>sumA)
				{
					countsA<-c(countsA,sumA)
					countsB<-c(countsB,sumB)
				}
				else
				{
				countsA<-c(countsA,sumB)
				countsB<-c(countsB,sumA) 
				}
			}
			EVENTS=mean(countsA)
			AVG_CONCORDANCE=mean(countsA/countsB)
			AVG_CONCORDANCE=round(AVG_CONCORDANCE,digits = 3)
			if(AVG_CONCORDANCE>1){AVG_CONCORDANCE=1}
			row=as.vector(c(ASSAY,TYPE,PROBAND,NAMES,round(EVENTS),AVG_CONCORDANCE))
			Table1<-rbind(Table1,row)
			OVERALL=rbind(OVERALL,row)
		}
		EVENTS=round(mean(as.numeric(OVERALL[,5])))
		AVG_CONCORDANCE=round(mean(as.numeric(OVERALL[,6])),digits=3)
		row=as.vector(c(ASSAY,TYPE,"Overall","-",EVENTS,AVG_CONCORDANCE))
		Table1<-rbind(Table1,row)
	}
}
Table1<-data.frame(Table1)
names(Table1)<-c("Assay","Type","Proband","N","Avg Event #","Avg Concordance")

#knitr::kable(Table1)
write.table(Table1,file="Table1.tsv",sep = "\t",row.names = F)


pd=position_dodge(0.1)
for (PROBAND in getsample)
{
	for (ASSAY in prefixes)
	{
		tmp<-OVERALL_PLOTS[which(OVERALL_PLOTS$PROBAND == PROBAND & OVERALL_PLOTS$ASSAY == ASSAY),]
		tmp$NUM_EVENTS[which(is.na(tmp$NUM_EVENTS))]<-0
		tmp$TOTAL_EVENTS[which(is.na(tmp$TOTAL_EVENTS))]<-0
		LEGEND=tapply(tmp$NUM_EVENTS,tmp$TYPE,sum)/tapply(tmp$TOTAL_EVENTS,tmp$TYPE,sum)
		LEGEND=round(LEGEND,digits=3)
		p=NULL
		p<- ggplot(tmp,aes(x=as.numeric(Size),y=MEAN_CONCORDANCE,order=tmp$TYPE,group=tmp$TYPE,colour=tmp$TYPE))+ylim(0,1)
		p<-p+scale_color_manual( values = c("black", "red","blue"))+geom_point()+geom_line()
		p<-p+theme(legend.position=c(0.1,0.1))
		p<-p+scale_color_manual("Overall",labels =c(paste(LEGEND,names(LEGEND))), values = c("black", "red","blue"))
		p+labs(title =ASSAY)
		ggsave(p+labs(title =paste(ASSAY,PROBAND)),file=paste(ASSAY,PROBAND,"png",sep="."))
	}  
}

SUMMARY=NULL
OVERALL_PLOTS$MEAN_CONCORDANCE[which(is.na(OVERALL_PLOTS$MEAN_CONCORDANCE))]<-1
OVERALL_PLOTS$MIN_CONCORDANCE[which(is.na(OVERALL_PLOTS$MIN_CONCORDANCE))]<-1
OVERALL_PLOTS$MAX_CONCORDANCE[which(is.na(OVERALL_PLOTS$MAX_CONCORDANCE))]<-1

for (ASSAY in prefixes)
{
	for (i in 1:30)
	{
		if(i==1)
		{
			MEAN=mean(OVERALL_PLOTS[which(OVERALL_PLOTS$TYPE=="SNPS" & OVERALL_PLOTS$ASSAY==ASSAY),"MEAN_CONCORDANCE"])
			MIN=mean(OVERALL_PLOTS[which(OVERALL_PLOTS$TYPE=="SNPS" & OVERALL_PLOTS$ASSAY==ASSAY),"MIN_CONCORDANCE"])
			MAX=mean(OVERALL_PLOTS[which(OVERALL_PLOTS$TYPE=="SNPS" & OVERALL_PLOTS$ASSAY==ASSAY),"MAX_CONCORDANCE"])
			NUM=mean(OVERALL_PLOTS[which(OVERALL_PLOTS$TYPE=="SNPS" & OVERALL_PLOTS$ASSAY==ASSAY),"NUM_EVENTS"])
			TOTAL=mean(OVERALL_PLOTS[which(OVERALL_PLOTS$TYPE=="SNPS" & OVERALL_PLOTS$ASSAY==ASSAY),"TOTAL_EVENTS"])
			RES=c("SNP",i,ASSAY,MEAN,MIN,MAX,NUM,TOTAL)
			SUMMARY=rbind(SUMMARY,RES)
		}
		MEAN=mean(OVERALL_PLOTS[which(OVERALL_PLOTS$TYPE=="INS" & OVERALL_PLOTS$ASSAY==ASSAY & OVERALL_PLOTS$Size==i),"MEAN_CONCORDANCE"])
		MIN=mean(OVERALL_PLOTS[which(OVERALL_PLOTS$TYPE=="INS" & OVERALL_PLOTS$ASSAY==ASSAY & OVERALL_PLOTS$Size==i),"MIN_CONCORDANCE"])
		MAX=mean(OVERALL_PLOTS[which(OVERALL_PLOTS$TYPE=="INS" & OVERALL_PLOTS$ASSAY==ASSAY & OVERALL_PLOTS$Size==i),"MAX_CONCORDANCE"])
		NUM=mean(OVERALL_PLOTS[which(OVERALL_PLOTS$TYPE=="INS" & OVERALL_PLOTS$ASSAY==ASSAY & OVERALL_PLOTS$Size==i),"NUM_EVENTS"])
		TOTAL=mean(OVERALL_PLOTS[which(OVERALL_PLOTS$TYPE=="INS" & OVERALL_PLOTS$ASSAY==ASSAY & OVERALL_PLOTS$Size==i),"TOTAL_EVENTS"])
		RES=c("INS",i,ASSAY,MEAN,MIN,MAX,NUM,TOTAL)    
		SUMMARY=rbind(SUMMARY,RES)
		MEAN=mean(OVERALL_PLOTS[which(OVERALL_PLOTS$TYPE=="DEL" & OVERALL_PLOTS$ASSAY==ASSAY & OVERALL_PLOTS$Size==i),"MEAN_CONCORDANCE"])
		MIN=min(OVERALL_PLOTS[which(OVERALL_PLOTS$TYPE=="DEL" & OVERALL_PLOTS$ASSAY==ASSAY & OVERALL_PLOTS$Size==i),"MIN_CONCORDANCE"])
		MAX=mean(OVERALL_PLOTS[which(OVERALL_PLOTS$TYPE=="DEL" & OVERALL_PLOTS$ASSAY==ASSAY & OVERALL_PLOTS$Size==i),"MAX_CONCORDANCE"])
		NUM=mean(OVERALL_PLOTS[which(OVERALL_PLOTS$TYPE=="DEL" & OVERALL_PLOTS$ASSAY==ASSAY & OVERALL_PLOTS$Size==i),"NUM_EVENTS"])
		TOTAL=mean(OVERALL_PLOTS[which(OVERALL_PLOTS$TYPE=="DEL" & OVERALL_PLOTS$ASSAY==ASSAY & OVERALL_PLOTS$Size==i),"TOTAL_EVENTS"])
		RES=c("DEL",i,ASSAY,MEAN,MIN,MAX,NUM,TOTAL)
		SUMMARY=rbind(SUMMARY,RES)  
	}	
}



SUMMARY<-data.frame(SUMMARY)
names(SUMMARY)<-c("TYPE","Size","ASSAY","MEAN_CONCORDANCE","MIN_CONCORDANCE","MAX_CONCORDANCE","NUM_EVENTS","TOTAL_EVENTS")


SUMMARY$Size<-as.numeric(SUMMARY$Size)
SUMMARY$MEAN_CONCORDANCE=as.numeric(as.character(SUMMARY$MEAN_CONCORDANCE))
SUMMARY$MIN_CONCORDANCE=as.numeric(as.character(SUMMARY$MIN_CONCORDANCE))
SUMMARY$MAX_CONCORDANCE=as.numeric(as.character(SUMMARY$MAX_CONCORDANCE))
SUMMARY$NUM_EVENTS=as.numeric(as.character(SUMMARY$NUM_EVENTS))
SUMMARY$MTOTAL_EVENTS=as.numeric(as.character(SUMMARY$TOTAL_EVENTS))
SUMMARY.backup<-SUMMARY

SUMMARY<-SUMMARY.backup

i=0
for (ASSAY in prefixes)
{
	i=i+1
	tmp<-SUMMARY[which(SUMMARY$ASSAY==ASSAY),]
	tmp$NUM_EVENTS=as.numeric(as.character(tmp$NUM_EVENTS))
	tmp$TOTAL_EVENTS=as.numeric(as.character(tmp$TOTAL_EVENTS))
	tmp<-na.omit(tmp)
	LEGEND=tapply(tmp$NUM_EVENTS,tmp$TYPE,sum)/tapply(tmp$TOTAL_EVENTS,tmp$TYPE,sum)
	LEGEND=round(LEGEND,digits=3)
	p=NULL
	p<- ggplot(tmp,aes(x=Size,y=MEAN_CONCORDANCE,order=TYPE,group=TYPE,colour=TYPE))+ylim(0,1)
	p<-p+scale_color_manual( values = c("black", "red","blue"))+geom_point()+geom_line()
	p<-p+theme(legend.position=c(0.2,0.2))
	p<-p+scale_color_manual("Overall",labels =c(paste(LEGEND,names(LEGEND))), values = c("black", "red","blue"))
	p+labs(title =ASSAY)
	if(i==1){u=p+labs(title =ASSAY)}
	if(i==2){v=p+labs(title =ASSAY)}
	if(i==3){x=p+labs(title =ASSAY)}
	if(i==4){y=p+labs(title =ASSAY)}
	if(i==5){z=p+labs(title =ASSAY)}
}

p=NULL
tmp<-OVERALL_PLOTS[which(OVERALL_PLOTS$PROBAND==getsample & OVERALL_PLOTS$ASSAY=="InterAssay" & OVERALL_PLOTS$replicate==1 ),]
tmp<-(tmp[,c("Size","TYPE","NUM_EVENTS")])
tmp$Size=(as.numeric(as.character(tmp$Size)))
tmp=na.omit(tmp)
p<-ggplot(tmp,aes(x=Size,y=NUM_EVENTS,fill=tmp$TYPE))+ylim(0,1500)
p+geom_bar(stat="identity",position="dodge")+theme(legend.position=c(0.2,0.2))
f=p+geom_bar(stat="identity",position="dodge")+theme(legend.position=c(0.8,0.8))

png(file="OverallConcordance.png",units="in",res=300,height=8,width=12)
if(exists('u')==TRUE  && exists('v')==TRUE && exists('x')==TRUE && exists('y')==TRUE && exists('z')==TRUE)
{
  grid.arrange(u,v,x,y,z,f,ncol=2)
}
if(exists('u')==TRUE  && exists('v')==TRUE && exists('x')==TRUE && exists('y')==TRUE && exists('z')==FALSE)
{
	grid.arrange(u,v,x,y,f,ncol=2)
}
if(exists('u')==TRUE  && exists('v')==TRUE && exists('x')==TRUE && exists('y')==FALSE && exists('z')==FALSE)
{
	grid.arrange(u,v,x,f,ncol=2)
}
if(exists('u')==TRUE  && exists('v')==TRUE && exists('x')==FALSE && exists('y')==FALSE && exists('z')==FALSE)
{
	grid.arrange(u,v,f,ncol=2)
}
if(exists('u')==TRUE  && exists('v')==FALSE && exists('x')==FALSE && exists('y')==FALSE && exists('z')==FALSE)
{
	grid.arrange(u,f,ncol=2)
}
dev.off()