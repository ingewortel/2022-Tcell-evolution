library( ggplot2 )
library( dplyr, warn.conflict = FALSE )
source("../scripts/plotting/mytheme.R")
mytheme <- mytheme + theme( 
	axis.line.x = element_blank(),
	axis.line.y = element_blank(),
	axis.title = element_blank(),
	axis.ticks = element_blank(),
	axis.text = element_blank()
)

argv <- commandArgs( trailingOnly = TRUE )

file <- argv[1]
traject.file <- argv[2]
opt.file <- argv[3]
outfile <- argv[4]

# Read the data (for fitness info)
d <- read.table( file )
colnames(d) <- c( "gen","ind", "mact","lact","fitness", "run")
#d <- d %>% filter( run == 1 )


d2 <- d %>%
	group_by( gen ) %>%
	summarise( mact = exp(mean(log(mact))), lact = exp(mean(log(lact)) ) )



# Read the trajectory parameters (for annotation)
dtraj <- read.table( traject.file )
colnames(dtraj) <- c("mact","lact")
dtraj$point <- seq(1,nrow(dtraj))

# Read the params surrounding optimum (for annotation)
dopt <- read.table( opt.file )
colnames(dopt) <- c("mact","lact")
mact_opt <- log10( as.numeric( names( sort( table( dopt$mact ), decreasing = TRUE )[1] ) ) )
lact_opt <- log10( as.numeric( names( sort( table( dopt$lact ), decreasing = TRUE )[1] ) ) )
mact_range <- log10( range( dopt$mact ) )
lact_range <- log10( range( dopt$lact ) )

#print(dopt)
#print(mact_range)
#print(lact_range)


ax.breaks <- c( seq(1,10), seq(20,100,10), seq(200, 1000, 100), seq(2000,10000,1000) )
ax.labels <- as.character( ax.breaks )
ax.labels[ ( seq_along( ax.breaks ) - 1 ) %% 9 != 0 ] <- ""


p1 <- ggplot( d, aes( x = log10(mact), y = log10(lact) ) ) +
	stat_summary_2d( aes( z = fitness ), fun = "median", show.legend=FALSE, alpha = 0.4 ) +
	#geom_path( data = d2, aes( color = gen ), show.legend = FALSE ) +
	scale_x_continuous( limits=c(-0.3,2.6), breaks = log10( ax.breaks ), labels = ax.labels ) +
	scale_y_continuous( limits=c(-0.3,3.5), breaks = log10( ax.breaks ), labels = ax.labels ) +
	geom_segment( data = dtraj, aes( yend = log10(lact)), xend = log10(250), lty = 2, size = 0.2 ) +
	geom_point( data = dtraj, size = 0.2, color="black" ) +
	geom_label( data = dtraj, aes(label=point), x = log10(250), size=2.5, label.padding=unit(0.08,"lines") ) +
	#labs( x = expression( max[act] ), y = expression( lambda[act] ), fill = "Median fitness", color = "Generation" ) +
	coord_fixed() +
	mytheme

outfile1 <- paste0( outfile, "-trajectory.pdf" )
ggsave( outfile1, width = 4, height = 5, units="cm" )

p2 <- ggplot( d, aes( x = log10(mact), y = log10(lact) ) ) +
	stat_summary_2d( aes( z = fitness ), fun = "median", show.legend=FALSE, alpha = 0.4 ) +
	scale_x_continuous( limits=c(-0.3,2.6), breaks = log10( ax.breaks ), labels = ax.labels ) +
	scale_y_continuous( limits=c(-0.3,3.5), breaks = log10( ax.breaks ), labels = ax.labels ) +
	annotate( "segment", x = mact_opt, xend = mact_opt, y = lact_range[1], yend = lact_range[2], color = "red", size=0.5 ) +
	annotate( "segment", x = mact_range[1], xend = mact_range[2], y = lact_opt, yend = lact_opt, color = "blue", size=0.5 ) +
	#labs( x = expression( max[act] ), y = expression( lambda[act] ), fill = "Median fitness", color = "Generation" ) +
	coord_fixed(xlim=log10(c(15,200)), ylim=log10(c(50,5000))) +
	mytheme

outfile2 <- paste0( outfile, "-optimum.pdf" )
ggsave( outfile2, width = 3, height = 5, units="cm" )
