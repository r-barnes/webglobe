webglobe: Interactive 3D Maps
=============================

You want to understand your data, but it's spatially distributed and you're
afraid that trying to make sense of it on something gross, like a Mercator
projection, is going to lead you to bad intuitions.

![Mercator Projection](vignettes/mercator.png)

(Greenland is nowhere near that big in reality.)

webglobe can help you do this! It allows you to interactively visualize your
data on either a three-dimensional globe or a flat map.



Example: Earth quakes
-----------------------------

    library(webglobe)              #Load the library
    data(quakes)                   #Load up some data

    wg <- webglobe(immediate=TRUE) #Make a webglobe (should open a net browser)
    Sys.sleep(10)                     #Wait for browser to start, or it won't work
    wg + wgpoints(quakes$lat, quakes$lon, size=5*quakes$mag) #Plot quakes
    wg + wgcamcenter(-24, 178.0650, 8000)                    #Move camera

![Webglobe earthquakes visualization](vignettes/webglobe_quakes.png)



Example: States
-----------------------------

    library(webglobe)                 #Load the library
    m  <- ggplot2::map_data("state")  #Get data
    m$extrude_height <- 1000000*runif(nrow(m),min=0,max=1)
    wg <- webglobe(immediate=TRUE)    #Make a webglobe (should open a net browser)
    Sys.sleep(10)                     #Wait for browser to start, or it won't work
    wg + wgpolygondf(m,fill="blue",alpha=1,stroke=NA)
    Sys.sleep(10)                     #Wait, in case you copy-pasted this
    wg + wgclear()                    #Clears the above

![Webglobe states visualization](vignettes/webglobe_states.png)



Modes
-----------------------------

webglobes have two modes: **immediate** and **not-immediate**. Immediate mode
displays a webglobe upon initialization and immediately prints all commands to
that globe. Not-immediate mode stores commands and displays them all at once,
allowing you to stage visualization without intermediate display. The difference
is illustrated below.

Display timing in intermediate mode:

    library(webglobe)
    data(quakes)                     #Get data
    q   <- quakes                    #Alias data
    wgi <- webglobe(immediate=TRUE)  #Webglobe is displayed now
    Sys.sleep(10)                    #Ensure webglobe runs before continuing
    wgi + wgpoints( q$lat,  q$lon)    #Data displays now!
    wgi + wgpoints(-q$lat, -q$lon)    #Data displays now!
    #Reloading the browser window clears everything

Display timing in not-intermediate mode:

    library(webglobe)
    data(quakes)                                  #Get data
    q   <- quakes                                 #Alias data
    wgn <- webglobe(immediate=FALSE)              #Webglobe is not displayed
    Sys.sleep(0)                                  #No need to wait
    #Note that we have to store commands
    wgn <- wgn + wgpoints( q$lat,  q$lon)         #Nothing shown yet
    wgn <- wgn + wgpoints(-q$lat, -q$lon)         #Nothing shown yet
    wgn <- wgn + wgcamcenter(2.89,-175.962,21460) #Nothing shown yet
    wgn                                           #Show it all now!
    #Reloading the browser window keeps everything

You can also switch between modes:

    library(webglobe)
    data(quakes)                                  #Get data
    q   <- quakes                                 #Alias data
    wgn <- webglobe(immediate=FALSE)              #Webglobe is not displayed
    Sys.sleep(0)                                  #No need to wait
    #Note that we have to store commands
    wgn <- wgn + wgpoints( q$lat,  q$lon)         #Nothing shown yet
    wgn <- wgn + wgpoints(-q$lat, -q$lon)         #Nothing shown yet
    wgn <- wgn + wgcamcenter(2.89,-175.962,21460) #Nothing shown yet
    wgn + wgimmediate()                           #Make it all immediate
    wgn
    wgn + wgpoints(q$lat, -q$lon)                 #This is shown right away
    #Reloading the browser window keeps everything up to `wgimmediate()`



Installation
-----------------------------

webglobe **hopefully will be** available from CRAN via:

    install.packages('webglobe')

If you want your code to be as up-to-date as possible, you can install it using:

    library(devtools) #Use `install.packages('devtools')` if need be
    install_github('r-barnes/webglobe', vignette=TRUE)



Developer Notes
-----------------------------

**How To Add Functionality**

There are really only two files that are import to contributing developers:
[inst/client/webglobe.js](inst/client/webglobe.js)
and
[R/webglobe.R](R/webglobe.R)
.

The package uses a JSON websocket message passing scheme to communicate data
between R and the JavaScript client.

Each `wg*()` function generates a JSON payload as follows:

    toString(jsonlite::toJSON(list(
      command = jsonlite::unbox("COMMAND_NAME"), #Required
      lat     = lat,                             #Example
      lon     = lon                              #Example
    )))

The payload consists of a `command` and accompanying data.

For more complex data, `geojsonio` can be leveraged to conveniently encode the
data. However, the resulting GeoJSON must be decoded, so that the whole packae
can be sent with only one level of encoding, as follows:

    toString(jsonlite::toJSON(list(
      command        = jsonlite::unbox("polygons"),
      polys          = jsonlite::fromJSON(geojsonio::geojson_json(df, group='group', geometry='polygon'))
    )))

On the JavaScript side, look for an object named `router`. `router` contains a
variety of fields which correspond to command names. To add a new command, add a
field with a corresponding function, such as:

    points: function(msg){
      var points = viewer.scene.primitives.add(new Cesium.PointPrimitiveCollection());
      for(var i=0;i<msg.lat.length;i++){
        points.add({
          position:  new Cesium.Cartesian3.fromDegrees(msg.lon[i], msg.lat[i], msg.alt[i]),
          color:     Cesium.Color[msg.colour[i].toUpperCase()],
          pixelSize: msg.size[i]
        });
      }
    }

Note that it is standard for the package to accept arguments such as `color`,
`size`, `width`, and so on as having either one value or a number of values
equal to the number of input points, polygons, or lines. That is: you should be
able to set the property of the entire group at once or at an individual level.

Note that functions added to [R/webglobe.R](R/webglobe.R) should be accompanied
by help text an examples, see the existing functions for templates.
Documentation should then be regenerated using

    roxygen2::roxygenise()

Changes to the vignettes (e.g. [vignettes/webglobe.Rmd](vignettes/webglobe.Rmd))
can be built using:

    devtools::build_vignettes()

It is polite to ensure that everything's good by using:

    devtools::check()

Once you have added your function, documented it, added any pertinent
explanations to the vignettes, and checked it, submit a pull request!


Licensing
-----------------------------

This package uses the following libraries:

 * cesiumjs: Cesium is licensed under Apache v2

This package, and all code and documentation not otherwise mentioned above
(essentially anything outside the `src/` directory of this package) are released
under the MIT (Expat) license, as stated in the `LICENSE` file. The `LICENCE`
file exists for use with CRAN.



Roadmap
-----------------------------

* Make not-intermediate mode work

* Additional graphics primitives

* Submission to CRAN



Credits
-----------------------------

This R package was developed by Richard Barnes (http://rbarnes.org).

It uses the Cesium WebGL virtual globe and map engine ([link](https://cesium.com/cesiumjs/)).
