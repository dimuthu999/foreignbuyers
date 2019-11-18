rm(list=ls())
library(data.table)
library(plyr)
library(dplyr)

state_name ="California"
state_code = "CA"
state_fips = "06"
min_sale_price = 0

selected_deed_types <- c("WRDE","DEED","SPWD","VLDE","GRDE","QCDE","BSDE","PRDE","NTSL","TRFC")

trans_main <- readRDS(file=paste("C:/Users/dnratnadiwakara/Documents/sunkcost_2019/ztraxdata/raw/",state_fips,"/ZTrans/main.rds",sep=""))
trans_main[,DocumentDate:=as.Date(trans_main$DocumentDate)]

trans_main <- trans_main[!trans_main$DocumentTypeStndCode %in% c("INTR","MTGE","NTDF")]

# trans_main <- trans_main[trans_main$DocumentTypeStndCode %in% selected_deed_types]
trans_main <- trans_main[trans_main$DataClassStndCode %in% c("D","H")]

buyer_address <- readRDS(file=paste("C:/Users/dnratnadiwakara/Documents/sunkcost_2019/ztraxdata/raw/",state_fips,"/ZTrans/buyermailaddress.rds",sep=""))

trans_main <- merge(trans_main,buyer_address,by="TransId")


trans_property<- readRDS(file=paste("C:/Users/dnratnadiwakara/Documents/sunkcost_2019/ztraxdata/raw/",state_fips,"/ZTrans/propertyinfo.rds",sep=""))
dup_transid <- trans_property[duplicated(trans_property$TransId)]$TransId
trans_property <- trans_property[!trans_property$TransId %in% dup_transid]


trans_main <- merge(trans_main,trans_property,by="TransId")

rm(buyer_address)
rm(trans_property)
gc()

# temp <- trans_main[trans_main$DocumentDate>"2014-01-01" & ( trans_main$BuyerMailState=="XX") ]
# trans_main[,foreign_address:=ifelse((trans_main$BuyerMailState=="" | trans_main$BuyerMailState=="XX") & is.na(trans_main$BuyerMailZip) & trans_main$BuyerMailCity!="",1,0)]
trans_main[,foreign_address:=ifelse((trans_main$BuyerMailState=="" | trans_main$BuyerMailState=="XX") & (trans_main$BuyerMailCity!="" | trans_main$BuyerMailFullStreetAddress != "") & trans_main$BuyerMailFullStreetAddress != trans_main$PropertyFullStreetAddress,1,0)]

keep <- c("TransId","FIPS.x","DataClassStndCode","DocumentTypeStndCode","DocumentDate","SalesPriceAmount","LoanAmount",
          "BuyerMailFullStreetAddress","BuyerMailCity","BuyerMailState","BuyerMailZip","ImportParcelID",
          "PropertyFullStreetAddress","PropertyState","PropertyZip","foreign_address")

trans_main <- subset(trans_main,select = keep)

# buyer_name <- readRDS(file=paste("C:/Users/dnratnadiwakara/Documents/sunkcost_2019/ztraxdata/raw/",state_fips,"/ZTrans/buyername.rds",sep=""))
# buyer_name <- subset(buyer_name,select = c("TransId","BuyerFirstMiddleName","BuyerLastName","BuyerIndividualFullName"))
# trans_main <- merge(trans_main,buyer_name,by="TransId")

asmt_main <- readRDS(file=paste("C:/Users/dnratnadiwakara/Documents/sunkcost_2019/ztraxdata/raw/",state_fips,"/ZAsmt/main.rds",sep=""))
asmt_main <- data.table(asmt_main)
asmt_main <- asmt_main[,c("RowID","ImportParcelID","FIPS","PropertyFullStreetAddress","PropertyCity","PropertyZip","TaxAmount","TaxYear",
                          "LotSizeSquareFeet","PropertyAddressLatitude","PropertyAddressLongitude","PropertyAddressCensusTractAndBlock")]
names(asmt_main) <- c("RowID","ImportParcelID","FIPS","StreetAddress","City","zip","TaxAmount","TaxYear",
                      "Lot_sqft","Latitude","Longitude","CensusTractAndBlock")

trans_main <- merge(trans_main,asmt_main,by="ImportParcelID")
rm(asmt_main)
gc()


asmt_building <- readRDS(file=paste("C:/Users/dnratnadiwakara/Documents/sunkcost_2019/ztraxdata/raw/",state_fips,"/ZAsmt/building.rds",sep=""))
asmt_building <- asmt_building[asmt_building$RowID %in% unique(trans_main$RowID)]
asmt_building <- asmt_building[,c("RowID","NoOfUnits","OccupancyStatusStndCode","PropertyCountyLandUseCode",
                                  "PropertyLandUseStndCode","YearBuilt","NoOfStories","TotalBedrooms",
                                  "TotalCalculatedBathCount")]
names(asmt_building) <- c("RowID","NoOfUnits","OccupancyStatus","CountyLandUseCode","LandUseStndCode",
                          "YearBuilt","NoOfStories","Bedrooms","Bathrooms")

trans_main <- merge(trans_main,asmt_building,by="RowID")


rm(asmt_building)

asmt_buildingarea <- readRDS(file=paste("C:/Users/dnratnadiwakara/Documents/sunkcost_2019/ztraxdata/raw/",state_fips,"/ZAsmt/buildingareas.rds",sep="")) 
asmt_buildingarea <- asmt_buildingarea[asmt_buildingarea$RowID %in% unique(trans_main$RowID)]
asmt_buildingarea <- asmt_buildingarea[asmt_buildingarea$BuildingAreaStndCode=="BAL"]
asmt_buildingarea <- asmt_buildingarea[,c("RowID","BuildingAreaSqFt")]

trans_main <- merge(trans_main,asmt_buildingarea,by="RowID",all.x=TRUE)

saveRDS(trans_main,file = paste("C:/Users/dnratnadiwakara/Documents/foreignbuyers/data/foreign_buyers_",state_fips,"_2.rds",sep=""))
