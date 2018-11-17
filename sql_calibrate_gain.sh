
# Initialize input parameters
pmt_list=""

# Parse input
for item in $* ; do
	# Decompose input
	name=$(echo ${item} | awk -F'=' '{print $1}')
	val=${item#${name}=}
	if [[ ${name} == "pmt" ]] ; then
		pmt_list=${val}
	elif [[ ${name} = "hv" ]] ; then
		hv=${val}
	fi
done

# Loop through all pmt's in pmt list
for pmt in ${pmt_list} ; do

	# Pick the right calibration file
	csv_file="calibration/pmt${pmt}_gain.csv"
	
	# Select hv_list
	if [ ${pmt} -le 4 ] ; then
		hv_list="2000 1975 1950 1925 1900 1800 1700 1600"
	else
		hv_list="1350 1300 1250 1200 1150 1100 1050 100"
	fi
	if [ ${#hv} -gt 0 ] ; then
		hv_list=${hv}
	fi

	# Loop through all hv's in hv list
	for hv in ${hv_list} ; do
		./sql_select_ids.sh id="fit_id" recent=1 good=1 hv=${hv} pmt=${pmt} >> /dev/null
		out=$(./sql_average.sh sig_out)
		new_val=${out#*:  (}
		new_val=${new_val%,*}
		check=$(echo ${new_val} | grep .)
		if [[ ${check} != "no fits" && ${check:0:1} != "-" ]] ; then
			old_line=$(grep ${hv} calibration/pmt${pmt}_gain.csv)
			old_val=$(echo ${old_line} | awk -F',' '{print $2}')
			new_line=$(echo ${old_line} | sed "s/${old_val}/${new_val}/g")
			sed -i "s/${old_line}/${new_line}/g" ${csv_file}
			echo updated pmt${pmt} hv${hv} with ${new_val}
		fi
	done
done
