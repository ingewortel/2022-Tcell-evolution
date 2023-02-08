library( celltrackR )
library( dplyr, warn.conflicts = FALSE )
source( "../scripts/analysis/trackAnalysisFunctions.R" )

argv <- commandArgs( trailingOnly = TRUE )

trackFile <- argv[1]
outfile <- argv[2]

load( trackFile )



getMSD <- function( tracks ){
	msd <- aggregate( tracks, squareDisplacement, FUN = "mean.se" ) 
	dt <- timeStep( tracks )
	msd$dt <- msd$i * dt 
	return(msd)
}

fuerthMSD <- function( dt, coef ){

	D <- coef[["D"]]
	P <- coef[["P"]]

	msd <- 4*D*( dt - P*(1-exp(-dt/P) ) )
	return(msd) 

}

fitMSD <- function( tracks, trace = FALSE, thresh = 1 ){

	# get MSD curve
	msd <- getMSD( tracks )
	
	# weights: number of *non-overlapping* subtracks of that length.
	msd$weight <- sapply( msd$i, function(x){
		tlen <- sapply( tracks, nrow ) - 1
		num <- floor( tlen/ x )
		return( sum( num ) )
	})

	
	# a sloppy fit to get an estimate of the persistence time
	roughmodel <- nls( mean ~ 4*D*(dt - P*(1-exp(-dt/P))), 
		data = msd, 
		start = list( D = 10, P = 1 ), 
		lower = list( D = 0, P = 0 ), 
		algorithm = "port" 
	)
			
	guessD <- coefficients( roughmodel)[["D"]]
	guessP <- coefficients( roughmodel)[["P"]]
	if( guessP < 1 ){ guessP <- 1 }
			
	model <- nls( 
		log( mean ) ~ log( 4*exp(logD)) + log((dt - (P)*(1-exp(-dt/(P) ))) ), 
		data = msd[ msd$dt >= thresh*guessP , ], 
		weights = msd$weight[ msd$dt >= thresh*guessP  ],
		start = list( logD = log(guessD), P = (guessP) ), 
		trace = trace
	)
		
	coef <- coefficients(model)
	coef[["D"]] <- exp( coef[["logD"]] )
		
	# add fitted to data
	msd$fit <- sapply( msd$dt, fuerthMSD, coef )
	return( list( msd = msd, coef = coef ) )

}




# fit the msds of all track objects in the list
msdfits <- lapply( all.tracks, fitMSD )
msdlist <- lapply( names( all.tracks ), function(x) {
	mutate( msdfits[[x]]$msd, point = x )
} )
msdall <- bind_rows( msdlist )

trajectP <- lapply( msdfits, function(x) x$coef[["P"]] )
save( trajectP, file = "data/trajectP.Rdata")

write.table( msdall, file = outfile, quote = FALSE, col.names = TRUE, row.names = FALSE )


