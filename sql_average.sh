
column="gain"
table="fit_results"
csv_file="selected_fits.csv"

for item in $* ; do
	name=$(echo ${item} | awk -F'=' '{print $1}')
	val=${item#${name}=}
	if [[ ${name} == "column" ]] ; then
		column=${val}
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
query="USE gaindb; SELECT AVG(${column}) FROM ${table} WHERE fit_id IN (${list});"
ave=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}")
query="USE gaindb; SELECT STDDEV(${column}) FROM ${table} WHERE fit_id IN (${list});"
std=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}")

echo "${column} (avg, std):  (${ave}, ${std})"
