content_types <- list(
  js   = "application/javascript",
  html = "text/html",
  css  = "text/css",
  png  = "image/png", 
  jpg  = "image/jpeg",
  json = "application/json"
)

wg404 <- list(
  status  = 404L,
  headers = list("Content-Type" = "text/plain"),
  body    = "Not found"
)

wg403 <- list(
  status  = 403L,
  headers = list("Content-Type" = "text/plain"),
  body    = "Forbidden"
)

wgstopbyenv <- function(wgenv){
  httpuv::stopDaemonizedServer(wgenv[['server']])
}

wgsend <- function(wg,msg){
  if(wg$env[['immediate']]){
    wgsendsend(wg,msg)
  } else {
    wg$env[['msgs']] <- c(wg$env[['msgs']],msg)
  }
}

wgsendsend <- function(wg,msg){
  tryCatch({
    wg$env[['ws']]$send(msg)
  }, error=function(e){
    print('Error: Could not send to client. Make sure you have a browser open!')
  })
}

print.webglobe <- function(wg){
  if(wg$env[['immediate']])
    print(paste0("Server should be running at 'http://localhost:",wg$env[['port']],"'"))
  else
    browseURL(paste0('http://localhost:',wg$env[['port']]))
}

is.webglobe <- function(x) inherits(x, "webglobe")

`+.webglobe` <- function(wg,x){
  wgsend(wg,x)
  wg
}


#' @name webglobe
#' 
#' @title      Make a new webglobe
#'
#' @description
#'             Constructs a new webglobe and starts its server
#' 
#' @param immediate 
#'             Whether the webglobe should immediately show the results of
#'             graphics commands or additively cache them. `immediate` mode can
#'             be used to experimentally build up a pipeline. Once established
#'             this can be stored in a non-immediate webglobe for easy acces
#'             later
#'
#' @return     A webglobe object
#'
#' @examples 
#' \dontrun{
#' library(webglobe)
#' a<-webglobe(immediate=TRUE)
#' }
#'
#' @export 
webglobe <- function(immediate=FALSE){
  the_env <- new.env(parent=emptyenv())
  app <- list(
    call = function(req) {
      if (!identical(req$REQUEST_METHOD, 'GET'))
        return(NULL)

      path <- req$PATH_INFO

      if (is.null(path))
        return(httpResponse(400, content="<h1>Bad Request</h1>"))

      if (path == '/')
        path <- '/index.html'

      path <- paste0(path.package('webglobe'),'inst/client',path)

      ctype <- content_types[[tools::file_ext(path)]]
      if(is.null(ctype))
        return(wg403)

      if(!file.exists(path))
        return(wg404)

      fcontents <- readBin(path, 'raw', n=file.info(path)$size)
      return(list(status=200L, headers=list('Content-Type'=ctype), body=fcontents))
    },
    onWSOpen = function(ws) {
      the_env[['ws']]<-ws
      ws$onMessage(function(binary, message) {
        .lastMessage <<- message
        ws$send('hey')
      })
    },
    env = the_env
  )

  app$env[['msgs']]      <- c()
  app$env[['immediate']] <- immediate

  startServer <- function(depth){
    tryCatch({
      app$env[['port']]   <- floor(runif(1,min=4000,max=8000))
      app$env[['server']] <- httpuv::startDaemonizedServer("0.0.0.0", app$env[['port']], app)
      TRUE
    }, error = function(e) {
      if(depth==100){
        return(FALSE)
      } else {
        return(startServer(depth+1))
      }
    })
  }

  if(!startServer(0)){
    stop('Could not start the server - probably no port was available.')
  }

  class(app) <- "webglobe"

  reg.finalizer(app$env, wgstopbyenv, onexit = TRUE)

  if(immediate)
  browseURL(paste0('http://localhost:',app$env[['port']]))

  return(app)
}



#' @name wgport
#' 
#' @title      Get webglobe's port
#'
#' @description
#'             Determine which port a webglobe is running on
#'
#' @param wg   Webglobe whose port should be determined
#' 
#' @return     A number representing the webglobe's port
#'
#' @examples 
#' \dontrun{
#' library(webglobe)
#' a<-webglobe(immediate=TRUE)
#' wgport(webglobe)
#' }
#'
#' @export 
wgport <- function(wg){
  wg$env[['port']]
}

#' @name wgpoints
#' 
#' @title      Plot points
#'
#' @description
#'             Plots latitude-longitude points
#'
#' @param lat  One or more latitude values
#' @param lon  One or more longitude values
#' @param alt  Altitude of the points, can be single value of vector
#' @param alt  Colour name of the points, can be single value of vector
#' @param size Size of the points, can be single value or vector
#' 
#' @return     A webglobe command
#'
#' @examples 
#' \dontrun{
#' library(webglobe)
#' a<-webglobe(immediate=TRUE)
#' a + wgpoints(c(45,20),c(-93,127),alt=3,colour=c("blue","red"))
#' }
#'
#' @export 
wgpoints <- function(lat,lon,alt=0,colour="yellow",size=10){
  if(length(lat)!=length(lon))
    stop('Same number of latitude and longitude points are required!')
  if(length(alt)!=1 && length(alt)!=length(lat))
    stop('One altitude must be specified, or a number equal to that of latitude/longitude!')
  if(length(alt)==1)
    alt <- rep(alt, length(lat))
  if(length(colour)==1)
    colour <- rep(colour, length(lat))
  if(length(size)==1)
    size <- rep(size, length(lat))
  toString(jsonlite::toJSON(list(
    command = jsonlite::unbox("points"),
    lat     = lat,
    lon     = lon,
    alt     = alt,
    colour  = colour,
    size    = size
  )))
}

#' @name wgcamhome
#' 
#' @title      Camera: Send home
#'
#' @description
#'             Send the camera to its home location
#' 
#' @return     A webglobe command
#'
#' @examples 
#' \dontrun{
#' library(webglobe)
#' a<-webglobe(immediate=TRUE)
#' a+wgcamhome()
#' }
#'
#' @export 
wgcamhome <- function(){
  toString(jsonlite::toJSON(list(
    command = jsonlite::unbox("cam_reset")
  )))
}

#' @name wgclear
#' 
#' @title      Clear the scene
#'
#' @description
#'             Clears everything from the map
#' 
#' @return     A webglobe command
#'
#' @examples 
#' \dontrun{
#' library(webglobe)
#' a<-webglobe(immediate=TRUE)
#' a+wgclear()
#' }
#'
#' @export 
wgclear <- function(){
  toString(jsonlite::toJSON(list(
    command = jsonlite::unbox("clear")
  )))
}

#' @name wgcamcenter
#' 
#' @title      Camera: Center on a point
#'
#' @description
#'             Centers the camera on a point
#'
#' @param lat  Latitude of the center point, in degrees
#' @param lon  Longitude of the center point, in degrees
#' @param alt  Altitude of the center point, in kilometres
#' 
#' @return     A webglobe command
#'
#' @examples 
#' \dontrun{
#' library(webglobe)
#' a<-webglobe(immediate=TRUE)
#' a+wgcamcenter(45,-93,5000)
#' }
#'
#' @export 
wgcamcenter <- function(lat,lon,alt=NA){
  if(!is.na(alt))
    alt<-1000*alt
  toString(jsonlite::toJSON(list(
    command = jsonlite::unbox("cam_center"),
    lat     = jsonlite::unbox(lat),
    lon     = jsonlite::unbox(lon),
    alt     = jsonlite::unbox(alt)
  )))
}

#' @name wgpolygondf
#' 
#' @title      Plot long-frame polygons
#'
#' @description
#'             Plot polygons defined by long-style data frame
#'
#' @param df              Data frame to plot
#' @param fill            Fill colour name
#' @param alpha           Alpha (transparency value)
#' @param extrude_height  Height of the polygon above the surrounding landscape, in TODO
#' @param stroke          Outline colour (TODO)
#' @param stroke_width    Outline width (TODO)
#' 
#' @return     A webglobe command
#'
#' @examples 
#' \dontrun{
#' library(webglobe)
#' a<-webglobe(immediate=TRUE)
#' a+wgpolygondf(ggplot2::map_data("usa"),fill="blue",extrude_height=1000)
#' }
#'
#' @export 
wgpolygondf <- function(df,fill=NA,alpha=1,extrude_height=0,stroke="yellow",stroke_width=10){
  toString(jsonlite::toJSON(list(
    command        = jsonlite::unbox("polygons"),
    polys          = jsonlite::fromJSON(geojsonio::geojson_json(b, group='group', geometry='polygon')),
    fill           = jsonlite::unbox(fill),
    extrude_height = jsonlite::unbox(extrude_height),
    alpha          = jsonlite::unbox(alpha),
    stroke         = jsonlite::unbox(stroke),
    stroke_width   = jsonlite::unbox(stroke_width)
  )))
}
