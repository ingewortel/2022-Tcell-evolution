let config = {

	// Grid settings
	ndim : 2,
	field_size : [150,150],
	
	// CPM parameters and configuration
	conf : {
		// Basic CPM parameters
		torus : [true,true],				// Should the grid have linked borders?
		seed : 1,							// Seed for random number generation.
		T : 20,								// CPM temperature
		
		// Constraint parameters. 
		// Mostly these have the format of an array in which each element specifies the
		// parameter value for one of the cellkinds on the grid.
		// First value is always cellkind 0 (the background) and is often not used.
				
		// Adhesion parameters:
		J: [[0,20,20], [20,0,2],[20,2,200]],
		
		// VolumeConstraint parameters
		LAMBDA_V: [0,30,30],					// VolumeConstraint importance per cellkind
		V: [0,500,760],						// Target volume of each cellkind
		
		// PerimeterConstraint parameters
		LAMBDA_P: [0,2,10],					// PerimeterConstraint importance per cellkind
		P : [0,260,330],					// Target perimeter of each cellkind
		
		// ActivityConstraint parameters
		LAMBDA_ACT : [0,1500,0],			// ActivityConstraint importance per cellkind
		MAX_ACT : [0,40,0],					// Activity memory duration per cellkind
		ACT_MEAN : "geometric"				// Is neighborhood activity computed as a
											// "geometric" or "arithmetic" mean?

	},
	
	// Simulation setup and configuration
	simsettings : {
	
		// Cells on the grid
		NRCELLS : [0,30],					// Number of cells to seed for all
											// non-background cellkinds.
		// Runtime etc
		BURNIN : 500,
		RUNTIME : 50000,	// this gets overwritten in the simulation node scripts; 
							// please adjust this in settings.env.
		
		// Visualization
		CANVASCOLOR : "FFFFFF",
		CELLCOLOR : ["000000","eaecef"],
		ACTCOLOR : [true,false],			// Should pixel activity values be displayed?
		SHOWBORDERS : [false,true],			// Should cellborders be displayed?
		BORDERCOL : ["000000","AAAAAA"],
		zoom : 2,							// zoom in on canvas with this factor.
		
		// Output images
		SAVEIMG : false,					// Should a png image of the grid be saved
											// during the simulation?
		IMGFRAMERATE : 1,					// If so, do this every <IMGFRAMERATE> MCS.
		SAVEPATH : "data/img",				// ... And save the image in this folder.
		EXPNAME : "EXP",					// Used for the filename of output images.
		
		// Output stats etc
		STATSOUT : { browser: false, node: true }, // Should stats be computed?
		LOGRATE : 5								// Output stats every <LOGRATE> MCS.

	}
}

if( typeof module !== "undefined" ){
	module.exports = config
}
