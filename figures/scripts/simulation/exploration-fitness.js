/* Get command line arguments:
 *	-s [settingsfile] : 	file with the config object for the simulation;
 *	-m [max_act] :			max_act value (must be integer)
 *	-l [lambda_act] :		lambda_act value (must be integer)
 *	-n [simulation no]:		used as the seed of the random number generator used
 *							for this simulation.
 */

const args = require('minimist')(process.argv.slice(2));

const settingsfile = args.s
const mact = parseFloat( args.m )
const lact = parseFloat( args.l )
const simnum = parseInt( args.n )

const actCellKind = 1
const skinCellKind = 2


// Source the code and the settings
let CPM = require("../artistoo/build/artistoo-cjs.js")
let config = require( settingsfile )

// adjust settings with input parameters
config.conf["MAX_ACT"][actCellKind] = mact
config.conf["LAMBDA_ACT"][actCellKind] = lact
config.conf.seed = simnum


/* ==============================================================
 *							METHODS
 * ============================================================== */

/* Custom method to initialize the grid. This method is only used if
 * we are running a skin simulation, which is deduced from the config
 * object in the script at the bottom of this page.
*/

function initializeGrid(){
	
	// add the initializer if not already there
	if( !this.helpClasses["gm"] ){ this.addGridManipulator() }
	
	// Seed the right number of skin cells first. Seed them with a different 
	// perimeter to get a nice tissue, then reset params afterwards.
    const skin_p = this.C.conf.P[skinCellKind]
    this.C.conf.P[skinCellKind] = 200

    let totalcells = 0
    for( let i = 0; i <= this.conf.NRCELLS[skinCellKind-1]; i++ ){
        // First cell: always at the midpoint
        if( totalcells == 0 ){
            this.gm.seedCellAt( skinCellKind, this.C.midpoint )
            totalcells++
                
            // Each cell gets its own burnin phase, because this yields much nicer tissues.	
            for( let j = 0; j < 50; j++ ){
                this.C.monteCarloStep()	
            }
        } else {
        	this.gm.seedCell( skinCellKind )
            totalcells++
            for( let j = 0; j < 50; j++ ){
                this.C.monteCarloStep()	
            }
        }

        
    }
        
    // Simulate a burnin phase to let the tissue equilibrate further.
    for( let i = 0; i < this.conf.BURNIN; i++ ){
        this.C.monteCarloStep()
    }
       
    // replace the first skin cell with a T cell
    for( let i of this.C.cellIDs() ){
        this.C.setCellKind( i, actCellKind )
        break
    }

    // Reset skin cell perimeter to original value after seeding
    this.C.conf.P[skinCellKind] = skin_p
		
}

/* The postMCSListener will check if the cell is still connected, and 
 * will update the list of visited pixels. */
function postMCSListener() {
	
	let conn = sim.C.getStat( CPM.Connectedness )
		
	// The cell dies if it is too broken
	if( conn[ this.ID ] < 0.9 ){
		sim.died = true
	}
	
	// update the visited pixels
	this.updateVisited()
}



function updateVisited(){

	// Get the centroid of the migrating cell
	const centroids = this.C.getStat( CPM.CentroidsWithTorusCorrection )
	let centroid = centroids[ this.ID ]

	// correct centroid position: minimize distance to previous centroid.
	// this way, we keep track of the 'frame' where the cell is moving
	// by crossing boundaries on the periodic grid.
	centroid = this.correctCentroid( centroid )	
	this.previousCentroid = centroid

	// Loop over the pixels belonging to the migrating cell. If they were 
	// not yet marked as visited, do so now. For each pixel, try if coordinates
	// need correction (if the cell crosses a grid boundary, not all its pixels
	// lie in the same 'frame' as the centroid).
	const cp = this.C.getStat( CPM.PixelsByCell )
	const cellPixels = cp[ this.ID ]
	for( let j = 0; j < cellPixels.length; j++ ){
		
		// these are the "corrected" coordinates corresponding to the infinite
		// grid we are emulating with our periodic boundaries. So these 
		// coordinates really are unique such that a cell revisiting
		// [i,j] <after> crossing a boundary doesn't again get coordinates [i,j],
		// but e.g. [i+fieldsize,j]. 
		let pixel = this.correctPixel( cellPixels[j], centroid )
		const index = pixel[0] + "-" + pixel[1]
		this.visited[index] = 1
		
	}


}

/* Find the 'true' position of a centroid on the 'infinite' grid corresponding
 * to our real grid with linked boundaries. We use the cell's previous centroid
 * to do so, and we use the simulation's 'frame' property to check how many times
 * the cell has crossed a boundary on each side. 
 * E.g. a cell with a centroid of [5,50] on a 100x100 grid which has crossed the
 * right boundary once (frame = [1,0]), will get a corrected centroid at 
 * [105,50]. */
function correctCentroid( centroid ){

	// First correct into the last-known frame
	centroid[0] += this.frame[0]*this.C.extents[0]
	centroid[1] += this.frame[1]*this.C.extents[1]

	// Check if frame needs an update (this happens if the cell just
	// crossed the boundary). We only check this after correcting
	// the position into the last-known frame, because then the 
	// position and the previous centroid (which has been corrected as well)
	// are at most [gridsize] pixels apart.
	const result = this.correctPosition( centroid, this.previousCentroid )
	this.frame[0] += result[0]
	this.frame[1] += result[1]

	// For each grid dimension, 'result' is 0 if the frame has stayed the same,
	// and -1 or +1 if the frame has shifted to one side. The centroid needs 
	// updating according to the current frame.
	centroid[0] += result[0]*this.C.extents[0]
	centroid[1] += result[1]*this.C.extents[1]
	return centroid
}

/* Find the 'true' position of a pixel on the 'infinite' grid corresponding
 * to our real grid with linked boundaries. We use the cell's corrected centroid
 * to do so. */
function correctPixel( position, refpos ){

	// First correct coordinates according to the current frame.
	// Eg. imagine a cell on a 100x100 grid, which crosses a boundary for
	// the first time (the right boundary). Its x coordinate will drop from 
	// 99 back to 0. But the frame property will be updated from [0,0] to [1,0]. 
	// what we now want to store is not its position [0,y], because [0,y] in
	// frame [1,0] is not the same as [0,y] in frame [0,0]. What we therefore
	// store is xpos + frame x gridsize, so we store the position [100,y]
	// (which doesn't exist physically on our grid, but it is the position the
	// cell would have ended up in if it was truly on an infinite grid rather
	// than a periodic one).
	position[0] += this.frame[0]*this.C.extents[0]
	position[1] += this.frame[1]*this.C.extents[1]

	// The 'frame' tells us the frame where the current centroid is in. But 
	// a pixel belonging to that same cell may lie in a different frame if
	// the cell crosses a grid boundary. Here, check if the current pixel is
	// in a different frame than the centroid of its cell.
	const result = this.correctPosition( position, refpos )
	//const pixelFrame = [this.frame[0]+result[0], this.frame[1]+result[1]]

	// Update position accordingly
	position[0] += result[0]*this.C.extents[0]
	position[1] += result[1]*this.C.extents[1]
	return position
}

/* This function corrects a position on the grid with regard to some reference
 * position, which must be a position that we <know> is close to the
 * position we wish to correct. For example, the centroid of a cell should be 
 * close to the centroid in the previous step (since a cell cannot suddenly travel
 * across the grid). So if we find that a centroid has suddenly moved a 100 pixels
 * in the x dimension in a single step, we conclude that it must have crossed the
 * grid boundary because a CPM cell cannot travel that far in a single step.
 *
 * This assumption is valid as long as we <know> that
 * the distance between the position and its reference is small compared to the
 * grid dimensions. In the case of two subsequent centroid positions, this is
 * certainly true if the grid dimensions are larger than a few pixels.
 *
 * We also use this method to check if a pixel is in the same frame as the
 * centroid of its cell. In that case, we are assuming that the distance of any
 * pixel of a cell to the centroid is (much) smaller than the grid dimensions. 
 * In the current simulation, that assumption is also safe. 
 *
 * The return value of this function is an array with for each grid dimension
 * the frameshift of [position] with regard to [refpos]. E.g. if a cell has crossed
 * the right grid boundary, and we are calling this method to compare its current
 * centroid to its previous centroid, we get a frameshift of [1,0]. If it had
 * crossed the left boundary, we'd get [-1,0], and if it stayed in frame [0,0].
 */
function correctPosition( position, refpos ){

	let distx = Math.abs( position[0] - refpos[0] ) 
	let disty = Math.abs( position[1] - refpos[1] )
	let addframe=[0,0]

	// check in which frame the distance to the reference position is 
	// minimal (frame -1, frame 0 = current frame, or frame +1). For
	// both x and y dimension.
	for( xx = -1; xx <= 1; xx++ ){
		distx2 = Math.abs( position[0] + xx*this.C.extents[0] - refpos[0] )
		if( distx2 < distx ){
			distx = distx2
			addframe[0] = xx
		}
		disty2 = Math.abs( position[1] + xx*this.C.extents[1] - refpos[1] )
		if( disty2 < disty ){
			disty = disty2
			addframe[1] = xx
		}
	}

	// This now contains the correction we should apply to the frame to
	// minimize the distance to the reference position in each dimension.
	return addframe
}





/* ==============================================================
 *							THE SIMULATION
 * ============================================================== */


// Custommethods
let custommethods = {
	postMCSListener : postMCSListener,
	updateVisited : updateVisited,
	correctCentroid : correctCentroid,
	correctPosition : correctPosition,
	correctPixel : correctPixel
}

// Check if this is a skin simulation ( >1 non-bg cellkinds ). If so,
// we need to us the custom initializeGrid method as well.
if( config.simsettings.NRCELLS.length > 1 ){
    custommethods["initializeGrid"] = initializeGrid
}

// Construct the simulation object, which immediately initializes it.
let sim = new CPM.Simulation( config, custommethods )

// Save the cellID of the migrating act cell in 'sim.ID'; then get its centroid.
for( let cid of sim.C.cellIDs() ){
	if( sim.C.cellKind( cid ) == actCellKind ){
		sim.ID = cid
		break
	}
}
let centroids = sim.C.getStat( CPM.CentroidsWithTorusCorrection )
sim.previousCentroid = centroids[ sim.ID ]

// This array will track changes in 'frame' when the cell crosses grid boundaries.
sim.frame=[0,0]

// An object to track the visited pixels for computing fitness. It begins empty.
// Note that this is a slight underestimate of the visited pixels, since we only 
// update once every monte carlo step and do not track every individual 
// setpix event <during> a monte carlo step. But in general this should be quite
// a good approximation, since it only misses pixels if they happen to be added
// and removed from the cell within one step. This is already rare, and since we 
// are tracking the visited pixels during the entire simulation, a pixel missed in
// this way may still be added to our list during later steps. So we'll miss 
// some pixels, but only a few.
sim.visited = {}


// Let the simulation run.
for( let t = 0; t < sim.conf["RUNTIME"]; t++ ){
	if( sim.died ){
		break
	}
	sim.step()
} 


// At the end, compute fitness as number of pixels visited.
// Cells that died (from lack of connectedness) have fitness 0.
if( !sim.died ){
	console.log( Object.keys( sim.visited ).length )
} else {
	console.log( 0 )
}

