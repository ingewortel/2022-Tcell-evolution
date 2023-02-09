.SECONDARY:
.DELETE_ON_ERROR:

all : figure4.pdf

simulation-data : data/free-instantaneous.Rdata data/skin-instantaneous.Rdata data/evolution-skin-combined.txt data/evolution-free-combined.txt data/CPM2D-speedpersistence-opt.txt data/CPMskin-speedpersistence-opt.txt

# =============================== SETTINGS =====================================

# Get other make variables from a general configuration file.
include ../settings.env

NUMGEN=15

# path to here from ../scripts/simulation/ where scripts are
pathToHere=../../figure4


# ================================ FIGURE ======================================

figure4.pdf : latex/figure4.pdf
	cp $< $@

latex/figure4.pdf : latex/figure4.tex  plots/F4panelA-tracks.pdf plots/F4panelC.pdf
	cd latex && latexmk -pdf figure4.tex && cp figure4.pdf ../ ;\
	latexmk -c


# =============================== PANEL A =======================================

# Step 1: create the correct settings file from the ../conf/ folder, replacing its
# runtime with the runtime defined in settings.env.
settings/autoconf-skin-evolution.js : ../conf/conf-skin-evolution.js  | settings
	cat $< | awk -v t=$(RUNTIME_evo) '/RUNTIME/ {b="\t\tRUNTIME : "t",";sub($$0,b)} {print}' > $@
	
settings/autoconf-2D-evolution.js : ../conf/conf-2D-evolution.js  | settings
	cat $< | awk -v t=$(RUNTIME_evo) '/RUNTIME/ {b="\t\tRUNTIME : "t",";sub($$0,b)} {print}' > $@


# Step 2: evolutionary runs with python. Python already parallelizes within each run.
# Also do the free cell again, but now from the same starting value of lambda_act.
evolution-data-skin : $(foreach i, $(runs), data/evolution-skin-$(i).txt )
data/evolution-skin-%.txt : ../scripts/simulation/evolutionary-algorithm.py \
	../scripts/simulation/exploration-fitness.js settings/autoconf-skin-evolution.js | data
	python3 $< ../scripts/simulation/exploration-fitness.js $(pathToHere)/settings/autoconf-skin-evolution.js $(LAMBDA) $(POPSIZE) $(NUMGEN) $(MACTSTART) $(LACTSTARTskin) $(MAXPROCESSORS) $* > $@

evolution-data-free : $(foreach i, $(runs), data/evolution-free-$(i).txt )
data/evolution-free-%.txt : ../scripts/simulation/evolutionary-algorithm.py \
	../scripts/simulation/exploration-fitness.js settings/autoconf-2D-evolution.js | data
	python3 $< ../scripts/simulation/exploration-fitness.js $(pathToHere)/settings/autoconf-2D-evolution.js $(LAMBDA) $(POPSIZE) $(NUMGEN) $(MACTSTART) $(LACTSTARTskin) $(MAXPROCESSORS) $* > $@


# Step 3: concatenate runs to a single file.
data/evolution-skin-combined.txt : $(foreach i, $(runs), data/evolution-skin-$(i).txt )
	for i in $(runs); do \
		cat data/evolution-skin-$$i.txt | awk -v sim=$$i 'NF > 1{print $$0, sim}';\
	done > $@
	
data/evolution-free-combined.txt : $(foreach i, $(runs), data/evolution-free-$(i).txt )
	for i in $(runs); do \
		cat data/evolution-free-$$i.txt | awk -v sim=$$i 'NF > 1{print $$0, sim}';\
	done > $@


# Step 4: plotting
# this also makes some plots for figure S2
settings/skin-optrange.txt : ../scripts/analysis/compute-optrange.R | settings
	Rscript $< $(OPTMACTSKIN) $(OPTLACTSKIN) settings/tmp.txt &&\
	cat settings/tmp.txt | awk '{print $$0,"stiff"}' > $@ && rm settings/tmp.txt

settings/free2-optrange.txt : ../scripts/analysis/compute-optrange.R | settings
	Rscript $< $(OPTMACT2) $(OPTLACT2) $@

plots/F4panelA-tracks.pdf : ../scripts/plotting/plot-evolution-skinvsfree.R \
	$(DIR)/evolution-skin-combined.txt $(DIR)/evolution-free-combined.txt \
	../figure2/$(DIR)/evolution-free-combined.txt settings/skin-optrange.txt settings/free2-optrange.txt | plots
	Rscript $< "skin free free2" $(DIR) plots/F4panelA
	
	
# =============================== PANEL C =======================================

# Step 1: create the correct settings file from the ../conf/ folder, replacing its
# runtime with the runtime defined in settings.env.
settings/autoconf-skin.js : ../conf/conf-skin.js  | settings
	cat $< | awk -v t=$(RUNTIME) '/RUNTIME/ {b="\t\tRUNTIME : "t",";sub($$0,b)} {print}' > $@
	
settings/autoconf-2D.js : ../conf/conf-2D.js  | settings
	cat $< | awk -v t=$(RUNTIME) '/RUNTIME/ {b="\t\tRUNTIME : "t",";sub($$0,b)} {print}' > $@

# Step 2: compute skin tracks at the skin-evolved optimum, and free tracks at the
# skin- and free-evolved optima.
progress/tracks-free : ../scripts/simulation/track-wrapper.py \
	../scripts/simulation/simple-track.js settings/autoconf-2D.js settings/skin-and-free-opt.txt | \
	progress data/tracks
	python3 $< ../scripts/simulation/simple-track.js $(pathToHere)/settings/autoconf-2D.js settings/skin-and-free-opt.txt $(NSIM) CPM2D $(MAXPROCESSORS) && \
	touch $@

progress/tracks-skin : ../scripts/simulation/track-wrapper.py \
	../scripts/simulation/skin-track.js settings/autoconf-skin.js settings/skin-opt.txt | \
	progress data/tracks
	python3 $< ../scripts/simulation/skin-track.js $(pathToHere)/settings/autoconf-skin.js settings/skin-opt.txt $(NSIM) CPMskin $(MAXPROCESSORS) && \
	touch $@


# Step 3: analyze the output tracks (speed and persistence)
data/CPM2D-speedpersistence-opt.txt : ../scripts/analysis/analysis-wrapper.py \
	settings/skin-and-free-opt.txt progress/tracks-free| settings 
	python3 $< settings/skin-and-free-opt.txt $(NSIM) CPM2D $(GROUPSIZE) $(MAXPROCESSORS) $@
	
data/CPMskin-speedpersistence-opt.txt : ../scripts/analysis/analysis-wrapper.py \
	 settings/skin-opt.txt progress/tracks-skin| settings 
	python3 $< settings/skin-opt.txt $(NSIM) CPMskin $(GROUPSIZE) $(MAXPROCESSORS) $@

# Step 3b: also analyze the instantaneous speeds in the output tracks
data/free-instantaneous.Rdata : ../scripts/analysis/analyze-instantaneous.R progress/tracks-free \
	settings/skin-and-free-opt.txt ../scripts/analysis/trackAnalysisFunctions.R
	Rscript $< CPM2D $(NSIM) settings/skin-and-free-opt.txt "mact lact" "2 1" 2 "150 150" $@
	
data/skin-instantaneous.Rdata : ../scripts/analysis/analyze-instantaneous.R progress/tracks-skin \
	settings/skin-opt.txt ../scripts/analysis/trackAnalysisFunctions.R
	Rscript $< CPMskin $(NSIM) settings/skin-opt.txt "mact lact tissue" "2 1 3" 2 "150 150" $@

# Step 4: plot
plots/F4panelC.pdf : ../scripts/plotting/plot-comparison-evolved.R \
	$(DIR)/free-instantaneous.Rdata $(DIR)/skin-instantaneous.Rdata \
	$(DIR)/CPM2D-speedpersistence-opt.txt $(DIR)/CPMskin-speedpersistence-opt.txt | plots
	Rscript $^ "$(OPTMACT2) $(OPTLACT2)" "$(OPTMACTSKIN) $(OPTLACTSKIN)" $@


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
	rm -f figure*.pdf && rm -rf data && rm -rf plots && rm -rf progress && \
	rm -f settings/autoconf* settings/*optrange.txt
