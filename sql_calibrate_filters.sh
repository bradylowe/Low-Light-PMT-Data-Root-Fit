
# Initialize parameters
quality=4
csv_file="calibration/filters.csv"
filter_list="1 8"

# Parse input
for item in $* ; do
	# Decompose input
	name=$(echo ${item} | awk -F'=' '{print $1}')
	val=${item#${name}=}
	if [[ ${name} = "quality" ]] ; then
		quality=${val}
	fi
done

# Loop through all hv's in hv list
for filter in ${filter_list} ; do
	# Select the good fits
	./sql_select_fits.sh recent=1 quality=${quality} hv=${hv} filter=${filter} >> /dev/null
	# Grab the average signal size and average signal rms of the fits
	out=$(./sql_average.sh column=mu_out)
	out_err=$(./sql_average.sh column=mu_out_error)
	new_val=${out#*:  (}
	new_val=${new_val%,*}
	new_err=${out_rms#*:  (}
	new_err=${new_err%,*}
	check=$(echo ${new_val} | grep .)
	check_rms=$(echo ${new_err} | grep .)
	# Absolute value
	if [[ ${check_rms:0:1} == "-" ]] ; then
		new_err=${new_err:1}
	fi
	# If values are good
	if [[ ${check} != "no fits" && ${check:0:1} != "-" ]] ; then
		# Grab the existing line from the file with this high voltage
		old_line=$(grep ${filter}, ${csv_file} | head -n 1)
		old_val=$(echo ${old_line} | awk -F',' '{print $2}')
		new_line="${filter},${new_val},${new_err},"
		# Store new value if none exists
		if [ ${#old_line} -eq 0 ] ; then
			echo ${new_line} >> ${csv_file}
		else
			# Check with the user before changing the file
			read -p "Overwrite ${old_line} with ${out}?  " choice
			if [[ ${choice:0:1} == "y" || ${choice:0:1} == "Y" ]] ; then
				sed -i "s/${old_line}/${new_line}/g" ${csv_file}
			fi
		fi
	fi
done
