
# Get column from command line
col="gain"
col_err="gain_percent_error"
table="fit_result"
csv_file="selected_fits.csv"

# Parse input
for item in $* ; do
	name=$(echo ${item} | awk -F'=' '{print $1}')
	val=${item#${name}=}
	if [[ ${name} == "column" ]] ; then
		col=${val}
	elif [[ ${name} == "error" ]] ; then
		col_err=${val}
	elif [[ ${name} == "high-light" ]] ; then
		table="high_light_results"
		csv_file="selected_high_light_fits.csv"
	fi
done

# Grab selected fits and put commas in there
list=$(head ${csv_file})
if [ ${#list} -eq 0 ] ; then
	echo no fits
	exit
fi

# Query database using info from run_params and fit_results tables
query="USE gaindb; SELECT AVG(${col}) FROM ${table} WHERE fit_id IN (${list});"
ave=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}")
query="USE gaindb; SELECT STDDEV(${col}) FROM ${table} WHERE fit_id IN (${list});"
std=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}")
# Repeat for error info
query="USE gaindb; SELECT AVG(${col_err}) FROM ${table} WHERE fit_id IN (${list});"
ave_error=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}")
query="USE gaindb; SELECT STDDEV(${col_err}) FROM ${table} WHERE fit_id IN (${list});"
std_error=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}")

echo "${col} (avg, std):  (${ave}, ${std})"
echo "${col_err} (avg, std):  (${ave_error}, ${std_error})"
