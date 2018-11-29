# Initialize 
im_dir="$(grep im_dir setup.txt | awk -F'=' '{print $2}')"
table="fit_results"
csv_file="selected_fits.csv"

# Parse input parameters
for item in $* ; do
	name=$(echo ${item} | awk -F'=' '{print $1}')
	val=${item#${name}=}
	# Grab fit type (low/high light fitter)
	if [[ ${name} == "high-light" ]] ; then
		table="high_light_results"
		csv_file="selected_high_light_fits.csv"
	fi
done

read -p "Are you sure you want to delete rows from ${table}? (y/n)  " val
if [[ ${val:0:1} != "y" && ${val:0:1} != "Y" ]] ; then
	exit
fi

# Grab the selected fits
fits=$(head ${csv_file})
fits_space=$(head ${csv_file} | sed "s/,/ /g")
for id in ${fits_space} ; do
	if [[ ${table} == "fit_results" ]] ; then
		# Delete associated pngs
		query="USE gaindb; SELECT CONCAT('${im_dir}/', human_png) FROM ${table} WHERE fit_id=${id} AND human_png IS NOT NULL;"
		files=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}")
		if [ ${#files} -gt 0 ] ; then
			rm ${files}
		fi
		# Delete associated nn pngs
		query="USE gaindb; SELECT CONCAT('${im_dir}/', nn_png) FROM ${table} WHERE fit_id=${id} AND nn_png IS NOT NULL;"
		files=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}")
		if [ ${#files} -gt 0 ] ; then
			rm ${files}
		fi
	elif [[ ${table} == "high_light_results" ]] ; then
		# Delete associated pngs
		query="USE gaindb; SELECT CONCAT('${im_dir}/', png_file) FROM ${table} WHERE fit_id=${id} AND png_file IS NOT NULL;"
		files=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}")
		if [ ${#files} -gt 0 ] ; then
			rm ${files}
		fi
	fi
done

# Delete rows from table
mysql --defaults-extra-file=~/.mysql.cnf -Bse "USE gaindb; DELETE FROM ${table} WHERE fit_id IN (${fits});"

# Update fit_id to lowest unused value greater than highest used value
newval=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "USE gaindb; SELECT MAX(fit_id) FROM ${table};")
newval=$((newval + 1))
mysql --defaults-extra-file=~/.mysql.cnf -Bse "USE gaindb; ALTER TABLE ${table} AUTO_INCREMENT = ${newval};"
