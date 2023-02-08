library( ggplot2 )
library( dplyr, warn.conflicts = FALSE )
options(dplyr.summarise.inform = FALSE)
source("../scripts/plotting/mytheme.R")
mytheme <- mytheme + theme( 
	panel.border = element_rect( fill = NA, colour = "black" ),
	axis.line.x = element_blank(),
	axis.line.y = element_blank()
)

argv <- commandArgs( trailingOnly = TRUE )

file <- argv[1]
outfile <- argv[2]
simToPlot <- 1


d <- read.table( file )

colnames(d) <- c( "gen","ind","mact","lact","fitness","sim")
d$gen <- d$gen + 1 

d2 <- d %>%
    filter( sim == simToPlot ) %>%
	group_by( gen ) %>%
	summarise( mact = exp(mean(log(mact))), lact = exp(mean(log(lact)) ) )


ax.breaks <- c( seq(1,10), seq(20,100,10), seq(200, 1000, 100), seq(2000,10000,1000) )
ax.labels <- as.character( ax.breaks )
ax.labels[ ( seq_along( ax.breaks ) - 1 ) %% 9 != 0 ] <- ""


ggplot( d2, aes( x = log10(mact), y = log10(lact) ) ) +
	stat_summary_2d( data = d, aes( z = fitness/500 ), fun = "median" ) +
	scale_x_continuous( limits=c(-0.3,2.6), breaks = log10( ax.breaks ), labels = ax.labels ) +
	scale_y_continuous( limits=c(-0.3,3.5), breaks = log10( ax.breaks ), labels = ax.labels ) +
	labs( x = expression( max[act] ), y = expression( lambda[act] ), fill = "Median fitness", color = "Generation" ) +
	coord_fixed() +
	geom_path( aes( color = gen ) ) +
	scale_fill_gradient( "fitness" ) +
	scale_colour_gradient( "generation", low = "white", high = "red", breaks=seq(0,max(d2$gen),50), limits=c(0,max(d2$gen)) ) +
	guides(fill = guide_colourbar(barwidth = 0.5, barheight = 2)) +
	guides(color = guide_colourbar(barwidth = 0.5, barheight = 2)) +
	mytheme + theme(
		legend.position = "right",
		legend.title = element_text(),
		legend.margin=margin(0,0,0,0),
	        legend.box.margin=margin(-10,-10,-10,-8)
	)

ggsave( outfile, width = 6, height = 5, units="cm" )
