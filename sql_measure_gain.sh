

# Define default conditions
defaults="label=1 AND gain > 0 AND gain_error > 0 AND gain_percent_error < 10 AND sig_min = sig_max AND sig_min < 0 AND mu_out_error > 0"

# Look at input parameters
if [ $# -eq 0 ] ; then
	fit_cond=${defaults}
elif [ $# -eq 1 ] ; then
	fit_cond="$1 AND ${defaults}"
else
	run_cond=$1
	fit_cond="$2 AND ${defaults}"
fi


# Query database using info from run_params and fit_results tables
if [ ${#run_cond} -gt 0 ] ; then
	query="USE gaindb; SELECT gain FROM fit_results WHERE fit_results.run_id IN (SELECT run_id FROM run_params WHERE ${run_cond}) AND ${fit_cond};"
	gains=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}")
	query="USE gaindb; SELECT gain_error FROM fit_results WHERE fit_results.run_id IN (SELECT run_id FROM run_params WHERE ${run_cond}) AND ${fit_cond};"
	errors=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}")
else
	query="USE gaindb; SELECT gain FROM fit_results WHERE ${fit_cond};"
	gains=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}")
	query="USE gaindb; SELECT gain_error FROM fit_results WHERE ${fit_cond};"
	errors=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}")
fi

# Count results for printing
echo ${gains} | sed "s/ /\n/g" > gain.txt


