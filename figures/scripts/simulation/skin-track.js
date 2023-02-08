/* Get command line arguments:
 *	-s [settingsfile] : 	file with the config object for the simulation;
 *	-m [max_act] :			max_act value (must be integer)
 *	-l [lambda_act] :		lambda_act value (must be integer)
 *	-t [tissue] :			"deformable" or "stiff" tissue.
 *	-d [draw="none"] (opt):	if specified, images are saved under 
 *								data/img/[value]/[value]-t[time].png.
 *	-n [simulation no]:		used as the seed of the random number generator used
 *							for this simulation.
 */

const args = require('minimist')(process.argv.slice(2));

const settingsfile = args.s
const mact = parseInt( args.m )
const lact = parseInt( args.l )
const tissue = args.t
const imgsave = args.d || "none"
const simnum = parseInt( args.n )


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


if( tissue == "stiff" ){
	// do nothing. maintain settings in template.
} else if ( tissue == "deformable" ){
	config.conf["LAMBDA_P"][2] = 1
	config.conf["J"][2][2] = 2
} else {
	throw("Unknown tissue type " + tissue +", please choose 'stiff' or 'deformable'!")
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

// custom method to initialize the grid. This ensures that the skin tissue is first
// seeded properly. 
function initializeGrid(){
	
	// add the initializer if not already there
	if( !this.helpClasses["gm"] ){ this.addGridManipulator() }
		
	// Seed the right number of skin cells first.
	// Seed them with a different perimeter to get a nice tissue.
	// Reset params afterwards.
	const skin_p = this.C.conf.P[2]
	this.C.conf.P[2] = 200

	let totalcells = 0
	let cellkind = 1 // the skin cellkind

	for( let i = 0; i <= this.conf.NRCELLS[cellkind]; i++ ){
		// first cell always at the midpoint. Any other cells
		// randomly. Each cell gets its own burnn phase of 20 MCS, because this yields much nicer tissues.				
		if( totalcells == 0 ){
			this.gm.seedCellAt( cellkind+1, this.C.midpoint )
			totalcells++
			for( let j = 0; j < 50; j++ ){
				this.C.monteCarloStep()	
			}
		} else {
			this.gm.seedCell( cellkind+1 )
			totalcells++
			for( let j = 0; j < 50; j++ ){
				this.C.monteCarloStep()	
			}
		}
	}
	
	// Simulate the burnin phase to let the tissue equilibrate further.
	for( let i = 0; i < this.conf.BURNIN; i++ ){
		this.C.monteCarloStep()
	}
	
	// replace the first skin cell with a T cell
	let first = true
	for( let i of this.C.cellIDs() ){
		if( first ){
			this.C.setCellKind( i, 1 )
			first = false
		}
		if( !first ){
			break
		}
	}

	// Reset skin cell perimeter to original value after seeding
	this.C.conf.P[2] = skin_p
	
	
}




// Construct simulation object and run the simulation.
let sim = new CPM.Simulation( config, { 
	logStats : logStats,
	initializeGrid : initializeGrid
} )
sim.run()

