
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
	if [ ${pmt} -le 4 ] ; then
		ll_list="2000 1975 1950 1925 1900 1800 1700 1600"
	else
		ll_list="1350 1300 1250 1200 1150 1100 1050 1000"
	fi
	if [ ${#ll} -gt 0 ] ; then
		ll_list=${ll}
	fi

	# Loop through all ll's in ll list
	for ll in ${ll_list} ; do
		# Select the good fits
		./sql_select_ids.sh fit recent=1 good=${good} run_cond="filter=7" ll=${ll} pmt=${pmt} >> /dev/null
		# Grab the average signal size and average signal rms of the fits
		out=$(./sql_average.sh sig_out)
		rms_out=$(./sql_average.sh sig_rms_out)
		new_val=${out#*:  (}
		new_val=${new_val%,*}
		new_rms=${out_rms#*:  (}
		new_rms=${new_rms%,*}
		check=$(echo ${new_val} | grep .)
		check_rms=$(echo ${new_rms} | grep .)
		# Absolute value
		if [[ ${check_rms:0:1} == "-" ]] ; then
			check_rms=${check_rms:1}
		fi
		# If values are good
		if [[ ${check} != "no fits" && ${check:0:1} != "-" ]] ; then
			# Grab the existing line from the file with this high voltage
			old_line=$(grep ${ll}, ${csv_file})
			old_val=$(echo ${old_line} | awk -F',' '{print $2}')
			new_line="${ll},${new_val},${new_rms},"
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
