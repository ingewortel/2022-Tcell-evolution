library( celltrackR )

argv <- commandArgs( trailingOnly = TRUE )

# these parameters will evolve
tfree <- as.numeric( argv[1] ) #5
vfree <- as.numeric( argv[2] ) #18.8
tpause <- as.numeric( argv[3] ) #0.5
seed <- as.numeric( argv[4] )

set.seed(seed)

runtime <- 10000 # same as number of MCS in cpm
dt <- 1          # as in 1MCS
radius <- 13     # measure of cell size that determines which area is "scanned"

runModel <- function( runtime, dt, tfree, vfree, tpause ){
  tt <- beaucheminTrack( sim.time = runtime, delta.t = dt, t.free = tfree,
                         v.free = vfree, t.pause = tpause)
  coordinates <- tt[,c("x","y")]
  return(coordinates)
}

pixelCoverage <- function( coordinate, radius = radius, plot = FALSE ){
  pixel_dx <- 1
  xmin <- floor( coordinate[1] - radius )
  xmax <- ceiling( coordinate[1] + radius )
  ymin <- floor( coordinate[2] - radius )
  ymax <- ceiling( coordinate[2] + radius )

  grid <- expand.grid( x = xmin:xmax, y = ymin:ymax )
  grid$dx <- grid$x - coordinate[1]
  grid$dy <- grid$y - coordinate[2]
  grid$dist <- sqrt( grid$dx^2  + grid$dy^2 )
  grid$name <- paste0( grid$x, "_", grid$y )
  grid$highlight <- grid$dist < radius
  
  out <- grid$name[ grid$dist < radius ]
  
  dpoint <- data.frame( x = coordinate[1], y = coordinate[2] )
  
  if(plot){
    require( ggplot2 )
    require( ggforce )
    xrange <- seq( xmin - pixel_dx/2, xmax + pixel_dx/2, by = pixel_dx )
    yrange <- seq( ymin - pixel_dx/2, ymax + pixel_dx/2, by = pixel_dx )
    
    p <- ggplot( grid, aes( x = x, y = y ) ) + 
      geom_hline( yintercept = yrange, color = "gray", size = 0.3 ) +
      geom_vline( xintercept = xrange, color = "gray", size = 0.3 ) +
      geom_point( aes( color = highlight ), show.legend=FALSE ) +
      geom_point( data = dpoint, color = "red", size = 2 ) +
      geom_circle( data = dpoint, aes( x0 = x, y0 = y, r = radius) ) +
      theme_classic() +
      coord_fixed( xlim = range(xrange), ylim = range(yrange), expand = FALSE ) +
      scale_color_manual( values = c("FALSE" = "gray", "TRUE" = "black" ) )
    print(p)
  }
  
  return( out )
  
}

fitness <- function( runtime, dt, tfree, vfree, tpause, radius ){
  coordinates <- runModel( runtime, dt, tfree, vfree, tpause )
  visited <- apply( coordinates, 1, pixelCoverage, radius = radius )
  return( length( unique( unlist( visited )  ) ) )
}

fout <- fitness( runtime, dt, tfree, vfree, tpause, radius )
cat( paste0( as.character(fout), "\n" ) )

# ==== OLD code
# library( ggplot2 )
# library( ggforce )
# 
# point <- c( 3.2, 6.678 )
# radius <- 3
# dpix <- expand.grid( x = 0:10, y = 0:10 )
# dpoint <- data.frame( x = point[1], y = point[2] )
# 
# dpix$dx <- dpix$x - point[1]
# dpix$dy <- dpix$y - point[2]
# dpix$dist <- sqrt( dpix$dx^2 + dpix$dy^2 )
# dpix$highlight <- dpix$dist < radius
# 
# ggplot( dpix, aes( x = x, y = y ) ) + 
#   geom_hline( yintercept = seq(-0.5,10.5), color = "gray", size = 0.3 ) +
#   geom_vline( xintercept = seq(-0.5,10.5), color = "gray", size = 0.3 ) +
#   geom_point( aes( color = highlight ) ) +
#   geom_point( data = dpoint, color = "red", size = 2 ) +
#   geom_circle( data = dpoint, aes( x0 = x, y0 = y, r = radius) ) +
#   theme_classic() +
#   coord_fixed( xlim = c(-0.5,10.5), ylim = c(-0.5,10.5), expand = FALSE ) +
#   scale_color_manual( values = c("FALSE" = "gray", "TRUE" = "black" ) )
# 


