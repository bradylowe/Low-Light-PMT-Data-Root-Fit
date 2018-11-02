
# Grab selected fits and put commas in there
list=$(head selected_fits.txt | sed "s/ /,/g")
if [ ${#list} -eq 0 ] ; then
	echo no fits
	exit
fi

# Query database using info from run_params and fit_results tables
query="USE gaindb; SELECT AVG(gain) FROM fit_results WHERE fit_id IN (${list});"
ave_gain=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}")
query="USE gaindb; SELECT STDDEV(gain) FROM fit_results WHERE fit_id IN (${list});"
std_gain=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}")
query="USE gaindb; SELECT AVG(gain_error) FROM fit_results WHERE fit_id IN (${list});"
ave_error=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}")
query="USE gaindb; SELECT STDDEV(gain_error) FROM fit_results WHERE fit_id IN (${list});"
std_error=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}")

echo "Gain (avg, std):  (${ave_gain}, ${std_gain})"
echo "Error (avg, std): (${ave_error}, ${std_error})"
