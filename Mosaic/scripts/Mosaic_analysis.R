


library(ggplot2)
#library(gridExtra)



args <- commandArgs(trailingOnly = TRUE)

INDIR <- args[1]; 
OUTDIR <- args[2]; 
SAMPLESTRING <- args[3];



SAMPLES <- unlist(strsplit(as.character(SAMPLESTRING), ','));


 
Mosaic<-NULL
AD<-NULL
i=0
a=NULL
b=NULL



setwd(INDIR)



for(x in paste0(SAMPLES,'_') ){
  
  analyses=dir()[grep(x,dir())]
  analyses <- analyses[grep("png",analyses,invert=T)]
  i=i+1


  for(analysis in analyses){
    
    print(analysis)
    setwd(INDIR)
    tmp<-read.table(paste(analysis,"/concordance.out",sep=""),na.strings = ".")
    #names(tmp)<-c("name1","name2","Concordance","Type","Size","CONCORDANCE","COUNT1","COUNT2","CONCORDANCE2","COUNT3","COUNT4","UNUSED")
    names(tmp)<-c("name1","name2","Concordance","Type","Size","CONCORDANCE","COUNT1","COUNT2")
    tmp$CONCORDANCE[which(tmp$CONCORDANCE>1)]<-1
    #tmp$CONCORDANCE2[which(tmp$CONCORDANCE2>1)]<-1
    tmp$Prefix=analysis
    tmp<-na.omit(tmp)
    #LEGEND=tapply(tmp$COUNT3,tmp$Type,sum)/tapply(tmp$COUNT1,tmp$Type,sum)
    LEGEND=tapply(tmp$COUNT1,tmp$Type,sum)/tapply(tmp$COUNT2,tmp$Type,sum)
    LEGEND=round(LEGEND,digits=3)
    LEGEND
    p=NULL;

    p<-ggplot(tmp,aes(x=Size,y=CONCORDANCE,group=Type,colour=Type))+ylim(0,1)
    p<-p+scale_color_manual( values = c("black", "red","blue"))+geom_point()+geom_line()
    p<-p+theme(legend.position=c(0.2,0.2))
    p<-p+scale_color_manual("Overall",labels =c(paste(LEGEND, names(LEGEND))), values = c("black", "red", "blue"))
    
    #if(i==1){a=p+labs(title = analysis)}
    #if(i==2){b=p+labs(title = analysis)}

    f=p+labs(title =analysis)

    setwd(OUTDIR)
    print(paste0(dirname(OUTDIR),'/',basename(OUTDIR),'/',analysis,"_concordanceVsSize.png"))
    png(file=paste0(dirname(OUTDIR),'/',basename(OUTDIR),'/',analysis,"_concordanceVsSize.png"), units="in", res=300, height=8, width=12)
    plot(f)
    dev.off()

    Mosaic<-rbind(Mosaic, tmp)

    #Now get AD

     setwd(INDIR)
     tmp<-read.table(paste0(analysis,"/AD.out"),sep="\t")
     tmp<-na.omit(tmp)
     names(tmp)<-c("Ref","Alt")
     tmp$Sample=analysis
     AD<-rbind(AD,tmp)

    #AD$AAF<-AD$Ref/AD$Alt

  }

}



AD$AAF<-AD$Ref/AD$Alt



p = NULL
p <- ggplot(AD,aes(x=Alt/(Ref+Alt),group=Sample))
c = p+geom_density(aes(fill=Sample))+theme(legend.position=c(0.8,0.8))+labs(title ="Mosaic")

png(file=paste0(OUTDIR,"/Mosaic.png"), units="in", res=300, height=8, width=12)
plot(c)
dev.off()



for( SAMPLE in SAMPLES ){

	Data2<-Mosaic[which(Mosaic$name2==SAMPLE),]
	tmp<-NULL

	for(i in 1:30){

 		if(i==1){
			TP=mean(Data2[which(Data2$Type=="SNPS" & Data2$Size==i ),"COUNT1"])
			RES=c("SNP",i,TP)
			tmp=rbind(tmp,RES)
    	 	}

		TP=mean(Data2[which(Data2$Type=="INS" & Data2$Size==i ),"COUNT1"])
		RES=c("INS",i,TP)
		tmp=rbind(tmp,RES)
		TP=mean(Data2[which(Data2$Type=="DEL" & Data2$Size==i ),"COUNT1"])
		RES=c("DEL",i,TP)
		tmp=rbind(tmp,RES)

	}

	tmp<-data.frame(tmp)
	names(tmp)<-c("TYPE","Size","COUNT1")
	tmp$Size<-as.numeric(as.character(tmp$Size))
	tmp$COUNT1<-as.numeric(as.character(tmp$COUNT1))
	tmp<-na.omit(tmp)
	p<-ggplot(tmp,aes(x=Size,y=COUNT1,fill=TYPE))+ylim(0,300)
	d=p+geom_bar(stat="identity",position="dodge")+theme(legend.position=c(0.9,0.8))

	print(paste0(dirname(OUTDIR),'/',basename(OUTDIR),'/',SAMPLE,"_varCountDist.png"))
	png(file=paste0(dirname(OUTDIR),'/',basename(OUTDIR),'/',SAMPLE,"_varCountDist.png"), units="in", res=300, height=8, width=12)
	plot(d)
	dev.off()

}



#png(file=paste0(dirname(OUTDIR),'/',basename(OUTDIR),'/',"Mosaic.png"),units="in",res=300,height=8,width=12)
#grid.arrange(a,b,c,d,ncol=2)
#dev.off()









