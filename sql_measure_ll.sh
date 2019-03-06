
# Initialize input parameters
pmt_list=""
quality=4
regime="all"
calibrate=0
ll_list="20 30 40 50 60 70 80 90 100"
run_cond="TRUE"
fit_cond="TRUE"
filter=7
min_hv=0

# Parse input
for item in $* ; do
	# Decompose input
	name=$(echo ${item} | awk -F'=' '{print $1}')
	val=${item#${name}=}
	if [[ ${name} == "pmt" ]] ; then
		pmt_list=${val}
	elif [[ ${name} = "min_hv" ]] ; then
		min_hv=${val}
	elif [[ ${name} = "ll" ]] ; then
		ll_list=${val}
	elif [[ ${name} == "quality" ]] ; then
		quality=${val}
	elif [[ ${name} == "regime" ]] ; then
		regime=${val}
	elif [[ ${name} == "filter" ]] ; then
		filter=${val}
	elif [[ ${name} == "calibrate" ]] ; then
		calibrate=1
	fi
done

# Loop through all pmt's in pmt list
for pmt in ${pmt_list} ; do

	# Clear the calibration files and add headers
	if [ ${calibrate} -ne 1 ] ; then
		echo "LL,Mu,Root-Error,Mu-RMS"
	fi

	for ll in ${ll_list} ; do
		nfits=$(./sql_select.sh pmt=${pmt} ll=${ll} filter=${filter} regime=${regime} recent=1 quality=${quality} run_cond="${run_cond}&&hv>=${min_hv}" fit_cond="${fit_cond}" | awk '{print $1}')

		if [ ${nfits} -eq 0 ] ; then
			continue
		fi

		# Calculate gain and error
		ret=$(./sql_ave_errors.sh column=mu_out error=mu_out_error)
		mu=$(echo ${ret} | awk -F'(' '{print $3}' | awk -F',' '{print $1}')
		mu_error=$(echo ${ret} | awk -F'(' '{print $5}' | awk -F',' '{print $1}')
		mu_rms=$(echo ${ret} | awk -F'(' '{print $3}' | awk '{print $2}' | awk -F')' '{print $1}')

		if [ ${calibrate} -eq 1 ] ; then

			# Grab current values from file
			old_line=$(grep ${ll}, calibration/pmt${pmt}_ll.csv | head -n 1)
			old_mu=$(echo ${old_line} | awk -F',' '{print $2}')
			sed -i "s/${ll},${old_mu}/${ll},${mu}/g" calibration/pmt${pmt}_ll.csv
		else
			echo "${ll},${mu},${mu_error},${mu_rms}"
		fi

	done
done
