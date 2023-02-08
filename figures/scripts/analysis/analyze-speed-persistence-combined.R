source("../scripts/analysis/trackAnalysisFunctions.R")

# Input arguments from stdin:
argv <- commandArgs( trailingOnly = TRUE )

trackfilename <- argv[1]
dim <- as.numeric( argv[2] )
parms <- unlist( strsplit( argv[3], " " ) )
parmnames <- unlist( strsplit( argv[4], " " ) )
nsim <- as.numeric( argv[5] )
simgroupsize <- as.numeric( argv[6] )
torusFieldsize <- as.numeric( unlist( strsplit( argv[7], " " ) ) )
expName <- argv[8]


# get parameter values and parameter names
parmValues <- setNames( parms, parmnames )

# plot autocovariance to check?
plotAcov <- FALSE

# Report progress to console
message( paste( "     Analyzing tracks", expName, ": ", paste0( parmnames, " = ", parms, collapse = ", " ) ) )

# Combine [simgroupsize] tracks to do analysis on. This way we can compute some measures
# in a step- or subtrack-based manner, avoiding the artefacts of individual track-based
# analyses. At the same time, because multiple of these "groups" are analyzed, we also
# get an idea of the variation in the computed outcomes (measurement error).
# 
# The resulting number of such analysis groups with nsim total tracks:
groups <- floor( nsim/simgroupsize )

# Now perform the analysis for every group
d <- data.frame()
for( g in 1:groups ){

	# Read the relevant files and concatenate simgroupsize files to 
	# one track object
	
	# Read the first track of the current 'group':
	sim <- 1+(g-1)*simgroupsize # the number of the first simulation in this group.
	tracklist <- readTracks( paste0( trackfilename, (sim-1), ".txt" ), dim, torusFieldsize )
	if( simgroupsize > 1){
		for( s in 2:simgroupsize ){
			sim <- s + (g-1)*simgroupsize	# the number of the s-th simulation in this group.
			file <- paste0( trackfilename, (sim-1), ".txt" )
			t <- readTracks( file, dim, torusFieldsize )
			tracklist <- c( tracklist, t )
		}

	}
	

	# Analyze speed and persistence
	if( plotAcov ){
		fileID <- paste0( parmnames, parms, collapse="-" )
		outplotname <- paste0( "data/analysis-",expName,"/acorplots/",fileID,"-groups",g,"_",groups,".pdf" )
	} else {
		outplotname <- NULL
	}
	
	
	# Compute the mean (step-based) speed of the tracks in this group	
	s <- meanSpeed( tracklist )
	
	# Persistence will be measured in multiple ways:
	# 	- interval method (1D simulations only): we subsample every 'interval'-th 
	# 		timepoint of the track to get a more coarse-grained track. For each interval,
	#		we measure if the cell was moving to the left, to the right, or not moving
	#		(displacement below a given threshold). We then measure the mean or median
	#		duration of stretches where the cell was consistently moving in the same
	#		direction.
	#		==> This yields the meanint/medianint values returned by trackPersistence. 
	#			These are NA for 2D/3D simulations, where this method does not work 
	#			because the number of directions the cell can move in is no longer finite.
	#	- persistence decay method: We compute an autocovariance plot of the tracks,
	#		fit this with an exponential decay function value ~ exp( -deltat / a ) * b, 
	#		and return the coefficient a of the fitted function as a measure of 
	#		persistence time. 
	#		==> This yields the decay value returned by trackPersistence.
	#	- persistence halflife method: Very similar to the decay method. Again compute
	#		the autocovariance plot, but this time do not assume that it follows an
	#		exponential decay (which is not necessarily true for non-random walk motility 
	#		patterns). Instead, use a loess kernel smoothing function to estimate the
	#		"halflife" of the autocovariance plot: the time interval dt where it reaches
	#		half its initial value.
	
	# Set the interval length for the interval method (1D only, so NULL for 2D/3D):	
	if( dim == 1){
		interval <- 10	
	} else {
		interval <- NULL	
	}
	
	# Use this function to get persistence estimates with the three different methods.
	p <- trackPersistence( tracklist, outplot = outplotname, interval = interval, threshold = 4 )
	
	# Add to the dataframe
	dparms <- as.data.frame(t(parmValues))
	dvalues <- data.frame(
		g = g, 
		speed = s, 
		pexp = p$decay, 
		phalf = p$halflife,
		pintmean = p$meanint, 
		pintmedian = p$medianint 
	)
	dtmp <- cbind( dparms, dvalues )
	d <- rbind( d, dtmp )


}


# Print the dataframe to the console (it will be saved to a file via the pipe)
print( unname(d), row.names=FALSE )
