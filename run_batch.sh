
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
	elif [[ ${name} == "filters" ]] ; then
		filters=${val}
	elif [[ ${name} == "iped" ]] ; then
		iped=${val}
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
	llhv=1
fi
if [ ${#hllv} -eq 0 ] ; then
	hllv=0
fi
if [ ${#lllv} -eq 0 ] ; then
	lllv=0
fi
if [ ${#filters} -eq 0 ] ; then
	filters=1
fi
if [ ${#iped} -eq 0 ] ; then
	iped=40
fi


# Run all the different fits for each PMT's data on the list
for pmt in ${pmt_list} ; do
	########
	# First, run the fits on non-filtered data.

	# Select ONLY recent runs that are non-pedestal with enough statistics
	default="iped=${iped} AND pmt=${pmt} AND gate=100 AND nevents>=500000 AND datarate>=3000 AND ll>0 AND filter=7"

	if [ ${llhv} -eq 1 ] ; then
		# Select the low light, high gain runs
		./sql_select_runs.sh "ll<=50 AND hv>=1900 AND ${default}"
		# Run fitting algorithm to measure gain and light level
		./run_fit_pmt.sh conGain=20 conLL=10
		./run_fit_pmt.sh conGain=20 conLL=10 noExpo=1
		./run_fit_pmt.sh conGain=20 conLL=10 fitEngine=1
		./run_fit_pmt.sh conGain=20 conLL=10 conInj=10
	fi

	if [ ${lllv} -eq 1 ] ; then
		# Select the low light, low gain runs
		./sql_select_runs.sh "ll<=50 AND hv<1900 AND ${default}"
		# Run fitting algorithm to measure gain
		./run_fit_pmt.sh conGain=10 conLL=1
		./run_fit_pmt.sh conGain=10 conLL=1 noExpo=1
	fi

	if [ ${hlhv} -eq 1 ] ; then
		# Select the high light, high gain runs
		./sql_select_runs.sh "ll>50 AND hv>=1900 AND ${default}"
		# Run fitting algorithm to measure light level
		./run_fit_pmt.sh conGain=1 conLL=20
		./run_fit_pmt.sh conGain=0 conLL=20
	fi

	if [ ${hllv} -eq 1 ] ; then
		# Select the high light, low gain runs
		./sql_select_runs.sh "ll>50 AND hv<1900 AND ${default}"
		# Run fitting algorithm to measure gain
		./run_fit_pmt.sh conGain=20 conLL=1
		./run_fit_pmt.sh conGain=20 conLL=0
	fi


	if [ ${filters} -eq 1 ] ; then
		########
		# Now run the filter data.
		# Filter 8 has high light at ll=100
		# Filter 1 has low light at ll=100
		default="iped=${iped} AND pmt=${pmt} AND gate=100 AND nevents>=500000 AND datarate>=3000 AND ll>0"

		# Filter 8
		./sql_select_runs.sh "filter=8 AND ll=100 AND ${default}"
		./run_fit_pmt.sh conGain=1 conLL=20
		./run_fit_pmt.sh conGain=0 conLL=20

		# Filter 1
		./sql_select_runs.sh "filter=1 AND ll=100 AND ${default}"
		./run_fit_pmt.sh conGain=5 conLL=20
		./run_fit_pmt.sh conGain=0 conLL=20
	fi

done
