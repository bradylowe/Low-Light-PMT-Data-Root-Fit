
# Initialize input parameters
pmt_list="1 2 3 4 5 6"
filter_list="1 8"
extra_fits=0

# Parse input parameters
for item in $* ; do
	name=$(echo ${item} | awk -F'=' '{print $1}')
	val=$(echo ${item} | awk -F'=' '{print $2}')
	if [[ ${name} == "pmt_list" || ${name} == "pmt" ]] ; then
		pmt_list=${val}
	elif [[ ${name} == "extra_fits" ]] ; then
		extra_fits=${val}
	fi
done

# Run all the different fits for each PMT's data on the list
for pmt in ${pmt_list} ; do

	# Do both filters one at a time
	for filter in ${filter_list} ; do
		./sql_select_runs.sh pmt=${pmt} filter=${filter} recent=1 quality regime=ll
		./run_fit_pmt.sh conGain=1 conLL=20
		./sql_select_runs.sh pmt=${pmt} filter=${filter} recent=1 quality regime=ll
		./run_fit_pmt.sh conGain=5 conLL=20
		if [ ${extra_fits} -eq 1 ] ; then
			./sql_select_runs.sh pmt=${pmt} filter=${filter} recent=1 quality regime=ll
			./run_fit_pmt.sh conGain=0 conLL=20
			./sql_select_runs.sh pmt=${pmt} filter=${filter} recent=1 quality regime=ll
			./run_fit_pmt.sh conGain=1 conLL=20 noExpo=1
			./sql_select_runs.sh pmt=${pmt} filter=${filter} recent=1 quality regime=ll
			./run_fit_pmt.sh conGain=1 conLL=10
			./sql_select_runs.sh pmt=${pmt} filter=${filter} recent=1 quality regime=ll
			./run_fit_pmt.sh conGain=5 conLL=10
		fi
	done

done
