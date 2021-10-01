#' Format input dataset to be use by report_content()
#'
#' This function reformate input csv to be use by report_conten
#'
#' @param file Path to the input file
#' @return A csv
#' @export

data_formatting = function(file){

#Inport dataset
fao<-read.csv(file)

#Validate format of dataset
#TODO

#Convert wide table to long table
fao_v <- fao[,!sapply(colnames(fao), startsWith, "S")]
colnames(fao_v)[1:4] <- c("flag", "species", "f_area", "unit")
tmp<-colnames(fao_v)
fao_v <- melt(fao_v, id=c("flag", "species", "f_area", "unit"),value.name="capture",variable.name = "year")
fao_v$year <- gsub('\\D','',fao_v$year)
fao_s <- fao[,!sapply(colnames(fao), startsWith, "X")]
colnames(fao_s)<- tmp
fao_s <- melt(fao_s, id=c("flag", "species", "f_area", "unit"),value.name="info",variable.name = "year")
fao_s$year <- gsub('\\D','',fao_s$year)
fao_n <- merge(fao_v,fao_s)
fao_n <- fao_n[!is.na(fao_n$flag),]
fao_n <- fao_n[fao_n$flag!="",]
fao_n <- fao_n[!is.na(fao_n$species),]
fao_n <- fao_n[fao_n$species!="",]

#Be sure to keep 2 character length format to area code
fao_n$f_area<-sprintf("%02d", as.numeric(fao_n$f_area))
#Keep information about inland/marine area base on
fao_n$f_area_type <- ifelse(fao_n$f_area%in%c("01","02","03","04","05","06","07"),"inland","marine")


#ISSCAAP Group register
gr<-readr::read_csv("https://raw.githubusercontent.com/openfigis/RefData/gh-pages/species/CL_FI_SPECIES_GROUPS.csv")
gr<-subset(gr,select=c('3A_Code','Taxonomic_Code','Name_En','Major_Group_En','ISSCAAP_Group_En'))
names(gr)<-c('species','Taxonomic_Code','Name_En','Major_Group_En','ISSCAAP_Group_En')

data<-merge(fao_n,gr,all.x = T,all.y=F)
data$Major_Group_En<-factor(data$Major_Group_En,
                            levels = c("PISCES", "MOLLUSCA", "CRUSTACEA", "INVERTEBRATA AQUATICA","PLANTAE AQUATICAE","AMPHIBIA, REPTILIA","MAMMALIA"))

#Species register
sp<-readr::read_csv("https://raw.githubusercontent.com/openfigis/RefData/gh-pages/species/CL_FI_SPECIES_ITEM.csv", col_names = T)
sp<-subset(sp,select=c('Alpha3_Code','Family_mapping','Order_mapping','Scientific_Name','Name_En'))
names(sp)<-c('species','family','order','scientific_name','sp_name_En')
data<-merge(data,sp,all.x = T,all.y=F)

#Ocean register
oc<-readr::read_csv("https://raw.githubusercontent.com/openfigis/RefData/gh-pages/waterarea/CL_FI_WATERAREA_MAJOR.csv", col_names = T)
oc<-subset(oc,select=c('Code','Name_En'))
names(oc)<-c('f_area','ocean')
oc$ocean<-gsub("(.*),.*", "\\1", oc$ocean)
oc$ocean<-ifelse(oc$f_area%in%c("01","02","03","04","05","06","07"),NA,oc$ocean)
data<-merge(data,oc,all.x = T,all.y=F)

#FAO Major Area register
ar<-readr::read_csv("https://raw.githubusercontent.com/openfigis/RefData/gh-pages/waterarea/CL_FI_WATERAREA_MAJOR.csv", col_names = T)
ar<-subset(ar,select=c('Code','Name_En'))
names(ar)<-c('f_area','f_area_name')

data<-merge(data,ar,all.x = T,all.y=F)
data$f_area_label<-paste0(data$f_area_name," [",data$f_area,"]")
#Data filter
data <- data %>%
  filter(!Major_Group_En %in% c("AMPHIBIA, REPTILIA","MAMMALIA")) %>% #Exclude of analysis ISSCAAP groups: Amphibia, reptilia and mammalia
  filter(!(capture == 0 & info == "")) #Exclude real zero capture (considering as record each other cases)

data$Major_Group_En<-factor(data$Major_Group_En)
return(data)
}