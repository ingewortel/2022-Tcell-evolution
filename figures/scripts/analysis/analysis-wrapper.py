import sys
import multiprocess as mp
import numpy as np
import pandas as pd
from Naked.toolshed.shell import execute
from os import path

""" 
	=========================== settings ===========================
"""

# Settings from command line
parms = sys.argv[1]
nsim = int( sys.argv[2] )
expName = sys.argv[3]
groupsize = int( sys.argv[4] )
maxProcessors = int( sys.argv[5] )
outFile = sys.argv[6]

# check that nsim is a multiple of groupsize

# Some other initial settings
nProcessors = mp.cpu_count()
if nProcessors > maxProcessors:
	nProcessors = maxProcessors


""" 
	=========================== Functions ===========================
"""

def analyze_skin(parms) : 
	mact = parms[1]
	lact = parms[2]
	tissue = parms[3]
	trackname =  "data/tracks/" + expName + "-lact" + str(lact) + "-mact" + str(mact) + "-tissue" + str(tissue) + "-sim"
	scriptname = "../scripts/analysis/analyze-speed-persistence-combined.R "
	parmstring = " 2 '" + str(lact) + " " + str(mact) + " " + str(tissue) + "' " + " 'lact mact tissue' "
	Rcommand = "Rscript " + scriptname + trackname + parmstring + str(nsim) + " " + str(groupsize) + " '150 150' " + expName
	command = Rcommand + " | awk 'NR>1' >> " + outFile #" | awk 'NR>1{print \$0}' > " + outFile
	success = execute( command )

def analyze_free(parms) : 
	mact = parms[1]
	lact = parms[2]
	trackname =  "data/tracks/" + expName + "-lact" + str(lact) + "-mact" + str(mact) + "-sim"
	scriptname = "../scripts/analysis/analyze-speed-persistence-combined.R "
	parmstring = " 2 '" + str(lact) + " " + str(mact) + "' " + " 'lact mact' "
	Rcommand = "Rscript " + scriptname + trackname + parmstring + str(nsim) + " " + str(groupsize) + " '150 150' " + expName
	command = Rcommand + " | awk 'NR>1' >> " + outFile #" | awk 'NR>1{print \$0}' > " + outFile
	success = execute( command )

def analyze(parms) :
	if expName == "CPM2D" :
		analyze_free( parms )
	elif expName == "CPMskin" :
		analyze_skin( parms )
	else : 
		raise NameError( "unknown expname" )

	

""" Parallel analysis of the simulations at a given parameter combination
"""
def run_analysis( theParms ):
	
    with mp.Pool( nProcessors ) as pool:
        result = pool.imap( analyze, theParms.itertuples(name=None), chunksize = 2 )
        output = pd.DataFrame()
        sims = 0
        for x in result:
            sims = sims+1
    print( "..." + " analyses done at params: " + theParms.iloc[[0]].to_string( header = False, index = False ) )


"""
    =========================== SCRIPT ===========================
"""

# Read the parameter file
parmTable = pd.read_table( parms, header = None, sep = " " )

# Print the first line with the column names
if expName == "CPM2D" :
	colNames = "lact mact group speed pexp phalf pintmean pintmedian"
elif expName == "CPMskin" :
	colNames = "lact mact tissue group speed pexp phalf pintmean pintmedian"
else : 
	raise NameError( "unknown expname" )
	
execute( "echo " + colNames + " > " + outFile )

# Run the analysis
run_analysis( parmTable )


