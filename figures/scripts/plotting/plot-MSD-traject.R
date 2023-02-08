library( ggplot2 )
library( ggrepel )
library( dplyr, warn.conflict = FALSE )
source( "../scripts/plotting/mytheme.R" )

argv <- commandArgs( trailingOnly = TRUE )

msdfile <- argv[1]
outplot <- argv[2]



msd <- read.table( msdfile, header = TRUE )

pointNames <- setNames( seq(2,5), unique( msd$point ) )
msd$pName <- pointNames[ as.character( msd$point ) ]

theme.text.size = 8
geom.size = (5/14) * theme.text.size

dlabel <- msd %>%
	group_by( pName ) %>%
	summarise( dt = 1.5*max( dt ), mean = max( mean ) )

scale_prettylog <- function( axis, minlog = NULL, maxlog = NULL, limits = NULL, labellogs = seq(minlog,maxlog), ticks = TRUE ){
	
	logs <- seq( min( labellogs), max(labellogs ))

	if( is.null(minlog) ){
		minlog <- min( labellogs )
	}
	if( is.null( maxlog) ){
		maxlog <- max( labellogs )
	}
	
	if( is.null(limits) ){
		limits <- c(10^minlog, 10^maxlog)
	}

	
	ax.breaks <- lapply( 1:(length(logs)-1), function(x){
		seq( 10^logs[x], 10^logs[x+1], by = 10^logs[x] ) 
	})
	
	ax.breaks <- unique( unlist( ax.breaks ) )
	ax.labels <- as.character( ax.breaks )
	lognum <- log10( as.numeric( ax.breaks ) )
	logtext <- paste( "10^", lognum )
	ax.labels <- sapply( logtext, function(x) parse( text = x ))
	
	#expression(  paste( "10^",  ) )
	#ax.labels <- expression( paste( "10^",lognum ) ) 
	#ax.labels[ ( seq_along( ax.breaks ) - 1 ) %% 9 != 0 ] <- ""
	ax.labels[ !is.element( lognum, labellogs) ] <- ""


	#return( list( breaks = ax.breaks, labels = ax.labels ) )
	
	if( axis == "x" ){
		return( scale_x_log10( breaks = ax.breaks, labels = ax.labels, 
			expand = c(0,0), limits = limits ) )
	} else if( axis == "y" ){
		return( scale_y_log10( breaks = ax.breaks, labels = ax.labels, 
			expand = c(0,0), limits = limits ) ) 
	} else {
		stop( "axis must be x or y!" )
	}
	
}

xrange <- c( 0, ceiling( max(log10(dlabel$dt*2)) ) )
yrange <- c( -2, ceiling( max(log10(msd$upper*2)) ) )



p <- ggplot( msd, aes( x = dt, y = mean, group = pName, color = pName ) ) +
	#geom_point( data = msd[ seq(1,nrow(msd), by = 100 ), ], alpha = 0.2 ) +
	geom_line( show.legend = FALSE, alpha = 0.3 ) +
	geom_line( aes( y = fit ), show.legend = FALSE, linetype = "dashed" ) +
	geom_text_repel( data = dlabel, direction= "y",  box.padding=0.05, force = 0.1,
		aes( label = pName ), show.legend = FALSE, size = geom.size ) +
	labs( x = expression( paste( Delta*t, " (MCS)" ) ), 
	 	y = expression( paste( symbol("\341")*displacement^2*symbol("\361"), " (",pixels^2,")") ) ) +
	#scale_x_log10( breaks = xax$breaks, labels = xax$labels ) +
	scale_prettylog( "x", labellogs = seq( xrange[1], xrange[2] ), limits = c( 4, 20000) )  +
	scale_prettylog( "y", labellogs = seq( yrange[1], yrange[2]+1, by = 2 ), limits=10^yrange ) +
	mytheme +
	theme(axis.text.y = element_text(hjust = 0))
	
ggsave(outplot, width = 7, height = 5, units = "cm" )

	
	