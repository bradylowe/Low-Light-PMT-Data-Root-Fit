
# Parse command line inputs
for item in $* ; do
	name=$(echo ${item} | awk -F'=' '{print $1}')
	val=$(echo ${item} | awk -F'=' '{print $2}')
	if [[ ${name} == "pmt_list" ]] ; then
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
		all=${val}
	fi
done

# Initialize all unspecified arguments
if [ ${#pmt_list} -eq 0 ] ; then
	pmt_list="1 2 3 4"
fi
if [ ${#hlhv} -eq 0 ] ; then
	hlhv=0
fi
if [ ${#llhv} -eq 0 ] ; then
	llhv=0
fi
if [ ${#hllv} -eq 0 ] ; then
	hllv=0
fi
if [ ${#lllv} -eq 0 ] ; then
	lllv=0
fi
if [ ${#all} -gt 0 ] ; then
	if [ ${all} -eq 1 ] ; then
		hlhv=1
		llhv=1
		hllv=1
		lllv=1
	fi
fi


# Run all the different fits for each PMT's data on the list
for pmt in ${pmt_list} ; do

	# LOW-light HIGH-voltage (used to measure gain) 
	if [ ${llhv} -eq 1 ] ; then
		# Select the low light, high gain runs
		./sql_select_ids.sh llhv=1 good=1 recent=1 
		# Run fitting algorithm to measure gain
		./run_fit_pmt.sh conGain=10 conLL=10
		./run_fit_pmt.sh conGain=10 conLL=10 noExpo=1
		./run_fit_pmt.sh conGain=10 conLL=10 fitEngine=1
		./run_fit_pmt.sh conGain=10 conLL=10 conInj=10
	fi

	# LOW-light LOW-voltage (used to attempt to measure gain)
	if [ ${lllv} -eq 1 ] ; then
		# Select the low light, low gain runs
		./sql_select_ids.sh lllv=1 good=1 recent=1 
		# Run fitting algorithm to measure gain
		./run_fit_pmt.sh conGain=10 conLL=1
		./run_fit_pmt.sh conGain=10 conLL=1 noExpo=1
	fi

	# HIGH-light HIGH-voltage (used to measure light level)
	if [ ${hlhv} -eq 1 ] ; then
		# Select the high light, high gain runs
		./sql_select_ids.sh hlhv=1 good=1 recent=1
		# Run fitting algorithm to measure light level
		./run_fit_pmt.sh conGain=1 conLL=20
		./run_fit_pmt.sh conGain=0 conLL=20
	fi

	# HIGH-light LOW-voltage (used to measure gain)
	if [ ${hllv} -eq 1 ] ; then
		# Select the high light, low gain runs
		./sql_select_ids.sh hllv=1 good=1 recent=1
		# Run fitting algorithm to measure gain
		./run_fit_pmt.sh conGain=20 conLL=1
		./run_fit_pmt.sh conGain=20 conLL=0
	fi

done
