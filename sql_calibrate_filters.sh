
# Initialize parameters
quality=4
csv_file="calibration/filters.csv"
filter_list="1 8"
hv_list="1000"
ll_list="30 40 50 60 70 80 90 100"

# Parse input
for item in $* ; do
	# Decompose input
	name=$(echo ${item} | awk -F'=' '{print $1}')
	val=${item#${name}=}
	if [[ ${name} = "quality" ]] ; then
		quality=${val}
	elif [[ ${name} == "hv" ]] ; then
		hv_list=${val}
	elif [[ ${name} == "ll" ]] ; then
		ll_list=${val}
	elif [[ ${name} == "filter" ]] ; then
		filter_list=${val}
	fi
done

# Loop through all hv's in hv list
for filter in ${filter_list} ; do
	for hv in ${hv_list} ; do
		for ll in ${ll_list} ; do
# Select the good fits with filter and low light
./sql_select_fits.sh pmt=6 quality=${quality} filter=${filter} hv=${hv} ll=${ll}
mu=$(./sql_average.sh column=mu_out | awk -F'(' '{print $3}' | awk -F',' '{print $1}')
mu_error=$(./sql_average.sh column=mu_out_error | awk -F'(' '{print $3}' | awk -F',' '{print $1}')

# Select the good fits with NO filter and low light
./sql_select_fits.sh pmt=6 quality=${quality} filter=7 hv=${hv} ll=${ll}
mu0=$(./sql_average.sh column=mu_out | awk -F'(' '{print $3}' | awk -F',' '{print $1}')
mu0_error=$(./sql_average.sh column=mu_out_error | awk -F'(' '{print $3}' | awk -F',' '{print $1}')

# Select the good fits with filter and high light
./sql_select_fits.sh pmt=6 high-light filter=${filter} hv=${hv} ll=${ll}
sig=$(./sql_average.sh column=sig_out high-light | awk -F'(' '{print $3}' | awk -F',' '{print $1}')
sig_error=$(./sql_average.sh column=sig_out_error high-light | awk -F'(' '{print $3}' | awk -F',' '{print $1}')

# Grab the gain of this hv
gain=$(grep ${hv} calibration/pmt6_gain.csv | head -n 1 | awk -F',' '{print $2}')
gain_error=$(grep ${hv} calibration/pmt6_gain.csv | head -n 1 | awk -F',' '{print $3}')

# Initialize line to print
line="(filter${filter}, hv${hv}, ll${ll})"

# If mu0 value is good
if [ ${#mu0} -gt 0 ] ; then
	# Try to do low-light measurement
	if [ ${#mu} -gt 0 ] ; then
		# Grab the existing line from the file with this high voltage
		old_line=$(grep ${filter}, ${csv_file} | head -n 1)
		# Calculate mu from high light signal
		new_val=$(root -l -b -q "divide.c(${mu}, ${mu0})")
		new_val=${new_val#*(double) }
		new_line="${filter},${new_val},"
		# Check with the user before changing the file
		#read -p "Update ${old_line} with ${new_line}?  " choice
		#if [[ ${choice:0:1} == "y" || ${choice:0:1} == "Y" ]] ; then
		#	sed -i "s/${old_line}/${new_line}/g" ${csv_file}
		#fi
		line="${line} (low-light: ${new_val})"
	fi
	# Try to do high-light measurement
	if [ ${#sig} -gt 0 -a ${#gain} -gt 0 ] ; then
		# Grab the existing line from the file with this high voltage
		old_line=$(grep ${filter}, ${csv_file} | head -n 1)
		# Calculate mu from high light signal
		mu_high=$(root -l -b -q "divide.c(${sig}, ${gain})")
		mu_high=${mu_high#*(double) }
		new_val=$(root -l -b -q "divide.c(${mu_high}, ${mu0})")
		new_val=${new_val#*(double) }
		new_line="${filter},${new_val},"
		line="${line} (high-light: ${new_val})"
		# Check with the user before changing the file
		#read -p "(high-light) Update ${old_line} with ${new_line}?  " choice
		#if [[ ${choice:0:1} == "y" || ${choice:0:1} == "Y" ]] ; then
		#	sed -i "s/${old_line}/${new_line}/g" ${csv_file}
		#fi
	fi
fi
echo ${line}


		done
	done
done
