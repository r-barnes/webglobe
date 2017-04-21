webglobe: Interactive 3D Maps
=============================

You want to understand your data, but it's spatially distributed and you're
afraid that trying to make sense of it on something gross, like a Mercator
projection, is going to lead you to bad intuitions.

![Mercator Projection](vignettes/mercator.png)

(Greenland is nowhere near that big in reality.)

webglobe can help you do this! It allows you to interactively visualize your
data on either a three-dimensional globe or a flat map.



##Example: Earth quakes

    library(webglobe)              #Load the library
    data(quakes)                   #Load up some data

    wg <- webglobe(immediate=TRUE) #Make a webglobe (should open a net browser)
    Sys.sleep(10)                     #Wait for browser to start, or it won't work
    wg + wgpoints(quakes$lat, quakes$lon, size=5*quakes$mag) #Plot quakes
    wg + wgcamcenter(-24, 178.0650, 8000)                    #Move camera

![Webglobe earthquakes visualization](vignettes/webglobe_quakes.png)



##Example: States

    library(webglobe)                 #Load the library
    m  <- ggplot2::map_data("state")  #Get data
    m$extrude_height <- 1000000*runif(nrow(m),min=0,max=1)
    wg <- webglobe(immediate=TRUE)    #Make a webglobe (should open a net browser)
    Sys.sleep(10)                     #Wait for browser to start, or it won't work
    wg + wgpolygondf(m,fill="blue",alpha=1,stroke=NA)
    Sys.sleep(10)                     #Wait, in case you copy-pasted this
    wg + wgclear()                    #Clears the above

![Webglobe states visualization](vignettes/webglobe_states.png)



##Installation

webglobe **hopefully will be** available from CRAN via:

    install.packages('webglobe')

If you want your code to be as up-to-date as possible, you can install it using:

    library(devtools) #Use `install.packages('devtools')` if need be
    install_github('r-barnes/webglobe', vignette=TRUE)



##Licensing

This package uses the following libraries:

 * cesiumjs: Cesium is licensed under Apache v2  

This package, and all code and documentation not otherwise mentioned above
(essentially anything outside the `src/` directory of this package) are released
under the MIT (Expat) license, as stated in the `LICENSE` file. The `LICENCE`
file exists for use with CRAN.



##Roadmap

* Additional graphics primitives

* Submission to CRAN



##Credits

This R package was developed by Richard Barnes (http://rbarnes.org).

It uses the Cesium WebGL virtual globe and map engine ([link](https://cesiumjs.org/)).
