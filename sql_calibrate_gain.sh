
# Initialize input parameters
pmt_list=""
ok=0
good=0
better=0

# Parse input
for item in $* ; do
	# Decompose input
	name=$(echo ${item} | awk -F'=' '{print $1}')
	val=${item#${name}=}
	if [[ ${name} == "pmt" ]] ; then
		pmt_list=${val}
	elif [[ ${name} = "hv" ]] ; then
		hv=${val}
	elif [[ ${name} = "ok" ]] ; then
		ok=${val}
	elif [[ ${name} = "good" ]] ; then
		good=${val}
	elif [[ ${name} = "better" ]] ; then
		better=${val}
	fi
done

# Loop through all pmt's in pmt list
for pmt in ${pmt_list} ; do

	# Pick the right calibration file
	csv_file="calibration/pmt${pmt}_gain.csv"
	
	# Select hv_list
	if [ ${pmt} -le 4 ] ; then
		hv_list="2000 1975 1950 1925 1900 1800 1700 1600 1500 1400 1300 1200 1100 1000 900 800 700"
	else
		hv_list="1350 1300 1250 1200 1150 1100 1050 1000 900 800 700 600 500"
	fi
	if [ ${#hv} -gt 0 ] ; then
		hv_list=${hv}
	fi

	# Loop through all hv's in hv list
	for hv in ${hv_list} ; do
		# Select the good fits
		./sql_select_ids.sh fit recent=1 good=${good} ok=${ok} better=${better} hv=${hv} pmt=${pmt} >> /dev/null
		# Grab the average signal size and average signal rms of the fits
		out=$(./sql_average.sh sig_out)
		out_rms=$(./sql_average.sh sig_rms_out)
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
			old_line=$(grep ${hv}, ${csv_file} | head -n 1)
			old_val=$(echo ${old_line} | awk -F',' '{print $2}')
			new_line="${hv},${new_val},${new_rms},"
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
