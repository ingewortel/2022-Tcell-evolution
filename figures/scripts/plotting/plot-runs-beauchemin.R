library(ggplot2)
library(dplyr, warn.conflict=FALSE)
library(patchwork)
source("../scripts/plotting/mytheme.R")
mytheme <- mytheme + theme( 
	panel.border = element_rect( fill = NA, colour = "black" ),
	axis.line.x = element_blank(),
	axis.line.y = element_blank()
)

argv <- commandArgs( trailingOnly = TRUE )

dataFile <- argv[1]
outplot <- argv[2]

d <- read.table( dataFile )

colnames(d) <- c("gen","ind","tfree","vfree","tpause","fitness", "sim")
d$gen <- d$gen + 1 


d$broken <- ifelse( d$fitness == 0, 1, 0 )

davg <- d %>% 
	group_by( gen, sim ) %>%
	summarise( 	
		tfree = mean(log10(tfree)),
		tpause = mean(log10(tpause)),
		vfree = mean(log10(vfree)) )



# nicer log10 axes
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
ax.labels <- as.character( ax.breaks )
ax.labels[ log10( ax.breaks ) %% 1 != 0 ] <- ""

limits.tfree <- c(floor(min(log10(d$tfree))), ceiling(max(log10(d$tfree))) )
limits.vfree <- c(floor(min(log10(d$vfree))), ceiling(max(log10(d$vfree))) )
limits.tpause <- c(floor(min(log10(d$tpause))), ceiling(max(log10(d$tpause))) )


# plot of all tracks compared
p1 <- ggplot( davg, aes( x = tfree, y = vfree, group = sim ) ) +
	geom_hline( yintercept = 0, color = "gray" ,lty  = 2 , size = .3 ) +
	geom_vline( xintercept = 0, color = "gray" ,lty  = 2 , size = .3 ) +
	geom_path( size=0.3, aes(color=gen), show.legend = FALSE ) +
	geom_point( data = davg[davg$gen == max(davg$gen),], size = 1 ) +
	scale_x_continuous( limits=limits.tfree, 
		breaks = log10( ax.breaks ), labels = ax.labels ) +
	scale_y_continuous( limits=limits.vfree, 
		breaks = log10( ax.breaks ), labels = ax.labels ) +
	labs( x = expression(t[free]), y = expression(v[free]) ) +	
	mytheme 

p2 <- ggplot( davg, aes( x = tfree, y = tpause , group = sim ) ) +
	geom_hline( yintercept = 0, color = "gray" ,lty  = 2 , size = .3 ) +
	geom_vline( xintercept = 0, color = "gray" ,lty  = 2 , size = .3 ) +
	geom_path( size=0.3, aes(color=gen), show.legend = FALSE ) +
	geom_point( data = davg[davg$gen == max(davg$gen),], size = 1 ) +
	scale_x_continuous( limits=limits.tfree, 
		breaks = log10( ax.breaks ), labels = ax.labels ) +
	scale_y_continuous( limits=limits.tpause, 
		breaks = log10( ax.breaks ), labels = ax.labels ) +
	labs( x = expression(t[free]), y = expression(t[pause]) ) +	
	mytheme 
	
p3 <- ggplot( davg, aes( x = tpause, y = vfree , group = sim ) ) +
	geom_hline( yintercept = 0, color = "gray" ,lty  = 2 , size = .3 ) +
	geom_vline( xintercept = 0, color = "gray" ,lty  = 2 , size = .3 ) +
	geom_path( size=0.3, aes(color=gen), show.legend = FALSE ) +
	geom_point( data = davg[davg$gen == max(davg$gen),], size = 1 ) +
	scale_x_continuous( limits=limits.tpause ,
		breaks = log10( ax.breaks ), labels = ax.labels ) +
	scale_y_continuous( limits=limits.vfree, 
		breaks = log10( ax.breaks ), labels = ax.labels ) +
	labs( x = expression(t[pause]), y = expression(v[free]) ) +	
	mytheme 



# again but not log scale
p1b <- ggplot( davg, aes( x = exp(tfree), y = exp(vfree), group = sim ) ) +
	geom_hline( yintercept = 1, color = "gray" ,lty  = 2 , size = .3 ) +
	geom_vline( xintercept = 1, color = "gray" ,lty  = 2 , size = .3 ) +
	geom_path( size=0.3, aes(color=gen), show.legend = FALSE ) +
	geom_point( data = davg[davg$gen == max(davg$gen),], size = 1 ) +
	scale_x_continuous(  ) +
	scale_y_continuous(  ) +
	labs( x = expression(t[free]), y = expression(v[free]) ) +	
	mytheme 

p2b <- ggplot( davg, aes( x = exp(tfree), y = exp(tpause) , group = sim ) ) +
	geom_hline( yintercept = 1, color = "gray" ,lty  = 2 , size = .3 ) +
	geom_vline( xintercept = 1, color = "gray" ,lty  = 2 , size = .3 ) +
	geom_path( size=0.3, aes(color=gen), show.legend = FALSE ) +
	geom_point( data = davg[davg$gen == max(davg$gen),], size = 1 ) +
	scale_x_continuous(  ) +
	scale_y_continuous(  ) +
	labs( x = expression(t[free]), y = expression(t[pause]) ) +	
	mytheme 
	
p3b <- ggplot( davg, aes( x = exp(tpause), y = exp(vfree) , group = sim ) ) +
	geom_hline( yintercept = 1, color = "gray" ,lty  = 2 , size = .3 ) +
	geom_vline( xintercept = 1, color = "gray" ,lty  = 2 , size = .3 ) +
	geom_path( size=0.3, aes(color=gen), show.legend = FALSE ) +
	geom_point( data = davg[davg$gen == max(davg$gen),], size = 1 ) +
	scale_x_continuous(  ) +
	scale_y_continuous(  ) +
	labs( x = expression(t[pause]), y = expression(v[free]) ) +	
	mytheme 

p <- p1 + p2 + p3 + p1b + p2b + p3b + plot_layout( ncol = 3 )

ggsave( outplot, plot = p, width = 15.5, height = 10, units="cm" )



