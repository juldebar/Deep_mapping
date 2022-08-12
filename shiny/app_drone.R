library(shiny)
library(shinyWidgets)
library(leaflet)
library(leaflet.extras)
library(leafpm)
library(plyr)
library(dplyr)
library(sf)
library(geojsonio)
library(DT)
library(plotly)

library(leaflet)
library(sf)
library(dplyr)
############################################################ DATA and FILTER ########################################################################################################################################################################
Host=Sys.getenv("DB_REEF_HOST")
Dbname =Sys.getenv("DB_REEF_NAME")
User=Sys.getenv("DB_REEF_USER")
Password=Sys.getenv("DB_REEF_PWD")
DRV=Sys.getenv("DB_DRV")
cat("Connect the database\n")
con_Reef_database <- dbConnect(drv = DRV,dbname=Dbname, host=Host, user=User,password=Password)

# layer <- "view_occurences_manual_annotation"
layer <- SQL("2019_10_11_Le_Morne_drone_kite_lagoon_Mission1")


sql_query <- paste0('select *, "datasetID" AS species_name  FROM "',layer,'" --  LIMIT 538')
data <- dbGetQuery(con_Reef_database,sql_query)
colnames(data)
data_sf <- st_as_sf(data,coords = c("decimalLongitude", "decimalLatitude"),crs = st_crs(4326))

# Set default values for filters to be displayed by UI and used by server to filter and process data
session_polygon <- data_sf %>% st_coordinates() %>% st_linestring()  %>% st_convex_hull()
# default_wkt <- 'POLYGON ((57.30624 -20.48051, 57.30484 -20.4797, 57.31045 -20.46872, 57.32219 -20.46208, 57.3222 -20.46208, 57.32224 -20.46209, 57.31797 -20.47225, 57.31643 -20.47398, 57.31643 -20.47398, 57.3164 -20.47401, 57.30624 -20.48051))'
default_wkt <- st_as_text(session_polygon)
wkt <- reactiveVal(default_wkt) 

#calculate coordinates of the center of the areas where photos are located
session_track_centroid <- data_sf %>% st_coordinates() %>% st_linestring()  %>% st_convex_hull() %>% st_centroid()
# colnames(data_sf)

# default_year <- NULL
# target_year <- year(data_sf$gps_time) %>% distinct(year) %>% arrange(desc(year))

# default_species <- c('Elagatis bipinnulata (Quoy & Gaimard, 1825)','Coryphaena hippurus Linnaeus, 1758')
default_species <- NULL
target_species <- data_sf %>% distinct(species_name)
# filter_species <-"tortue"
filter_species <-"2019_10_11_Le_Morne_drone_kite_lagoon_Mission1"

################################################################ USER INTERFACE ###################################################################################################################################################


################################################################ USER INTERFACE ###################################################################################################################################################

ui <- fluidPage(
  # titlePanel("Species occurences viewer: map and plots"),
  navbarPage(title="Data viewer for Coral Reef images",
             tabPanel("Species occurences viewer",
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
                                          inputId = "species",
                                          label = "Scientific Name",
                                          choices = target_species$species_name,
                                          multiple = TRUE,
                                          selected= default_species
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
    updateSelectInput(session,"species",choices = target_species$species_name, selected = NULL )
  },
  ignoreInit = TRUE)
  
  data <- eventReactive(input$submit, {
    if(is.null(input$species)){filter_species=target_species$species_name}else{filter_species=input$species}
    data_sf %>% 
      filter(species_name %in% filter_species) %>%
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
    
    # df <- data_dwc %>%  filter(st_within(geometry,st_as_sfc(session_polygon, crs = 4326),sparse = FALSE)[, 1]) 
    df <- data()  
    
    mymap <-leaflet(data=df,options = leafletOptions(minZoom = 10, maxZoom = 40)) %>% 
      clearPopups()  %>% 
      # https://leaflet-extras.github.io/leaflet-providers/preview/ 
      addProviderTiles("Esri.OceanBasemap", group = "ESRI") %>%
      addProviderTiles("Esri.WorldImagery", group = "ESRI2") %>% 
      clearBounds() %>% addTiles(
      ) %>% addCircleMarkers(lng =~as_data_frame(st_coordinates(df))$X,
                             lat = ~as_data_frame(st_coordinates(df))$Y,
                             label = ~as.character(session_photo_number),
                             labelOptions = labelOptions(noHide = F, textsize = "15px"),
                             popup = paste0("<img src=\"data:image/jpeg;base64, ", gsub("base64:","",df$ThumbnailImage),"\"  style=\"display:block; width:100px;height:100px;\" >")
      ) %>% setView(lng = st_coordinates(session_track_centroid)[1], lat =st_coordinates(session_track_centroid)[2], zoom = 5
      ) %>% addProviderTiles(providers$Esri.WorldImagery, group = "ESRI World imagery", options = providerTileOptions(opacity = 0.95)
      ) %>% addWMSTiles(
        # "https://geoserver-sdi-lab.d4science.org/geoserver/Reef_database/ows",
        "https://gs.marbec-tools.ird.fr/geoserver/SEATIZEN/ows",
        layers = layer,
        options = WMSTileOptions(format = "image/png", transparent = TRUE), group ="Seatizen",
        attribution = "Seatizen WMS"
      )  %>% 
      addDrawToolbar(
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
        baseGroups = c("My Seatizen Map","ESRI", "ESRI2"),
        overlayGroups = c("draw"),
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
    
    # pie_data <- data_sf  %>% st_drop_geometry() %>% group_by(species_name) %>% summarise(count = n_distinct(id)) %>% arrange(count) # %>% top_n(10)
    # pie_data <- data()  %>% st_drop_geometry() %>% group_by(species_name) %>% summarise(count = n_distinct(id)) %>% arrange(count) # %>% top_n(10)
    pie_data <- data()  %>% st_drop_geometry() %>% group_by(species_name) %>% summarise(count = n_distinct(session_photo_number)) %>% arrange(count) # %>% top_n(10)
    
    fig <- plot_ly(pie_data, labels = ~species_name, values = ~count, type = 'pie', width = 350, height = 500,
                   marker = list( line = list(color = '#FFFFFF', width = 1), sort = FALSE),
                   showlegend = TRUE)
    
    fig <- fig %>% layout(title = 'Number of annotated images per species',
                          xaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE),
                          yaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE))
    fig <- fig %>% layout(legend = list(orientation = 'h'))
    fig
    
    
  })
  
  
}

# Run the application 
shinyApp(ui = ui, server = server)

