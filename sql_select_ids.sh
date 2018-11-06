
########################################## Parse input parameters
for item in $* ; do
	name=$(echo ${item} | awk -F'=' '{print $1}')
	val=$(echo ${item} | awk -F'=' '{print $2}')
	# Grab run_cond value
	if [[ ${name} == "run_cond" ]] ; then
		run_cond=${val}
	# Grab fit_cond value
	elif [[ ${name} == "fit_cond" ]] ; then
		fit_cond=${val}
	# Return either run_ids or fit_ids
	elif [[ ${name} == "id" ]] ; then
		id=${val}
	# Only grab good fits
	elif [[ ${name} == "good" ]] ; then
		good=${val}
	# Only grab recent fits
	elif [[ ${name} == "recent" ]] ; then
		recent=${val}
	# Grab the high-light, high-voltage runs
	elif [[ ${name} == "hlhv" ]] ; then
		run_cond="((filter=7 AND ll>50) OR (filter=8 AND ll>60))"
		run_cond="${run_cond} AND hv >= 1800"
	# Grab the high-light, low-voltage runs
	elif [[ ${name} == "hllv" ]] ; then
		run_cond="((filter=7 AND ll>50) OR (filter=8 AND ll>60))"
		run_cond="${run_cond} AND hv < 1800"
	# Grab the low-light, high-voltage runs
	elif [[ ${name} == "llhv" ]] ; then
		run_cond="((filter=7 AND ll<=50) OR (filter=8 AND ll<=60) OR (filter=1))"
		run_cond="${run_cond} AND hv >= 1800"
	# Grab the low-light, low-voltage runs
	elif [[ ${name} == "lllv" ]] ; then
		run_cond="((filter=7 AND ll<=50) OR (filter=8 AND ll<=60) OR (filter=1))"
		run_cond="${run_cond} AND hv < 1800"
	fi
done

############################ Initialize other variables, check for errors
# If no condition is sent in, grab all the runs available
if [ ${#run_cond} -eq 0 ] ; then
	run_cond="TRUE"
fi
if [ ${#fit_cond} -eq 0 ] ; then
	fit_cond="TRUE"
fi
# Make sure we are grabbing some type of id
if [ ${#id} -eq 0 ] ; then
	id="run_id"
fi
if [ ${#good} -gt 0 ] ; then
	fit_cond="${fit_cond} AND chi<10 AND gain>0 AND gain<1.5 AND gain_percent_error<10 AND mu_out>mu_out_error AND gain_percent_error>0 AND ll>0"
fi
if [ ${#recent} -gt 0 ] ; then
	run_cond="${run_cond} AND iped=40 AND gate=100 AND datarate=3500"
fi
# Set the output filename and table name according to id type
if [[ ${id} == "run_id" ]] ; then
	table="run_params"
	outfile="selected_runs.txt"
else
	table="fit_results"
	outfile="selected_fits.txt"
fi


############################# Query database, write results to output file

if [[ ${id} == "run_id" ]] ; then
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
	query="USE gaindb; SELECT fit_id FROM fit_results WHERE run_id IN (${list}) AND ${fit_cond};"
	ret=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}")
	# Count the selected runs
	query="USE gaindb; SELECT COUNT(fit_id) FROM fit_results WHERE run_id IN (${list}) AND ${fit_cond};"
	count=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}")
fi

# Make result space-separated list
list=$(echo ${ret} | sed "s/\n/ /g")

# Write the runs to file and report to user
echo ${list} > ${outfile}
echo "${count} ${id}s selected"

