#' @importFrom geojsonio  geojson_json
#' @importFrom httpuv     stopDaemonizedServer startDaemonizedServer
#' @importFrom jsonlite   toJSON fromJSON unbox
#' @importFrom stats      runif
#' @importFrom utils      browseURL

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

wg400 <- list(
  status  = 400L,
  headers = list("Content-Type" = "text/plain"),
  body    = "Bad request"
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



#' @name print.webglobe
#' 
#' @title      Display a webglobe
#'
#' @description
#'             Displays a webglobe. If the webglobe is immediate, then a browser
#'             window containing it should already be open; in this case, the
#'             webglobe's address is returned. If the webglobe is not immediate
#'             then a new browser is open and the cached pipeline is sent to it.
#' 
#' @param x    The webglobe   
#' @param ...  Ignored 
#'
#' @return     NA
#'
#' @examples 
#' \dontrun{
#' library(webglobe)
#' wg<-webglobe()
#' wg
#' }
#'
#' @export 
print.webglobe <- function(x, ...){
  if(x$env[['immediate']])
    print(paste0("Server should be running at 'http://localhost:",x$env[['port']],"'"))
  else
    utils::browseURL(paste0('http://localhost:',x$env[['port']]))
  NA
}

#' @name is.webglobe
#' 
#' @title      Is it a webglobe?
#'
#' @description
#'             Determine if an object is a webglobe
#' 
#' @param x    The object that might be a webglobe
#'
#' @return     TRUE or FALSE
#'
#' @examples 
#' \dontrun{
#' library(webglobe)
#' wg<-webglobe(immediate=TRUE)
#' is.webglobe(wg)
#' }
#'
#' @export 
is.webglobe <- function(x) inherits(x, "webglobe")

#' @name +.webglobe
#' 
#' @title      Send command
#'
#' @description
#'             Send a command to a webglobe
#' 
#' @param wg   Webglobe
#' @param x    Command to send
#'
#' @return     The same webglobe
#'
#' @examples 
#' \dontrun{
#' library(webglobe)
#' wg<-webglobe(immediate=TRUE)
#' wg + wgclear()
#' }
#'
#' @export 
`+.webglobe` <- function(wg,x){
  if(x=="immediate")
    wg$env[['immediate']] <- TRUE
  else if (x=="unimmediate")
    wg$env[['immediate']] <- FALSE
  else
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
#' wg<-webglobe(immediate=TRUE)
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
        return(wg400)

      if (path == '/')
        path <- '/index.html'

      path <- file.path(path.package('webglobe'),'client',path)

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
        if(message!="sally_forth")
          return
        for(m in the_env[['msgs']])
          ws$send(m)
      })
    },
    env = the_env
  )

  app$env[['msgs']]      <- c()
  app$env[['immediate']] <- immediate

  startServer <- function(depth){
    tryCatch({
      app$env[['port']]   <- floor(stats::runif(1,min=4000,max=8000))
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
  utils::browseURL(paste0('http://localhost:',app$env[['port']]))

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
#' wg<-webglobe(immediate=TRUE)
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
#' @param lat    One or more latitude values
#' @param lon    One or more longitude values
#' @param label  Label to put next to point
#' @param alt    Altitude of the points, can be single value or vector
#' @param colour Colour name of the points, can be single value or vector
#' @param size   Size of the points, can be single value or vector
#' 
#' @return     A webglobe command
#'
#' @examples 
#' \dontrun{
#' library(webglobe)
#' wg <- webglobe(immediate=FALSE)
#' wg <- wg + wgpoints(c(45,20),c(-93,127),alt=3,colour=c("blue","red"))
#' wg <- wg + wgpoints(51.5074,-0.1278,label="London",alt=0,colour="blue")
#' wg
#' }
#'
#' @export 
wgpoints <- function(lat,lon,label=NA,alt=0,colour="yellow",size=10){
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
  if(length(label)==1)
    label <- rep(label, length(lat))
  toString(jsonlite::toJSON(list(
    command = jsonlite::unbox("points"),
    lat     = lat,
    lon     = lon,
    alt     = alt,
    colour  = colour,
    size    = size,
    label   = label
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
#' wg<-webglobe(immediate=TRUE)
#' wg+wgcamhome()
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
#' wg<-webglobe(immediate=TRUE)
#' wg+wgclear()
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
#' wg<-webglobe(immediate=TRUE)
#' wg+wgcamcenter(45,-93,5000)
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
#' wg<-webglobe(immediate=TRUE)
#' wg+wgpolygondf(ggplot2::map_data("usa"),fill="blue",extrude_height=1000)
#' }
#'
#' @export 
wgpolygondf <- function(df,fill=NA,alpha=1,extrude_height=0,stroke="yellow",stroke_width=10){
  toString(jsonlite::toJSON(list(
    command        = jsonlite::unbox("polygons"),
    polys          = jsonlite::fromJSON(geojsonio::geojson_json(df, group='group', geometry='polygon')),
    fill           = jsonlite::unbox(fill),
    extrude_height = jsonlite::unbox(extrude_height),
    alpha          = jsonlite::unbox(alpha),
    stroke         = jsonlite::unbox(stroke),
    stroke_width   = jsonlite::unbox(stroke_width)
  )))
}



#' @name wgtitle
#' 
#' @title      Title of webglobe browser window
#'
#' @description
#'             Changes the tab/window title of the webglobe's browser view
#'
#' @param title  The title to use
#' 
#' @return     A webglobe command
#'
#' @examples 
#' \dontrun{
#' library(webglobe)
#' wg<-webglobe(immediate=TRUE)
#' wg+wgtitle("I am the new title!")
#' }
#'
#' @export 
wgtitle <- function(title){
  toString(jsonlite::toJSON(list(
    command = jsonlite::unbox("title"),
    title   = jsonlite::unbox(title)
  )))
}



#' @name wgbar
#' 
#' @title      Plot bars from the surface
#'
#' @description
#'             Plots bars rising upwards from points on the Earth's surface
#'
#' @param lat    Latitude of the bars' bases, in degrees
#' @param lon    Latitude of the bars' bases, in degrees
#' @param alt    Altitude of the bars' tops, may be one or many values
#' @param colour Colour of the bars, may be one or many values
#' @param width  Width of bar bars, may be one or many values
#' 
#' @return     A webglobe command
#'
#' @examples 
#' \dontrun{
#' library(webglobe)
#' data(quakes)                                                      #Load up some data
#' wg <- webglobe(immediate=FALSE)                                   #Make a webglobe
#' wg <- wg + wgbar(quakes$lat, quakes$lon, alt=1.5e6*quakes$mag/10) #Plot quakes
#' wg <- wg + wgcamcenter(-33.35, 142.96, 8000)                      #Move camera
#' wg
#' }
#'
#' @export 
wgbar <- function(lat,lon,alt=3000000,colour="blue",width=3){
  if(length(lat)!=length(lon))
    stop('Same number of latitude and longitude points are required!')
  if(length(alt)!=1 && length(alt)!=length(lat))
    stop('One altitude must be specified, or a number equal to that of latitude/longitude!')
  if(length(colour)!=1 && length(colour)!=length(lat))
    stop('One colour must be specified, or a number equal to that of latitude/longitude!')
  if(length(width)!=1 && length(width)!=length(lat))
    stop('One width must be specified, or a number equal to that of latitude/longitude!')
  if(length(alt)==1)
    alt <- rep(alt, length(lat))
  if(length(colour)==1)
    colour <- rep(colour, length(lat))
  if(length(width)==1)
    width <- rep(width, length(lat))
  toString(jsonlite::toJSON(list(
    command = jsonlite::unbox("bars"),
    lat     = lat,
    lon     = lon,
    alt     = alt,
    colour  = colour,
    width   = width
  )))
}



#' @name wgimmediate
#' 
#' @title      Immediate mode: On
#'
#' @description
#'             Turns on immediate mode
#' 
#' @return     A webglobe command
#'
#' @examples 
#' \dontrun{
#' library(webglobe)
#' wg<-webglobe(immediate=FALSE)
#' wg + wgimmediate() #wg is now immediate
#' }
#'
#' @export 
wgimmediate <- function(){
  "immediate"
}

#' @name wgunimmediate
#' 
#' @title      Immediate mode: Off
#'
#' @description
#'             Turns off immediate mode
#' 
#' @return     A webglobe command
#'
#' @examples 
#' \dontrun{
#' library(webglobe)
#' wg<-webglobe(immediate=TRUE)
#' wg + wgunimmediate() #wg is now unimmediate
#' }
#'
#' @export 
wgunimmediate <- function(){
  "unimmediate"
}

#' @name wgimmediate_set
#' 
#' @title      Immediate mode: Set
#'
#' @description
#'             Set immediate mode by value
#'
#' @param mode TRUE or FALSE: TRUE immplies immediate mode on, FALSE implies off
#' 
#' @return     A webglobe command
#'
#' @examples 
#' \dontrun{
#' library(webglobe)
#' wg<-webglobe(immediate=TRUE)
#' wg + wgimmediate_set(FALSE) #wg is now unimmediate
#' }
#'
#' @export 
wgimmediate_set <- function(mode){
  if(mode)
    "immediate"
  else
    "unimmediate"
}
