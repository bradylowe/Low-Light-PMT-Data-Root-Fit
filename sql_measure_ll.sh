
# Initialize input parameters
pmt_list="1 2 3 4 5 6"
ll_list="20 30 40 50 90 100"
quality=2
regime="all"

# Parse input parameters
for item in $* ; do
	name=$(echo ${item} | awk -F'=' '{print $1}')
	val=${item#${name}=}
	if [[ ${name} == "pmt" ]] ; then
		pmt_list=${val}
	elif [[ ${name} == "ll" ]] ; then
		ll_list=${val}
	elif [[ ${name} == "quality" ]] ; then
		quality=${val}
	elif [[ ${name} == "regime" ]] ; then
		regime=${val}
	fi
		
done

# Loop through pmt's
for pmt in ${pmt_list} ; do
	echo
	echo pmt ${pmt}
	echo ==================================
	# Loop through all ll's for this pmt
	for ll in ${ll_list} ; do
		./sql_select_fits.sh pmt=${pmt} regime=${regime} run_cond="filter=7" ll=${ll} quality=${quality} recent=1
		echo ll = ${ll}
		./sql_ave_errors.sh mu_out
		echo ---
	done
	echo ==================================
done
