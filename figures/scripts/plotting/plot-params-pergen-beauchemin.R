library( ggplot2 )
library( dplyr, warn.conflict=FALSE )
library( patchwork )
source("../scripts/plotting/mytheme.R")

argv <- commandArgs( trailingOnly = TRUE )

file <- argv[1]
outfile <- argv[2]

d <- read.table( file )

colnames(d) <- c("gen","ind","tfree","vfree","tpause","fitness", "sim")

nsim <- max( d$sim )
d$sim <- as.character(d$sim)
d$gen <- d$gen + 1 

d2 <- d %>%
	group_by( sim, gen ) %>%
	summarise( 	
			mu_tfree = exp(mean(log(tfree))), 
			mu_vfree = exp(mean(log(vfree))),
			mu_tpause = exp(mean(log(tpause))),
			tfree_lo = exp(mean(log(tfree)) + sd(log(tfree))),
			tfree_hi = exp(mean(log(tfree)) - sd(log(tfree))),
			vfree_lo = exp(mean(log(vfree)) + sd(log(vfree))),
			vfree_hi = exp(mean(log(vfree)) - sd(log(vfree))),
			tpause_lo = exp(mean(log(tpause)) + sd(log(tpause))),
			tpause_hi = exp(mean(log(tpause)) - sd(log(tpause)))
 )


ax.breaks <- c( seq(0.01,0.1,0.01), seq(0.2,1,0.1), seq(2,10), seq(20,100,10), seq(200, 1000, 100), seq(2000,10000,1000) )
ax.labels <- as.character( ax.breaks )
ax.labels[ ( seq_along( ax.breaks ) - 1 ) %% 9 != 0 ] <- ""

limits.tfree <- c(floor(min(log10(d2$tfree_hi))), ceiling(max(log10(d2$tfree_lo))) )
limits.vfree <- c(floor(min(log10(d2$vfree_hi))), ceiling(max(log10(d2$vfree_lo))) )
limits.tpause <- c(floor(min(log10(d2$tpause_hi))), ceiling(max(log10(d2$tpause_lo))) )


# align multiple plots underneath each other

#cols <- c("1"="black","2"="red","3"="forestgreen","4"="blue","5"="maroon3")
#cols <- c("1"="gray","2"="gray","3"="gray","4"="black","5"="gray")
cols <- setNames( rep("gray",10), seq(1,10) )
cols["4"] <- "black"

p1 <- ggplot( d2, aes( x = gen, y = log10(mu_tfree), group = sim, color = sim, fill = sim ) )
if( nsim > 1 ){
	p1 <- p1 + geom_line( data = d2[ d2$sim != "4", ], size = 0.3, show.legend=FALSE)
}
p1 <- p1 + geom_ribbon( data = d2[ d2$sim == "4", ], aes( ymin = log10(tfree_lo), ymax = log10(tfree_hi) ), color = NA, alpha = 0.3, show.legend=FALSE ) +
	geom_line( data = d2[ d2$sim == "4", ], show.legend = FALSE ) +
	scale_x_continuous( expand=c(0,0), limits=c(0,NA) ) +
	scale_y_continuous( limits=limits.tfree, breaks = log10(ax.breaks), labels = ax.labels ) +
	labs( x = "generation", y = expression( t[free] ) ) +
	scale_colour_manual( values = cols )+
	scale_fill_manual( values = cols )+
	mytheme +
	theme( axis.title.x = element_blank(),
	plot.margin = unit(c(0.3, 0.5, 0, 0.3), "cm") )

p2 <- ggplot( d2, aes( x = gen, y = log10(mu_vfree), group = sim, color = sim, fill = sim  ) )
if( nsim > 1 ){
	p2 <- p2 + geom_line( data = d2[ d2$sim != "4", ], size = 0.3, show.legend=FALSE)
}
p2 <- p2 + geom_ribbon( data = d2[ d2$sim == "4", ], aes( ymin = log10(vfree_lo), ymax = log10(vfree_hi) ), alpha = 0.3 , color = NA, show.legend=FALSE )  +
	geom_line( data = d2[ d2$sim == "4", ], show.legend = FALSE ) +
	scale_colour_manual( values = cols )+
	scale_fill_manual( values = cols )+
	scale_x_continuous( expand=c(0,0), limits=c(0,NA) ) +
	scale_y_continuous( limits=limits.vfree, breaks = log10(ax.breaks), labels = ax.labels ) +
	labs( x = "generation", y = expression( v[free] ) ) +
	mytheme + theme(
		axis.title.x = element_blank(),
		plot.margin = unit(c(0, 0.5, 0, 0.3), "cm")
	)

p3 <- ggplot( d2, aes( x = gen, y = log10(mu_tpause), group = sim, color = sim, fill = sim ) )
if( nsim > 1 ){
	p3 <- p3 + geom_line( data = d2[ d2$sim != "4", ], size = 0.3, show.legend=FALSE)
}
p3 <- p3 + geom_ribbon( data = d2[ d2$sim == "4", ], aes( ymin = log10(tpause_lo), ymax = log10(tpause_hi) ), color = NA, alpha = 0.3, show.legend=FALSE ) +
	geom_line( data = d2[ d2$sim == "4", ], show.legend = FALSE ) +
	scale_x_continuous( expand=c(0,0), limits=c(0,NA) ) +
	scale_y_continuous( limits=limits.tpause, breaks = log10(ax.breaks), labels = ax.labels ) +
	labs( x = "generation", y = expression( t[pause] ) ) +
	scale_colour_manual( values = cols )+
	scale_fill_manual( values = cols )+
	mytheme +
	theme( 
	plot.margin = unit(c(0, 0.5, 0.3, 0.3), "cm") )

p <- p1 + p2 + p3 + plot_layout( ncol = 1, heights = c(0.9,0.9,1) )



ggsave( outfile, width = 6, height=9.5, units="cm" )
