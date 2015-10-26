library("ggplot2");
library("gridExtra")
#Read in data points
clcMissed<-read.delim("clcMissed.AD",header=F,stringsAsFactors=F)
ggpsMissed<-read.delim("ggpsMissed.AD",header=F,stringsAsFactors=F)
clcNotMissed<-read.delim("clcNotMissed.AD",header=F,stringsAsFactors=F)
ggpsNotMissed<-read.delim("ggpsNotMissed.AD",header=F,stringsAsFactors=F)
names(clcMissed)<-c("ref","alt","GQ")
names(clcNotMissed)<-c("ref","alt","GQ")
names(ggpsMissed)<-c("ref","alt","GQ")
names(ggpsNotMissed)<-c("ref","alt","GQ")
clcMissed$Type="clcMissed"
clcNotMissed$Type="clcNotMissed"
ggpsMissed$Type="ggpsMissed"
ggpsNotMissed$Type="ggpsNotMissed"

#Make AF x DP plot
res<-rbind(clcMissed,ggpsMissed)
res$AF=res$alt/(res$ref+res$alt+.0001)
res$DP=res$ref+res$alt
a<-ggplot(data=res,aes(x=DP,y=AF,color=Type,size=GQ))+geom_point()

#Make Barplot
b<-ggplot(data=res,aes(x=Type,fill=Type))+geom_bar()

#Make AF diff plot
clc<-clcMissed$alt/(clcMissed$ref+clcMissed$alt)
clc[which(is.na(clc))]<-0
ggps<-ggpsNotMissed$alt/(ggpsNotMissed$ref+ggpsNotMissed$alt)
ggps[which(is.na(ggps))]<-0
CLC<-clc-ggps
CLC<-data.frame(CLC)
names(CLC)[1]<-"deltaAF"
CLC$Type="clcMissed"
ggps<-ggpsMissed$alt/(ggpsMissed$ref+ggpsMissed$alt)
ggps[which(is.na(ggps))]<-0
clc<-clcNotMissed$alt/(clcNotMissed$ref+clcNotMissed$alt)
clc[which(is.na(clc))]<-0
GGPS<-clc-ggps
GGPS<-data.frame(GGPS)
GGPS$Type="ggpsMissed"
names(GGPS)[1]<-"deltaAF"
AF<-rbind(CLC,GGPS)
c<-ggplot(data=AF,aes(x=deltaAF,color=Type,fill=Type))+geom_density(alpha = 0.2)+xlab("deltaAF")+ggtitle("Low = GGPS >> CLC")

#Make DP diff plot
clc<-(clcMissed$ref+clcMissed$alt)
clc[which(is.na(clc))]<-0
ggps<-ggpsNotMissed$ref+ggpsNotMissed$alt
ggps[which(is.na(ggps))]<-0
CLC<-clc-ggps
CLC<-data.frame(CLC)
names(CLC)[1]<-"deltaDP"
CLC$Type="clcMissed"
ggps<-(ggpsMissed$ref+ggpsMissed$alt)
ggps[which(is.na(ggps))]<-0
clc<-(clcNotMissed$ref+clcNotMissed$alt)
clc[which(is.na(clc))]<-0
GGPS<-clc-ggps
GGPS<-data.frame(GGPS)
GGPS$Type="ggpsMissed"
names(GGPS)[1]<-"deltaDP"
AF<-rbind(CLC,GGPS)
d<-ggplot(data=AF,aes(x=deltaDP,color=Type,fill=Type))+geom_density(alpha = 0.2)+xlab("deltaDP")+ggtitle("Low = GGPS >> CLC")
png(file="DifferenceAssessment.png",units="in",res=300,height=8,width=16)
grid.arrange(a,b,c,d,ncol=2)
dev.off()
