library( celltrackR )
library( dplyr, warn.conflicts = FALSE )
library( ggplot2) 
library( cowplot , warn.conflicts = FALSE )
source( "../scripts/analysis/trackAnalysisFunctions.R" )
source( "../scripts/plotting/mytheme.R" )




argv <- commandArgs( trailingOnly = TRUE )

trackFile <- argv[1]
trajectFile <- argv[2]
outPlot <- argv[3]

load(trackFile)

#trajectP
load( trajectFile )

acovPerTrack <- function( tracks ){

	# get autocovaraince curve per track
	acovs <- lapply( tracks, function(x) aggregate( wrapTrack(x), overallDot ) )
	acovs2 <- lapply( seq(1,length(acovs)), function(x) mutate( acovs[[x]], id = x))
	
	# combine into single df
	acov <- bind_rows( acovs2 )
	acov$dt <- acov$i * timeStep( tracks )
	return(acov)
		
	
}

fitAcovWithBootstrap <- function( acovdata, guessPersis, frac = 0.5, guessTime = NA ){

	acov <- acovdata

	# fit this dataset
	acovFit <- acov %>% 
		filter( dt >= frac*guessPersis ) 
	
	if( !is.na( guessTime ) ){
	
		if( guessTime < 20 ){
			guessTime <- 20
		}
		acovFit <- acov %>% filter( dt <= 3*guessTime )
	}
	
	# fit the exponential decay model on these data
	model <- nls( value ~ exp( -dt / sqrt(P2) ) * b, data = acovFit,
		start = list( P2 = (guessPersis^2), b = 1 ) )
		#lower = list( P = 0, b = 0), algorithm = "port" )
		
	# get the new persistence estimate
	pNew <- sqrt( coefficients(model)[["P2"]] )
	
	tmax <- 5*pNew
	if( tmax < 100 ){ tmax <- 100 }
	
	acov <- acov %>% filter( dt <= tmax )
	
	# add fit to dataframe
	dt <- seq( min( acovFit$dt ), max( acov$dt), length.out = 500 )
	dfit <- data.frame( dt = dt,
		value = exp( -dt / pNew )*coefficients(model)[["b"]] )
	
	return( list( acov = acov, fit = dfit, P = pNew ))
	
}

plotAcovFitted <- function( acovfit ){
	
	acov <- acovfit$acov
	fit <- acovfit$fit
		
	acovSum <- acov %>%
		group_by( dt ) %>%
		summarise( mean = mean(value), lo = quantile( value, 0.025 ), hi = quantile( value, 0.975))
	
	p <- ggplot( acovSum, aes( x = dt, y = mean ) ) +
		geom_hline( yintercept = 0 ) +
		geom_ribbon( aes( ymin = lo, ymax = hi ), alpha = 0.2 ) +
		geom_line( data = fit, aes( y = value ), color = "red"  ) +
		geom_vline( xintercept = acovfit$P, color = "gray", lty = 2 ) +
		labs( x = expression( Delta*t), y = "autocovariance" ) +
		geom_line( aes( y = mean ), alpha = 0.5 ) +
		theme_classic() + theme(
			axis.line.x = element_blank()
		)
		
	return(p)
		

}



acovlist <- lapply( all.tracks, acovPerTrack )
gp <- lapply( all.tracks, guessPoint, 0.05 )
fitlist <- lapply( names( all.tracks), function(x){	
	fitAcovWithBootstrap( acovlist[[x]], guessPersis = trajectP[[x]], guessTime = gp[[x]] )
})
plotlist <- lapply( fitlist, plotAcovFitted )
out <- plot_grid( plotlist=plotlist, ncol = 4 )

ggsave( outPlot, width = 25, height = 5, units = "cm" )
