
# Get column from command line
if [ $# -eq 0 ] ; then
	col="gain"
	col_err="gain_percent_error"
else
	col=$1
	col_err="$1_error"
fi

# Grab selected fits and put commas in there
list=$(head selected_fits.csv)
if [ ${#list} -eq 0 ] ; then
	echo no fits
	exit
fi

# Query database using info from run_params and fit_results tables
query="USE gaindb; SELECT AVG(${col}) FROM fit_results WHERE fit_id IN (${list});"
ave=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}")
query="USE gaindb; SELECT STDDEV(${col}) FROM fit_results WHERE fit_id IN (${list});"
std=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}")
# Repeat for error info
query="USE gaindb; SELECT AVG(${col_err}) FROM fit_results WHERE fit_id IN (${list});"
ave_error=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}")
query="USE gaindb; SELECT STDDEV(${col_err}) FROM fit_results WHERE fit_id IN (${list});"
std_error=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}")

echo "${col} (avg, std):  (${ave}, ${std})"
echo "${col_err} (avg, std):  (${ave_error}, ${std_error})"
