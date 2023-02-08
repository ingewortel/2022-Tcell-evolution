import sys
import multiprocess as mp
import numpy as np
import pandas as pd
from Naked.toolshed.shell import execute_js
from os import path

""" 
	=========================== settings ===========================
"""

# Settings from command line
simulationScript = sys.argv[1]
conf = sys.argv[2]
parms = sys.argv[3]
nsim = int( sys.argv[4] )
expName = sys.argv[5]
maxProcessors = int( sys.argv[6] )


# Some other initial settings
nProcessors = mp.cpu_count()
if nProcessors > maxProcessors:
	nProcessors = maxProcessors


""" 
	=========================== Functions ===========================
"""


""" Function to run the node script at given parameters.
"""
def run_node_free( parms ):
	id = parms[0]
	mact = parms[1]
	lact = parms[2]
	outfile = "data/tracks/" + expName + "-lact" + str(lact) + "-mact" + str(mact) + "-sim" + str(id) + ".txt"
	argstring = "-s " + conf + " -m " + str(mact) + " -l " + str(lact) + " -n " + str(id) + " > " + outfile
	if path.exists(outfile):
		# do nothing, the file already exists.
		pass
	else:
		success = execute_js( simulationScript, argstring )
		if success:
			pass
		else:
			raise NameError("error in node: " + argstring )

def run_node_skin( parms ):
	id = parms[0]
	mact = parms[1]
	lact = parms[2]
	tissuetype = parms[3]
	outfile = "data/tracks/" + expName + "-lact" + str(lact) + "-mact" + str(mact) + "-tissue" + tissuetype + "-sim" + str(id) + ".txt"
	argstring = "-s " + conf + " -m " + str(mact) + " -l " + str(lact) + " -t " + tissuetype + " -n " + str(id) + " > " + outfile
	if path.exists(outfile):
		# do nothing, the file already exists.
		pass
	else:
		success = execute_js( simulationScript, argstring )
		if success:
			pass
		else:
			raise NameError("error in node: " + argstring )


def run_node(parms) :
	if expName == "CPM2D" :
		run_node_free( parms )
	elif expName == "CPMskin" :
		run_node_skin( parms )
	else : 
		raise NameError( "unknown expname" )



""" Parallel computation of the simulations at a given parameter combination
"""
def run_all( theParms ):
	
    with mp.Pool( nProcessors ) as pool:
        result = pool.imap( run_node, theParms.itertuples(name=None), chunksize = 2 )
        output = pd.DataFrame()
        sims = 0
        for x in result:
            sims = sims+1
    print( "..." + str(sims) + " simulations done at params: " + theParms.iloc[[0]].to_string( header = False, index = False ) )


"""
    =========================== SCRIPT ===========================
"""

# Read the parameter file
parmTable = pd.read_table( parms, header = None, sep = " " )


# Loop over the settings in this file line by line, and call the function
# run_node() to take care of running the appropriate number of simulations, etc.
for i in range(0,len(parmTable)):
	theParms = parmTable.loc[[i]]
	theParms = pd.concat( [theParms]*nsim, ignore_index=True )
	run_all( theParms )



