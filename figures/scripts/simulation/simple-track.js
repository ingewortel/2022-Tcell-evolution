/* Get command line arguments:
 *	-s [settingsfile] : 	file with the config object for the simulation;
 *	-m [max_act] :			max_act value (must be integer)
 *	-l [lambda_act] :		lambda_act value (must be integer)
 *	-d [draw="none"] (opt):	if specified, images are saved under 
 *								data/img/[value]/[value]-t[time].png.
 *	-n [simulation no]:		used as the seed of the random number generator used
 *							for this simulation.
 *	-c [channel=false]:		with flag -c, a microchannel will be drawn on the grid.
 */

const args = require('minimist')(process.argv.slice(2));

const settingsfile = args.s
const mact = parseInt( args.m )
const lact = parseInt( args.l )
const imgsave = args.d || "none"
const simnum = parseInt( args.n )
const channel = args.c || false



let CPM = require("../artistoo/build/artistoo-cjs.js")
let config = require( settingsfile )


// update parameters in config
config.conf["MAX_ACT"][1] = mact
config.conf["LAMBDA_ACT"][1] = lact
config.conf.seed = simnum

if( imgsave === "none" ){
	config.simsettings.SAVEIMG = false
} else {
	config.simsettings.SAVEIMG = true
	config.simsettings.SAVEPATH = "data/img/" + imgsave
	config.simsettings.EXPNAME = imgsave
}


// Stat to compute percentage active pixels
class PercentageActive extends CPM.Stat {

	computePercentageOfCell( cellid, cellpixels  ){
	
		// get pixels of this cell
		const pixels = cellpixels[ cellid ]
		
		// loop over the pixels and count activities > 0
		let activecount = 0
		for( let i = 0; i < pixels.length; i++ ){
			const pos = this.M.grid.p2i( pixels[i] )
			if( this.M.getConstraint( "ActivityConstraint" ).pxact( pos ) > 0 ){
				activecount++
			}
		}
		
		// divide by total number of pixels and multiply with 100 to get percentage
		return ( 100 * activecount / pixels.length )
		
	}

	compute(){
		// Get object with arrays of pixels for each cell on the grid, and get
		// the array for the current cell.
		let cellpixels = this.M.getStat( CPM.PixelsByCell ) 
		
		// Create an object for the centroids. Add the centroid array for each cell.
		let percentages = {}
		for( let cid of this.M.cellIDs() ){
			percentages[cid] = this.computePercentageOfCell( cid, cellpixels )
		}
		
		return percentages
		
	}
}

// Custom method to log stats; this overwrites the default logStats()
// method of the CPM.Simulation class (which only computes centroids).
function logStats(){
		
	// compute centroids for all cells
	let centroids = this.C.getStat( CPM.CentroidsWithTorusCorrection )
	
	// compute connectedness for all cells
	let conn = this.C.getStat( CPM.Connectedness )
	
	// compute percentage of active pixels
	let pact = this.C.getStat( PercentageActive )
	
		
	for( let cid of this.C.cellIDs() ){
		if( this.C.cellKind( cid ) == 1 ){
		
			console.log( 
				this.time + "\t" + 
				cid + "\t" + 
				this.C.cellKind(cid) + "\t" + 
				centroids[cid].join("\t") + "\t" +
				conn[cid] + "\t" +
				pact[cid] )
			}
	
		}
}

// Custom version of initializeGrid that builds a microchannel
function initializeGrid(){
	
		// add the initializer if not already there
		if( !this.helpClasses["gm"] ){ this.addGridManipulator() }
	
		let nrcells = this.conf["NRCELLS"], cellkind, i
		this.buildChannel()
		
		// Seed the right number of cells for each cellkind
		for( cellkind = 0; cellkind < nrcells.length; cellkind ++ ){
			
			for( i = 0; i < nrcells[cellkind]; i++ ){
				// first cell always at the midpoint. Any other cells
				// randomly.				
				if( i == 0 ){
					this.gm.seedCellAt( cellkind+1, this.C.midpoint )
				} else {
					this.gm.seedCell( cellkind+1 )
				}
			}
		}
}

// Function to build the microchannel
function buildChannel(){
		
	
		this.channelvoxels = this.gm.makePlane( [], 1, 0 )
		let gridheight = this.C.extents[1]
		this.channelvoxels = this.gm.makePlane( this.channelvoxels, 1, gridheight-1 )
		
		this.gm.changeKind( this.channelvoxels, 2  )

		
}


// Construct simulation object, depending on if there should be a microchannel.
let sim
if( channel ){
	// If channel = true, overwrite initializeGrid so that a microchannel is
	// constructed before the simulation starts. 
	sim = new CPM.Simulation( config, { 
		logStats : logStats, 
		initializeGrid : initializeGrid,
		buildChannel : buildChannel 
	} )
} else {
	// Else just overwrite the logStats to get the proper statistics.
	sim = new CPM.Simulation( config, { logStats : logStats } )
}

sim.run()

