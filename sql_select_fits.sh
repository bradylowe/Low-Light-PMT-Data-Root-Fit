
############################### Initialize input params, check for errors
run_cond="TRUE"
fit_cond="TRUE"
id_type="fit_id"
table="fit_results"
outfile="selected_fits.csv"
regime="all"
pmt=1

# Define high/low voltage regimes
high_voltage="hv >= 1600"
low_voltage="hv <= 1800"

# Define high/low light level regimes
high_light="(filter=7 AND ll>50) OR (filter=8 AND ll>60)"
low_light="(filter=7 AND ll<=50) OR (filter=8 AND ll<=60) OR filter=1"

good_runs="ll>0 AND nevents>=500000"
recent_runs="iped=40 AND gate=100 AND datarate=3500 AND daq=3"

# Define quality of fits on a scale from 1 (bad) to 5 (good)
sloppy_fits="chi>=0 AND chi<10000 AND gain>0 AND gain<1.5 AND gain_percent_error<1000 AND mu_out>mu_out_error AND gain_percent_error>0"
ok_fits="chi>=0 AND chi<50 AND gain>0 AND gain<1.5 AND gain_percent_error<50 AND mu_out>mu_out_error AND gain_percent_error>0"
good_fits="chi>=0 AND chi<10 AND gain>0 AND gain<1.5 AND gain_percent_error<10 AND mu_out>mu_out_error AND gain_percent_error>0"
better_fits="chi>=0 AND chi<2 AND gain>0 AND gain<1.5 AND gain_percent_error<3 AND mu_out>mu_out_error AND gain_percent_error>0"
best_fits="${sloppy_fits} ORDER BY chi, gain_percent_error, mu_out_error LIMIT 1"


############################################### Parse input parameters
for item in $* ; do
	name=$(echo ${item} | awk -F'=' '{print $1}')
	val=${item#${name}=}
	# Grab run_cond value
	if [[ ${name} == "run_cond" ]] ; then
		val=$(echo ${val} | sed "s/-/ /g")
		run_cond="${run_cond} AND ${val}"
	# Grab fit_cond value
	elif [[ ${name} == "fit_cond" ]] ; then
		fit_cond="${fit_cond} AND ${val}"
	# Return fit_ids from low light fit
	elif [[ ${name} == "regime" ]] ; then
		regime=${val}
	# Select the quality of fits here
	elif [[ ${name} == "quality" ]] ; then
		run_cond="${run_cond} AND ${good_runs}"
		if [ ${val} -eq 1 ] ; then
			fit_cond="${fit_cond} AND ${sloppy_fits}"
		elif [ ${val} -eq 2 ] ; then
			fit_cond="${fit_cond} AND ${ok_fits}"
		elif [ ${val} -eq 3 ] ; then
			fit_cond="${fit_cond} AND ${good_fits}"
		elif [ ${val} -eq 4 ] ; then
			fit_cond="${fit_cond} AND ${better_fits}"
		elif [ ${val} -eq 5 ] ; then
			fit_cond="${fit_cond} AND ${best_fits}"
		fi
	# Only grab recent fits
	elif [[ ${name} == "recent" ]] ; then
		if [ ${val} -eq 1 ] ; then
			run_cond="${run_cond} AND ${recent_runs}"
		fi
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
		id_type="fit_id"
		table="fit_results"
		outfile="selected_fits.csv"
		run_cond="${run_cond} AND ${low_light}"
	fi
	# Check for high light regime
	check=$(echo ${regime} | grep "hl")
	if [ ${#check} -gt 0 ] ; then
		id_type="fit_id"
		table="high_light_results"
		outfile="selected_high_light_fits.csv"
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
ret=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}")
# Make result comma-separated list
list=$(echo ${ret} | sed "s/\n/ /g" | sed "s/ /,/g")
if [ ${#list} -eq 0 ] ; then
	list=0
fi
query="USE gaindb; SELECT fit_id FROM ${table} WHERE run_id IN (${list}) AND ${fit_cond};"
ret=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}")
# Count the selected runs
query="USE gaindb; SELECT COUNT(fit_id) FROM ${table} WHERE run_id IN (${list}) AND ${fit_cond};"
count=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}")

# Make result comma-separated list
list=$(echo ${ret} | sed "s/\n/ /g")
list=$(echo ${ret} | sed "s/ /,/g")

# Write the runs to file and report to user
echo ${list} > ${outfile}
echo "${count} ${id_type}s selected"

