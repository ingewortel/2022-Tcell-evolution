library( celltrackR )
source( "../scripts/analysis/trackAnalysisFunctions.R" )

argv <- commandArgs( trailingOnly = TRUE )


parmfile <- argv[1]
expname <- argv[2]
nsim <- as.numeric( argv[3] )
outplot <- argv[4]
outdata <- argv[5]


# Get the filename of a given track
trackFileName <- function( mact, lact, sim ){
	if( expname == "CPMskin" ){
		tname <- paste0( "data/tracks/CPMskin-lact", lact, "-mact", mact, "-tissuestiff-sim", sim, ".txt" )
	} else if (expname == "CPM2D" ) {
		tname <- paste0( "data/tracks/CPM2D-lact", lact, "-mact", mact, "-sim", sim, ".txt" )
	}
	return(tname)
}

# Function to read all tracks at a given param combo
readAllTracks <- function( mact, lact, nsim ){

	simnums <- seq(0,nsim-1)
	t <- lapply( simnums, function(x){
		return( readTracks( trackFileName( mact, lact, x ), 2, c(150,150) )[[1]] )
	})
	names(t) <- seq(1,length(t))
	return( as.tracks(t) )
}


parms <- read.table( parmfile, stringsAsFactors = FALSE )

parms$ID <- paste0( parms$V1, "-", parms$V2 )


all.tracks <- lapply( 1:nrow(parms), function(x){
	readAllTracks( parms$V1[x], parms$V2[x], nsim )
})
names( all.tracks ) <- parms$ID 

save( all.tracks, file = outdata )

pdf( outplot )
par( mfrow = c( 3, 2 ))
for( i in 1:length(all.tracks) ){
	plot( normalizeTracks( subsample( all.tracks[[i]], 5 ) ) )
}
dev.off()