
pmt=1

# Define default conditions
defaults="gain > 0 AND gain_error > 0 AND gain_percent_error < 10 AND con_gain > 10 AND con_ll < 100 AND con_ll > 0 AND mu_out < 10"

# Look at input parameters
if [ $# -eq 0 ] ; then
	fit_cond=${defaults}
elif [ $# -eq 1 ] ; then
	fit_cond="$1 AND ${defaults}"
else
	run_cond=$2
	fit_cond="$1 AND ${defaults}"
fi


# Query database using info from run_params and fit_results tables
if [ ${#run_cond} -gt 0 ] ; then
	query="USE gaindb; SELECT gain FROM fit_results WHERE fit_results.run_id IN (SELECT run_id FROM run_params WHERE ${run_cond} AND pmt=${pmt}) AND ${fit_cond};"
	gains=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}")
	query="USE gaindb; SELECT gain_error FROM fit_results WHERE fit_results.run_id IN (SELECT run_id FROM run_params WHERE ${run_cond} AND pmt=${pmt}) AND ${fit_cond};"
	errors=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}")
else
	query="USE gaindb; SELECT gain FROM fit_results WHERE ${fit_cond};"
	gains=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}")
	query="USE gaindb; SELECT gain_error FROM fit_results WHERE ${fit_cond};"
	errors=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}")
fi

# Count results for printing
gains=$(echo ${gains} | sed "s/0\.//g")
errors=$(echo ${errors} | sed "s/0\.//g")
echo ${gains} > gain.txt
echo ${errors} > gain.txt

count=0
sum=0
# Get average
for item in ${gains} ; do
	sum=$((sum + item))
	count=$((count + 1))
done
ave=$((sum / count))

sum=0
for item in ${gains} ; do
	diff=$((item - ave))
	diff=$((diff * diff))
	sum=$((sum + diff))
done
var=$((sum / count))

echo average: ${ave}
echo variance: ${var}
