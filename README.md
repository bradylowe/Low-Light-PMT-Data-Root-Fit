# Low-Light-PMT-Data-Root-Fit
This repository houses code for modeling the response of photomultiplier tubes at very low light conditions. A photomultiplier tube is a device that can detect single photons (light particles) and amplify the signal enough to be detected by very sensitive electronics. Descriptions of the electronics can be found on another repository of mine [here](https://github.com/bradylowe/daq-pves-lab.git).

*Dependencies:*
 - Cern Root (found [here](https://root.cern.ch/building-root))
 - Linux environment for running bash scripts
 - MySQL for database use (found [here](https://dev.mysql.com/doc/refman/8.0/en/installing.html))

*Quick start:*
 - First, run ./sql_select_runs.sh "hv=2000 AND pmt=1"
 - Then, run ./run_fit_pmt.sh
 - To view the results of what you just ran (up to 20 fits), execute:
    * mysql -u user -p -e "USE gaindb; SELECT fit_id, gain, chi FROM fit_results ORDER BY fit_id DESC LIMIT 20;"

---
---
---

## Description of files and directories

### *fit_pmt.c* 
 - This Root macro defines a 9-parameter mathematical model of a PMT response.
 - This macro takes in around 50 input parameters which gives the user immense control over the parameter-space search, and also allows for highly detailed recording of past search attempts and results.
 - The algorithm in this macro was defined in a NIM publication in 1992 and written in Root by YuXiang Zhao, then passed onto Dustin McNulty, and then finally to me. I have made many changes, but very few to the underlying mathematics.
 - This macro outputs pngs for humans to view as well as neural networks. This allows for creating and studying of all data as well as applying machine learning to the same task. This macro also outptus an SQL query into a text file which a shell script (run_fit_pmt.sh) uses to store fit input and output in an SQL database.

### *fit_pmt_wrapper.c*
 - This Root macro serves as a bridge between the immense power and detail of fit_pmt.c and the ease of use of run_fit_pmt.sh (described next).
 - This macro takes in only 22 parameters that are much more aligned with human concerns such as which run number to use, how much to constrain our varaibles during fitting, which types of outputs to save, and any initial conditions we would like considered.
 - This macro also contains hard-coded into it all of our currently accepted PMT, light source, and filter calibration values measured and set by me personally. Unfortunately, some of these values are subject to change (though the gains of the tubes shouldn't change).
 - This macro has an option to print a thorough summary of the settings that went into producing this fit.

### *run_fit_pmt.sh* 
 - This shell script is a Cadillac compared to the above C-code. 
 - This script takes in an optional 15 input parameters that do not need to 
    be in any certain order. 
 - The input param list:  
    * gain (initial guess)
    * conGain (constrain gain param to some percent of best guess)
    * ll (initial light level guess)
    * conLL (constrain ll)
    * pedInj (initial pedestal injection rate guess)
    * conInj (constrain)
    * pngFile (output montage name [for multiple files])
    * rootFile (source data filename)
    * fitEngine (Root fit engine options)
    * tile (for custom montage tiling)
    * printSum (boolean for printing summary box)
    * savePNG (boolean for saving human style png)
    * saveNN (boolean for saving neural network output png)
    * runs (list of run id's to fit)
    * run_id (single run id to fit)
 - If the user sends in either a "rootFile" or a single "run_id", then the script will allow Root to remain open for the user to interact with. Otherwise, Root will be ran in batch mode and only saved output will remain.
 - After the root macro has performed the fit and saved its output pngs and SQL query textfile, this script may use the png in creating a montage, then it will put the png in its correct directory or delete it, and then the script will grab the SQL query from the text file and submit it to save the fit output to the gaindb database.
 - Example usage: ./run_fit_pmt.sh fitEngine=1 printSum=true ll=47 conGain=90 savePNG=true pngFile="nice_montage.png" runs="17 29 49 50 51"

### *run_batch.sh*
 -  This script is simply executed as ./run_batch.sh (no input arguments)
 -  This script runs the run_fit_pmt.sh script on a predefined list of run_id's with predefined input arguments. This is a way to make many different fits to many different data runs at once.

### *sql_select_runs.sh*
 - This script takes in a string as inputs that is used in mysql query to run_params table.
 - This file writes the selected run_ids to the selected_runs.txt file.

### *sql_select_fits.sh*
 - This script is just like the above except it takes in two query strings and outputs fit_ids instead of run_ids.
 - The first input string is a query to run_params. The second queries fit_results.
 - If only one parameter is sent in, it is used to query fit_results table.

### *histograms:*
 - This directory houses a collection of text files with numbers in them.
 - The numbers in these files define our dataset; each file represent a histogram with 4095 bins.
 - The files list the number of leading and trainling zeros, then it lists all the entries in between the leading/trailing zeros.
 - By reconstructing the 4095-dimensional vector, we will have a list of ordered pairs that define out data.
 - The error on each data point is assumed to be the square root of the value of the data point.
 - These files allow for the construction of png images.

### *gaindb.sql:*
 - This file is a complete backup of the gaindb database.
 - The gaindb database stores two tables: run_params and fit_results.
 - The run_params table stores experimental run parameters such as:
    * high voltage setting
    * which PMT was used
    * which ADC channel was the signal taken on
    * what what the light level
    * which filters were used
    * etc (use "DESCRIBE run_params;" to see the complete list in sql)
 - The fit_results table stores required fit inputs and all fit outputs such as:
    * initial guesses of all 9 parameters
    * min and max bounds of all 9 parameters
    * the output parameters selected by the fitting algorithm
    * the calculated error on the predicted parameters from the fit
    * chi-squared per degree of freedom
 - Once mysql is installed, you should be able to (from the command line) run:
    * mysql -u user -p gaindb < gaindb.sql
 - This command should create the gaindb database and populate it with values. (If this is not the case, you must first define the gaindb database on your system and give your user all permissions over the database, described [here](https://dev.mysql.com/doc/refman/8.0/en/creating-database.html)).

### *pedestalFit.sh* 
 - This script needs sql_select_runs.sh to be ran before so that selected_runs.txt exists.
 - This script executes a fit to the V965 pedestal (zero signal) events defined in pedestalFit.c.
 - This script will execute one fit at a time and wait for you to exit to show the next run.

### *make_plot.sh*
 - This script executes make_plot.c after doing some things with mysql database
 - This script needs 4 parameters to operate very well:
    * First parameter tells what to plot as independent variable
    * Second parameter decides the dependent variable
    * Third parameter selects which runs to consider from run_params table
    * Fourth parameter selects which fits to consider from fit_results table
 - The first two parameters can be any numeric column value from either the run_params table OR the fit_results table. For a list of possibilities, execute:
    * ./make_plot.sh help
 - Example usage:
    * ./make_plot.sh hv gain "hv>1400 AND pmt=1 AND ll>30 AND ll<65"  "chi < 2 AND gain > 0"
    * ./make_gain_curve.sh is a shortcut when the first two parameters are "hv" and "gain"

### *labelmaker.sh*
 - This script allows us to label the fits as either good or bad.
 - The script will query the database and show one fit after another that has not been labeled yet.
 - After viewing the png of the fit, the user can enter:
    * 0 for "bad fit"
    * 1 for "good fit"
    * u for "undo last label"
    * q for "quit"

### *dataAnalyzer.c*
 - This file is where custom Root functions are defined for convenience in coding the fit_pmt algorithm.
 - Some of the defined functions are:
    * myStoi(string) for converting strings to integers
    * getDataPedSig(filename, channel, param, saveImage) for getting statistics from histogram
    * getDataMinMax(filename, channel, minmax, limit) for selecting where to cut the data
    * writeHistToFile(histogram, filename, bins) for writing all histogram info to .hist file.

### *enter_run_params.sh*
 - This script allows us to enter the run parameters into the MySQL database when we collect new data.
 - Some parameters we need to record include high-voltage, run number, light level, ADC channel, etc. - Simply execute ./enter_run_params.sh and you will be prompted for values.
 - NOTE:  some values are hard-coded for convenience that ALMOST never change...

### *docs*
 - This directory contains documentation about measuring the gain of PMTs.
 - Summary of files:
    * new_pmt_response_jlab.pdf models the amplification of the electrons for the first few dynode stages and assumes those stages may have different gains
    * NIM_A339_468_PMT_Calibration.pdf describes the fit_pmt algorithm
    * pmt_sim_tilecal-99-012.pdf describes a monte-carlo method of measuring PMT gain
    * recent_1-s2.0-S016890021730311X-main.pdf describes a method of measuring the gain at higher light levels than other methods and claims to be more robust to different setups.
    * rpp2014-rev-probability describes in great detail the math behind Poissonian statistics and random events.

