
# Initialize input parameters
pmt_list="1 2 3 4"
hv_list="2000 1975 1950 1925 1900"
good=1

# Parse input
for item in $* ; do
	# Decompose input
	name=$(echo ${item} | awk -F'=' '{print $1}')
	val=${item#${name}=}
	if [[ ${name} == "pmt_list" || ${name} == "pmt" ]] ; then
		pmt_list=${val}
	elif [[ ${name} == "hv_list" || ${name} = "hv" ]] ; then
		hv_list=${val}
	elif [[ ${name} == "good" ]] ; then
		good=${val}
	fi
done

# Loop through all pmt's in pmt list
for pmt in ${pmt_list} ; do
	echo
	echo pmt ${pmt}
	# Loop through all hv's in hv list
	for hv in ${hv_list} ; do
		./sql_select_ids.sh id="fit_id" recent=1 good=${good} hv=${hv} pmt=${pmt}
		echo hv: ${hv}
		./sql_ave_errors.sh
	done
	echo ================================
done
