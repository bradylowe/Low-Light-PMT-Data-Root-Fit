
# Get list of png filenames
query="USE gaindb; SELECT nn_png FROM fit_results WHERE nn_png IS NOT NULL AND label IS NULL ORDER BY run_id DESC LIMIT 100;"
output=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}")

# Store record of pngs viewed
list=""
count=0
# Loop through all the pngs in that directory
for png in ${output} ; do
	# Create the corresponding log filename
	logpng=$(echo ${png} | sed "s/log0/log1/g")
	# Create a filename for both plots together for us to view
	bothpng=$(echo ${png} | sed "s/log0/logX/g")
	# indexf the log plot is not found, skip this one
	if [ ! -f ${logpng} ] ; then
		echo ${logpng} not found
		continue
	fi
	# Create concat version of two plots for viewing
	montage -label "%f" -frame 5 -geometry 500x400+1+1 ${png} ${logpng} ${bothpng} 
	# Record filename for cleanup later
	list="${list} ${bothpng}"
	count=$((count + 1))
	echo ${bothpng} created
done

# Now, loop through the items on the list, but
# allow for scrolling back and forth.
choice="begin"
index=0
array=(${list})
while [[ ${choice} != "e" && ${choice} != "q" ]] ; do
	
	# Check index is in bounds
	if [ ${index} -ge ${count} ] ; then
		break
	elif [ ${index} -lt 0 ] ; then
		index=$((count - 1))
	fi

	# Grab filenames of current image
	bothpng=$(echo ${array[${index}]})
	png=$(echo ${bothpng} | sed "s/logX/log0/g")

	# Show image, save ID, wait for input
	eog ${bothpng} &
	child=$!
	read -n 1 choice

	# Label image if necessary
	if [[ ${choice} == "2" || ${choice} == "1" || ${choice} == "0" ]] ; then
		query="USE gaindb; UPDATE fit_results SET label=${choice} WHERE nn_png='${png}';"
		mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}"
	elif [[ ${choice} == "u" ]] ; then
		index=$((index - 1))
		bothpng=$(echo ${array[${index}]})
		png=$(echo ${bothpng} | sed "s/logX/log0/g")
		query="USE gaindb; UPDATE fit_results SET label=NULL WHERE nn_png='${png}';"
		mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}"
	fi

	# Update index
	index=$((index + 1))

	# Exit the eog image
	kill ${child}
done






rm ${list}


