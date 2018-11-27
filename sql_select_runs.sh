
############################### Initialize input params, check for errors
run_cond="TRUE"
id_type="run_id"
table="run_params"
outfile="selected_runs.csv"
regime="all"
pmt=0

# Define high/low voltage regimes
high_voltage="hv>=1600"
low_voltage="hv<=1800"

# Define high/low light level regimes
high_light="((filter=7 AND ll>=50) OR (filter=8 AND ll>=60))"
low_light="((filter=7 AND ll<=50) OR (filter=8 AND ll<=60) OR filter=1)"

good_runs="ll>0 AND nevents>=500000"
recent_runs="iped=40 AND gate=100 AND datarate=3500 AND daq=3"

############################################### Parse input parameters
for item in $* ; do
	name=$(echo ${item} | awk -F'=' '{print $1}')
	val=${item#${name}=}
	# Grab run_cond value
	if [[ ${name} == "run_cond" ]] ; then
		val=$(echo ${val} | sed "s/-/ /g")
		run_cond="${run_cond} AND ${val}"
	# Select the quality of fits here
	elif [[ ${name} == "quality" ]] ; then
		run_cond="${run_cond} AND ${good_runs}"
	# Only grab recent fits
	elif [[ ${name} == "recent" ]] ; then
		if [ ${val} -eq 1 ] ; then
			run_cond="${run_cond} AND ${recent_runs}"
		fi
	# Grab data regime (light level and voltage)
	elif [[ ${name} == "regime" ]] ; then
		regime=${val}
	# Grab pmt
	elif [[ ${name} == "pmt" ]] ; then
		pmt=${val}
		run_cond="${run_cond} AND pmt=${pmt}"
		if [ ${pmt} -eq 5 ] ; then
			high_voltage="hv >= 1000"
			low_voltage="hv <= 1100"
		elif [ ${pmt} -eq 6 ] ; then
			high_voltage="hv >= 800"
			low_voltage="hv <= 900"
		fi
	# Grab high voltage, light level, and filter
	elif [[ ${name:0:2} == "hv" || ${name:0:2} == "ll" || ${name:0:6} == "filter" ]] ; then
		run_cond="${run_cond} AND ${item}"
	fi
done

# Apply conditions for regime of choice
if [[ ${regime} != "all" ]] ; then
	# Check for low light regime
	check=$(echo ${regime} | grep "ll")
	if [ ${#check} -gt 0 ] ; then
		run_cond="${run_cond} AND ${low_light}"
	fi
	# Check for high light regime
	check=$(echo ${regime} | grep "hl")
	if [ ${#check} -gt 0 ] ; then
		run_cond="${run_cond} AND ${high_light}"
	fi
	# Check for low voltage regime
	check=$(echo ${regime} | grep "lv")
	if [ ${#check} -gt 0 ] ; then
		run_cond="${run_cond} AND ${low_voltage}"
	fi
	# Check for high voltage regime
	check=$(echo ${regime} | grep "hv")
	if [ ${#check} -gt 0 ] ; then
		run_cond="${run_cond} AND ${high_voltage}"
	fi
fi




############################# Query database, write results to output file
# Create the query from condition
query="USE gaindb; SELECT run_id FROM run_params WHERE ${run_cond};"



echo ${query}
ret=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}")
# Count the selected runs
query="USE gaindb; SELECT COUNT(run_id) FROM run_params WHERE ${run_cond};"
count=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}")

# Make result comma-separated list
list=$(echo ${ret} | sed "s/\n/ /g")
list=$(echo ${ret} | sed "s/ /,/g")

# Write the runs to file and report to user
echo ${list} > ${outfile}
echo "${count} ${id_type}s selected"

