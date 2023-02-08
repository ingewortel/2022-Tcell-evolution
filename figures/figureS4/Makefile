.SECONDARY:
.DELETE_ON_ERROR:

all : figureS4.pdf

simulation-data : data/instantaneous.Rdata data/optimum-speedpersistence.Rdata

# =============================== SETTINGS =====================================
# Get other make variables from a general configuration file.
include ../settings.env

# Specific for this figure:
# optimal parameters for skin evolution
OPTMACT=55
OPTLACT=1190


# overrule maxprocessors
MAXPROCESSORS=4

# path to here from ../scripts/simulation/ where scripts are
pathToHere=../../figureS4

# ================================ FIGURE ======================================

figureS4.pdf : latex/figureS4.pdf
	cp $< $@

latex/figureS4.pdf : latex/figureS4.tex plots/SF4panelA.pdf plots/SF4panelB.pdf plots/SF4panelC.pdf plots/SF4panelD.pdf
	cd latex && latexmk -pdf figureS4.tex && cp figureS4.pdf ../ ;\
	latexmk -c



# =============================== PANEL A =======================================

# Step 1: create the correct settings file from the ../conf/ folder, replacing its
# runtime with the runtime defined in settings.env.
settings/autoconf-skin.js : ../conf/conf-skin.js ../settings.env | settings
	cat $< | awk -v t=$(RUNTIME) '/RUNTIME/ {b="\t\tRUNTIME : "t",";sub($$0,b)} {print}' > $@

# Step 2: use the python wrapper script to perform the simulations at the starting point
# of the trajectory and at the control point with lact = 0.
progress/tracks-skin-start : ../scripts/simulation/track-wrapper.py \
	../scripts/simulation/skin-track.js settings/autoconf-skin.js settings/skin-start-comparison.txt | \
	progress data/tracks
	python3 $< ../scripts/simulation/skin-track.js $(pathToHere)/settings/autoconf-skin.js settings/skin-start-comparison.txt $(NSIM) CPMskin $(MAXPROCESSORS) && \
	touch $@

# Step 3: analyze the output tracks
data/instantaneous.Rdata : ../scripts/analysis/analyze-instantaneous.R progress/tracks-skin-start \
	settings/skin-start-comparison.txt ../scripts/analysis/trackAnalysisFunctions.R
	Rscript $< CPMskin $(NSIM) settings/skin-start-comparison.txt "mact lact tissue" "2 1 3" 2 "150 150" $@

# Step 4: plot
plots/SF4panelA.pdf : ../scripts/plotting/plot-instantaneous-speed-nomove.R $(DIR)/instantaneous.Rdata | plots
	Rscript $^ $@


# =============================== PANEL B =======================================
# Two of the required plots are actually made in figure 4.

plots/SF4panelB.pdf : ../figure4/plots/F4panelA-skin.pdf ../figure4/plots/F4panelA-free.pdf

# =============================== PANEL C =======================================

# panel B just replots the data from figure 4, but now merges info from different
# evolutionary runs and looks at exploration area, cell breaking, and fitness.
plots/SF4panelC.pdf : ../scripts/plotting/plot-FL-pooled.R ../figure4/$(DIR)/evolution-skin-combined.txt | plots
	Rscript $^ $@
	
	

# =============================== PANEL D =======================================
# Step 1: compute the range of parameters around the optimum
settings/optrange.txt : ../scripts/analysis/compute-optrange.R | settings
	Rscript $< $(OPTMACT) $(OPTLACT) settings/tmp.txt &&\
	cat settings/tmp.txt | awk '{print $$0,"stiff"}' > $@ && rm settings/tmp.txt

# Step 2: use the python wrapper script to perform the simulations along different
# points around the optimum.
progress/tracks-skin-opt : ../scripts/simulation/track-wrapper.py \
	../scripts/simulation/simple-track.js settings/autoconf-skin.js settings/optrange.txt | \
	progress data/tracks
	python3 $< ../scripts/simulation/skin-track.js $(pathToHere)/settings/autoconf-skin.js settings/optrange.txt $(NSIM) CPMskin $(MAXPROCESSORS) && \
	touch $@

# Step 3: analyze the output tracks
data/CPMskin-speedpersistence-opt.txt : ../scripts/analysis/analysis-wrapper.py \
	 settings/optrange.txt progress/tracks-skin-opt | settings 
	python3 $< settings/optrange.txt $(NSIM) CPMskin $(GROUPSIZE) $(MAXPROCESSORS) $@

# Step 4: second level of analysis, computing speed, persistence, and cell breaking per
# parameter combination
data/optimum-speedpersistence.Rdata : ../scripts/analysis/get-opt-speed-persistence.R \
	data/CPMskin-speedpersistence-opt.txt settings/optrange.txt | data
	Rscript $^ $(NSIM) CPMskin $@


plots/SF4panelD.pdf : ../scripts/plotting/plot-opt-speed-persistence.R $(DIR)/optimum-speedpersistence.Rdata | plots
	Rscript $^ $@




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
	rm -f figure*.pdf && rm -rf data && rm -rf plots && rm -rf progress && rm -f settings/autoconf* settings/optrange.txt
