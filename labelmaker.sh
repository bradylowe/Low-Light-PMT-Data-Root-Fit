
# PNG location
im_dir="/media/data/Projects/fit_pmt/images/png_fit/"

# Get list of png filenames
query="USE gaindb; SELECT human_png FROM fit_results WHERE nn_png IS NOT NULL AND label IS NULL ORDER BY fit_id;"
output=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}")

# Now, loop through the items on the list, but
# allow for scrolling back and forth.
lastpng=""
count=0
for png in ${output} ; do
	
	# Show image, save PID, wait for input
	eog ${im_dir}/${png} &
	child=$!
	read -n 1 choice

	# Exit, if user says "q" or "e"
	if [[ ${choice} == "q" || ${choice} == "e" ]] ; then
		kill ${child}
		echo
		exit
	# Get rid of the previous label
	elif [[ ${choice} == "u" && ${lastpng} != "" ]] ; then
		query="USE gaindb; UPDATE fit_results SET label=NULL WHERE human_png='${lastpng}';"
		mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}"
	# Label image if numeric digit is given
	elif [ ${choice} -ge 0 -a ${choice} -le 9 ] ; then
		query="USE gaindb; UPDATE fit_results SET label=${choice} WHERE human_png='${png}';"
		mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}"
		count=$((count + 1))
		if [ $((${count} % 100)) -eq 0 ] ; then
			echo 
			echo "Labeled ${count} images"
			echo
		fi
	fi

	# Exit the eog image
	kill ${child}
	# Remember the last png filename
	lastpng=${png}
done

echo
