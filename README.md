# Low-Light-PMT-Data-Root-Fit
This repository houses code for modeling the response of photomultiplier tubes at very low light conditions. A photomultiplier tube is a device that can detect single photons (light particles) and amplify the signal enough to be detected by very sensitive electronics. Descriptions of the electronics can be found on another repository of mine [here](https://github.com/bradylowe/daq-pves-lab.git).

*Dependencies:*
 - Cern Root (found [here](https://root.cern.ch/building-root))
 - Linux environment for running bash scripts
 - MySQL for database use (found [here](https://dev.mysql.com/doc/refman/8.0/en/installing.html))

*Quick start:*
 - First, open setup.txt and set the correct values for directories
 - Next, run ./sql_select_runs.sh run_cond="hv=2000&&pmt=1"
 - Then, run ./run_fit_pmt.sh
 - To view the results of what you just ran (up to 20 fits), execute:
    * mysql -u user -p -e "USE gaindb; SELECT fit_id, gain, chi FROM fit_results ORDER BY fit_id DESC LIMIT 20;"

---
---
---

## Description of files and directories

### *setup.txt*
 - This text file is for portability to different machines.
 - In this file, we can set different global variables such as the location of images or data on this computer.
 - This allows us to store the data and images anywhere (which can take up a lot of space sometimes).

### *fit_pmt.c* 
 - This Root macro defines a 9-parameter mathematical model of a PMT response.
 - This macro takes in around 50 input parameters which gives the user immense control over the parameter-space search, and also allows for highly detailed recording of past search attempts and results.
 - The algorithm in this macro was defined in a NIM publication in 1992 and written in Root by YuXiang Zhao, then passed onto Dustin McNulty, and then finally to me. I have made many changes, but very few to the underlying mathematics.
 - This macro outputs pngs for humans to view as well as neural networks. This allows for creating and studying of all data as well as applying machine learning to the same task. This macro also outptus an SQL query into a text file which a shell script (run_fit_pmt.sh) uses to store fit input and output in an SQL database.
 - Error outputs (function return values):
    * -1 means negative chi per ndf
    * -2 means chi per ndf > 10^7
    * -3 means fit didn't run due to data overflow
    * -4 means error in NPE calculation
    * -5 means error opening root file
    * -6 means null TTree in .root file

### *fit_pmt_wrapper.c*
 - This Root macro serves as a bridge between the immense power and detail of fit_pmt.c and the ease of use of run_fit_pmt.sh (described next).
 - This macro takes in only 22 parameters that are much more aligned with human concerns such as which run number to use, how much to constrain our varaibles during fitting, which types of outputs to save, and any initial conditions we would like considered.

### *run_fit_pmt.sh* 
 - This shell script is a Cadillac compared to the above C-code. 
 - This script takes in an optional 15 input parameters that do not need to 
    be in any certain order. 
 - The input param list:  
    * conGain (constrain gain param to some percent of best guess)
    * conLL (constrain ll)
    * pedInj (initial pedestal injection rate guess)
    * conInj (constrain)
    * rootFile (source data filename)
    * fitEngine (Root fit engine options)
    * tile (for custom montage tiling)
    * savePNG (boolean for saving human style png)
    * saveNN (boolean for saving neural network output png)
    * run_id (single run id to fit)
 - If the user sends in either a "rootFile" or a single "run_id", then the script will allow Root to remain open for the user to interact with. Otherwise, Root will be ran in batch mode and only saved output will remain.
 - After the root macro has performed the fit and saved its output pngs and SQL query textfile, this script may use the png in creating a montage, then it will put the png in its correct directory or delete it, and then the script will grab the SQL query from the text file and submit it to save the fit output to the gaindb database.
 - Example usage: ./run_fit_pmt.sh conGain=20 conLL=10 noExpo=1 

### *fit_high_light.c*
 - This macro assumes a gaussian pedestal and a gaus+exp tail.
 - It returns the separation between the two distribution means.

### *run_fit_high_light.sh*
 - This script executes the high light fit macro on all selected_runs.csv.
 - If necessary, the fit will run on the high range and multiply all measured values by 8.
 - Outputs will be stored in fit_high_light table in the gaindb database.
 - Output pngs will be stored in ${im_dir}/png_high_light.

### *pedestalfit.c*
 - This macro assumes a sum of three gaussians as the distribution.

### *run_fit_pedestal.sh*
 - This script fits selected_runs.csv to the pedestal fit.

### *run_batch.sh*
 -  This script runs the run_fit_pmt.sh script on a predefined list of run_id's with predefined input arguments. 
 - This is a way to systematically analyze new data sets.

---
---
---

### *sql_select_runs.sh*
 - This script takes in some sql conditional statements, selects corresponding run_ids, and writes them to selected_runs.csv.
 - Example usage:   ./sql_select_runs.sh fit run_cond="hv=2000&&ll<90"
 - Through this shell script, we can select the quality of runs we want to see, recent data, or different voltage or light level regimes.
 - The "regime" parameter is sent in the form regime="_,_" or regime="_" where the "_" are replaced by:
    * ll for low light
    * lv for low voltage
    * hl for high light
    * hv for high voltage
 - The "quality" parameter here is just sent in as a flag to select runs with high statistics some light and voltage.
 - Here is a list of possible input parameters as well as possible values:
    * quality
    * recent=1
    * run_cond="hv>1700&&hv<2000&&gate=100"
    * regime="ll,hv"

### *sql_select_fits.sh*
 - This script is just like the above, except it puts fit_ids into selected_fits.csv.
 - If the user sends in the "high-light" flag as a parameter, then the fit_high_light will be used instead (and selected_high_light_fits.csv).
 - In this script, the quality parameter ranges from 0 to 5 where:
    * 0 returns all fits from quality data runs
    * 1 returns the above minus really horrible fits
    * 2 returns the above with fewer bad fits
    * 3 returns mainly good fits, but still some bad ones
    * 4 should only return good fits
    * 5 returns only 1 fit (the "best" one)
 - The quality parameter is only set up to be used with the low light fit. The high light fit should be easily sortable with chi2.
 - Here are a couple new parameters from the run_id version:
    * quality=5
    * fit_cond="chi<2&&mu_out<5.5"

### *sql_remove_fits.sh*
 - This script removes all the fits in selected_fits.csv
    * The row is removed from the SQL table.
    * Any associated images are deleted from file.

### *sql_view_fits.sh*
 - This script opens eog file viewer with all filenames corresponding to selected_fits.csv

### *sql_average.sh*
 - This script takes in an argument which is a column in the fit_results table and finds the average and standard dev of the column for the runs in selected_runs.csv.
 - Example:  ./sql_average.sh column=mu_out regime=low 

### *sql_ave_errors.sh*
 - This script is just like the above, but it also grabs the errors column and returns it.

### *sql_make_plot.sh*
 - This script executes make_plot.c after grabbing values corresponding to selected_fits.csv
 - This script takes 2 parameters
    * x - independent variable
    * y - dependent variable
 - The two parameters can be any numeric column value from either the run_params table OR the fit_results table. For a list of possibilities, execute:
    * ./sql_make_plot.sh help
 - Example usage:
    * ./sql_make_plot.sh hv gain 

### *sql_calibrate_gain(ll).sh*
 - This script finds the average measurement of any available good fits and updates the calibration file.

---
---
---

### *Other setup files:*
 - pmtN_gain.csv
    * This collection of files stores pmt gain signal size calibrations for measured high voltages.
 - pmtN_ll.csv
    * This collection of files stores light level calibrations for a given pmt.
 - filters.csv
    * This file stores the transparencies of our filters.

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
 - This script needs sql_select_runs.sh to be ran before so that selected_runs.csv exists.
 - This script executes a fit to the V965 pedestal (zero signal) events defined in pedestalFit.c.
 - This script will execute one fit at a time and wait for you to exit to show the next run.

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

### *saved_runs*
 - This directory houses some csv files that store run_ids.
 - Each file stores a group of related run_ids with explanatory filename.

### *docs*
 - This directory contains documentation about measuring the gain of PMTs.
 - Summary of files:
    * new_pmt_response_jlab.pdf models the amplification of the electrons for the first few dynode stages and assumes those stages may have different gains
    * NIM_A339_468_PMT_Calibration.pdf describes the fit_pmt algorithm
    * pmt_sim_tilecal-99-012.pdf describes a monte-carlo method of measuring PMT gain
    * recent_1-s2.0-S016890021730311X-main.pdf describes a method of measuring the gain at higher light levels than other methods and claims to be more robust to different setups.
    * rpp2014-rev-probability describes in great detail the math behind Poissonian statistics and random events.

