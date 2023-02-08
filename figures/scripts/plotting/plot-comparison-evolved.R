library( ggplot2 )
library( ggbeeswarm )
library( dplyr )
library( cowplot )
source("../scripts/plotting/mytheme.R")

argv <- commandArgs( trailingOnly = TRUE )

inst.free.data <- argv[1]
inst.skin.data <- argv[2]
free.sp.data <- argv[3]
skin.sp.data <- argv[4]
freeopt <- as.numeric( unlist( strsplit( argv[5], " " ) ) )
skinopt <- as.numeric( unlist( strsplit( argv[6], " " ) ) )
outname <- argv[7]

# Load instantaneous speed data
load( inst.free.data )
dfree <- data
dfree$tissue <- NA
dfree$exp <- "free"

load( inst.skin.data )
data$exp <- "skin"

d <- rbind( dfree, data )
d$cell <- paste0( d$exp, "-m", d$mact )

d$cell <- factor( d$cell, levels = c( paste0("skin-m", skinopt[1]), 
	paste0("free-m", freeopt[1]), paste0("free-m", skinopt[1]) ) )

# Plot instantaneous speeds
p1 <- ggplot( d, aes( x = cell, y = v ) ) +
	geom_violin( fill = "gray", color = NA ) +
	labs( y = "inst. speed\n(pixels/MCS)" ) +
	scale_y_continuous( limits=c(0,0.4), expand=c(0,0) )+
	geom_boxplot( outlier.shape = NA, size = 0.3, width = 0.4 ) +
	mytheme +
	theme( axis.text.x = element_blank(),
		axis.title.x = element_blank(),
		plot.margin = unit(c(0.3, 0.3, 0.05, 0.3), "cm") )

# load speed persistence data
dfree <- read.table( free.sp.data, header = TRUE )
dfree$tissue <- NA

dfree1 <- dfree[ dfree$mact == freeopt[1] & dfree$lact == freeopt[2] , ]
dfree1$cell <- paste0( "free-m", unique( dfree1$mact ) )
dfree2 <- dfree[ dfree$mact == skinopt[1] & dfree$lact == skinopt[2] , ]
dfree2$cell <- paste0( "free-m" , unique( dfree2$mact ) )

dfree <- rbind( dfree1, dfree2 )

dskin <- read.table( skin.sp.data, header = TRUE )
dskin <- dskin[ dskin$mact == skinopt[1] & dskin$lact == skinopt[2] , ]
dskin$cell <- paste0( "skin-m", unique( dskin$mact ) )


sp <- rbind( dfree, dskin )
sp$cell <- factor( sp$cell, levels = c( paste0("skin-m", skinopt[1]), 
	paste0("free-m", freeopt[1]), paste0("free-m", skinopt[1]) ) )

smean <- sp %>% group_by( cell ) %>% summarise( phalf = mean(phalf, na.rm=TRUE) ) 


p2 <- ggplot( sp, aes( x = cell, y = phalf ) ) +
	geom_quasirandom( size = 0.5 ) +
	scale_y_log10( limits=c(5,10000), expand=c(0,0) ) +
	labs( y = "persistence\ntime (MCS)" ) +
	geom_segment( data = smean, aes( x = as.numeric(cell) - 0.35, xend = as.numeric(cell) + 0.35, y = phalf, yend = phalf ), size = 0.3 ) +
	mytheme +
	theme( axis.text.x = element_blank(),
		axis.title.x = element_blank(),
		plot.margin = unit(c(0.4, 0, 0, 0), "cm"))

m <- matrix( c("skin","free","skin","skin","free","free" ), nrow = 2, ncol = 3, byrow = TRUE )
colnames(m) <- levels( sp$cell )
rownames(m) <- c("evolution:","analysis:" )

ann <- as.data.frame.table( m )

pa <- ggplot( ann, aes( x = Var2, y = Var1 ) ) +
	geom_text( aes( label = Freq ), size = 2.8 ) +
	labs( x = NULL, y = NULL ) +
	mytheme +
	theme( axis.line.x = element_blank(),
		axis.line.y = element_blank(),
		axis.text.x = element_blank(),
		axis.ticks = element_blank(),
		plot.margin = unit(c(0, 0, 0.1, 0), "cm") ) 


p <- plot_grid( plotlist=list( p1,p2,pa), 
		labels = NULL, align="v", ncol = 1, rel_heights=c(1,1,0.5) ) 


ggsave(outname, width = 5, height = 5, units="cm")


