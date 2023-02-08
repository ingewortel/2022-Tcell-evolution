library(ggplot2)
library(dplyr, warn.conflict = FALSE)
library(cowplot)
source("../scripts/plotting/mytheme.R")
mytheme <- mytheme + theme( 
	panel.border = element_rect( fill = NA, colour = "black" ),
	axis.line.x = element_blank(),
	axis.line.y = element_blank(),
		legend.title = element_text(),
		#legend.background=element_rect(fill="red"),
		#plot.background=element_rect(fill="red"),
		legend.margin=margin(t=-0.6,unit="cm"),
		legend.box.margin=margin(c(0.3,0,-0.3,0),unit="cm"),
	plot.margin=margin(c(0.4,0.5,0,0.3),unit="cm"),
	
)

argv <- commandArgs( trailingOnly = TRUE )

infile <- argv[1]
outplot <- argv[2]

d <- read.table(infile)
colnames(d) <- c("gen","ind","mact","lact","fitness","run")


d$broken <- ifelse( d$fitness == 0, 1, 0 )
d$area <- d$fitness
d$area[ d$fitness == 0 ] <- NA


# plot
ax.breaks <- c( seq(1,10), seq(20,100,10), seq(200, 1000, 100), seq(2000,10000,1000) )
ax.labels <- as.character( ax.breaks )
ax.labels[ ( seq_along( ax.breaks ) - 1 ) %% 9 != 0 ] <- ""

sum(is.na(d$lact))

pfitness <- ggplot( d, aes( x = log10(mact), y = log10(lact) ) ) +
	stat_summary_2d( aes( z = fitness/500 ), fun = function(x) mean(x, na.rm=TRUE) ) +
	scale_x_continuous( limits=c(-0.3,2.6), 
		breaks = log10( ax.breaks ), labels = ax.labels ) +
	scale_y_continuous( limits=c(-0.7,3.5), 
		breaks = log10( ax.breaks ), labels = ax.labels ) +
	labs( x = expression(max[act]), y = expression(lambda[act]) ) +	
	coord_fixed() +
	scale_fill_gradient( "fitness", limits=c(1,NA)) +
	guides(fill = guide_colourbar(barwidth = 4, barheight = 0.5, title.position="top")) +
	#annotate( "text", x = 2.5, y = 3.4, label="cell in skin", size = 2, hjust=1) +
	mytheme 


d.area <- d[ !is.na(d$area), ]
range( d.area$area/100 )
sum(is.na(d.area))

parea <- ggplot( d.area, aes( x = log10(mact), y = log10(lact) ) ) +
	stat_summary_2d( aes( z = area/500 ),fun = function(x) mean(x, na.rm=TRUE) ) +
	scale_x_continuous( limits=c(-0.3,2.6), 
		breaks = log10( ax.breaks ), labels = ax.labels ) +
	scale_y_continuous( limits=c(-0.3,3.5), 
		breaks = log10( ax.breaks ), labels = ax.labels ) +
	labs( x = expression(max[act]), y = expression(lambda[act]) ) +	
	coord_fixed() +
	scale_fill_gradient( "area searched" ) +
	guides(fill = guide_colourbar(barwidth = 4, barheight = 0.5, title.position="top")) +
	#annotate( "text", x = 2.5, y = 3.4, label="cell in skin", size = 2, hjust=1) +
	mytheme 

pbroken <- ggplot( d, aes( x = log10(mact), y = log10(lact) ) ) +
	stat_summary_2d( aes( z = 100*broken ),fun = function(x) mean(x, na.rm=TRUE) ) +
	scale_x_continuous( limits=c(-0.3,2.6), 
		breaks = log10( ax.breaks ), labels = ax.labels ) +
	scale_y_continuous( limits=c(-0.3,3.5), 
		breaks = log10( ax.breaks ), labels = ax.labels ) +
	labs( x = expression(max[act]), y = expression(lambda[act]) ) +	
	coord_fixed() +
	scale_fill_gradient( "% cells broken", limits=c(1,NA), breaks=c(1,50,100) ) +
	guides(fill = guide_colourbar(barwidth = 4, barheight = 0.5, title.position="top")) +
	#annotate( "text", x = 2.5, y = 3.4, label="cell in skin", size = 2, hjust=1) +
	mytheme 


P <- plot_grid( plotlist=list( pfitness, parea, pbroken), labels = NULL, align="h", ncol = 3, rel_widths=c(1,1,1 ) )
ggsave( outplot, width =14 , height = 6, units="cm" )

