library( ggplot2 )
library( dplyr, quietly = TRUE, warn.conflicts = FALSE )
require( cowplot, quietly = TRUE, warn.conflicts = FALSE )
source("../scripts/plotting/mytheme.R")

argv <- commandArgs( trailingOnly = TRUE )

datafile <- argv[1]
outfile <- argv[2]

# Read datafile (called 'dtot')
load( datafile )
d.lactfix <- dtot %>% filter( fixed == "lact" )
d.mactfix <- dtot %>% filter( fixed == "mact" )

mact_opt <- unique( d.mactfix$mact )
lact_opt <- unique( d.lactfix$lact )



# Plotting: fixed lambda_act

ax.breaks <- d.lactfix$mact
ax.breaks <- ax.breaks[c(1,4,7)]
ax.labels <- as.character( ax.breaks )
pspeed <- ggplot( d.lactfix, aes( x = mact, y = m_speed ) ) +
	geom_ribbon( aes( ymin = m_speed - sd_speed, ymax = m_speed + sd_speed ), alpha = 0.3, color =NA ) +
	geom_point( size = 0.8, color="blue") +
	geom_path(color="blue") +
	geom_vline( xintercept = mact_opt, lty = 2 ) +
	labs( x = expression(max[act]), y = "mean speed\n(pixels/MCS)" ) +
	scale_x_log10(breaks=ax.breaks,labels=ax.labels)+
	scale_y_continuous( expand=c(0,0), limits=c(0,1.05*max(d.lactfix$m_speed)) ) +
	mytheme + theme(
		axis.text.x = element_blank(),
		axis.title.x = element_blank(),
		plot.margin = unit(c(0.3, 0, 0.1, 0.3), "cm")
	)

max.persis <- max( dtot$m_persistence )
ymax <- ifelse( max.persis < 1000, 200, 10000 )

ppersis <- ggplot( d.lactfix, aes( x = mact, y = m_persistence ) ) +
	geom_ribbon( aes( ymin = m_persistence - sd_persistence, ymax = m_persistence + sd_persistence ), alpha = 0.3, color = NA ) +
	geom_point( size = 0.8, color="blue") +
	geom_path(color="blue") +
	geom_vline( xintercept = mact_opt, lty = 2 ) +
	labs( x = expression(max[act]), y = "persistence\ntime (MCS)" ) +
	scale_x_log10(breaks=ax.breaks,labels=ax.labels)+
	scale_y_log10( expand=c(0,0), limits=c(5,ymax)) +
	mytheme + theme(
		axis.title.x = element_blank(),
		axis.text.x = element_blank(),
		plot.margin = unit(c(0.1, 0, 0, 0.3), "cm")
	)

pbreaking <- ggplot( d.lactfix, aes( x = mact, y = broken ) ) +
	geom_point( size = 0.8, color="blue") +
	geom_path(color="blue") +
	geom_vline( xintercept = mact_opt, lty = 2 ) +
	labs( x = expression(max[act]), y = "broken\ncells (%)" ) +
	scale_x_log10(breaks=ax.breaks,labels=ax.labels)+
	scale_y_continuous( expand=c(0,0), limits=c(0,100)) +
	mytheme + theme(
		axis.text.x = element_text( angle = 0 ),
		plot.margin = unit(c(0.15, 0, 0.3, 0.3), "cm")
	)

plact <- plot_grid( plotlist = list(pspeed,ppersis,pbreaking), labels = NULL, align = "v", ncol = 1, rel_heights=c(0.7,0.6,1))


# Plotting: fixed max_act

ax.breaks <- d.mactfix$lact
ax.breaks <- ax.breaks[c(1,4,7)]
ax.labels <- as.character( ax.breaks )
#ax.labels[ ( seq_along( ax.breaks ) - 1 ) %% 2 != 0 ] <- ""

pspeed <- ggplot( d.mactfix, aes( x = lact, y = m_speed ) ) +
	geom_ribbon( aes( ymin = m_speed - sd_speed, ymax = m_speed + sd_speed ), alpha = 0.3, color =NA ) +
	geom_point( size = 0.8, color="red") +
	geom_path(color="red") +
	geom_vline( xintercept = lact_opt, lty = 2 ) +
	labs( x = expression(lambda[act]), y = "mean speed\n(pixels/MCS)" ) +
	scale_x_log10( breaks = ax.breaks, labels = ax.labels )+
	scale_y_continuous( expand=c(0,0), limits=c(0,1.05*max(d.mactfix$m_speed ) ) ) +
	mytheme + theme(
		axis.title.x = element_blank(),
		plot.margin = unit(c(0.3, 0.5, 0.1, 0), "cm"),
		axis.text.x = element_blank(),
		axis.title.y = element_blank()
	)



ppersis <- ggplot( d.mactfix, aes( x = lact, y = m_persistence ) ) +
	geom_ribbon( aes( ymin = m_persistence - sd_persistence, ymax = m_persistence + sd_persistence ), alpha = 0.3, color = NA ) +
	geom_point( size = 0.8, color="red") +
	geom_path(color="red") +
	geom_vline( xintercept = lact_opt, lty = 2 ) +
	labs( x = expression(lambda[act]), y = "persistence\ntime (MCS)" ) +
	scale_x_log10(breaks = ax.breaks, labels = ax.labels ) +
	scale_y_log10( expand=c(0,0), limits=c(5,ymax)) +
	mytheme + theme(
		axis.title.x = element_blank(),
		plot.margin = unit(c(0.1, 0.5, 0, 0), "cm"),
		axis.text.x = element_blank(),
		axis.title.y = element_blank()
	)

pbreaking <- ggplot( d.mactfix, aes( x = lact, y = broken ) ) +
	geom_point( size = 0.8, color="red") +
	geom_path(color="red") +
	geom_vline( xintercept = lact_opt, lty = 2 ) +
	labs( x = expression(lambda[act]), y = "broken\ncells (%)" ) +
	scale_x_log10(breaks=ax.breaks,labels=ax.labels)+
	scale_y_continuous( expand=c(0,0), limits=c(0,100)) +
	mytheme + theme(
		axis.title.y = element_blank(),
		axis.text.x = element_text( angle = 0 ),
		plot.margin = unit(c(0.15, 0, 0.3, 0.3), "cm")
	)
pmact <- plot_grid( plotlist = list(pspeed,ppersis,pbreaking), labels = NULL, align = "v", ncol = 1, rel_heights=c(0.7,0.6,1))

p <- plot_grid( plotlist=list( plact, pmact), labels = NULL, align="h", ncol = 2, rel_widths=c(1,0.9 ) )


ggsave( outfile, width = 7.5, height=6, units="cm" )




