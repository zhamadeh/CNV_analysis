######################################################################
                    ####CNV analysis of good libraries (n=317)####
######################################################################
#packages
library(tidyverse)
library(rtracklayer)
#data
CNV<- import("SERVER-OUTPUT/BROWSERFILES/method-HMM/binsize_1e+05_stepsize_1e+05_StrandSeq_CNV.bed")
CNV<- import("SERVER-OUTPUT/BROWSERFILES/method-HMM/binsize_1e+05_stepsize_1e+05_StrandSeq_breakpoint-hotspots.bed")

cnv <- as.data.frame(CNV)
write.table(cnv,"SERVER-OUTPUT/BROWSERFILES/CNV_by_gene.txt",quote=F,row.names = F,col.names = T,sep="\t")

#core function
countTDs <- function(CNV){
  
  tandemRepeats=data.frame()

  for (i in 1:length(CNV)){

    ID <- strsplit(strsplit(CNV[i]@listData[[1]]@metadata$trackLine@description,split = " ")[[1]][4],split = "[-_.]")[[1]]
  
    for (j in ID){
      if ("blm" %in% tolower(ID) ){
        if ("recq5" %in% tolower(ID) ||"recql5" %in% tolower(ID) ){
          id <- "BLM/RECQL5"
        } else {
          id <- "BLM"
        }
      } else if ("recq5" %in% tolower(ID) ||"recql5" %in% tolower(ID) ){
        if (! "blm" %in% tolower(ID) ){
          id <- "RECQL5"
        }
      } else {id <- "WT" }
      }
      
    tmp <- as.data.frame(CNV[i])
    tmp$name <- as.factor(tmp$name)
    ploidyTable <- tmp %>% group_by(name) %>% summarize(n())
    ploidy = as.numeric(strsplit(as.character(ploidyTable[which.max(ploidyTable$`n()`),]$name),split = "[-]")[[1]][1])
    if (ploidy==0){
      ploidy=1
    }
    remove=c()
    
    for (row in 1:nrow(ploidyTable)){
      print(row)
      print(ploidyTable[row,1]$name)
      if (ploidyTable[row,1]$name=="zero-inflation"){
        remove <- append(row,remove)
      }
      else {
        level = as.numeric(strsplit(as.character(ploidyTable[row,1]$name),split = "[-]")[[1]][1])
        if (level <= ploidy){
          remove <- append(row,remove)
        }
      }
    }
    if (length(remove)>0){
      td <- sum(ploidyTable[-c(remove),]$`n()`)
    } else {td <- sum(ploidyTable$`n()`)}
    
    for (row in 1:nrow(tmp)){
      
      if (tmp[row,]$name=="zero-inflation"){
        remove <- append(row,remove)
      }
      else {
        level = as.numeric(strsplit(as.character(tmp[row,]$name),split = "[-]")[[1]][1])
        if (level <= ploidy){
          remove <- append(row,remove)
        }
      }
    }
    if (length(remove)>0){
      td_count <- sum(tmp[-c(remove),]$width)
    } else {td_count <- sum(tmp[-c(remove),]$width)}

    row <- data.frame(ID=id,TD=td,ploidy=ploidy,td_sum=td_count)
    tandemRepeats <- rbind(row,tandemRepeats)
  }
  return(tandemRepeats)
}

tandemRepeats <- countTDs(CNV)


counts <- tandemRepeats%>% group_by(ID)%>%summarize(n())

tandemRepeats$norm=NA
for (row in 1:nrow(tandemRepeats)){
  if (tandemRepeats[row,]$ID=="WT"){
    tandemRepeats[row,]$norm <- tandemRepeats[row,]$TD/counts[counts$ID=="WT",2]
  } else if (tandemRepeats[row,]$ID=="RECQL5"){
    tandemRepeats[row,]$norm <- tandemRepeats[row,]$TD/counts[counts$ID=="RECQL5",2]
  } else if (tandemRepeats[row,]$ID=="BLM"){
    tandemRepeats[row,]$norm <- tandemRepeats[row,]$TD/counts[counts$ID=="BLM",2]
  } else{
    tandemRepeats[row,]$norm <- tandemRepeats[row,]$TD/counts[counts$ID=="BLM/RECQL5",2]
  }
}

cnv1=cnv[1:100,]
cnv2=cnv[100000:100100,]
cnv$gene = NA
row=1
for (row in 1:nrow(cnv)){
  ID <- strsplit(strsplit(cnv$group_name[row],split = " ")[[1]][4],split = "[-_.]")[[1]]
  
    if ("blm" %in% tolower(ID) ){
      if ("recq5" %in% tolower(ID) ||"recql5" %in% tolower(ID) ){
        id <- "BLM/RECQL5"
      } else {
        id <- "BLM"
      }
    } else if ("recq5" %in% tolower(ID) ||"recql5" %in% tolower(ID) ){
      if (! "blm" %in% tolower(ID) ){
        id <- "RECQL5"
      }
    } else {id <- "WT" }

  cnv[row,]$gene=id
}

tandemRepeats%>% group_by(ID)%>%summarize(mean(TD))

######################################################################
                    ####PLOTTING####
######################################################################
ggplot()+geom_density(data = filter(tandemRepeats,ID=="BLM"),aes(x = TD,color=ID))+
  geom_density(data = filter(tandemRepeats,ID=="BLM/RECQL5"),aes(x = TD,color=ID))+ 
  geom_density(data = filter(tandemRepeats,ID=="RECQL5"),aes(x = TD,color=ID))+ 
  geom_density(data = filter(tandemRepeats,ID=="WT"),aes(x = TD,color=ID))+ 
  theme_bw() +labs(title = "Aneuploidy count/library")+
  scale_x_log10()

ggplot(tandemRepeats)+geom_density(mapping = aes(x = TD,color=ID,fill=ID),alpha=0.4)+
  theme_bw() +labs(title = "Aneuploidy count/library")+
  scale_x_log10()+ ggsave("Plots/Aneuploidy-count-library.png")

ggplot()+geom_density(data = tandemRepeats,aes(x = TD))+
  theme_bw() +labs(title = "Aneuploidy count/library")+
  scale_x_log10()



ggplot(tandemRepeats)+geom_density(aes(x = td_sum,color=ID,group=ID))+
  theme_bw() +
  labs(title = "Aneuploidy count/library")+ ylim(c(0,15))+
  scale_x_log10() + ggsave("Plots/aneuploidy_amount.png") 

ggplot()+geom_density(data = cnv,aes(x = width,color=gene),size=1.5)+
  theme_bw() +labs(title = "CNV segment size")+
  scale_x_log10(breaks = c(1e+5,1e+6,1e+7,1e+8),
                limits = c(50000, 1e+8)) + 
  ggsave("Plots/CNV_segment_size.png")


blm <- filter(cnv,gene=="BLM") %>% select(c(seqnames,start,end))
write.table(blm,"blmCNV.bed",quote = F,row.names = F,col.names = F,sep = "\t")
blm <- filter(cnv,gene=="BLM/RECQL5") %>% select(c(seqnames,start,end))
write.table(blm,"blm-recql5CNV.bed",quote = F,row.names = F,col.names = F,sep = "\t")
blm <- filter(cnv,gene=="RECQL5") %>% select(c(seqnames,start,end))
write.table(blm,"recql5CNV.bed",quote = F,row.names = F,col.names = F,sep = "\t")
blm <- filter(cnv,gene=="WT") %>% select(c(seqnames,start,end))
write.table(blm,"wtCNV.bed",quote = F,row.names = F,col.names = F,sep = "\t")

ggplot(tandemRepeats,aes(ID,TD))+geom_violin(aes(fill=ID))+
  geom_boxplot(width=0.05)+scale_y_log10()+ theme_bw()+
  labs(x="DNA Repair Deficiency",y="Number of CNV segments/cell")+
  ggsave("Plots/CNV_per_cell.png")
