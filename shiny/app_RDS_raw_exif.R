library(shiny)
library(shinyWidgets)
library(leaflet)
library(leaflet.extras)
library(leafpm)
library(plyr)
library(sf)
library(geojsonio)
library(DT)
library(plotly)
library(leaflet)
library(leafpop)
library(dplyr)
# library(DBI)
# library(RPostgres)
library(RPostgreSQL)
############################################################ DATA and FILTER ########################################################################################################################################################################
# data <- readRDS("/media/julien/SSD2TO/Deep_Mapping/new/mada/session_2022_10_31_kite_Ifaty/METADATA/exif/All_Exif_metadata_session_2022_10_31_kite_Ifaty.RDS")  
# data <- read.csv("/media/julien/SSD2TO/Deep_Mapping/new/mada/session_2022_10_31_kite_Ifaty/GPS/photos_location_session_2022_10_31_kite_Ifaty.csv")  
layer <- "session_2022_10_31_kite_Ifaty"
data_sf <- NULL
data_sf <-st_read(con_Reef_database, query = "select * from \"view_session_2022_10_31_kite_Ifaty\" WHERE \"LightValue\" > 12 ORDER BY photo_id LIMIT 2000")
# data_sf <- data %>% slice_head(n=1000) %>% select(photo_id,photo_identifier,session_id,session_photo_number,Make,Model,ThumbnailImage,decimalLatitude,decimalLongitude,ThumbnailImage)
# photo_id,photo_identifier,session_id,session_photo_number,photo_relative_file_path,photos_in_this_segment,list_time_photos,count_photos,cell_number,ratio,segment_wkt,segment_geom,footprintWKT,decimalLatitude,decimalLongitude,the_geom,GPSDateTime,DateTimeOriginal,LightValue,ImageSize,Make,Model,ThumbnailImage,PreviewImage,URL_original_image

session_polygon <- data_sf %>% st_coordinates() %>% st_linestring()  %>% st_convex_hull()
# default_wkt <- 'POLYGON ((57.30624 -20.48051, 57.30484 -20.4797, 57.31045 -20.46872, 57.32219 -20.46208, 57.3222 -20.46208, 57.32224 -20.46209, 57.31797 -20.47225, 57.31643 -20.47398, 57.31643 -20.47398, 57.3164 -20.47401, 57.30624 -20.48051))'
default_wkt <- st_as_text(session_polygon)
wkt <- reactiveVal(default_wkt) 

#calculate coordinates of the center of the areas where photos are located
session_track_centroid <- data_sf %>% st_coordinates() %>% st_linestring()  %>% st_convex_hull() %>% st_centroid()

default_Make <- NULL
target_Make <- data_sf %>% distinct(Make)
filter_Make <-"GoPro"


default_session <- NULL
target_session <- data_sf %>% distinct(session_id)
filter_session <-"session_2022_10_31_kite_Ifaty"

default_light <- NULL
target_light <- data_sf %>% distinct(session_id)
filter_light <-"11"

# default_year <- NULL
# target_year <- year(data_sf$gps_time) %>% distinct(year) %>% arrange(desc(year))

################################################################ USER INTERFACE ###################################################################################################################################################


################################################################ USER INTERFACE ###################################################################################################################################################

ui <- fluidPage(
  # titlePanel("Make occurences viewer: map and plots"),
  navbarPage(title="Data viewer for Coral Reef images",
             tabPanel("Make occurences viewer",
                      div(class="outer",
                          # tags$head(includeCSS("styles.css")),
                          tags$head(includeCSS("https://raw.githubusercontent.com/juldebar/MIKAROKA/main/styles.css")),
                          leafletOutput("mymap", width="100%", height="100%"),
                          
                          # Shiny versions prior to 0.11 should use class = "modal" instead.
                          absolutePanel(id = "controls", class = "panel panel-default", fixed = TRUE,
                                        draggable = TRUE, top = "15%", left = "auto", right="75%", width = "20%", height = "auto",
                                        tags$br(),
                                        h2("Select filters to customize indicators"),
                                        tags$br(),
                                        actionButton(
                                          inputId = "submit",
                                          label = "Display data",
                                          # icon = icon("refresh"),
                                          icon("play-circle"), 
                                          style="color: #fff; background-color: #F51D08; border-color: #2e6da4"
                                        ),
                                        selectInput(
                                          inputId = "Make",
                                          label = "Scientific Name",
                                          choices = target_Make$Make,
                                          multiple = TRUE,
                                          selected= default_Make
                                        ),
                                        textInput(
                                          inputId="polygon",
                                          label="Edit WKT",
                                          value=default_wkt
                                        ),
                                        actionButton(
                                          inputId = "resetWkt",
                                          label = "Reset WKT",
                                          icon("sync"), 
                                          style="color: #fff; background-color: #63B061; border-color: #2e6da4"
                                        ),
                                        actionButton(
                                          inputId = "resetAllFilters",
                                          label = "Reset all filters",
                                          icon("sync"), 
                                          style="color: #fff; background-color: #63C5DA; border-color: #2e6da4"
                                        ),
                                        tags$br(),
                                        tags$br()
                          ),
                          
                          absolutePanel(id = "controls", class = "panel panel-default",
                                        top = "15%", right = "auto", left ="73%", width = "25%", fixed=TRUE,
                                        draggable = TRUE, height = "auto",
                                        tags$br(),
                                        tags$br(),
                                        plotlyOutput("pie_map", height ="100%"),
                          ),
                          absolutePanel(id = "logo", class = "card", bottom = "4%", left = "2%", width = "5%", fixed=TRUE, draggable = FALSE, height = "auto",
                                        tags$a(href='https://mikaroka.ird.fr/', tags$img(src='http://mikaroka.ird.fr/wp-content/uploads/2020/01/MIKAROKA_logo.png',width = '200')))
                          # tags$a(href='https://www.ird.fr/', tags$img(src='https://raw.githubusercontent.com/juldebar/IRDTunaAtlas/master/logo_IRD.svg',height='89',width='108')))
                          
                      )
             ),
             tabPanel("Explore current data table",
                      hr(),
                      DT::dataTableOutput("DT_within_WKT")
                      # downloadButton("downloadCsv", "Download as CSV"),tags$br(),tags$br(),
             ),
             navbarMenu("More",
                        tabPanel("About",
                                 fluidRow(
                                   column(3,
                                          tags$small(
                                            "Funding : MIKAROKA ",
                                            a(href='http://mikaroka.ird.fr/', img(src='http://mikaroka.ird.fr/wp-content/uploads/2020/01/MIKAROKA_logo.png',width='30%'))
                                          )
                                   ),
                                   column(3,
                                          tags$small(
                                            "Source: GBIF data",
                                            img(class="logo_IRD", src=paste0("https://raw.githubusercontent.com/juldebar/MIKAROKA/main/data/gbif_23m361.svg")),
                                            # https://doi.org/10.15468/23m361 https://doi.org/10.15468/dl.5bzzz4
                                          )
                                   ),
                                   column(3,
                                          img(class="logo_IRD",
                                              src=paste0("https://raw.githubusercontent.com/juldebar/IRDTunaAtlas/master/logo_IRD.svg")),
                                          tags$small(
                                            "General Disclaimer:",
                                            "This repository contains work in progress. It can be used to explore the content of biodiversity / ecological data using Darwin Core data format Results presented here do not represent the official view of IRD, its staff or consultants.",
                                            "Caution must be taken when interpreting all data presented, and differences between information products published by IRD and other sources using different inclusion criteria and different data cut-off times are to be expected. While steps are taken to ensure accuracy and reliability, all data are subject to continuous verification and change.  See here for further background and other important considerations surrounding the source data."
                                          )
                                   )
                                   
                                 )
                        ),
                        tabPanel(
                          title = "Current WKT polygon",
                          textOutput("WKT")
                        )
             )
  )
)

################################################################ SERVER ###################################################################################################################################################
server <- function(input, output, session) {
  
  
  
  observeEvent(input$resetWkt, {
    wkt(default_wkt)
  },
  ignoreInit = TRUE)
  
  observe({
    updateTextInput(session, "polygon", value = wkt())
  })
  
  observeEvent(input$resetAllFilters, {
    updateTextInput(session, "polygon", value = wkt())
    updateSelectInput(session,"Make",choices = target_Make$Make, selected = NULL )
  },
  ignoreInit = TRUE)
  
  data <- eventReactive(input$submit, {
    if(is.null(input$Make)){filter_Make=target_Make$Make}else{filter_Make=input$Make}
    data_sf %>% 
      filter(Make %in% filter_Make) %>%
      dplyr::filter(st_within(.,st_as_sfc(input$polygon, crs = 4326), sparse = FALSE)) # %>% head(500)
    # dplyr::filter(st_within(.,session_polygon, sparse = FALSE)) # %>% head(500)
    
  },ignoreNULL = FALSE)
  
  ############################################################# OUTPUTS   ############################################################# 
  
  
  output$DT_within_WKT <- renderDT({
    data() %>%  dplyr::filter(st_within(.,st_as_sfc(input$polygon, crs = 4326), sparse = FALSE))  %>% st_drop_geometry()
  }) 
  
  output$WKT <- renderText({
    wkt()
  }) 
  
  
  output$mymap <- renderLeaflet({
    
    shiny::validate(
      need(nrow(data())>0, 'Sorry no data with current filters !'),
      errorClass = "myClass"
      
    )
    
    # df <- data_sf %>%  filter(st_within(geometry,st_as_sfc(session_polygon, crs = 4326),sparse = FALSE)[, 1]) 
    df <- data() 
    df_popup <- df %>%  select(-c(segment_geom, the_geom, photo_id, session_id, photos_in_this_segment, list_time_photos, count_photos, cell_number, ratio, decimalLatitude,decimalLongitude,segment_wkt, footprintWKT, ThumbnailImage,PreviewImage))
    content <- paste(sep = "<br/>",
                       paste0("<img src=\"data:image/jpeg;base64, ", gsub("base64:","",df$ThumbnailImage),"\"  style=\"display:block; width:100px;height:100px;\" >"),
                       paste0("<b><a href='https://zenodo.org/record/7090281'>",df$photo_identifier,"</a></b>"),
                       paste0("<b>Place: </b>", "Fray Bentos, Uruguay"),
                       paste0("<a href='https://en.wikipedia.org/wiki/Frigor%C3%ADfico_Anglo_del_Uruguay", "'>Link</a>"))
    
    mymap <-leaflet(data=df,options = leafletOptions(minZoom = 10, maxZoom = 40)
                    ) %>% clearPopups(
      ) %>% clearBounds(
      ) %>% addCircleMarkers(lng =~as_tibble(st_coordinates(df))$X,
                           lat = ~as_tibble(st_coordinates(df))$Y,
                           label = ~as.character(photo_id),
                           labelOptions = labelOptions(noHide = F, textsize = "15px"),
                           # popup = popupImage(img=paste0('src="data:image/png;base64,', gsub("base64:","",df$ThumbnailImage)), src ="local", embed = TRUE)
                       # popup =popupTable(select(df_popup,-c(URL_original_image)))
                       # popup = popupTable(df_popup)
                       # popup =content
                       popup = ~paste0("<b><a href='https://zenodo.org/record/7090281'>",photo_identifier,"</a></b> <img src=\"data:image/jpeg;base64, ", gsub("base64:","",df$ThumbnailImage),"\"  style=\"display:block; width:100px;height:100px;\" >"),
                       group = "Photos"
                       # clusterOptions = markerClusterOptions(spiderfyOnMaxZoom = 0.1)
    ) %>% setView(lng = st_coordinates(session_track_centroid)[1],
                  lat =st_coordinates(session_track_centroid)[2], zoom = 5
    # https://leaflet-extras.github.io/leaflet-providers/preview/ 
    ) %>% addProviderTiles(providers$Esri.WorldImagery,
                           group = "ESRI",
                           options = providerTileOptions(opacity = 0.95)     
   # )  %>% addProviderTiles("Esri.OceanBasemap", group = "ESRI"
    # )  %>% addProviderTiles("Esri.WorldImagery", group = "ESRI2" 
    ) %>% addWMSTiles(
      "https://gs.marbec-tools.ird.fr/geoserver/COI/ows",
      layers = "Mangroves_Mada_COI-OCEA-IHSM-ARDA_WGS84-UTM38S_V05-1",
      options = WMSTileOptions(format = "image/png", transparent = TRUE),
      group ="Mangroves",
      attribution = "Seatizen WMS"
    ) %>% addTiles(
    ) %>% addDrawToolbar(
        targetGroup = "draw",
        polylineOptions = FALSE,
        circleOptions = FALSE,
        markerOptions = FALSE,
        circleMarkerOptions = FALSE,
        editOptions = editToolbarOptions(
          selectedPathOptions = selectedPathOptions()
        )
      ) %>%
      addLayersControl(
        baseGroups = c("ESRI", "ESRI2"),
        overlayGroups = c("draw","Photos", "Mangroves"),
        options = layersControlOptions(collapsed = FALSE),
        position = "bottomright"
      )
    # mymap
    
  })
  
  observe({
    #use the draw_stop event to detect when users finished drawing
    feature <- input$mymap_draw_new_feature
    req(input$mymap_draw_stop)
    print(feature)
    polygon_coordinates <- input$mymap_draw_new_feature$geometry$coordinates[[1]]
    # see  https://rstudio.github.io/leaflet/shiny.html
    bb <- input$mymap_bounds 
    geom_polygon <- input$mymap_draw_new_feature$geometry
    # drawn_polygon <- Polygon(do.call(rbind,lapply(polygon_coordinates,function(x){c(x[[1]][1],x[[2]][1])})))
    geoJson <- geojsonio::as.json(feature)
    # spdf <- geojsonio::geojson_sp(feature)
    geom <- st_read(geoJson)
    wkt(st_as_text(st_geometry(geom[1,])))
    coord <- st_as_text(st_geometry(geom[1,]))
    
    north <- polygon_coordinates[[1]][[1]]
    south <- polygon_coordinates[[2]][[1]]
    east <- polygon_coordinates[[1]][[2]]
    west <- polygon_coordinates[[2]][[2]]
    
    
    if(is.null(polygon_coordinates))
      return()
    text<-paste("North ", north, "South ", east)
    
    # mymap_proxy = leafletProxy("mymap") %>% clearPopups() %>% addPopups(south,west,coord)
    # textOutput("wkt")
    
  })
  

  
  
  output$pie_map <- renderPlotly({
    
    shiny::validate(
      need(nrow(data())>0, 'Sorry no data with current filters !'),
      errorClass = "myClass"
      
    )
    
    pie_data <- data()  %>% st_drop_geometry() %>% group_by(Make) %>% summarise(count = n_distinct(photo_id)) %>% arrange(count) # %>% top_n(10)
    
    fig <- plot_ly(pie_data, labels = ~Make, values = ~count, type = 'pie', width = 350, height = 500,
                   marker = list( line = list(color = '#FFFFFF', width = 1), sort = FALSE),
                   showlegend = TRUE)
    
    fig <- fig %>% layout(title = 'Number of annotated images per Make',
                          xaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE),
                          yaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE))
    fig <- fig %>% layout(legend = list(orientation = 'h'))
    fig
    
    
  })
  
  
}

# Run the application 
shinyApp(ui = ui, server = server)

