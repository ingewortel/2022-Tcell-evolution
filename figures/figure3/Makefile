.SECONDARY:
.DELETE_ON_ERROR:

all : figure3.pdf

simulation-data : 

# =============================== SETTINGS =====================================
# Get other make variables from a general configuration file.
include ../settings.env

# Specific for this figure:
#
OPTMACT=50
OPTLACT=1165

# path to here from ../scripts/simulation/ where scripts are
pathToHere=../../figure3

# ================================ FIGURE ======================================

figure3.pdf : latex/figure3.pdf
	cp $< $@

latex/figure3.pdf : latex/figure3.tex plots/F3panelA-FL-trajectory.pdf \
	plots/F3panelA-speed-persistence.pdf plots/F3panelB-speed-persistence.pdf
	cd latex && latexmk -pdf figure3.tex && cp figure3.pdf ../ ;\
	latexmk -c



# =============================== PANEL A =======================================

# Step 1: create the correct settings file from the ../conf/ folder, replacing its
# runtime with the runtime defined in settings.env.
settings/autoconf-2D.js : ../conf/conf-2D.js | settings
	cat $< | awk -v t=$(RUNTIME) '/RUNTIME/ {b="\t\tRUNTIME : "t",";sub($$0,b)} {print}' > $@

# Step 2: use the python wrapper script to perform the simulations along different
# points in the trajectory.
progress/tracks-2D-traj : ../scripts/simulation/track-wrapper.py \
	../scripts/simulation/simple-track.js settings/autoconf-2D.js settings/traj.txt | \
	progress data/tracks
	python3 $< ../scripts/simulation/simple-track.js $(pathToHere)/settings/autoconf-2D.js settings/traj.txt $(NSIM) CPM2D $(MAXPROCESSORS) && \
	touch $@

# Step 3: analyze the output tracks
data/CPM2D-speedpersistence-traj.txt : ../scripts/analysis/analysis-wrapper.py \
	 settings/traj.txt progress/tracks-2D-traj | settings 
	python3 $< settings/traj.txt $(NSIM) CPM2D $(GROUPSIZE) $(MAXPROCESSORS) $@

# Step 4: plot
plots/F3panelA-speed-persistence.pdf : ../scripts/plotting/plot-traject-speed-persistence.R data/CPM2D-speedpersistence-traj.txt settings/traj.txt | plots
	Rscript $^ $@

plots/F3panelA-FL-trajectory.pdf : ../scripts/plotting/plot-FL.R ../figure2/data/evolution-free-combined.txt settings/traj.txt settings/optrange.txt | plots
	Rscript $< ../figure2/$(DIR)/evolution-free-combined.txt settings/traj.txt settings/optrange.txt plots/F3panelA-FL




# =============================== PANEL B =======================================


# Step 1: compute the range of parameters around the optimum
settings/optrange.txt : ../scripts/analysis/compute-optrange.R | settings
	Rscript $< $(OPTMACT) $(OPTLACT) $@

# Step 2: use the python wrapper script to perform the simulations along different
# points around the optimum.
progress/tracks-2D-opt : ../scripts/simulation/track-wrapper.py \
	../scripts/simulation/simple-track.js settings/autoconf-2D.js settings/optrange.txt | \
	progress data/tracks
	python3 $< ../scripts/simulation/simple-track.js $(pathToHere)/settings/autoconf-2D.js settings/optrange.txt $(NSIM) CPM2D $(MAXPROCESSORS) && \
	touch $@

# Step 3: analyze the output tracks
data/CPM2D-speedpersistence-opt.txt : ../scripts/analysis/analysis-wrapper.py \
	 settings/optrange.txt progress/tracks-2D-opt | settings 
	python3 $< settings/optrange.txt $(NSIM) CPM2D $(GROUPSIZE) $(MAXPROCESSORS) $@


# Step 4: second level of analysis, computing speed, persistence, and cell breaking per
# parameter combination
data/optimum-speedpersistence.Rdata : ../scripts/analysis/get-opt-speed-persistence.R \
	data/CPM2D-speedpersistence-opt.txt settings/optrange.txt | data
	Rscript $^ $(NSIM) CPM2D $@

# Step 5: plot
plots/F3panelB-speed-persistence.pdf : ../scripts/plotting/plot-opt-speed-persistence.R \
	data/optimum-speedpersistence.Rdata | plots
	Rscript $^ $@



data/tracks :
	mkdir -p $@

plots : 
	mkdir -p $@
	
progress :	
	mkdir -p $@

latex-clean : 
	rm -f latex/*.pdf
			
clean : latex-clean
	rm -f figure*.pdf && rm -rf data && rm -rf plots && rm -rf progress && rm -f settings/autoconf*.js settings/optrange.txt

