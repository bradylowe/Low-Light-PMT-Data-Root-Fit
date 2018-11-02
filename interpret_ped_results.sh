
while read line ; do
	# Get values from line
	id=$(echo ${line} | awk '{print $1}' | awk -F':' '{print $2}')
	scale=$(echo ${line} | awk '{print $2}' | awk -F':' '{print $2}')
	signal=$(echo ${line} | awk '{print $3}' | awk -F':' '{print $2}')

	# Measure mu_out
	count=$(./sql_select_fits.sh "run_id=${id}" "TRUE" | awk '{print $1}')
	if [ ${count} -eq 0 ] ; then
		continue
	fi
	mu=$(./sql_average.sh mu_out)
	mu=${mu%,*}
	mu=${mu#*:*(}

	# Get hv from sql table
	hv=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "USE gaindb; SELECT hv FROM run_params WHERE run_id=${id};")
	pmt=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "USE gaindb; SELECT pmt FROM run_params WHERE run_id=${id};")

	# Compute gain measurement
	gain=$(root -l -q -b "divide.c(${signal}, ${mu})")
	gain=${gain#*(double) }
	gain=$(root -l -q -b "sigToGain.c(${gain}, ${mu}, ${scale})")
	gain=${gain#*(double) }
	echo "${id} (pmt${pmt}, ${hv}V): ${gain}"
done < ped_results.txt
