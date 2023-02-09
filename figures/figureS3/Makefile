.SECONDARY:
.DELETE_ON_ERROR:

all : figureS3.pdf

simulation-data : data/evolution-beauchemin-combined.txt

# =============================== SETTINGS =====================================
# Get other make variables from a general configuration file.
include ../settings.env

# Specific for this figure:
TFREESTART=1
VFREESTART=1
TPAUSESTART=1
# NUMGEN can be lower because the fitness has a maximum
NUMGEN=26
POPSIZE=10

#
# path to here from ../scripts/simulation/ where scripts are
pathToHere=../../figure-beauchemin

# ================================ FIGURE ======================================

figureS3.pdf : latex/figureS3.pdf
	cp $< $@

latex/figureS3.pdf : latex/figureS3.tex plots/SF3panelA.pdf plots/SF3panelB.pdf plots/SF3panelC.pdf plots/SF3panelD.pdf
	cd latex && latexmk -pdf figureS3.tex && cp figureS3.pdf ../ ;\
	latexmk -c

# ================================ PANELS ======================================


# Step 1: evolutionary runs with python. Python already parallelizes within each run.
evolution-data : $(foreach i, $(runs), data/evolution-beauchemin-$(i).txt )
data/evolution-beauchemin-%.txt : ../scripts/simulation/evolutionary-algorithm-beauchemin.py \
	../scripts/simulation/beauchemin-fitness.R  | data
	python3 $< ../scripts/simulation/beauchemin-fitness.R $(LAMBDA) $(POPSIZE) $(NUMGEN) $(TFREESTART) $(VFREESTART) $(TPAUSESTART) $(MAXPROCESSORS) $* > $@

# Step 2: concatenate runs to a single file.
data/evolution-beauchemin-combined.txt : $(foreach i, $(runs), data/evolution-beauchemin-$(i).txt )
	for i in $(runs); do \
		cat data/evolution-beauchemin-$$i.txt | awk -v sim=$$i 'NF > 1{print $$0, sim}';\
	done > $@

# Step 3: plotting.
plots/SF3panelB.pdf : ../scripts/plotting/plot-params-pergen-beauchemin.R $(DIR)/evolution-beauchemin-combined.txt | plots
	Rscript $^ $@

plots/SF3panelD.pdf : ../scripts/plotting/plot-parameter-evolution-beauchemin.R $(DIR)/evolution-beauchemin-combined.txt | plots
	Rscript $^ $@
	
plots/SF3panelC.pdf : ../scripts/plotting/plot-runs-beauchemin.R $(DIR)/evolution-beauchemin-combined.txt | plots
	Rscript $^ $@
	
plots/SF3panelA.pdf : ../scripts/plotting/plot-beauchemin-fitness.R $(DIR)/evolution-beauchemin-combined.txt | plots
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
	rm -f figure*.pdf && rm -rf data && rm -rf plots && rm -rf progress
