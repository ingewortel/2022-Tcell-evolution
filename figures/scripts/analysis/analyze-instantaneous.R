source("../scripts/analysis/trackAnalysisFunctions.R")

argv <- commandArgs( trailingOnly = TRUE )

expname <- argv[1]
nsim <- as.numeric( argv[2] )
paramfile <- argv[3]
paramcolnames <- unlist( strsplit( argv[4], " " ) )
paramorder <- as.numeric( unlist( strsplit( argv[5], " ")))
ndim <- as.numeric( argv[6] )
fieldsize <- as.numeric( unlist( strsplit( argv[7], " ")))
outfile <- argv[8]

if( fieldsize[1] == 0 ){
  fieldsize <- NULL
}

# Get parameter combinations
params <- read.table( paramfile )
colnames( params ) <- paramcolnames
paramcolnames <- paramcolnames[ paramorder ]

# convert factor to character
for( i in 1:ncol(params) ){
	if( is.factor( params[,i] ) ){
		params[,i] <- as.character( params[,i] )
	}
}

# column with connectivity, percentage active pixels depends on ndim
if( ndim == 3 ){
  conn.col <- 7
  pact.col <- 8
} else {
  conn.col <- 6
  pact.col <- 7
}

# Functions to get instantaneous speeds and turning angles.
# instantaneous = 2 steps, because we need at least two steps to
# compute an angle.
# Also get minimum connectivity at this two-step subtrack, so we
# can later filter for subtracks where the cell was intact.
getAng <- function( track ){
  require( celltrackR, quietly = TRUE )
  
  length <- nrow(track)
  i <- seq(1,length - 2)
  ang <- sapply( i, function(x) overallAngle( track[x:(x+2), ] ) )
  ang <- 90*(ang/pi)
}
getSpeed <- function( track ){
  require( celltrackR, quietly = TRUE )
  
  length <- nrow(track)
  i <- seq(1,length - 2)
  speed <- sapply( i, function(x) speed( track[x:(x+2), ] ) )
  return( speed )
}

# this works if the dataframe contains a single track, which it does in
# these simulations.
getConn <- function( data ){
	length <- nrow(data)
	i <- seq(1,length - 2)
	conn <- sapply( i, function(x) min( data[x:(x+2), conn.col ] ) )
	return(conn)
}

getAct <- function( data ){
	length <- nrow(data)
	i <- seq(1,length - 2)
	pact <- sapply( i, function(x) mean( data[x:(x+2), pact.col ] ) )
	return(pact)
}

# empty df for output, loop over param combinations
data <- data.frame()
for( p in 1:nrow(params ) ){
  
  pp <- setNames( as.numeric( params[p,] ), colnames(params) )
  pp2 <- setNames( params[p,],  colnames(params) )
  msg <- paste( sapply( paramcolnames, function(x) paste( x, ":", pp2[x] ) ), collapse = " " )
  message( msg )
  
  for( s in 0:(nsim-1) ){
    #message( paste0("sim: ", s))
    # Read both as track and as dataframe
    tparams <- paste0( sapply( paramcolnames, function(x) paste0( "-", x, pp2[x] ) ) , collapse="")
    tname <- paste0( "data/tracks/",expname,tparams,"-sim",s,".txt")
    t <- readTracks( tname, ndim, torus.fieldsize = fieldsize )
    d <- read.table( tname )
    
    # Compute instantaneous speeds, turning angles from track
    v <- unname( unlist( lapply( t, getSpeed ) ) )
    a <- unname( unlist( lapply( t, getAng ) ) )
    
    # Get connectivity, percentage active pixels from dataframe d
    pact <- getAct( d )
    conn <- getConn( d )
    
    
    # Cut them all off into the same length
    lengths <- sapply( list(v,a,pact,conn), length )
    ml <- min(lengths)
    dout <- data.frame( sim = s,
                        v = v[1:ml],
                        a = a[1:ml],
                        pact = pact[1:ml],
						conn = conn[1:ml] )
    for( ppi in paramcolnames ){
		dout[[ppi]] <- pp2[[ppi]]
    }
    data <- rbind( data, dout )
    
  }
}

save( data, file = outfile )
