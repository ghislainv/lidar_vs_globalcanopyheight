#!/usr/bin/R

## ==============================================================================
## author          :Ghislain Vieilledent
## email           :ghislain.vieilledent@cirad.fr, ghislainv@gmail.com
## web             :https://ghislainv.github.io
## license         :GPLv3
## ==============================================================================

# Import libraries
library(terra)
library(here)
library(sf)
library(urltools)
library(ggplot2)

# Load data
lidar <- terra::rast(here("data", "kuebini_CHM.tif"))
ext_lidar <- terra::ext(lidar)

# Get global canopy height
proj_s <- "EPSG:4326"
ulx <- 166.95
uly <- -22.214
lrx <- 166.97
lry <- -22.237
ullr_extent <- c(ulx, uly, lrx, lry)
url_base <- paste0("https://libdrive.ethz.ch/index.php/",
                   "s/cO8or7iOe5dT2Rt/download?path=/3deg_cogs",
                   "&files=")
ifile <- paste0("/visicurl/", url_base,
                "ETH_GlobalCanopyHeight_10m_2020_S24E165_Map.tif")
ofile <- here("data", "gch_kuebini.tif")
opts <- c("-projwin", ullr_extent, "-projwin_srs", proj_s,
          "-co", "COMPRESS=LZW", "-co", "PREDICTOR=2")

# This does not work because of ifile url encoding and ?
sf::gdal_utils(util="translate",
               source=paste0("'", ifile, "'"),
               destination=ofile,
               options=opts,
               config_options=c(GTIFF_SRS_SOURCE="EPSG"),
               quiet=FALSE)

# This command is working with "'" around input file
system("gdal_translate -projwin 166.95 -22.214 166.97 -22.237 -projwin_srs EPSG:4326 '/vsicurl/https://libdrive.ethz.ch/index.php/s/cO8or7iOe5dT2Rt/download?path=%2F3deg_cogs&files=ETH_GlobalCanopyHeight_10m_2020_S24E165_Map.tif' /home/ghislain/Code/lidar_vs_globalcanopyheight/data/kuebini_gch.tif")
gch <- terra::rast(here("data", "kuebini_gch.tif"))

# Sample points within lidar
samp_lidar <- terra::spatSample(lidar, size=1000, xy=TRUE, as.points=TRUE)
samp_gch <- terra::extract(gch, xy=TRUE, samp_lidar)
samp <- cbind(as.data.frame(samp_lidar), samp_gch)
head(samp)

# Plot
p <- ggplot(data=samp, aes(x=kuebini_CHM, y=kuebini_gch)) +
  geom_point() +
  geom_abline(intercept=0, slope=1) +
  xlim(0, 25) + ylim(0, 25)

ggsave(filename="outputs/gch_chm.png", plot=p)

# End of file
