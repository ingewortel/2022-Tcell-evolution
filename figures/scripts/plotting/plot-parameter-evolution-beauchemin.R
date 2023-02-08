library( ggplot2 )
library( dplyr, warn.conflict=FALSE )
source("../scripts/plotting/mytheme.R")
mytheme <- mytheme + theme( 
	panel.border = element_rect( fill = NA, colour = "black" ),
	axis.line.x = element_blank(),
	axis.line.y = element_blank()
)
library(patchwork)

argv <- commandArgs( trailingOnly = TRUE )

file <- argv[1]
outfile <- argv[2]
simToPlot <- 1

cell_area <- pi * 13^2

d <- read.table( file )

colnames(d) <- c("gen","ind","tfree","vfree","tpause","fitness", "sim")
d$gen <- d$gen + 1 

#d <- d %>%
#    filter( sim == simToPlot )

d2 <- d %>%
    filter( sim == simToPlot ) %>%
	group_by( gen ) %>%
	summarise( tfree = exp(mean(log(tfree))), vfree = exp(mean(log(vfree)) ),
		tpause = exp(mean(log(tpause))) )


make.breaks <- function( powers ){

	breaks <- numeric(0)
	for( p in powers){
		start.value <- 10^p
		sequence <- seq(start.value,10*start.value,start.value)
		breaks <- unique( c( breaks, sequence ))
	}
	return(breaks)
}

ax.breaks <- make.breaks( seq(-3,5))
#c( seq(1,10), seq(20,100,10), seq(200, 1000, 100), seq(2000,10000,1000) )
ax.labels <- as.character( ax.breaks )
ax.labels[ log10( ax.breaks ) %% 1 != 0 ] <- ""

limits.tfree <- c(floor(min(log10(d2$tfree))), ceiling(max(log10(d2$tfree))) )
limits.vfree <- c(floor(min(log10(d2$vfree))), ceiling(max(log10(d2$vfree))) )
limits.tpause <- c(floor(min(log10(d2$tpause))), ceiling(max(log10(d2$tpause))) )


p1 <- ggplot( d2, aes( x = log10(tfree), y = log10(vfree) ) ) +
	stat_summary_2d( data = d, aes( z = fitness/cell_area ), fun = "median", show.legend = FALSE ) +
	scale_x_continuous( limits=limits.tfree, breaks = log10( ax.breaks ), labels = ax.labels ) +
	scale_y_continuous( limits=limits.vfree, breaks = log10( ax.breaks ), labels = ax.labels ) +
	labs( x = expression( t[free] ), y = expression( v[free] ), fill = "Median fitness", color = "Generation" ) +
	#coord_fixed() +
	#geom_point( aes( color = gen ), size = 0.8 ) +
	geom_path( aes( color = gen ), show.legend = FALSE ) +
	scale_fill_gradient( "fitness" ) +
	scale_colour_gradient( "generation", low = "white", high = "red", breaks=seq(0,max(d2$gen),5), limits=c(0,max(d2$gen)) ) +
	#guides(fill = guide_colourbar(barwidth = 0.5, barheight = 2)) +
	#guides(color = guide_colourbar(barwidth = 0.5, barheight = 2)) +
	mytheme 
	
p2 <- ggplot( d2, aes( x = log10(tfree), y = log10(tpause) ) ) +
	stat_summary_2d( data = d, aes( z = fitness/cell_area ), fun = "median", show.legend = FALSE ) +
	scale_x_continuous( limits=limits.tfree, breaks = log10( ax.breaks ), labels = ax.labels ) +
	scale_y_continuous( limits=limits.tpause, breaks = log10( ax.breaks ), labels = ax.labels ) +
	labs( x = expression( t[free] ), y = expression( t[pause] ), fill = "Median fitness", color = "Generation" ) +
	#coord_fixed() +
	#geom_point( aes( color = gen ), size = 0.8 ) +
	geom_path( aes( color = gen ) , show.legend = FALSE ) +
	scale_fill_gradient( "fitness" ) +
	scale_colour_gradient( "generation", low = "white", high = "red", breaks=seq(0,max(d2$gen),5), limits=c(0,max(d2$gen)) ) +
	#guides(fill = guide_colourbar(barwidth = 0.5, barheight = 2)) +
	#guides(color = guide_colourbar(barwidth = 0.5, barheight = 2)) +
	mytheme + theme(
		legend.position = "right",
		legend.title = element_text()
	)
	
p3 <- ggplot( d2, aes( x = log10(tpause), y = log10(vfree) ) ) +
	stat_summary_2d( data = d, aes( z = fitness/500 ), fun = "median" ) +
	scale_x_continuous( limits= limits.tpause, breaks = log10( ax.breaks ), labels = ax.labels ) +
	scale_y_continuous( limits=limits.vfree, breaks = log10( ax.breaks ), labels = ax.labels ) +
	labs( x = expression( "t"["pause"] ), y = expression( "v"["free"] ), fill = "Median fitness", color = "Generation" ) +
	#coord_fixed() +
	#geom_point( aes( color = gen ), size = 0.8 ) +
	geom_path( aes( color = gen ) ) +
	scale_fill_gradient( "fitness" ) +
	scale_colour_gradient( "generation", low = "white", high = "red", breaks=seq(0,max(d2$gen),5), limits=c(0,max(d2$gen)) ) +
	guides(fill = guide_colourbar(barwidth = 0.5, barheight = 2)) +
	guides(color = guide_colourbar(barwidth = 0.5, barheight = 2)) +
	mytheme + theme(
		legend.position = "right",
		legend.title = element_text()
	)

p <- p1 + p2 + p3


ggsave( outfile, plot = p, width = 18, height = 6, units="cm" )
