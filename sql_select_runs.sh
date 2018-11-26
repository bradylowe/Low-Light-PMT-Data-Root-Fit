
############################### Initialize input params, check for errors
run_cond="TRUE"
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
	elif [[ ${name:0:2} == "hv" || ${name:0:2} == "ll" || ${name:0:3} == "pmt" || ${name:0:6} == "filter" ]] ; then
		run_cond="${run_cond} AND ${item}"
	fi
done



############################# Query database, write results to output file
# Create the query from condition
query="USE gaindb; SELECT run_id FROM run_params WHERE ${run_cond};"
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

