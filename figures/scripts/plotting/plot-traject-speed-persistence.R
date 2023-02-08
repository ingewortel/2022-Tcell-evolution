library( ggplot2 )
library( dplyr, quietly = TRUE, warn.conflicts = FALSE )
require( cowplot, quietly = TRUE, warn.conflicts = FALSE )
source("../scripts/plotting/mytheme.R")

argv <- commandArgs( trailingOnly = TRUE )

datafile <- argv[1]
paramfile <- argv[2] # Must be an ordered list of mact/lact params, ordered over the trajectory points.
outfile <- argv[3]

# Read datafile
d <- read.table( datafile, header=TRUE )


# Read file with params to check
parms <- read.table( paramfile )
colnames(parms) <- c("mact","lact" )
parms$id <- paste0(parms$mact,"-",parms$lact)
parms$point <- seq(1,nrow(parms))

print(parms)


# Filter these params from data
dsum <- d %>% 
	group_by( mact, lact ) %>%
	summarise( m_speed = mean(speed), m_persistence = mean(phalf,na.rm=TRUE), sd_speed = sd(speed), sd_persistence = sd(phalf,na.rm=TRUE) ) %>%
	as.data.frame()
rownames(dsum) <- paste0(dsum$mact,"-",dsum$lact)

print(dsum)


dtraject <- dsum[ parms$id, ]
dtraject$point <- seq(1,nrow(parms))

print( dtraject )


# Plotting
pspeed <- ggplot( dtraject, aes( x = point, y = m_speed ) ) +
	geom_ribbon( aes( ymin = m_speed - sd_speed, ymax = m_speed + sd_speed ), alpha = 0.3, color =NA ) +
	geom_point( size = 0.8) +
	geom_path() +
	labs( x = "trajectory point", y = "mean speed\n(pixels/MCS)" ) +
	scale_y_continuous( expand=c(0,0), limits=c(0,1.05*max(dtraject$m_speed)) ) +
	mytheme + theme(
		axis.title.x = element_blank(),
		plot.margin = unit(c(0.3, 0.5, 0, 0.3), "cm")
	)

ppersis <- ggplot( dtraject, aes( x = point, y = m_persistence ) ) +
	geom_ribbon( aes( ymin = m_persistence - sd_persistence, ymax = m_persistence + sd_persistence ), alpha = 0.3, color = NA ) +
	geom_point( size = 0.8 ) +
	geom_path() +
	labs( x = "trajectory point", y = "persistence\ntime (MCS)" ) +
	scale_y_log10( expand=c(0,0), limits=c(5,10000)) +
	mytheme + theme(
		plot.margin = unit(c(0, 0.5, 0.3, 0.3), "cm")
	)
p <- plot_grid( plotlist = list(pspeed,ppersis), labels = NULL, align = "v", ncol = 1, rel_heights=c(0.9,1))

ggsave( outfile, width = 4.5, height=6, units="cm" )







#ax.breaks <- c( seq(0.01,0.1,0.01), seq(0.2,1,0.1), seq(2,10), seq(20,100,10), seq(200, 1000, 100), seq(2000,10000,1000) )
#ax.labels <- as.character( ax.breaks )
#ax.labels[ ( seq_along( ax.breaks ) - 1 ) %% 9 != 0 ] <- ""

# align multiple plots underneath each other
#cols <- c("1"="black","2"="red","3"="forestgreen","4"="blue","5"="maroon3")

#	plot.margin = unit(c(0.3, 0.5, 0, 0.3), "cm") )
#plot.margin = unit(c(0, 0.5, 0.3, 0.3), "cm")



