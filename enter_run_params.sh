
#  BRADY LOWE  #  LOWEBRA2@ISU.EDU  #  9/1/2018
###################################################################
# USAGE:  ./enter_run_params.sh
#         ./enter_run_params.sh 2044
#         ./enter_run_params.sh 2012 2014 2017-2022 2029 2033-2039
#
# RESULTS:
#        Decodes all selected files using evio2nt_v965
#        Outputs a .root file for each input data file
#
# NOTES:
#        YOU MUST FIRST SOURCE ~/coda/3.06/.setup
#
####################################################################

old_dir=$(pwd)
cd /media/data/Projects/fit_pmt/data
selected_files=$(ls daq3/r*.root)
selected_files="${selected_files} $(ls daq5/r*.root)"

# SET INPUT VALUE FOR ALL SELECTED RUNS
for rootfile in ${selected_files} ; do

	# Skip this one if already in database
	query="USE gaindb; SELECT run_id FROM run_params WHERE rootfile='${rootfile}';"
	res=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}")
	if [ ${#res} -gt 0 ] ; then
		continue
	fi

	# Make datafile name from rootfile name
	datafile="${rootfile%.root}.dat"

	# Initialize values that might be read from the filename
	adc="v965ST"
	daq=$(echo ${rootfile} | awk -F'/' '{print $1}')
	daq=${daq:3}

	# Remove leading 'daq?/r' and '.root'
	run_num=${rootfile:6}
	run_num=${run_num%.root}
	# Filename is of style r123_v965ST_5.root
	if [ $(echo ${run_num} | grep v965ST) ] ; then	
		# Grab the run number
		run_num=$(echo ${run_num} | awk -F'_' '{print $1}')
		# Grab the adc value
		adc=$(echo ${rootfile} | awk -F'_' '{print $2}')
		# Grab the daq value
		daq=$(echo ${rootfile} | awk -F'_' '{print $3}')
		daq=$(echo ${daq} | awk -F'.' '{print $1}') 
	# Filename is of style r123_5.root 
	elif echo ${run_num} | grep _ ; then
		# Grab the run number
		run_num=$(echo ${run_num} | awk -F'.' '{print $1}')
		# Grab the daq value
		daq=$(echo ${rootfile} | awk -F'_' '{print $2}')
		daq=$(echo ${daq} | awk -F'.' '{print $1}') 
	# Filename is of style r123.dat
	else
		# Grab the run number
		run_num=$(echo ${run_num} | awk -F'.' '{print $1}')
	fi

	# Initialize values to common defaults
	chan="12"
	gate="100"
	pmt=1
	base=1
	iped=40
	hv=2000
	datarate=3500
	pedrate=400
	filter=7
	nevents=500000
	ll=0

	echo "---------------------------------"
	echo "For ${rootfile}"
	echo "---------------------------------"
	##################################################
	read -p "Enter hv (${hv}): " val
	# If the user sent something, grab it
        if [ ${#val} -gt 0 ] ; then
		hv=${val}
        fi
	##################################################
	read -p "Enter channel (${chan}): " val
	# If the user sent something, grab it
        if [ ${#val} -gt 0 ] ; then
		chan=${val}
        fi
	##################################################
	read -p "Enter gate (${gate}): " val
	# If the user sent something, grab it
        if [ ${#val} -gt 0 ] ; then
		gate=${val}
        fi
	##################################################
	read -p "Enter iped (${iped}): " val
	# If the user sent something, grab it
        if [ ${#val} -gt 0 ] ; then
		iped=${val}
        fi
	##################################################
	read -p "Enter pmt (${pmt}): " val
	# If the user sent something, grab it
        if [ ${#val} -gt 0 ] ; then
		pmt=${val}
        fi
	##################################################
	read -p "Enter daq (${daq}): " val
	# If the user sent something, grab it
        if [ ${#val} -gt 0 ] ; then
		daq=${val}
        fi
	##################################################
	read -p "Enter datarate (${datarate}): " val
	# If the user sent something, grab it
        if [ ${#val} -gt 0 ] ; then
		datarate=${val}
        fi
	##################################################
	read -p "Enter pedrate (${pedrate}): " val
	# If the user sent something, grab it
        if [ ${#val} -gt 0 ] ; then
		pedrate=${val}
        fi
	##################################################
	read -p "Enter ll (${ll}): " val
	# If the user sent something, grab it
        if [ ${#val} -gt 0 ] ; then
		ll=${val}
        fi
	##################################################
	read -p "Enter filter (${filter}): " val
	# If the user sent something, grab it
        if [ ${#val} -gt 0 ] ; then
		filter=${val}
        fi
	##################################################
	read -p "Enter nevents (${nevents}): " val
	# If the user sent something, grab it
        if [ ${#val} -gt 0 ] ; then
		nevents=${val}
        fi
	##################################################

	# Create query
	query="USE gaindb; INSERT INTO run_params (run_num, daq, adc, chan, gate, pmt, base, hv, datarate, pedrate, ll, filter, nevents, rootfile, datafile, iped) VALUES('${run_num}', '${daq}', '${adc}', '${chan}', '${gate}', '${pmt}', '${base}', '${hv}', '${datarate}', '${pedrate}', '${ll}', '${filter}', '${nevents}', '${rootfile}', '${datafile}', '${iped}');"
	# Submit info to database
	mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}"

	# Echo line to check query for ease of use
	echo mysql --defaults-extra-file=~/.mysql.cnf -e \"USE gaindb \; SELECT \* FROM run_params ORDER BY run_id DESC LIMIT 1\"

done

