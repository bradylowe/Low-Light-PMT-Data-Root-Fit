
# Get column from command line
if [ $# -eq 0 ] ; then
	column="gain"
else
	column=$1
fi

# Grab selected fits and put commas in there
list=$(head selected_fits.csv)
if [ ${#list} -eq 0 ] ; then
	echo no fits
	exit
fi

# Query database using info from run_params and fit_results tables
query="USE gaindb; SELECT AVG(${column}) FROM fit_results WHERE fit_id IN (${list});"
ave=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}")
query="USE gaindb; SELECT STDDEV(${column}) FROM fit_results WHERE fit_id IN (${list});"
std=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}")

echo "${column} (avg, std):  (${ave}, ${std})"
