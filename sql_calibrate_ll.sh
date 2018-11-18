
# Initialize input parameters
pmt_list=""
good=1

# Parse input
for item in $* ; do
	# Decompose input
	name=$(echo ${item} | awk -F'=' '{print $1}')
	val=${item#${name}=}
	if [[ ${name} == "pmt" ]] ; then
		pmt_list=${val}
	elif [[ ${name} = "ll" ]] ; then
		ll=${val}
	elif [[ ${name} = "good" ]] ; then
		good=${val}
	fi
done

# Loop through all pmt's in pmt list
for pmt in ${pmt_list} ; do

	# Pick the right calibration file
	csv_file="calibration/pmt${pmt}_ll.csv"
	
	# Select ll_list
	ll_list="20 30 40 50 90 100"
	if [ ${#ll} -gt 0 ] ; then
		ll_list=${ll}
	fi

	# Loop through all ll's in ll list
	for ll in ${ll_list} ; do
		# Select the good fits
		./sql_select_ids.sh fit recent=1 good=${good} run_cond="filter=7&&ll=${ll}" pmt=${pmt} >> /dev/null
		# Grab the average PEs per flash from the fits
		out=$(./sql_average.sh mu_out)
		new_val=${out#*:  (}
		new_val=${new_val%,*}
		check=$(echo ${new_val} | grep .)
		# Absolute value
		# If values are good
		if [[ ${check} != "no fits" && ${check:0:1} != "-" ]] ; then
			# Grab the existing line from the file with this high voltage
			old_line=$(grep ${ll}, ${csv_file})
			old_val=$(echo ${old_line} | awk -F',' '{print $2}')
			new_line="${ll},${new_val},"
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
done
