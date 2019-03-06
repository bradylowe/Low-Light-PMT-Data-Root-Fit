
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

# Initialize values to be input into table
pmt=1
if [ ${pmt} -lt 5 ] ; then
	base=1
else
	base=${pmt}
fi
hv=2000
filter=7
ll=0
daq=3
adc="v965ST"
chan="12"
gate="100"
iped=40
datarate=3500
pedrate=400
nevents=500000

# Move to the data directory
cd $(grep data_dir setup.txt | awk -F'=' '{print $2}')

# Grab the files
if [ ${#1} -gt 0 -a ${#2} -gt 0 ] ; then
	daq=$1
	run_nums=$2
	run_nums=$(echo ${run_nums} | sed "s/,/ /g")
	selected_files=""
	for cur_run in ${run_nums} ; do
		selected_files="${selected_files} $(ls daq${daq}/r${cur_run}*.root)"
	done
else
	selected_files=$(ls daq3/r3*.root)
	selected_files="${selected_files} $(ls daq5/r*.root)"
fi

# SET INPUT VALUE FOR ALL SELECTED RUNS
for rootfile in ${selected_files} ; do

	# Skip this one if already in database
	query="USE gaindb; SELECT run_id FROM run_params WHERE rootfile='${rootfile}';"
	run_id=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}")
echo ${run_id}
	if [ ${#run_id} -gt 0 ] ; then
		continue
	fi

	# Make datafile name from rootfile name
	datafile="${rootfile%.root}.dat"

	# Grab daq from which daq folder the run is in
	daq=$(echo ${rootfile} | awk -F'/' '{print $1}')
	# Remove the letters "daq"
	daq=${daq:3}
	# Remove leading 'daq?/r' and '.root'
	run_num=${rootfile#daq${daq}/r}
	run_num=${run_num%.root}
	run_num=${run_num%_*}

	# Only do files that have bigger run numbers than the ones we have
	query="USE gaindb; SELECT MAX(run_num) FROM run_params WHERE daq=${daq};"
	max_run_num=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}")
echo ${run_num}
	if [ ${#1} -eq 0 -a ${run_num} -lt ${max_run_num} ] ; then
echo hello
		continue
	fi
echo hello

	echo "---------------------------------"
	echo "For ${rootfile}"
	echo "---------------------------------"
	##################################################
	read -p "Enter hv (${hv}): " val
	# Skip this run if user desires
	if [[ ${val} == "skip" ]] ; then
		continue
	fi
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

