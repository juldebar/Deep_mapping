require(rgdal)
require(sf)
require(trackeR)

# gpx to wkt
gpx_to_wkt <- function(gps_file, dTolerance = 0.00005){
  spatial_data <- rgdal::readOGR(dsn = gps_file, layer="tracks",stringsAsFactors = FALSE)
  class(spatial_data)
  spatial_data <- st_read(gps_file,layer = "tracks")
  session_track <- st_as_text(spatial_data$geometry)
  simple_session_track <- st_as_text(st_simplify(spatial_data$geometry, dTolerance = dTolerance))
  simple_session_track
  wkt <- simple_session_track
  return(wkt)
}

# gps_file="/home/juldebar/Téléchargements/activity_4057551218.gpx"
# wkt <- gpx_to_wkt(gps_file)

# tcx to wkt
tcx_to_wkt <- function(gps_file,dTolerance=0.00005){
  dataframe_gps_file <- readTCX(file=gps_file, timezone = "UTC")
  dataframe_gps_file
  gps_points <- st_as_sf(dataframe_gps_file, coords = c("longitude", "latitude"),crs = 4326)
  session_track <- gps_points %>% st_coordinates() %>% st_linestring()
  simple_session_track <- session_track %>% st_simplify(dTolerance = dTolerance)  %>% st_as_text()
  simple_session_track
  wkt <- simple_session_track
  
  # session_track <- st_as_text(gps_points$geometry %>% st_cast("LINESTRING"))
  # simple_session_track <- st_as_text(st_simplify(session_track, dTolerance = 0.00005))
  
  return(wkt)
}

# gps_file <-"/home/juldebar/Téléchargements/22445995855.tcx"
# wkt <- tcx_to_wkt(gps_file,dTolerance = 0.00005)
# wkt
