# Low-Light-PMT-Data-Root-Fit
This repository houses code for modeling the response of photomultiplier tubes at very low light conditions. A photomultiplier tube is a device that can detect single photons (light particles) and amplify the signal enough to be detected by very sensitive electronics. Descriptions of the electronics can be found on another repository of mine [here](https://github.com/bradylowe/daq-pves-lab.git).

*Dependencies:*
 - Cern Root (found [here](https://root.cern.ch/building-root))
 - Linux environment for running bash scripts
 - MySQL for database use

---
---
---

## List of files

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
    * conGain (constrain gain param 0-100 percent to accepted value)
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
