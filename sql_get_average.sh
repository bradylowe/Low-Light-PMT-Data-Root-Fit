
pmt=1

# Define default conditions
defaults="gain > 0 AND gain_error > 0 AND gain_percent_error < 10 AND con_gain > 10 AND con_ll < 100 AND con_ll > 0 AND mu_out < 10"

# Look at input parameters
if [ $# -eq 0 ] ; then
	echo error
	exit
elif [ $# -eq 1 ] ; then
	fit_cond=${defaults}
elif [ $# -eq 2 ] ; then
	fit_cond="$2 AND ${defaults}"
else
	run_cond=$2
	fit_cond="$3 AND ${defaults}"
fi

# Grab parameter to find average of
table=$(echo $1 | awk -F'.' '{print $1}')
param=$(echo $1 | awk -F'.' '{print $2}')

# Query database using info from run_params and fit_results tables
if [ ${#run_cond} -gt 0 ] ; then
	query="USE gaindb; SELECT ${param} FROM ${table} WHERE fit_results.run_id IN (SELECT run_id FROM run_params WHERE ${run_cond} AND pmt=${pmt}) AND ${fit_cond};"
	values=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}")
else
	query="USE gaindb; SELECT ${param} FROM ${table} WHERE ${fit_cond};"
	values=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}")
fi

# Count results for printing
values=$(echo ${values} | sed "s/\.//g")

count=0
sum=0
# Get average
for item in ${values} ; do
	sum=$((sum + item))
	count=$((count + 1))
done
ave=$((sum / count))

sum=0
for item in ${values} ; do
	diff=$((item - ave))
	diff=$((diff * diff))
	sum=$((sum + diff))
done
var=$((sum / count))

echo average: ${ave}
echo variance: ${var}
