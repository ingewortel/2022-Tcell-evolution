library( ggplot2 )
library( dplyr, quietly = TRUE, warn.conflicts = FALSE )
require( cowplot, quietly = TRUE, warn.conflicts = FALSE )
source("../scripts/plotting/mytheme.R")

argv <- commandArgs( trailingOnly = TRUE )

datafile <- argv[1]
paramfile <- argv[2] # Must be list of mact/lact params surrounding the optimum point
nsim <- as.numeric( argv[3] )
name <- argv[4]
outfile <- argv[5]

# Read datafile
d <- read.table( datafile, header=TRUE )


# Read file with params to check
parms <- read.table( paramfile )
if( ncol(parms) == 2 ){
	colnames(parms) <- c("mact","lact" )
} else {
	colnames(parms) <- c("mact","lact","tissue")
}

# Get the optimum
mact_opt <- as.numeric( names( sort( table( parms$mact ), decreasing = TRUE )[1] ) )
lact_opt <- as.numeric( names( sort( table( parms$lact ), decreasing = TRUE )[1] ) )

# Filter parameters with either maxact or lambda act fixed:
parms_lactfix <- parms %>% filter( lact == lact_opt )
parms_lactfix <- arrange( parms_lactfix, mact )
parms_lactfix$id <- paste0( parms_lactfix$mact, "-", parms_lactfix$lact )

parms_mactfix <- parms[ parms$mact == mact_opt, ]
parms_mactfix <- arrange( parms_mactfix, lact )
parms_mactfix$id <- paste0( parms_mactfix$mact, "-", parms_mactfix$lact )


# Filter these params from data, and compute the mean speed/persistence in each group
dsum <- d %>% 
	group_by( mact, lact ) %>%
	summarise( m_speed = mean(speed), m_persistence = mean(phalf,na.rm=TRUE), sd_speed = sd(speed), sd_persistence = sd(phalf,na.rm=TRUE) ) %>%
	as.data.frame()
rownames(dsum) <- paste0(dsum$mact,"-",dsum$lact)
d.lactfix <- dsum[ parms_lactfix$id, ]
d.lactfix$fixed <- "lact"
d.mactfix <- dsum[ parms_mactfix$id, ]
d.mactfix$fixed <- "mact"


# Find percentages of broken cells
# These will be stored in a new column
d.lactfix$broken <- 0
d.mactfix$broken <- 0


# Given a file with a track, find the minimum connectedness in that track
min.conn <- function( filename ){
	tmp <- read.table( filename )
	# filter out the first 10000 steps, to check cellbreaking during the same
	# interval as used during evolutionary runs.
	tmp <- tmp[ tmp$V2 <= 10000, ]
	
	# get min connectedness
	return( min( tmp$V6 ) )
}

# Given an expname, parameters, and simulation, construct the name of the corresponding
# track file
make.filename <- function( name, lact, mact, s ){
	if( name == "CPMskin" ){
		filename <- paste0( "data/tracks/",name,"-lact",lact,"-mact",mact,"-tissuestiff-sim",s,".txt" )
	} else {
		filename <- paste0( "data/tracks/",name,"-lact",lact,"-mact",mact,"-sim",s,".txt" )
	}
}

# Function to find the percentage of broken cells at a given parameter combination
percentage.broken <- function( mact, lact, nsim ){
	min.connectedness <- sapply(seq(0,(nsim-1)), 
		function(x) min.conn( make.filename(name, lact, mact, x) ) )
	perc.broken <- 100*( sum( min.connectedness < 0.9 ) / nsim )
	return(perc.broken)
}


for( i in 1:nrow(d.mactfix) ){
	mact <- d.mactfix$mact[i]
	lact <- d.mactfix$lact[i]
	d.mactfix$broken[i] <- percentage.broken( mact, lact, nsim )
}


for( i in 1:nrow(d.lactfix) ){
	mact <- d.lactfix$mact[i]
	lact <- d.lactfix$lact[i]
	d.lactfix$broken[i] <- percentage.broken( mact, lact, nsim )
}


dtot <- rbind( d.lactfix, d.mactfix )


save( dtot, file = outfile )


