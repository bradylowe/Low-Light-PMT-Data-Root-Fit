
############################### Initialize input params, check for errors
run_cond="TRUE"
fit_cond="TRUE"
id_type="run_id"
table="run_params"
outfile="selected_runs.csv"

# Define high voltage/light level regimes
limit=1800  # 2" PMTs
#limit=1100 # 3" PMTs
hlhv="((filter=7 AND ll>50) OR (filter=8 AND ll>60)) AND hv >= ${limit}"
hllv="((filter=7 AND ll>50) OR (filter=8 AND ll>60)) AND hv < ${limit}"
llhv="((filter=7 AND ll<=50) OR (filter=8 AND ll<=60) OR (filter=1)) AND hv >= ${limit}"
lllv="((filter=7 AND ll<=50) OR (filter=8 AND ll<=60) OR (filter=1)) AND hv < ${limit}"

# Define quality of fits on a scale from 1 (bad) to 5 (good)
good_runs="ll>0 AND nevents>=500000"
sloppy_fits="chi>=0 AND chi<10000 AND gain>0 AND gain<1.5 AND gain_percent_error<1000 AND mu_out>mu_out_error AND gain_percent_error>0"
ok_fits="chi>=0 AND chi<50 AND gain>0 AND gain<1.5 AND gain_percent_error<50 AND mu_out>mu_out_error AND gain_percent_error>0"
good_fits="chi>=0 AND chi<10 AND gain>0 AND gain<1.5 AND gain_percent_error<10 AND mu_out>mu_out_error AND gain_percent_error>0"
better_fits="chi>=0 AND chi<2 AND gain>0 AND gain<1.5 AND gain_percent_error<3 AND mu_out>mu_out_error AND gain_percent_error>0"
best_fits="${sloppy_fits} ORDER BY chi DESC, gain_percent_error DESC, mu_out_error DESC LIMIT 1"

recent_runs="iped=40 AND gate=100 AND datarate=3500 AND daq=3"

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
	# Return either run_ids or fit_ids
	elif [[ ${name} == "fit" || ${name} == "fits" ]] ; then
		id_type="fit_id"
		table="fit_results"
		outfile="selected_fits.csv"
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
	# Grab the high-light, high-voltage runs
	elif [[ ${name} == "hlhv" ]] ; then
		if [ ${val} -eq 1 ] ; then
			run_cond="${run_cond} AND ${hlhv}"
		fi
	# Grab the high-light, low-voltage runs
	elif [[ ${name} == "hllv" ]] ; then
		if [ ${val} -eq 1 ] ; then
			run_cond="${run_cond} AND ${hllv}"
		fi
	# Grab the low-light, high-voltage runs
	elif [[ ${name} == "llhv" ]] ; then
		if [ ${val} -eq 1 ] ; then
			run_cond="${run_cond} AND ${llhv}"
		fi
	# Grab the low-light, low-voltage runs
	elif [[ ${name} == "lllv" ]] ; then
		if [ ${val} -eq 1 ] ; then
			run_cond="${run_cond} AND ${lllv}"
		fi
	# Grab high voltage and light level
	elif [[ ${name} == "hv" || ${name} == "ll" || ${name} == "pmt" || ${name} == "filter" ]] ; then
		run_cond="${run_cond} AND ${item}"
	fi
done



############################# Query database, write results to output file
if [[ ${id_type} == "run_id" ]] ; then
	# Create the query from condition
	query="USE gaindb; SELECT run_id FROM run_params WHERE ${run_cond};"
	ret=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}")
	# Count the selected runs
	query="USE gaindb; SELECT COUNT(run_id) FROM run_params WHERE ${run_cond};"
	count=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}")
else
	# Create the query from condition
	query="USE gaindb; SELECT run_id FROM run_params WHERE ${run_cond};"
	ret=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}")
	# Make result comma-separated list
	list=$(echo ${ret} | sed "s/\n/ /g" | sed "s/ /,/g")
	if [ ${#list} -eq 0 ] ; then
		list=0
	fi
	query="USE gaindb; SELECT fit_id FROM fit_results WHERE run_id IN (${list}) AND ${fit_cond};"
	ret=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}")
	# Count the selected runs
	query="USE gaindb; SELECT COUNT(fit_id) FROM fit_results WHERE run_id IN (${list}) AND ${fit_cond};"
	count=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}")
fi

# Make result comma-separated list
list=$(echo ${ret} | sed "s/\n/ /g")
list=$(echo ${ret} | sed "s/ /,/g")

# Write the runs to file and report to user
echo ${list} > ${outfile}
echo "${count} ${id_type}s selected"

