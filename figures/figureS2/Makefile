.SECONDARY:
.DELETE_ON_ERROR:

all : figureS2.pdf

simulation-data : data/trajectTracks.Rdata data/msdfit.txt

# =============================== SETTINGS =====================================
# Get other make variables from a general configuration file.
include ../settings.env

# Specific for this figure:
#
# path to here from ../scripts/simulation/ where scripts are
pathToHere=../../figureS2

# ================================ FIGURE ======================================

figureS2.pdf : latex/figureS2.pdf
	cp $< $@

latex/figureS2.pdf : latex/figureS2.tex  plots/SF2panelA.pdf plots/SF2panelB.pdf
	cd latex && latexmk -pdf figureS2.tex && cp figureS2.pdf ../ ;\
	latexmk -c


# =============================== panel A =======================================

# Step 0a: points to compute msd for. Don't use the first point, where the cell isn't
# moving at all.
settings/traj-msd.txt : ../figure3/settings/traj.txt | settings
	cat $< | awk 'NR>1' > $@

# Step 0b: get data from figure 3, where points along the trajectory were simulated;
# link these data here.
progress/tracks-2D-traj : ../figure3/progress/tracks-2D-traj | data
	cd data && ln -s ../../figure3/data/tracks


# Step 1: collect tracks along the trajectory
# This also produces a plot plots/checkLoadedTracks.pdf, to see if everything is okay
# with torus correction etc.
data/trajectTracks.Rdata : ../scripts/analysis/collect-tracks.R settings/traj-msd.txt \
	progress/tracks-2D-traj | data plots
	Rscript $< settings/traj-msd.txt CPM2D $(NSIM) plots/checkLoadedTracks.pdf $@

# Step 2: fit the MSD curves
data/msdfit.txt : ../scripts/analysis/fit-msd.R data/trajectTracks.Rdata
	Rscript $^ $@

# step 3: plot
plots/SF2panelA.pdf : ../scripts/plotting/plot-MSD-traject.R $(DIR)/msdfit.txt | plots
	Rscript $^ $@

# =============================== panel B =======================================

# check autocovariance curves
plots/SF2panelB.pdf : ../scripts/plotting/plot-acovs.R $(DIR)/trajectTracks.Rdata $(DIR)/msdfit.txt | plots
	 Rscript $< $(DIR)/trajectTracks.Rdata $(DIR)/trajectP.Rdata $@

# ============================ FOLDERS/OTHER ====================================
# Automatically generate the directory structure.

data :
	@mkdir -p $@

settings : 
	@mkdir -p $@

data/tracks :
	@mkdir -p $@
	
plots : 
	@mkdir -p $@
	
progress :
	@mkdir -p $@
	
latex-clean : 
	rm -f latex/*.pdf
	
clean : latex-clean
	rm -f figure*.pdf && rm -rf data && rm -rf plots && rm -rf progress
