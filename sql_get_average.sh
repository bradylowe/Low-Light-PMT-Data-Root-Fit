
# Look at input parameters
if [ $# -ne 3 ] ; then
	echo error
	exit
fi

run_cond=$2
fit_cond=$3
# Grab parameter to find average of
table=$(echo $1 | awk -F'.' '{print $1}')
param=$(echo $1 | awk -F'.' '{print $2}')

# Query database using info from run_params and fit_results tables
if [[ ${table} == "fit_results" ]] ; then
	query="USE gaindb; SELECT ${param} FROM fit_results WHERE fit_results.run_id IN (SELECT run_id FROM run_params WHERE ${run_cond}) AND ${fit_cond};"
	values=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}")
else
	query="USE gaindb; SELECT ${param} FROM run_params WHERE run_params.run_id IN (SELECT run_id FROM fit_results WHERE ${fit_cond}) AND ${run_cond};"
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
if [ ${count} -eq 0 ] ; then
	echo no runs
	exit
fi
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
