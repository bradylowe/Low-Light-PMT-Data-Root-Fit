
column="gain"
table="fit_results"
regime="all"

for item in $* ; do
	name=$(echo ${item} | awk -F'=' '{print $1}')
	val=${item#${name}=}
	if [[ ${name} == "column" ]] ; then
		column=${val}
	elif [[ ${name} == "regime" ]] ; then
		regime=${val}
	fi
done

# Grab selected fits and put commas in there
list=$(head selected_fits.csv)
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
