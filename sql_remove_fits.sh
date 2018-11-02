
# Grab image directory
im_dir="$(grep im_dir setup.txt | awk -F'=' '{print $2}')"

# Grab fits from file
fits=$(head selected_fits.txt)

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
