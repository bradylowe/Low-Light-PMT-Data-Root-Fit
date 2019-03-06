
# Initialize input parameters
pmt=0
quality=4
filter=8
compare_filter=7
min_voltage=0
run_cond="TRUE"
fit_cond="TRUE"

ll_list="20 30 40 50 60 70 80 90 100"
ll_begin=20
ll_end=100

# Parse input
for item in $* ; do
	# Decompose input
	name=$(echo ${item} | awk -F'=' '{print $1}')
	val=${item#${name}=}
	if [[ ${name} == "pmt" ]] ; then
		pmt=${val}
	elif [[ ${name} == "ll" ]] ; then
		ll=${val}
	elif [[ ${name} == "quality" ]] ; then
		quality=${val}
	elif [[ ${name} == "filter" ]] ; then
		filter=${val}
	elif [[ ${name} == "ll" ]] ; then
		ll_list=${val}
		ll_begin=${val}
		ll_end=$((val + 1))
	elif [[ ${name} == "run_cond" ]] ; then
		run_cond=${val}
	elif [[ ${name} == "fit_cond" ]] ; then
		fit_cond=${val}
	elif [[ ${name} == "compare_filter" ]] ; then
		compare_filter=${val}
	elif [[ ${name} == "min_voltage" ]] ; then
		min_voltage=${val}
	fi
done


#while [ ${ll_begin} -le ${ll_end} ] ; do
for ll_begin in ${ll_list} ; do
	cmp=$(./sql_measure_ll.sh ll=${ll_begin} filter=${compare_filter} pmt=${pmt} quality=${quality} min_hv=${min_voltage} run_cond="${run_cond}" fit_cond="${fit_cond}" yes=0)
	cmp_avg=$(echo ${cmp} | awk -F'(' '{print $3}' | awk -F',' '{print $1}')
	cmp_std=$(echo ${cmp} | awk '{print $NF}' | awk -F')' '{print $1}')
	
	filt=$(./sql_measure_ll.sh ll=${ll_begin} filter=${filter} pmt=${pmt} quality=${quality} min_hv=${min_voltage} run_cond="${run_cond}" fit_cond="${fit_cond}" yes=0)
	filt_avg=$(echo ${filt} | awk -F'(' '{print $3}' | awk -F',' '{print $1}')
	filt_std=$(echo ${filt} | awk '{print $NF}' | awk -F')' '{print $1}')
	
	if [ ${#cmp_avg} -gt 0 -a ${#filt_avg} -gt 0 ] ; then
		ratio=$(root -l -b -q "divide.c(${filt_avg}, ${cmp_avg})")
		ratio=$(echo ${ratio} | awk '{print $NF}')
		cmp_ratio=$(grep ${compare_filter}, calibration/filters.csv | awk -F',' '{print $2}')
		ratio=$(root -l -b -q "multiply.c(${ratio}, ${cmp_ratio})")
		ratio=$(echo ${ratio} | awk '{print $NF}')
		echo _________________________________________________________
		echo ll = ${ll_begin}
		echo compare ${compare_filter}:  ${cmp_avg} +/- ${cmp_std}
		echo filter ${filter}:  ${filt_avg} +/- ${filt_std}
		echo relative transmission: ${ratio}
	fi
	
	ll_begin=$((ll_begin + 1))
done
