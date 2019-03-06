
# run_fit_pmt.sh
# Brady Lowe # lowebra2@isu.edu
#
#################################################################
# This script will call a root analyzer for every data run in
# the current directory with a .root file associated 
# with it. PNGs will be output for each data file.  
##################################################################

# Quickly grab the output from the run_id selection
run_list=$(head -n 1 selected_runs.csv | sed "s/,/ /g")

# This is where data/images are stored
data_dir=$(grep data_dir setup.txt | awk -F'=' '{print $2}')
im_dir=$(grep im_dir setup.txt | awk -F'=' '{print $2}')


# Initialize variables
rootfile=""
chan=2
adc_range=1
binWidth=1
signal=120
sigrms=28
ped=0
pedrms=0
sig=0
sigrms=0
mu=1
hv=0
run_num=0
detector=""
energy=0.0

# Decode input parameters
for item in $* ; do
	name=$(echo ${item} | awk -F'=' '{print $1 }')
	val=${item#${name}=}
	# Check for some words
	if [[ ${name} == "rootfile" ]] ; then
		rootfile=${val}
		run_num=${rootfile#*_%.root}
	elif [[ ${name} == "chan" ]] ; then
		chan=${val}
	elif [[ ${name} == "adc_range" ]] ; then
		adc_range=${val}
	elif [[ ${name} == "binWidth" ]] ; then
		binWidth=${val}
	elif [[ ${name} == "sig" ]] ; then
		sig=${val}
	elif [[ ${name} == "sigrms" ]] ; then
		sigrms=${val}
	elif [[ ${name} == "ped" ]] ; then
		ped=${val}
	elif [[ ${name} == "pedrms" ]] ; then
		pedrms=${val}
	elif [[ ${name} == "mu" ]] ; then
		mu=${val}
	elif [[ ${name} == "hv" ]] ; then
		hv=${val}
	elif [[ ${name} == "run_num" ]] ; then
		run_num=${val}
	fi	
done

# Check for a run to analyze
if [ ${run_num} -eq 0 ] ; then
	echo "Need to choose a run"
	exit
fi

# Grab the info from files about this run
rootfile="SLAC_BEAM_TEST_DATA/run_${run_num}.root"
hv=$(grep ${run_num}, testbeam_run_params.csv | awk -F',' '{print $2}')
detector=$(grep ${run_num}, testbeam_run_params.csv | awk -F',' '{print $3}')
energy=$(grep ${run_num}, testbeam_run_params.csv | awk -F',' '{print $4}')
pmt=$(grep ${run_num}, testbeam_run_params.csv | awk -F',' '{print $5}')
if [ ${ped} -eq 0 ] ; then
	ped=$(grep ${run_num}, testbeam_run_params.csv | awk -F',' '{print $6}')
fi
if [ ${pedrms} -eq 0 ] ; then
	pedrms=$(grep ${run_num}, testbeam_run_params.csv | awk -F',' '{print $7}')
fi
if [ ${sig} -eq 0 ] ; then
	sig=$(grep ${run_num}, testbeam_run_params.csv | awk -F',' '{print $8}')
fi
if [ ${sigrms} -eq 0 ] ; then
	sigrms=$(grep ${run_num}, testbeam_run_params.csv | awk -F',' '{print $9}')
fi

# Grab the signal from 1 PE at this hv with this pmt
sigPE=$(grep ${hv},${pmt}, hv_pmt_signal.csv | awk -F',' '{print $3}')

echo ${hv} ${detector} ${energy} ${sigPE}

# Fit the data, grab chi squared per ndf
root -l "fit_showermax_wrapper.c(\"${rootfile}\", ${chan}, ${adc_range}, ${binWidth}, ${sig}, ${sigrms}, ${ped}, ${pedrms}, ${mu}, ${hv}, ${sigPE}, \"${detector}\", ${energy})"
