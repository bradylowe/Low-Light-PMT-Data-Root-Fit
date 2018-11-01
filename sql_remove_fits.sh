
im_dir="$(grep im_dir setup.txt | awk -F'=' '{print $2}')"

# Look at input parameters
if [ $# -eq 1 ] ; then
	fit_cond=$1
else
	run_cond=$1
	fit_cond=$2
fi

# Query database using info from run_params and fit_results tables
if [ ${#run_cond} -gt 0 ] ; then
	fits=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "USE gaindb; SELECT fit_id FROM fit_results WHERE fit_results.run_id IN (SELECT run_id FROM run_params WHERE ${run_cond}) AND ${fit_cond};")
else
	fits=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "USE gaindb; SELECT fit_id FROM fit_results WHERE ${fit_cond};")
fi

# Count results for printing
count=0
for item in ${fits} ; do
	count=$((count + 1))
done

echo ${count} fits selected
# Delete pngs, remove row in sql table
for id in ${fits} ; do
	files=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "USE gaindb; SELECT CONCAT('${im_dir}/png_fit/', human_png) FROM fit_results WHERE fit_id=${id} AND human_png IS NOT NULL;")
	if [ ${#files} -gt 0 ] ; then
		rm ${files}
	fi
	files=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "USE gaindb; SELECT CONCAT('${im_dir}/png_fit_nn/', nn_png) FROM fit_results WHERE fit_id=${id} AND nn_png IS NOT NULL;")
	if [ ${#files} -gt 0 ] ; then
		rm ${files}
	fi
	mysql --defaults-extra-file=~/.mysql.cnf -Bse "USE gaindb; DELETE FROM fit_results WHERE fit_id=${id};"
done

# update fit_id to lowest unused value greater than highest used value
newval=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "USE gaindb; SELECT MAX(fit_id) FROM fit_results;")
newval=$((newval + 1))
mysql --defaults-extra-file=~/.mysql.cnf -Bse "USE gaindb; ALTER TABLE fit_results AUTO_INCREMENT = ${newval};"
