# Reading the tracks depends on the number of dimensions (2 or 3 pos.columns?)
# The torus.fieldsize argument, if not null, indicates that a correction for a torus 
# should be implemented with the specified fieldsize in x,y(,z) dimensions.
readTracks <- function( trackfile, dim, torus.fieldsize = NULL ){
	suppressMessages( require( celltrackR, quietly=TRUE  ) )
	if( dim == 3 ){
		# 3D coordinates in columns 4-6
		tracks <- read.tracks.csv( trackfile, id.column=2, time.column=1, pos.columns=4:6 )
	} else {
		# 1D and 2D simulations both have x and y coordinates in columns 4-5
		tracks <- read.tracks.csv( trackfile, id.column=2, time.column=1, pos.columns=4:5 )
	}

	if( !is.null(torus.fieldsize) ){
		tracks <- correctTorus( tracks, fieldsize = torus.fieldsize )
	}
	

	return( tracks )

}

# Correct tracks when cells move in a torus
correctTorus <- function( tracks, fieldsize = c(150,150) ){

	# Loop over separate tracks in the tracks object (can be just one)
	for( t in 1:length(tracks) ){

		# Loop over the dimensions x,y(,z) (first column is time)
		coordlastcol <- ncol( tracks[[t]] )
		for( d in 2:coordlastcol ){
		
			# do the correction only if the fieldsize in that dimension is not NA
			# (which indicates that there is no torus to be corrected for)
			if( !is.na( fieldsize[d-1] ) ){
			
				# distance traveled in that direction
				dc <- c( 0, diff( tracks[[t]][,d] ) )

				# if absolute distance is more than half the gridsize,
				# the cell has crossed the torus border.
				# if the distance is negative, all subsequent points
				# should be shifted with + fieldsize, if positive,
				# with -fieldsize.
				corr <- 0
				corr[ dc < (-fieldsize[d-1]/2) ] <- fieldsize[d-1]
				corr[ dc > (fieldsize[d-1]/2) ] <- -fieldsize[d-1]
				corr.points <- which( corr != 0 )

				# apply the correction: shift all subsequent points with the
				# correction factor determined above.
				totrows <- nrow( tracks[[t]] )
				for( row in corr.points ){
					tracks[[t]][ (row:totrows), d ] <- tracks[[t]][ (row:totrows), d ] + corr[row]
				}
			
			}
			
		}

	}

	# return corrected tracks
	return( tracks )

}

# This function makes a (rough!) guess of the subtrack length where the autocovariance
# plot drops to fraction times its original level.
guessPoint <- function( tracks, fraction = 0.1, points = 500 ){
  
  require( celltrackR, quietly = TRUE )
  
  # Compute dot product over subtracks of different lengths to generate
  # a (rough) autocovariance curve. Find its maximum value, then guess
  # the time where the autocovariance becomes less then fraction * its
  # initial (maximum) value.
  tracklength <- median( sapply( tracks, nrow ) )
  rough.subtracks <- unique( round( exp( seq( 0, floor( log( tracklength ) ), length.out = points ) ) ) )
  d0 <- suppressWarnings( aggregate( tracks, overallDot, subtrack.length = rough.subtracks ) )
  maxvalue <- d0$value[1]
  guesspoint <- d0$i[ head( which( d0$value <= fraction*maxvalue ), 1 ) ]

  if( length( guesspoint ) == 0 ){
    warning("No measured points below the threshold. Guessing from loess fit instead.")
    
    # fit a smooth curve with loess to make the guess instead.
    fit <- loess( value ~ i, data = d0 )
    guesspoint <- d0$i[ head( which( fit$fitted <= fraction*maxvalue ),1 ) ]
    
    # if this still doesn't work, return a warning
    if( length( guesspoint ) == 0 ){
      warning( paste0("Autocovariance curve does not drop below the threshold of ", fraction,".") )
      return(NA)
    }
        
  }
      
  return( guesspoint )
}

# Measure an autocovariance plot of 20 points at the relevant timescale
# (which is estimated internally).
acovdata <- function( tracks, fraction = 0.1 ){
  
  require( celltrackR, quietly=TRUE )
  
  # First guess the point where the autocovariance plot becomes less than 10%
  # of its initial value:
  guess1 <- guessPoint( tracks, fraction = fraction, points= 500 )
  
  # From this guess, determine the cutoff point for the autocovariance to be
  # measured.
  if( is.na( guess1 ) ){
    # point not found. Any fit will be unreliable; return NA.
    return( NA )
  } else {
    # Cutoff point is twice the guessed time, but maximum is the tracklength.
    tracklength <- max( sapply( tracks, nrow ) )
    cutoff <- 2*guess1
    if( cutoff >= tracklength ){
      cutoff <- tracklength - 1 
    }
  }
  
  # Get 20 subtrack lengths to measure autocovariance on.
  # If the cutoff is really low, measure every point.
  # otherwise measure log-distributed points so that there
  # are more points in the intial part of the autocovariance plot.
  if( cutoff < 550 ){
    if( cutoff < 20 ) {
      subtracks <- seq(1,20)
    } else {
      startpoints <- seq(1,10)
      restcurve <- round( 2^seq(log2(11),log2(cutoff),length.out=10))
      subtracks <- unique( c(startpoints, restcurve) )
    }
  } else {
    # Hack to increase the chance that the unique vector of log-spaced values
    # has 20 points.
    subtracks <- unique( round( 2^seq(0,log2(cutoff),length.out=20) ) )
    if( length( subtracks < 20 ) ){
      subtracks <- unique( round( 2^seq(0,log2(cutoff),length.out=21) ) )
    }
  }
  
  # Now measure the autocovariance plot on these subtracks.
  dotdata <- suppressWarnings( aggregate( tracks, overallDot, subtrack.length = subtracks ) )
  
  # Find the timedifference dt between the track points, and convert subtrack lengths
  # to a time scale.
  dt <- head( diff( tracks[[1]][,"t"]), 1 )
  dotdata$deltat <- dotdata$i * dt
  
  return(dotdata)
  
}

# Measure persistence using autocovariance with exponential decay fit.
persistenceDecay <- function( tracks, outplot = NULL ){
  
  # Measure autocovariance.
  # This is a measure of persistence as it includes a cosine term which is maximal if
  # two vectors align, and minimal if they point in opposite directions.
  dotdata <- acovdata( tracks, fraction = 0.1 )
  
  # if the result is NA (not a dataframe), return NA (autocovariance plot does not 
  # decay enough to allow reliable estimation)
  if( !is.data.frame( dotdata ) ){
    return( NA )
  }
  
  # Otherwise fit the exponential model.
  # Fit (guess the start parameters from dotdata ):
  guessA <- max( dotdata$deltat )
  guessB <- dotdata$value[1]
  
  # Weights decay with i because the number of subtracks decreases.
  tracklength <- max( sapply( tracks, nrow ) )
  dotdata$weights <- tracklength - dotdata$i + 1
  
  model <- tryCatch( nls( value ~ exp( -deltat / a ) * b, data = dotdata, 
                          start = list( a = guessA, b = guessB),
                          weights = dotdata$weights ),
                     error = function(e) NA )
  
  if( !is.null( outplot ) ){
    pdf(outplot)
    plot( dotdata )
  }
  
  if( is.na( model[1] ) ){
    if( !is.null(outplot)){dev.off()}
    return( NA )
  }
    
  persistence <- coefficients(model)["a"]
  
  if( !is.null( outplot ) ){
    b <- coefficients( model )["b"]
    dt <- seq(1,max(dotdata$deltat), length.out = 100 )
    fit <- exp( -dt/persistence)*b
    lines( dt, fit, col = "red" )
    dev.off()
  }

  return( unname( persistence ) )
  
}

# Measure persistence using autocovariance halflife
persistenceHalflife <- function( tracks ){
  
  # Get the acov data at the relevant time interval
  dotdata <- acovdata( tracks, fraction = 0.5 )
  
  # if the result is NA (not a dataframe), return NA (autocovariance plot does not 
  # decay enough to allow reliable estimation)
  if( !is.data.frame( dotdata ) ){
    return( NA )
  }
  
  # Fit a loess smooth
  dotdata$fit <- loess( value ~ deltat, data = dotdata )$fitted
  
  # Estimate the halflife
  maxvalue <- max(dotdata$value)
  srtdata <- sortedXyData( expression( deltat ), expression( fit ), dotdata )
  halflife <- NLSstClosestX( srtdata, 0.5*maxvalue )
  
  return(halflife)
}

# The following functions are helpers for persistenceInterval:
# Take only the every [interval]-th line of the data
getIntervals <- function( data, interval ){
  lines <- seq(1,nrow(data),by=interval)
  newdata <- data[lines,]
  return( newdata )
}

# Add a column with the difference in location x (last element is NA).
addDiff <- function( data ){
  
  nc <- ncol(data)
  new <- c( diff(data[,"x"]), NA )
  data <- cbind( data, new )
  colnames(data)[nc+1] <- "dx"
  return( data )
  
}

# Add a column to classify interval as movement in either direction
# (-1,1) or a stop (0)
addDir <- function( data, threshold ){
  
  nc <- ncol(data)
  new <- rep(0, nrow(data))
  new[ data[,"dx"] > threshold ] <- 1
  new[ data[,"dx"] < (-threshold) ] <- -1
  data <- cbind( data, new )
  colnames(data)[nc+1] <- "dir"
  return( data )
  
}


# Measure persistence using interval method (1D only)
persistenceInterval <- function( tracks, grouppoints = 10, threshold = 4 ){
  
  # Sample every "grouppoints"-th row of the data to assess movement over
  # a larger timeinterval.
  t1 <- lapply( tracks, getIntervals, grouppoints )
  
  # Compute the distance traveled in those intervals
  t1 <- lapply( t1, addDiff )
  
  # Classify direction/stops
  t1 <- lapply( t1, addDir, threshold )
  
  # Use rle to get stretches where the classification stays the same
  stretches <- lapply( t1, function(x) rle( x[,"dir"] ) )
  
  # Filter out the non-stops and get their lengths
  movementstretches <- unlist( lapply( stretches, function(x) x$lengths[x$values != 0] ) )
  
  # Get mean and median, and multiply with time interval.
  dt <- head( diff( t1[[1]][,"t"]), 1 )
  
  return( list( meantime = mean(movementstretches)*dt,
                mediantime = median(movementstretches )*dt ) )
  
}


# Compute the mean persistence of the tracks
# Input is a tracks object from celltrackR
trackPersistence <- function( tracks, outplot=NULL, interval = NULL, threshold = 4 ){

  # Get the different measures of persistence
  decay <- persistenceDecay( tracks, outplot = outplot )
  halflife <- persistenceHalflife( tracks )
  
  # if interval is not NULL, use also the interval method
  if( !is.null(interval)){
    interval <- persistenceInterval( tracks, grouppoints = interval, threshold = threshold )
    return( list( halflife = halflife, decay = decay, meanint = interval$meantime,
                  medianint = interval$mediantime ) )
  }
  
  # otherwise return only the other two methods
  return( list( halflife = halflife, decay = decay, meanint = NA, medianint = NA ) )
}

# Compute the mean speed of the tracks
# Input is a tracks object from celltrackR
meanSpeed <- function( tracks ){

	require(  celltrackR, quietly=TRUE   )

	# Compute using speed function of celltrackR
	speed <- aggregate( tracks, speed, subtrack.length = 1 )$value
	return(speed)

} 

# Get number of simulation resets
numResets <- function( tracks, channelwidth, tol = 50 ){
  
  # if there is only one track, there was no reset
  if( length( tracks ) == 1 ){
    return( 0 )
  }
  resets <- 0
  for( t in 1:(length(tracks)-1) ){
    ttmp <- tracks[[t]]
    endpos <- tail(ttmp,1)[,"x"]
    if( abs( channelwidth - endpos ) < tol | endpos < tol ){
      resets <- resets + 1
    }
  }
  return(resets)
}

# Get number of direction switches that last at least 5 observations in the track
numSwitches <- function( tracks, minlength = 5 ){
  
  # Get direction of each observation
  directions <- lapply( tracks, function(t) diff( t[,"x"] ) > 0 )
  
  # Find lengths of stretches in a given direction
  stretches <- lapply( directions, rle )
  
  # Get only the stretches of the minimum length
  stretches2 <- lapply( stretches, function(s) s$values[ s$lengths >= minlength ] )
  
  switches <- sapply( stretches2, function(s) length(s) - 1 )
  return( sum( switches ) )
  
}
