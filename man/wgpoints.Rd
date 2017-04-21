% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/webglobe.R
\name{wgpoints}
\alias{wgpoints}
\title{Plot points}
\usage{
wgpoints(lat, lon, alt = 0, colour = "yellow", size = 10)
}
\arguments{
\item{lat}{One or more latitude values}

\item{lon}{One or more longitude values}

\item{alt}{Altitude of the points, can be single value of vector}

\item{colour}{Colour name of the points, can be single value of vector}

\item{size}{Size of the points, can be single value or vector}
}
\value{
A webglobe command
}
\description{
Plots latitude-longitude points
}
\examples{
\dontrun{
library(webglobe)
wg<-webglobe(immediate=TRUE)
wg + wgpoints(c(45,20),c(-93,127),alt=3,colour=c("blue","red"))
}

}
