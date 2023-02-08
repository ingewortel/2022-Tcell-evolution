.SECONDARY:
.DELETE_ON_ERROR:

all : figure2.pdf

simulation-data : data/evolution-free-combined.txt

# =============================== SETTINGS =====================================
# Get other make variables from a general configuration file.
include ../settings.env

# Specific for this figure:
#
# path to here from ../scripts/simulation/ where scripts are
pathToHere=../../figure2

# ================================ FIGURE ======================================

figure2.pdf : latex/figure2.pdf
	cp $< $@

latex/figure2.pdf : latex/figure2.tex  plots/F2panelB.pdf plots/F2panelC.pdf cartoons/evo-setup.pdf
	cd latex && latexmk -pdf figure2.tex && cp figure2.pdf ../ ;\
	latexmk -c


# =============================== PANEL B =======================================

# Step 1: create the correct settings file from the ../conf/ folder, replacing its
# runtime with the runtime defined in settings.env.
settings/autoconf-2D-evolution.js : ../conf/conf-2D-evolution.js ../settings.env | settings
	cat $< | awk -v t=$(RUNTIME_evo) '/RUNTIME/ {b="\t\tRUNTIME : "t",";sub($$0,b)} {print}' > $@


# Step 2: evolutionary runs with python. Python already parallelizes within each run.
evolution-data : $(foreach i, $(runs), data/evolution-free-$(i).txt )
data/evolution-free-%.txt : ../scripts/simulation/evolutionary-algorithm.py \
	../scripts/simulation/exploration-fitness.js settings/autoconf-2D-evolution.js | data
	python3 $< ../scripts/simulation/exploration-fitness.js $(pathToHere)/settings/autoconf-2D-evolution.js $(LAMBDA) $(POPSIZE) $(NUMGEN) $(MACTSTART) $(LACTSTART) $(MAXPROCESSORS) $* > $@

# Step 3: concatenate runs to a single file.
data/evolution-free-combined.txt : $(foreach i, $(runs), data/evolution-free-$(i).txt )
	for i in $(runs); do \
		cat data/evolution-free-$$i.txt | awk -v sim=$$i 'NF > 1{print $$0, sim}';\
	done > $@

# Step 4: plotting.
plots/F2panelB.pdf : ../scripts/plotting/plot-params-pergen.R $(DIR)/evolution-free-combined.txt | plots
	Rscript $^ $@


plots/F2panelC.pdf : ../scripts/plotting/plot-parameter-evolution.R $(DIR)/evolution-free-combined.txt | plots
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
	rm -f figure*.pdf && rm -rf data && rm -rf plots && rm -rf progress && rm -rf settings
