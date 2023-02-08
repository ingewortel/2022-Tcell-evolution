.SECONDARY:
.DELETE_ON_ERROR:

all : figureS1.pdf

simulation-data : data/instantaneous.Rdata

# =============================== SETTINGS =====================================
# Get other make variables from a general configuration file.
include ../settings.env


# path to here from ../scripts/simulation/ where scripts are
pathToHere=../../figureS1

# ================================ FIGURE ======================================

figureS1.pdf : latex/figureS1.pdf
	cp $< $@

latex/figureS1.pdf : latex/figureS1.tex  plots/SF1panelA.pdf plots/SF1panelB.pdf
	cd latex && latexmk -pdf figureS1.tex && cp figureS1.pdf ../ ;\
	latexmk -c

# =============================== PANEL A =======================================

# Step 1: create the correct settings file from the ../conf/ folder, replacing its
# runtime with the runtime defined in settings.env.
settings/autoconf-2D.js : ../conf/conf-2D.js ../settings.env | settings
	cat $< | awk -v t=$(RUNTIME) '/RUNTIME/ {b="\t\tRUNTIME : "t",";sub($$0,b)} {print}' > $@

# Step 2: use the python wrapper script to perform the simulations at the starting point
# of the trajectory and at the control point with lact = 0.
progress/tracks-2D-start : ../scripts/simulation/track-wrapper.py \
	../scripts/simulation/simple-track.js settings/autoconf-2D.js settings/free-start-comparison.txt | \
	progress data/tracks
	python3 $< ../scripts/simulation/simple-track.js $(pathToHere)/settings/autoconf-2D.js settings/free-start-comparison.txt $(NSIM) CPM2D $(MAXPROCESSORS) && \
	touch $@

# Step 3: analyze the output tracks
data/instantaneous.Rdata : ../scripts/analysis/analyze-instantaneous.R progress/tracks-2D-start \
	settings/free-start-comparison.txt ../scripts/analysis/trackAnalysisFunctions.R
	Rscript $< CPM2D $(NSIM) settings/free-start-comparison.txt "mact lact" "2 1" 2 "150 150" $@


# Step 4: plot
plots/SF1panelA.pdf : ../scripts/plotting/plot-instantaneous-speed-nomove.R $(DIR)/instantaneous.Rdata | plots
	Rscript $^ $@



# =============================== PANEL B =======================================

# panel B just replots the data from figure 2, but now merges info from different
# evolutionary runs and looks at exploration area, cell breaking, and fitness.
plots/SF1panelB.pdf : ../scripts/plotting/plot-FL-pooled.R ../figure2/$(DIR)/evolution-free-combined.txt | plots
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
	rm -f figure*.pdf && rm -rf data && rm -rf plots && rm -rf progress && rm -f settings/autoconf*
