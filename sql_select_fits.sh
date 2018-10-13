
# Look at input parameters
if [ $# -eq 1 ] ; then
	fit_cond=$1
else
	run_cond=$1
	fit_cond=$2
fi

# Query database using info from run_params and fit_results tables
if [ ${#run_cond} -gt 0 ] ; then
	fits=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "USE gaindb; SELECT fit_id FROM fit_results WHERE fit_results.run_id IN (SELECT run_id FROM run_params WHERE ${run_cond}) AND ${fit_cond};")
else
	fits=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "USE gaindb; SELECT fit_id FROM fit_results WHERE ${fit_cond};")
fi

# Count results for printing
count=0
for item in ${fits} ; do
	count=$((count + 1))
done

# Write output
echo ${fits} > selected_fits.txt
echo ${count} fits selected

