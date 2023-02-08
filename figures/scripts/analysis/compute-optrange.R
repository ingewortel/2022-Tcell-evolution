library( dplyr, warn.conflict = FALSE )

argv <- commandArgs( trailingOnly = TRUE )

optmact <- as.numeric( argv[1] )
optlact <- as.numeric( argv[2] )
outfile <- argv[3]

range <- seq( -0.3, 0.3, by = 0.1 )


mactRange <- round( exp( log(optmact) + range ) )
lactRange <- round( exp( log(optlact) + range ) )

parms1 <- expand.grid( mactRange, optlact )
parms2 <- expand.grid( optmact, lactRange )
parms <- rbind( parms1, parms2 )

parms <- parms %>% distinct()

write.table( parms, file = outfile, row.names = FALSE, quote = FALSE, col.names = FALSE )

#print(parms)

