
# Initialize input parameters
pmt_list="1 2 3 4 5 6"
hlhv=0
llhv=0
hllv=0
lllv=0
extra_fits=0
all=1

# Parse input parameters
for item in $* ; do
	name=$(echo ${item} | awk -F'=' '{print $1}')
	val=$(echo ${item} | awk -F'=' '{print $2}')
	if [[ ${name} == "pmt_list" || ${name} == "pmt" ]] ; then
		pmt_list=${val}
	elif [[ ${name} == "hlhv" ]] ; then
		hlhv=${val}
	elif [[ ${name} == "llhv" ]] ; then
		llhv=${val}
	elif [[ ${name} == "hllv" ]] ; then
		hllv=${val}
	elif [[ ${name} == "lllv" ]] ; then
		lllv=${val}
	elif [[ ${name} == "all" ]] ; then
		if [ ${val} -eq 1 ] ; then
			hlhv=1
			llhv=1
			hllv=1
			lllv=1
		fi
	elif [[ ${name} == "extra_fits" ]] ; then
		extra_fits=${val}
	fi
done

# Run all the different fits for each PMT's data on the list
for pmt in ${pmt_list} ; do

	# LOW-light HIGH-voltage (used to measure gain) 
	if [ ${llhv} -eq 1 ] ; then
		# Select the low light, high gain runs
		./sql_select_ids.sh llhv=1 good=1 recent=1 
		./run_fit_pmt.sh conGain=10 conLL=10
		./sql_select_ids.sh llhv=1 good=1 recent=1 
		./run_fit_pmt.sh conGain=10 conLL=10 noExpo=1
		if [ ${extra_fits} -eq 1 ] ; then
			./sql_select_ids.sh llhv=1 good=1 recent=1 
			./run_fit_pmt.sh conGain=10 conLL=10 fitEngine=1
			./sql_select_ids.sh llhv=1 good=1 recent=1 
			./run_fit_pmt.sh conGain=10 conLL=10 conInj=10
		fi
	fi

	# LOW-light LOW-voltage (used to attempt to measure gain)
	if [ ${lllv} -eq 1 ] ; then
		# Select the low light, low gain runs
		./sql_select_ids.sh lllv=1 good=1 recent=1 
		./run_fit_pmt.sh conGain=20 conLL=2
		./sql_select_ids.sh lllv=1 good=1 recent=1 
		./run_fit_pmt.sh conGain=20 conLL=2 noExpo=1
	fi

	# HIGH-light HIGH-voltage (used to measure light level)
	if [ ${hlhv} -eq 1 ] ; then
		# Select the high light, high gain runs
		./sql_select_ids.sh hlhv=1 good=1 recent=1
		./run_fit_pmt.sh conGain=1 conLL=20
		./sql_select_ids.sh hlhv=1 good=1 recent=1
		./run_fit_pmt.sh conGain=1 conLL=20 noExpo=1
	fi

	# HIGH-light LOW-voltage (used to measure gain)
	if [ ${hllv} -eq 1 ] ; then
		# Select the high light, low gain runs
		./sql_select_ids.sh hllv=1 good=1 recent=1
		./run_fit_pmt.sh conGain=20 conLL=1
		./sql_select_ids.sh hllv=1 good=1 recent=1
		./run_fit_pmt.sh conGain=20 conLL=1 noExpo=1
	fi

done
