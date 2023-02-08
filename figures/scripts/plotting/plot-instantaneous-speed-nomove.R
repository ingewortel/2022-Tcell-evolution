library( dplyr, warn.conflict = FALSE )
library( ggplot2 )
source("../scripts/plotting/mytheme.R")

argv <- commandArgs( trailingOnly = TRUE )

datafile <- argv[1]
outplot <- argv[2]

# Load data and create the variable for generating the facet labels:
load( datafile )
#data <- sample_n( data, nrow(data)/100 )
data$mact2 <- factor( data$mact, labels = paste0( "max[act] : ",levels(factor(data$mact))))

# Remove all observations with a connectivity below 100 from the instantaneous step data. These can cause artefacts from cell breaking.
remove.rows <- data$conn < 1
print( paste0( "WARNING --- Removing ", sum(remove.rows), " rows from data with broken cells..." ) )
data <- data[ !remove.rows, ]

# For each max act value, generate positions for the corresponding range of lambda act values.
# used later for plotting by geom_text
data2 <- data.frame()
annotationdata <- data.frame()
	for( m in unique( data$mact ) ){
		 dtmp <- data %>% filter(mact == m ) %>% as.data.frame()
		 dtmp$lact2 <- ( dtmp$lact - min(dtmp$lact) ) / ( max( dtmp$lact ) - min(dtmp$lact) )
  
		adtmp <- data.frame(  
                       mact = m,
		       mact2 = unique( dtmp$mact2 ),
			lact = unique( dtmp$lact ), 
                       lact2 = unique( dtmp$lact2),
		       v = 0.95*max(dtmp$v) )
  		data2 <- rbind( data2, dtmp)
  		annotationdata <- rbind( annotationdata, adtmp )
	}	

annotationdata2 <- annotationdata %>% 
  group_by( mact, mact2 ) %>%
  summarise( v = mean(v) )

# Create the plot


p <- ggplot( data2, aes( x = factor(lact), y = v, group = lact) ) + 
  geom_violin(show.legend=FALSE, color = NA, fill = "gray" ) +
  geom_boxplot( outlier.size = 0 ) +  
  labs( 	y = "Instantaneous speed\n(pixels/MCS)",
         x = expression(lambda[act]) ) +
  scale_y_continuous( limits=c(0,NA),expand=c(0,0) ) +
  # sizes in geom_text are in mm = 14/5 pt, so multiply textsize in pt with 5/14 to get
  # proper size in geom_text.
  mytheme + theme(
    legend.position = "right",
    axis.line.x = element_blank(),
    panel.spacing.x = unit(1, "lines")
  )

npanelrows <- 1
pwidth <- 6
pheight <- 4*npanelrows + 1

ggsave( outplot, width = pwidth, height = pheight, units="cm")
