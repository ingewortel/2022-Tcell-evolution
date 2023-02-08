library( ggplot2, warn.conflicts = FALSE )
library( grid, warn.conflicts = FALSE )

set_panel_size <- function(p=NULL, g=ggplotGrob(p), width=unit(3, "cm"), height=unit(3, "cm")){
  panel_index_w<- g$layout$l[g$layout$name=="panel"]
  panel_index_h<- g$layout$t[g$layout$name=="panel"]
  g$widths[[panel_index_w]] <- width
  g$heights[[panel_index_h]] <- height
  class(g) <- c("fixed", class(g), "ggplot")
  g
}

#General plotting theme
mytheme <-  theme_classic() +
  theme(
    line=element_line(size=2),
    text=element_text(size=8),
    axis.text=element_text(size=8),
    legend.position="top",
    legend.title=element_blank(),
    axis.line.x=element_line(size=0.25),
    axis.line.y=element_line(size=0.25),
    axis.ticks=element_line(size=0.25),
    strip.text = element_text(size=8),
    strip.background = element_rect(fill=NA,color=NA),
    plot.margin = unit(c(0.3,0.5,0.3,0.3),"cm")#trbl
  )		
