import sys
import multiprocess as mp
import numpy as np
import pandas as pd
from Naked.toolshed.shell import muterun_js

""" 
	=========================== settings ===========================
"""

# Settings from command line
simulationScript = sys.argv[1]
conf = sys.argv[2]
nChild = int( sys.argv[3] )
nInd = int( sys.argv[4] )
nGen = int( sys.argv[5] )
mactStart = float( sys.argv[6] )
lactStart = float( sys.argv[7] )
maxProcessors = int( sys.argv[8] )
seed = int( sys.argv[9] ) # set the seed for an evolutionary run

# Some other initial settings
nProcessors = mp.cpu_count()
if nProcessors > maxProcessors:
	nProcessors = maxProcessors

SDstart = 0.6
SDmain = 0.2
SD = SDstart # will be reduced to SDmain after 5 generations
np.random.seed( seed )


""" 
	=========================== Functions ===========================
"""



""" Function to run the node script at given parameters.
    Eventually, this should also output the parameters and fitness to
    an output file.
"""
def get_fitness( parms ):
	id = parms[0]
	mact = parms[1]
	lact = parms[2]
	argstring = "-s " + conf + " -m " + str(mact) + " -l " + str(lact) + " -n " + str(id)
	response = muterun_js( simulationScript, argstring )
	if response.exitcode == 0:
		fitness = float( response.stdout.decode("utf-8") )
	else:
		print( response.stdout.decode("utf-8"))
		raise NameError("error in node: " + response.stderr.decode("utf-8"))
	d = pd.DataFrame( [[ g, id, mact, lact, fitness ]] )
	return d

""" Mutate the values in a dataframe column. This is done on logscale, so values never become negative.
    The SD is defined as a global variable, and the mutation is the current value + gaussian noise with 
    this SD.
"""
def mutate(values):
    logVal = np.log(values)
    mutation = np.random.normal(0, SD, logVal.size)
    return np.exp( logVal + mutation )


""" Initialize a population of nInd individuals, each with the same parameter values 
    (the starting values defined at the beginning of the script).
"""
def init_pop():
    pop = pd.DataFrame()
    pop = pd.concat( [pop, pd.DataFrame([[ mactStart, lactStart ]]) ], ignore_index = True, axis = 1 )
    pop = pd.concat( [pop]*nInd, ignore_index=True )
    return pop

""" At the beginning of each generation, the population expands because
    individuals produce children. For each individual, the current 
    individual is concatenated with nChild children (which are mutated
    versions of that individual - see mutate() function).
"""
def expand_pop(population):
    for ind in range(0,nInd):
        ind_data = population.iloc[[ind]]
        ind_data = pd.concat( [ind_data]*nChild, ignore_index=True )
        ind_data = ind_data.transform( lambda x: mutate(x) )
        population = pd.concat( [ population, ind_data], ignore_index = True )
    return population

""" The shrink_pop function computes fitness for each individual in the
    expanded population, then lets only the fittest nInd individuals
    survive for the next generation.
"""
def shrink_pop(population):
    
    # Compute fitnesses
    fitnessData = evaluate_fitness( population )

    # Select the fittest nInd individuals by sorting the dataframe on the fitness column
    # and then selecting the top nInd rows.
    # fitnessData cols: 0 = gen, 1 = individual id (seed), 2 = mact, 3 = lact, 4 = fitness
    fitnessData = fitnessData.sort_values( by = 4, ascending = False )
    
    # Print this generation to the console
    print(fitnessData.to_string( header = False, index = False ) )
    
    # Select the fittest individuals, and return their parameters as the next population.
    # fitnessData cols: 0 = gen, 1 = individual id (seed), 2 = mact, 3 = lact, 4 = fitness
    population = fitnessData.iloc[:nInd,:]
    population = population[[2,3]]
    return population

""" Parallel computation of the fitnesses of individuals in the current generation.
"""
def evaluate_fitness(population):
    with mp.Pool( nProcessors ) as pool:
        result = pool.imap( get_fitness, population.itertuples(name=None), chunksize = 2 )
        output = pd.DataFrame()
        for x in result:
            output=pd.concat( [output,x], ignore_index = True )
    return output


"""
    =========================== SCRIPT ===========================
"""

# Initialize the population

g = 0
population = init_pop()

# Run the generations one by one
for g in range(0,nGen):
    
    # Reduce the mutation SD in the fifth generation
    if g == 5:
    	SD = SDmain
    	  
    # Expand the population with mutated individuals
    population = expand_pop(population )
    
    # Evaluate fitness and shrink the population back to its
    # original size. 
    population = shrink_pop(population)



