library( ggplot2 )
library( dplyr )
require( cowplot, quietly = TRUE, warn.conflicts = FALSE )
source("../scripts/plotting/mytheme.R")

argv <- commandArgs( trailingOnly = TRUE )

file <- argv[1]
outfile <- argv[2]

d <- read.table( file )

colnames(d) <- c("gen","ind","mact","lact","fitness", "sim")

nsim <- max( d$sim )
d$sim <- as.character(d$sim)
d$gen <- d$gen + 1 

d2 <- d %>%
	group_by( sim, gen ) %>%
	summarise( 	mu_mact = exp(mean(log(mact))), 
			mu_lact = exp(mean(log(lact))),
			mact_lo = exp(mean(log(mact)) + sd(log(mact))),
			mact_hi = exp(mean(log(mact)) - sd(log(mact))),
			lact_lo = exp(mean(log(lact)) + sd(log(lact))),
			lact_hi = exp(mean(log(lact)) - sd(log(lact)))  
 )


ax.breaks <- c( seq(0.01,0.1,0.01), seq(0.2,1,0.1), seq(2,10), seq(20,100,10), seq(200, 1000, 100), seq(2000,10000,1000) )
ax.labels <- as.character( ax.breaks )
ax.labels[ ( seq_along( ax.breaks ) - 1 ) %% 9 != 0 ] <- ""

# align multiple plots underneath each other

#cols <- c("1"="black","2"="red","3"="forestgreen","4"="blue","5"="maroon3")
#cols <- c("1"="gray","2"="gray","3"="gray","4"="black","5"="gray")
cols <- setNames( rep("gray",10), seq(1,10) )
cols["4"] <- "black"

p1 <- ggplot( d2, aes( x = gen, y = log10(mu_lact), group = sim, color = sim, fill = sim ) )
if( nsim > 1 ){
	p1 <- p1 + geom_line( data = d2[ d2$sim != "4", ], size = 0.3, show.legend=FALSE)
}
p1 <- p1 + geom_ribbon( data = d2[ d2$sim == "4", ], aes( ymin = log10(lact_lo), ymax = log10(lact_hi) ), color = NA, alpha = 0.3, show.legend=FALSE ) +
	geom_line( data = d2[ d2$sim == "4", ], show.legend = FALSE ) +
	scale_x_continuous( expand=c(0,0), limits=c(0,NA) ) +
	scale_y_continuous( limits=c(NA,3.5), breaks = log10(ax.breaks), labels = ax.labels ) +
	labs( x = "generation", y = expression( lambda[act] ) ) +
	scale_colour_manual( values = cols )+
	scale_fill_manual( values = cols )+
	mytheme +
	theme( axis.title.x = element_blank(),
	plot.margin = unit(c(0.3, 0.5, 0, 0.3), "cm") )

p2 <- ggplot( d2, aes( x = gen, y = log10(mu_mact), group = sim, color = sim, fill = sim  ) )
if( nsim > 1 ){
	p2 <- p2 + geom_line( data = d2[ d2$sim != "4", ], size = 0.3, show.legend=FALSE)
}
p2 <- p2 + geom_ribbon( data = d2[ d2$sim == "4", ], aes( ymin = log10(mact_lo), ymax = log10(mact_hi) ), alpha = 0.3 , color = NA, show.legend=FALSE )  +
	geom_line( data = d2[ d2$sim == "4", ], show.legend = FALSE ) +
	scale_colour_manual( values = cols )+
	scale_fill_manual( values = cols )+
	scale_x_continuous( expand=c(0,0), limits=c(0,NA) ) +
	scale_y_continuous( limits=c(NA,2.7), breaks = log10(ax.breaks), labels = ax.labels ) +
	labs( x = "generation", y = expression( max[act] ) ) +
	mytheme + theme(
		plot.margin = unit(c(0, 0.5, 0.3, 0.3), "cm")
	)
p <- plot_grid( plotlist = list(p1,p2), labels = NULL, align = "v", ncol = 1, rel_heights=c(0.9,1))



ggsave( outfile, width = 4.5, height=5, units="cm" )
