# Set packages
library(dplyr)
library(sf)
library(zen4R)
library(parallel)
library(leaflet)
library(leaflet.extras)

# Download and unzip files (uncomment if not present in working directory)
# Global timeout for downloads
# options(timeout = 1000000) 
# zen4R::download_zenodo(doi = "10.5281/zenodo.15700848", parallel = TRUE, path = "./",timeout = 10000000,
#                        files = "darwincore_multilabel_annotation.zip", parallel_handler = parLapply, cl = makeCluster(16))
# unzip(zipfile = "darwincore_multilabel_annotation.zip")

#load files
# df_dois <- read.csv("session_doi.csv") %>% select(c("session_name","session_doi"))
df_dwc <-read.csv("./dwc/occurrence.csv")
nrow(df_dwc)
df_dwc_event <-read.csv("./dwc/event.csv")
df_dwc_location <-read.csv("./dwc/location.csv")
df_dwc_record_level <-read.csv("./dwc/record-level.csv")
df_dwc_taxon <-read.csv("./dwc/taxon.csv")
df_dwc <-read.csv("./dwc/occurrence.csv")

# Add columns to facilitate data agregation / filtering
df_dwc$ID <- seq.int(nrow(df_dwc))
df_dwc$one <- 1

#Explore values and set filters
View(df_dwc)  
colnames(df_dwc)
unique(df_dwc$eventID)
unique(df_dwc$occurenceID)
unique(df_dwc$taxonID)
unique(df_dwc$recordNumber)
unique(df_dwc$occurrenceStatus)
filter_status <- c("present")
unique(df_dwc$recordedBy)
filter_recordedBy <- c("Yves Amoros Mitondrasoa")
unique(df_dwc$associatedMedia)
# Set WKT to keep only occurences in la Réunion 
filter_area_RUN <- "POLYGON((54.51903028016422 -20.42124491331873,56.76024121766422 -20.42124491331873,56.76024121766422 -22.049391502584825,54.51903028016422 -22.049391502584825,54.51903028016422 -20.42124491331873))"
filter_area_geom <- st_sf(st_as_sfc(filter_area_RUN, crs = 4326))

#Apply filters
df_dwc_sf<- df_dwc %>% dplyr::filter(occurrenceStatus %in% filter_status, !recordedBy %in% filter_recordedBy)  %>% 
  dplyr::left_join(df_dwc_location, by="eventID")  %>% 
  st_as_sf(coords = c("decimalLongitude","decimalLatitude")) %>% sf::st_set_crs(4326) %>%
  # dplyr::filter(sf::st_contains(filter_area_geom)) # 
  dplyr::filter(sf::st_within(., filter_area_geom, sparse = FALSE)) %>% 
  dplyr::left_join(df_dwc_event, by="eventID") %>% 
  dplyr::left_join(df_dwc_taxon, by="taxonID") %>% 
  dplyr::left_join(df_dwc_record_level, by=c("recordNumber"="recordID"))

#Explore other values and set new filters from new columns
View(df_dwc_sf)  
colnames(df_dwc_sf)
unique(df_dwc_sf$occurrenceStatus)
unique(df_dwc_sf$occurenceID)
unique(df_dwc_sf$datasetID)
unique(df_dwc_sf$recordedBy)
unique(df_dwc_sf$recordNumber)
unique(df_dwc$associatedMedia)
taxonRank <-unique(df_dwc_sf$taxonRank)
vernacularName <- unique(df_dwc_sf$vernacularName)
scientifiNameID <- unique(df_dwc_sf$scientifiNameID)
scientificName <- unique(df_dwc_sf$scientificName)
# df_dwc_sf %>% dplyr::filter(taxonRank=="PHYLUM")


# Map data (displayed with leaflet)
plot(df_dwc_sf$geometry)  

leaflet(data = df_sf,options = leafletOptions(minZoom = 3, maxZoom = 18)) %>% 
          addProviderTiles(providers$Esri.WorldImagery, 
                           group = "ESRI World imagery", options = providerTileOptions(opacity = 0.95) ) %>% 
  addCircleMarkers() %>% addLayersControl(
    baseGroups = "My Seatizen Map",
    #overlayGroups = c("Seatizen WMS","ESRI World imagery"),
    options = layersControlOptions(collapsed = FALSE)
  ) %>% addLayersControl(
    baseGroups = "My Seatizen Map",
    #overlayGroups = c("Seatizen WMS","ESRI World imagery"),
    options = layersControlOptions(collapsed = FALSE)
  )

# Aggregate data

df_dwc_grouped <- df_dwc_sf %>% dplyr::group_by(taxonID) %>% dplyr::summarise(count = sum(one)) %>% dplyr::arrange(count)
View(df_dwc_grouped)
plot(df_dwc_grouped %>% dplyr::filter(taxonID %in% c("29")))


# [1] "Corallinales"                                   "Scleractinia"                                  
# [3] "Echinometra mathaei (Blainville, 1825)"         "Echinoidea"                                    
# [5] "Acropora Oken, 1815"                            "Cnidaria"                                      
# [7] "Tridacna Bruguière, 1797"                       "Porifera"                                      
# [9] "Holothuria Linnaeus, 1767"                      "Tripneustes gratilla (Linnaeus, 1758)"         
# [11] "Syringodium isoetifolium (Asch.) Dandy"         "Stichopus chloronotus Brandt, 1835"            
# [13] "Asteroidea"                                     "Halimeda J.V.F.Lamouroux, 1812"                
# [15] "Synapta maculata (Chamisso & Eysenhardt, 1821)" "Actiniaria" 