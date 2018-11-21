
data_dir=$(grep data_dir setup.txt | awk -F'=' '{print $2}')
im_dir=$(grep im_dir setup.txt | awk -F'=' '{print $2}')
noSQL=0
savePNG=1


if [[ $1 == "scale=1" ]] ; then
	scale=1
else
	scale=0
fi

files=$(head selected_runs.csv | sed "s/,/ /g")

for cur_id in ${files} ; do
	# Grab the filename
	filename=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "USE gaindb; SELECT rootfile FROM run_params WHERE run_id=${cur_id};")

	# Insert a new row in the fit_results table and grab the fit_id
	if [ ${noSQL} -eq 0 ] ; then
		mysql --defaults-extra-file=~/.mysql.cnf -Bse "USE gaindb; INSERT INTO high_light_results (run_id) VALUES(${cur_id});"
		fit_id=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "USE gaindb; SELECT fit_id FROM high_light_results WHERE run_id=${cur_id} ORDER BY fit_id DESC LIMIT 1;")
	else
		fit_id=0
	fi

	# Run the fitting algorithm
	chi2=$(root -b -q -l "fit_high_light.c(\"${data_dir}/${filename}\", ${cur_id}, ${fit_id}, ${scale})")
	chi2=$(echo ${chi2} | awk '{print $NF}')
	#echo run:${id} scale:${scale} signal:${res} >> ped_results.txt
	# Put the image where it goes
	
	# Query the database to store all output info from this fit
	sqlfile="sql_output_high_light_${fit_id}.csv"
	if [ -f ${sqlfile} -a ${noSQL} -eq 0 ] ; then
		# Move the images to the storage directories
		if [ ${savePNG} -gt 0 ] ; then
			mv high_light_${fit_id}.png ${im_dir}/png_high_light/.
		fi
		# Initialize the update query
		query="USE gaindb; UPDATE high_light_results SET $(head -n 1 ${sqlfile})"
		query="${query} WHERE fit_id=${fit_id};"
		# We don't want anything that is "not a number"
		query=$(echo ${query} | sed "s/nan/-1.0/g")
		res=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}")
		# Delete file after query submission to avoid double submission
		if [[ ${res:0:5} != "ERROR" ]] ; then
			rm ${sqlfile}
		# If there was an error with this query, drop the row from the table
		else
			mysql --defaults-extra-file=~/.mysql.cnf -Bse "USE gaindb; DELETE FROM high_light_results WHERE fit_id=${fit_id};"
		fi

		# If no exponential on ped, set label=10 as a hack
		if [ ${#label} -gt 0 ] ; then
			mysql --defaults-extra-file=~/.mysql.cnf -Bse "USE gaindb; UPDATE high_light_results SET label=${label} WHERE fit_id=${fit_id};"
		fi
		# If error, write error value to fit_results table in chi column
	elif [ ${chi2} -lt 0 ] ; then
		query="USE gaindb; UPDATE high_light_results SET chi=${chi2} WHERE fit_id=${fit_id};"
		res=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}")
	fi

done
