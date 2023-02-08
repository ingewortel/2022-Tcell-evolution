library(ggplot2)
library(dplyr,warn.conflict =FALSE)
library(cowplot)
source("../scripts/plotting/mytheme.R")
mytheme <- mytheme + theme( 
	panel.border = element_rect( fill = NA, colour = "black" ),
	axis.line.x = element_blank(),
	axis.line.y = element_blank()
)

argv <- commandArgs( trailingOnly = TRUE )

compwhich <- unlist(strsplit( argv[1], " " ) )
datadir <- argv[2]
outplot <- argv[3]


cellvolume <- 500
parms.skin <- read.table("settings/skin-optrange.txt")
parms.free <- read.table("../figure3/settings/optrange.txt")


# comparisons options
files <- c( "skin" = paste0( datadir, "/evolution-skin-combined.txt"),
			"free" = paste0( datadir, "/evolution-free-combined.txt"),
		"free2" = paste0( "../figure2/", datadir, "/evolution-free-combined.txt" )

load.files <- function( filename, expname ){
	d1 <- read.table( filename )
	colnames(d1) <- c( "gen", "ind", "mact", "lact", "area", "sim" )
	d1$exp <- expname
	return(d1)
}

d <- data.frame()
for( exp in compwhich ){
	dtmp <- load.files( files[exp], exp )
	d <- rbind( d, dtmp )
} 
d$broken <- ifelse( d$area == 0, 1, 0 )
#d$exp2 <- gsub( "small", "free", d$exp )
#d$exp2 <- gsub( "skin", "skin", d$exp2 )
d$exp2 <- d$exp #gsub( "2", "", d$exp )

davg <- d %>% 
	group_by( exp, exp2, gen, sim ) %>%
	summarise( 	mact = mean(log10(mact)),
			lact = mean(log10(lact)),
			area = mean(area) )

plotColors <- c( "free2"="gray70", "free" = "black", "skin"="forestgreen" )

# plot
ax.breaks <- c( seq(0.1,1,0.1), seq(2,10), seq(20,100,10), seq(200, 1000, 100), seq(2000,10000,1000) )
ax.labels <- as.character( ax.breaks )
ax.labels[ ( seq_along( ax.breaks ) - 1 ) %% 9 != 0 ] <- ""

zoom.window <- log10( c( 20,100,500,2500 ) )

dold <- davg %>% filter( exp == "free2" )
davg <- davg %>% filter( exp != "free2" )

# plot of all tracks compared
ptracks <- ggplot( davg, aes( x = mact, y = lact, color = exp2, group = interaction(sim,exp) ) ) +
	geom_path( data = dold, size=0.15, color = "gray70" ) +
	geom_path( size=0.15, alpha =0.8 ) +
	scale_x_continuous( limits=c(-0.5,2.7), 
		breaks = log10( ax.breaks ), labels = ax.labels ) +
	scale_y_continuous( limits=c(-0.7,3.5), 
		breaks = log10( ax.breaks ), labels = ax.labels ) +
	labs( x = expression(max[act]), y = expression(lambda[act]) ) +	
	annotate( "rect", xmin= zoom.window[1], xmax=zoom.window[2], ymin=zoom.window[3], ymax=zoom.window[4], fill = NA , color="black", size=0.2 ) +
	coord_fixed() +
	scale_color_manual( values = plotColors) +
 	guides(color = guide_legend(keywidth=0.75, keyheight=0.6)) +
	mytheme + theme(
		legend.position = c(0.95,0.01),
		legend.justification = c(1,0),	
	#legend.background=element_rect(fill="red"),
		#plot.background=element_rect(fill="red"),
		legend.margin=margin(0,0,0,0),
		plot.margin = unit(c(0.3,0.2,0.3,0.1),"cm")
	)

ggsave( paste0(outplot,"-tracks.pdf"), width =4.75 , height = 5, units="cm" )


# zoomed version for annotation:
colnames(parms.skin) <- c("mact","lact","lp")
parms.skin[,1:2] <- log10(parms.skin[,1:2])
parms.skin <- parms.skin %>% filter( mact == min(mact) | mact==max(mact) | lact == min(lact) | lact == max(lact) )
parms.skin$ann <- "mactfix"
parms.skin$ann[ !is.element( parms.skin$lact, range( parms.skin$lact ) )] <- "lactfix"

print('test')


colnames(parms.free) <- c("mact","lact")
parms.free <- log10(parms.free)
parms.free <- parms.free %>% filter( mact == min(mact) | mact==max(mact) | lact == min(lact) | lact == max(lact) )
parms.free$ann <- "mactfix"
parms.free$ann[ !is.element( parms.free$lact, range( parms.free$lact ) )] <- "lactfix"



ptracks <- ggplot( davg, aes( x = mact, y = lact, color = exp2, group = interaction(sim,exp) ) ) +
	geom_path( size=0.3 ) +
	annotate( "rect", xmin= zoom.window[1], xmax=zoom.window[2], ymin=zoom.window[3], ymax=zoom.window[4], fill = "white", alpha = 0.5 ) +
	scale_x_continuous( limits=c(-0.5,2.7), expand=c(0,0),
		breaks = log10( ax.breaks ), labels = ax.labels ) +
	scale_y_continuous( limits=c(-0.7,3.5), expand=c(0,0),
		breaks = log10( ax.breaks ), labels = ax.labels ) +
	labs( x = expression(max[act]), y = expression(lambda[act]) ) +	
	coord_fixed( xlim = zoom.window[1:2],ylim=zoom.window[3:4] ) +
	annotate( "point", x = median(parms.free$mact), y = median(parms.free$lact), size = 1, color = "gray30" )+
	annotate( "point", x = median(parms.skin$mact), y = median(parms.skin$lact), size = 1,
color = "forestgreen" ) +
	#geom_line( data = parms.free[parms.free$ann=="lactfix",], group=1, color="black") +
	#geom_line( data = parms.free[parms.free$ann=="mactfix",], group=1, color="black") +
	#geom_line( data = parms.skin[parms.skin$ann=="lactfix",], group=1, color="red") +
	#geom_line( data = parms.skin[parms.skin$ann=="mactfix",], group=1, color="blue") +
	scale_color_manual( values = plotColors) +
 	guides(color = "none") +
	mytheme + theme(
		axis.ticks = element_blank(),
		axis.title = element_blank(),
		axis.text = element_blank()
		#plot.background = element_rect( fill = "red" )
	)

ggsave( paste0(outplot,"-zoom.pdf"), width = 2.7 , height = 2.5, units="cm" )


ptracks <- ggplot( davg, aes( x = mact, y = lact, color = exp2, group = interaction(sim,exp) ) ) +
	geom_path( size=0.3 ) +
	annotate( "rect", xmin= zoom.window[1], xmax=zoom.window[2], ymin=zoom.window[3], ymax=zoom.window[4], fill = "white", alpha = 0.4 ) +
	scale_x_continuous( limits=c(-0.5,2.7), expand=c(0,0),
		breaks = log10( ax.breaks ), labels = ax.labels ) +
	scale_y_continuous( limits=c(-0.7,3.5), expand=c(0,0),
		breaks = log10( ax.breaks ), labels = ax.labels ) +
	labs( x = expression(max[act]), y = expression(lambda[act]) ) +	
	coord_fixed( xlim = zoom.window[1:2],ylim=zoom.window[3:4] ) +
	annotate( "point", x = median(parms.free$mact), y = median(parms.free$lact), size = 1 )+
	#geom_line( data = parms.free[parms.free$ann=="lactfix",], group=1, color="black") +
	#geom_line( data = parms.free[parms.free$ann=="mactfix",], group=1, color="black") +
	geom_line( data = parms.skin[parms.skin$ann=="lactfix",], group=1, color="red") +
	geom_line( data = parms.skin[parms.skin$ann=="mactfix",], group=1, color="blue") +
	scale_color_manual( values = plotColors) +
 	guides(color = "none") +
	mytheme + theme(
		axis.ticks = element_blank(),
		axis.title = element_blank(),
		axis.text = element_blank()
		#plot.background = element_rect( fill = "red" )
	)

ggsave( paste0(outplot,"-zoom2.pdf"), width = 2.7 , height = 2.5, units="cm" )


# plot of runs from free small cell (one sim for both startpoints)
davg <- rbind( davg, dold )
dsmall <- davg %>%
	filter( exp != "skin" ) %>%
	filter( sim == 4 )
fitness_small <- d %>%
	filter( exp != "skin" ) %>%
	#filter( sim == 4 ) %>%
	mutate( mact = log10(mact)) %>%
	mutate( lact = log10(lact)) %>%
	mutate( id = "x" )

psmall <- ggplot( dsmall, aes( x = mact, y = lact, group = interaction( sim, exp ) ) ) +
	stat_summary_hex( data = fitness_small, aes( z = area/cellvolume, group = id ), fun = "median" ) +
	geom_path( aes(color=gen, group = exp ) ) +
	scale_x_continuous( limits=c(-0.5,2.7), 
		breaks = log10( ax.breaks ), labels = ax.labels ) +
	scale_y_continuous( limits=c(-1,3.5), 
		breaks = log10( ax.breaks ), labels = ax.labels ) +
	labs( x = expression(max[act]), y = expression(lambda[act]) ) +	
	coord_fixed() +
	scale_colour_gradient( "generation", low = "white", high = "red", breaks=seq(0,200,50 )) +
	scale_fill_gradient( "fitness", breaks=seq(0,500,50) ) +
	guides(color = "none")+#guide_colourbar(barwidth = 0.5, barheight = 2)) +
	guides(fill = guide_colourbar(barwidth = 2.3, barheight = 0.5,title.position="top", title.vjust=-0.8, label.vjust=2)) +
	#annotate( "text", x = 2.5, y = 3.4, label="cell in skin", size = 2, hjust=1) +
	mytheme  + theme(
		legend.position = c(0.95,0.01),
		legend.justification = c(1,0),
		legend.direction = "horizontal",	
	#legend.background=element_rect(fill="red"),
		#plot.background=element_rect(fill="red"),
		legend.title = element_text(),
		legend.title.align=1,	
		legend.margin=margin(0,0,-2,0),
		plot.margin = unit(c(0.3,0.2,0.3,0.1),"cm"),
		legend.background = element_rect(fill="transparent")
	)

ggsave( paste0(outplot,"-free.pdf"), width =4.72 , height = 5.3, units="cm" )

# plot of FL + traject for skin
dskin <- davg %>%
	filter( exp == "skin" ) %>%
	filter( sim == 1 )
fitness_skin <- d %>%
	filter( exp == "skin" ) %>%
	#filter( sim == 1 ) %>%
	mutate( mact = log10(mact) ) %>%
	mutate( lact = log10(lact) )
pskin <- ggplot( dskin, aes( x = mact, y = lact, group = interaction( sim, exp ) ) ) +
	stat_summary_hex( data = fitness_skin, aes( z = area/cellvolume, group = exp ), fun = "median" ) +
	geom_path( aes(color=gen) ) +
	scale_x_continuous( limits=c(-0.5,2.7), 
		breaks = log10( ax.breaks ), labels = ax.labels ) +
	scale_y_continuous( limits=c(-1,3.5), 
		breaks = log10( ax.breaks ), labels = ax.labels ) +
	labs( x = expression(max[act]), y = expression(lambda[act]) ) +	
	coord_fixed() +
	scale_colour_gradient( "generation", low = "white", high = "red" ) +
	scale_fill_gradient( "fitness" ,breaks=c(0,20,40) ) +
	guides(color = "none")+#guide_colourbar(barwidth = 0.5, barheight = 2)) +
	guides(fill = guide_colourbar(barwidth = 2.3, barheight = 0.5,title.position="top", title.vjust=-0.8, label.vjust=2)) +
	#annotate( "text", x = 2.5, y = 3.4, label="cell in skin", size = 2, hjust=1) +
	mytheme  + theme(
		legend.position = c(0.95,0.01),
		legend.justification = c(1,0),
		legend.direction = "horizontal",	
	#legend.background=element_rect(fill="red"),
		#plot.background=element_rect(fill="red"),
		legend.title = element_text(),
		legend.title.align=1,	
		legend.margin=margin(0,0,-2,0)
	)


ggsave( paste0(outplot,"-skin.pdf"), width =4.75 , height = 5.3, units="cm" )
