
# Initialize input parameters
pmt_list="1 2 3 4"
ll_list="20 30 40 50 90 100"
good=1

# Parse input parameters
for item in $* ; do
	name=$(echo ${item} | awk -F'=' '{print $1}')
	val=${item#${name}=}
	if [[ ${name} == "pmt_list" || ${name} == "pmt" ]] ; then
		pmt_list=${val}
	elif [[ ${name} == "ll_list" || ${name} == "ll" ]] ; then
		ll_list=${val}
	elif [[ ${name} == "good" ]] ; then
		good=${val}
	fi
		
done

# Loop through pmt's
for pmt in ${pmt_list} ; do
	echo
	echo pmt ${pmt}
	# Loop through all ll's for this pmt
	for ll in ${ll_list} ; do
		./sql_select_ids.sh id="fit_id" ll=${ll} pmt=${pmt} good=${good} recent=1
		echo ll = ${ll}
		./sql_ave_errors.sh mu_out
	done
	echo ==================================
done
