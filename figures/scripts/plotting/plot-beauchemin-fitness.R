library( dplyr, warn.conflict=FALSE )
library( ggplot2 )
library( patchwork )
source("../scripts/plotting/mytheme.R" )


argv <- commandArgs( trailingOnly = TRUE )

inFile <- argv[1]
outPlot <- argv[2]


d <- read.table( inFile, header = FALSE )
colnames(d) <- c( "gen", "ind", "tfree","vfree","tpause","fitness", "sim" )

dsum <- d %>%
	group_by( gen, sim ) %>%
	mutate( fitness = fitness/500 ) %>%
	summarise( mu = mean(fitness), sd = sd(fitness), q25 = quantile(fitness,0.25), q75 = quantile(fitness,0.75) )
	

p1 <- ggplot( dsum, aes( x = gen, y = mu, group = sim ) ) +
	geom_vline( xintercept = 15, size = 0.2, lty = 2 ) +
	geom_line( size = 0.2 ) +
	scale_x_continuous( expand = c(0,0)) +
	scale_y_continuous( expand = c(0,0), limits = c(0,NA)) +
	labs( x = "generation", y = "fitness" ) +
	mytheme
	
p2 <- ggplot( dsum, aes( x = gen, y = mu, group = sim ) ) +
	geom_line( size = 0.2 ) +
	scale_x_continuous( expand = c(0,0), limits = c(0,15)) +
	scale_y_continuous( expand = c(0,0), limits = c(0,NA)) +
	labs( x = "generation", y = "fitness" ) +
	mytheme

p <- p1 + p2 + plot_layout( ncol = 1 )

ggsave( outPlot, width = 6, height = 6, units = "cm", useDingbats = FALSE )
