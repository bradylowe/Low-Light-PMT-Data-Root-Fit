
# Initialize input parameters
pmt_list="1 2 3 4 5 6"
good=1

# Parse input
for item in $* ; do
	# Decompose input
	name=$(echo ${item} | awk -F'=' '{print $1}')
	val=${item#${name}=}
	if [[ ${name} == "pmt" ]] ; then
		pmt_list=${val}
	elif [[ ${name} = "hv" ]] ; then
		hv=${val}
	elif [[ ${name} == "good" ]] ; then
		good=${val}
	fi
done

# Loop through all pmt's in pmt list
for pmt in ${pmt_list} ; do
	# Select hv_list
	if [ ${pmt} -le 4 ] ; then
		hv_list="2000 1975 1950 1925 1900"
	else
		hv_list="1300 1250 1200 1150 1100"
	fi
	if [ ${#hv} -gt 0 ] ; then
		hv_list=${hv}
	fi

	# Loop through all hv's in hv list
	echo
	echo pmt ${pmt}
	echo ================================
	for hv in ${hv_list} ; do
		./sql_select_ids.sh id="fit_id" recent=1 good=${good} hv=${hv} pmt=${pmt}
		echo hv: ${hv}
		./sql_ave_errors.sh
		./sql_ave_errors.sh sig_out
		echo ================================
	done
done
