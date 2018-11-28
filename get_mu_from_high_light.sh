
# Initialize
id_list=""

# Parse input
for item in $* ; do
	name=$(echo ${item} | awk -F'=' '{print $1}')
	val=${item#${name}=}
	if [[ ${name} == "run_id" ]] ; then
		id_list=${val}
	fi
done

# Loop through all fits
for run_id in ${id_list} ; do
	# Grab signal corresponding to this run
	query="USE gaindb; SELECT sig_out FROM high_light_results WHERE run_id=${run_id} ORDER BY chi LIMIT 1;"
	signal=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}")
	query="USE gaindb; SELECT sig_out FROM high_light_results WHERE run_id=${run_id} ORDER BY chi LIMIT 1;"
	signal=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}")

	# Compute gain measurement
	gain=$(root -l -q -b "divide.c(${signal}, ${mu})")
	gain=${gain#*(double) }

done
