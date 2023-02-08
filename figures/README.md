# Figure by figure code

## Prerequisites

### R and python

To use the code, please make sure you have the following installed:

- R (we tested using R version 4.2.1)

- python >v3.6, including the modules "Naked", "numpy", "pandas", and "multiprocess"
(you only need this if you plan to re-run simulations in bulk, see below)

You can do this manually or if you have conda, run:

```
conda env create -f environment.yml
conda activate cpm-evo
```

Naked is not in conda repositories so still has to be installed: 

```
pip3 install Naked
```

### Other dependencies


- Basic command line tools such as "make", "awk", "bc" etc. On MacOS, look for xcode CLT.
 On Linux, look for build-essential. On Windows, you may not be able to automatically 
 run the code, but you can still find and look through relevant scripts (see below on 
 how to read the Makefiles)
 
- To make the full figure pdfs you will need latex (including the tikz package). 
 
- nodejs and npm. See https://nodejs.org/en/download/.

Standard package managers sometimes install incompatible versions of npm and nodejs. 
To avoid this, you can install both at once using nvm:

```
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.2/install.sh | bash
nvm install --lts
nvm use --lts
```

### Node modules and R packages

After that, from the command line you can type:

```
make setup
```

This will also install the required node_modules (needed for simulations) and 
check if all the R packages are installed (if not, it will prompt you to install 
them automatically). Alternatively, R packages are listed in Rpackages.txt and can be installed
manually if you prefer. 


**Note: many figures in the paper used a `ggplot2` function `stat_summary_hex` to 
generate figures, but this function has a bug in the current ggplot2 release. 
This repository therefore uses `stat_summary_2d` instead. This changes nothing in the 
results but the plots may look slightly different. You can try replacing the code with 
`stat_summary_hex` depending on your version of ggplot (the bug will likely be fixed soon,
but for compatibility we use `stat_summary_2d` for now).**


## How it works

The directories each point directly to the corresponding (supplemental) figure in the
manuscript (except for figure 1, which consists of schematics only).

Once you have ensured your prerequisites are in order, you can go to the
directory of a figure, e.g.:

```
cd figure2
```

### Folder contents

Inside this folder you will find some or all of the following:

- `Makefile`, this is an overview you can use to trace back exactly with what 
code and from what data a given figure was created. Explained below.

- `input/`, a directory with simulation outputs needed to generate panels in the figure. 
These simulation outputs can also be reproduced, but for some this can take considerable
amounts of time. For convenience, the end product is used by default so you can use it 
if you just want to see how the analysis is performed. To generate the simulation outputs
yourself, see below.

- `settings/`, a directory with files with parameter combinations used for any simulations
in the figure. You mostly need this if you want to re-generate simulations, see below.

- `latex/`, a directory with a latex file that combines all inputs into a pdf of
the figure as it is shown in the manuscript. You only need this if you want to 
automatically re-generate the entire figure; see below.

- `img/` or `cartoons/`, any separate images or screenshots needed to complete the figure.  


### How to use and read the Makefile

If you have all the prerequisites installed, from the figure directory (e.g. `figure1/`)
you should be able to type:

```
make
```

this will produce a file `figureX.pdf` recreating the figure from the manuscript.
**Note: by default this uses the pre-stored simulation outputs used for the paper.
If you want to use your own simulations to make the figure, you need to adapt the file
called 'settings.env' in the parent directory. See below.**

The `Makefile` itself also contains the information on how the figure was generated.
Makefiles have the following general structure:

```
some-target-file.file : dependency1.script dependency2.data | other-stuff
	[recipe]
```

You would read this as follows:

- the file `some-target-file.file` can be reproduced using the script `dependency1.script`
 and any data in `dependency2.data`. 

- The code needed to do so is contained in the "recipe". In principle, you should be able
to run this from the command line and get the same result. But sometimes, the files contain
Makefile shortcuts: "$@" contains the file being made (in this case `some-target-file.file`),
"$<" contains the first dependency file (in this case `dependency1.script`), and
"$^" contains all dependency files before "|" (in this case `dependency1.script dependency2.data` )

- Anything after the "|" typically indicates something that needs to be done first, 
such as generating a directory called "data" or processing/copying data from another figure.

As an example:

The `Makefile` in `figure2` contains the following:

```
	
figure2.pdf : latex/figure2.pdf
	cp $< $@

latex/figure2.pdf : latex/figure2.tex  plots/F2panelB.pdf plots/F2panelC.pdf
	cd latex && latexmk -pdf figure2.tex && cp figure2.pdf ../ ;\
	latexmk -c
```

So we know that it will create `figure2.pdf` first in the folder `latex/` and then
copy it to the main folder when it is done. But to create `latex/figure2.pdf`, it
first needs to produce `plots/F2panel[X].pdf`.

Further on in the Makefile, we find the recipe for these files, e.g.:

```
plots/F2panelB.pdf : ../scripts/plotting/plot-params-pergen.R $(DIR)/evolution-free-combined.txt | plots
	Rscript $^ $@
```

`$(...)` refers to a Makefile variable, which can either be defined in the Makefile itself
or in `../settings.env`. In this case `$(DIR)` is defined in `../settings.env` and reflects the `input` folder.
This tells us that we can create plots/F2panelB.pdf by typing in the commandline:

```
Rscript ../scripts/plotting/plot-params-pergen.R input/evolution-free-combined.txt plots/F2panelB.pdf | plots
```

(remember the meaning of "$^" and "$@" as explained above). But before this can happen,
the Makefile first creates the folder called "plots". If we had set `$(DIR)` to be `data`,
it would also first re-generate the file `data/evolution-free-combined.txt` rather than 
using the saved version from the `input` folder. 

This way, you can use the Makefile to trace back how each file is generated (i.e., by which scripts 
and from which inputs) in the same way. 

### Recreating simulations

In most figures, the simulation outputs are not regenerated by typing `make` because
this might take quite long.

The plots will therefore typically use a file called `input/something.sth`, which 
contains these stored simulation outputs. However, the Makefile also shows you 
how to recreate these simulations if you want to. Any `input/something.sth` is 
matched with a corresponding `data/something.sth` which you can use to regenerate 
the simulation. See the section above on how to use the Makefile, or simply type:

```
make simulation-data
```

in folders of figures that contain simulated data.

If you want to use your newly simulated data to make the figure, set the `DIR` variable
in `../settings.env` to "data" rather than "input", and then repeat

```
make
```


In the `../settings.env`, you can set 
control e.g. the number of simulations, duration of each simulation, etc; adapting these
can allow you to run a smaller set of simulations first. 
You can also set MAXPROC, the max number of cores you want to 
allow to run simulations in parallel (please note though that if you choose to 'make' 
in two folders simultaneously, the cores in MAXPROC will add up).

Typically, this works as follows:

- CPM simulations are in node.js scripts `some-simulation.js`, but they are called via...

- ...a 'master' python script like `evolutionary-algorithm.py` or `track-wrapper.py`, which
can run these simulations in parallel at the desired hyperparameters (`../settings.env`), 
and...

- may use files like `settings/something.txt` to further configure the simulation and/or choose
parameters. 

- when this process is finished, an empty file `progress/something` is generated to indicate that
this is done, and the Makefile will automatically continue to the next step: 
analyzing the simulation outputs and producing the file `data/something.sth`.


If you just want to run a single simulation manually, simply type:

```
node the-simulation-script.js [-any-flags-with value] > myoutput.txt
```
