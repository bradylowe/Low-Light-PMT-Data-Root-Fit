
# Get column from command line
if [ $# -eq 0 ] ; then
	echo choose a column
	exit
fi
column=$1

# Grab selected fits and put commas in there
list=$(head selected_fits.txt | sed "s/ /,/g")
if [ ${#list} -eq 0 ] ; then
	echo no fits
	exit
fi

# Query database using info from run_params and fit_results tables
query="USE gaindb; SELECT AVG(${column}) FROM fit_results WHERE fit_id IN (${list});"
ave=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}")
query="USE gaindb; SELECT STDDEV(${column}) FROM fit_results WHERE fit_id IN (${list});"
std=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}")
# Repeat for error info
query="USE gaindb; SELECT AVG(${column}_error) FROM fit_results WHERE fit_id IN (${list});"
ave_error=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}")
query="USE gaindb; SELECT STDDEV(${column}_error) FROM fit_results WHERE fit_id IN (${list});"
std_error=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}")

echo "${column} (avg, std):  (${ave}, ${std})"
echo "${column}_error (avg, std):  (${ave_error}, ${std_error})"
