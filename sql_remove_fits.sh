# Initialize
im_dir="$(grep im_dir setup.txt | awk -F'=' '{print $2}')"
table="fit_results"
csv_file="selected_fits.csv"

# Parse input
for item in $* ; do
	name=$(echo ${item} | awk -F'=' '{print $1}')
	val=${item#${name}=}
	# Use high light fitter instead
	if [[ ${name} == "high-light" ]] ; then
		table="high_light_results"
		csv_file="selected_high_light_fits.csv"
	fi
done

# Double check before we delete
read -p "Are you sure you want to delete rows from ${table}? (y/n)  " val
if [[ ${val:0:1} != "y" && ${val:0:1} != "Y" ]] ; then
	exit
fi

# Grab the fits
fits=$(head ${csv_file})
if [ ${#fits} -eq 0 ] ; then
	echo no fits
	exit
fi

# Delete the pictures
if [[ ${table} == "fit_results" ]] ; then
	query="USE gaindb; SELECT CONCAT('${im_dir}/', human_png) FROM ${table} WHERE fit_id IN (${fits}) AND human_png IS NOT NULL;"
	files=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}")
	if [ ${#files} -gt 0 ] ; then
		rm ${files}
	fi
	query="USE gaindb; SELECT CONCAT('${im_dir}/', nn_png) FROM ${table} WHERE fit_id IN (${fits}) AND nn_png IS NOT NULL;"
	files=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}")
	if [ ${#files} -gt 0 ] ; then
		rm ${files}
	fi
elif [[ ${table} == "high_light_results" ]] ; then
	query="USE gaindb; SELECT CONCAT('${im_dir}/', png_file) FROM ${table} WHERE fit_id IN (${fits}) AND png_file IS NOT NULL;"
	files=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}")
	if [ ${#files} -gt 0 ] ; then
		rm ${files}
	fi
fi

# Delete the rows from the table
mysql --defaults-extra-file=~/.mysql.cnf -Bse "USE gaindb; DELETE FROM ${table} WHERE fit_id IN (${fits});"

# Update the table with lowest possible auto-increment id
newval=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "USE gaindb; SELECT MAX(fit_id) FROM ${table};")
newval=$((newval + 1))
mysql --defaults-extra-file=~/.mysql.cnf -Bse "USE gaindb; ALTER TABLE ${table} AUTO_INCREMENT = ${newval};"
