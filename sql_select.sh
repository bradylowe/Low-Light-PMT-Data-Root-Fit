
############################### Initialize input params, check for errors
run_cond="TRUE"
fit_cond="TRUE"
id_type="fit_id"
table="fit_results"
csv_file="selected_fits.csv"
regime="all"
pmt=0

# Define high/low voltage regimes
high_voltage="hv>=1600"
low_voltage="hv<=1800"

# Define high/low light level regimes
high_light="((filter=7 AND ll>50) OR (filter=8 AND ll>70))"
low_light="((filter=7 AND ll<=50) OR (filter=8 AND ll<=70) OR filter=1)"

good_runs="ll>0 AND nevents>=500000"
recent_runs="iped=40 AND gate=100 AND datarate=3500 AND daq=3"

# Define quality of fits on a scale from 1 (bad) to 5 (good)
sloppy_fits="chi>=0 AND chi<10000 AND gain>0 AND gain<3.5 AND gain_percent_error<1000 AND mu_out>mu_out_error AND gain_percent_error>0"
ok_fits="chi>=0 AND chi<20 AND gain>0 AND gain<3.5 AND gain_percent_error<20 AND mu_out>mu_out_error AND gain_percent_error>0"
good_fits="chi>=0 AND chi<10 AND gain>0 AND gain<3.5 AND gain_percent_error<10 AND mu_out>mu_out_error AND gain_percent_error>0"
better_fits="chi>=0 AND chi<4 AND gain>0 AND gain<3.5 AND gain_percent_error<5 AND mu_out>mu_out_error AND gain_percent_error>0"
best_fits="${sloppy_fits} ORDER BY chi, gain_percent_error, mu_out_error LIMIT 1"


############################################### Parse input parameters
for item in $* ; do
	name=$(echo ${item} | awk -F'=' '{print $1}')
	val=${item#${name}=}
	if [[ ${name} == "run_cond" ]] ; then
		run_cond="${run_cond} AND ${val}"
	elif [[ ${name} == "fit_cond" ]] ; then
		fit_cond="${fit_cond} AND ${val}"
	elif [[ ${name} == "runs" || ${name} == "run" ]] ; then
		id_type="run_id"
		csv_file="selected_runs.csv"
	elif [[ ${name} == "regime" ]] ; then
		regime=${val}
	elif [[ ${name} == "run_list" ]] ; then
		run_cond="${run_cond} AND run_id IN (${val})"
	elif [[ ${name} == "fit_list" ]] ; then
		fit_cond="${fit_cond} AND fit_id IN (${val})"
	# Use high light fitter instead 
	elif [[ ${name} == "high-light" ]] ; then
		table="high_light_results"
		csv_file="selected_high_light_fits.csv"
	elif [[ ${name} == "daq" ]] ; then
		run_cond="${run_cond} AND daq=${val}"
	# Select the quality of fits here
	elif [[ ${name} == "quality" ]] ; then
		run_cond="${run_cond} AND ${good_runs}"
		if [ ${val} -eq 1 ] ; then
			fit_cond="${fit_cond} AND ${sloppy_fits}"
		elif [ ${val} -eq 2 ] ; then
			fit_cond="${fit_cond} AND ${ok_fits}"
		elif [ ${val} -eq 3 ] ; then
			fit_cond="${fit_cond} AND ${good_fits}"
		elif [ ${val} -eq 4 ] ; then
			fit_cond="${fit_cond} AND ${better_fits}"
		elif [ ${val} -eq 5 ] ; then
			fit_cond="${fit_cond} AND ${best_fits}"
		fi
	# Only grab recent fits
	elif [[ ${name} == "recent" ]] ; then
		if [ ${val} -eq 1 ] ; then
			run_cond="${run_cond} AND ${recent_runs}"
		fi
	# Grab pmt
	elif [[ ${name} == "pmt" ]] ; then
		pmt=${val}
		run_cond="${run_cond} AND pmt=${pmt}"
		if [ ${pmt} -eq 5 ] ; then
			high_voltage="hv>=1100"
			low_voltage="hv<=1200"
		elif [ ${pmt} -eq 6 ] ; then
			high_voltage="hv >= 800"
			low_voltage="hv <= 900"
		fi
	fi

	if [[ ${name:0:2} == "hv" || ${name:0:2} == "ll" || ${name:0:6} == "filter" ]] ; then
		run_cond="${run_cond} AND ${item}"
	elif [[ ${name:0:3} == "chi" || ${name:0:4} == "gain" ]] ; then
		fit_cond="${fit_cond} AND ${item}"
	fi
done

# Change all:   param=NULL    into    param IS NULL

run_cond=$(echo ${run_cond} | sed "s/!=NULL/ IS NOT NULL/g")
run_cond=$(echo ${run_cond} | sed "s/=NULL/ IS NULL/g")
fit_cond=$(echo ${fit_cond} | sed "s/!=NULL/ IS NOT NULL/g")
fit_cond=$(echo ${fit_cond} | sed "s/=NULL/ IS NULL/g")

# Apply conditions for regime of choice
if [[ ${regime} != "all" ]] ; then
	# Check for low light regime
	check=$(echo ${regime} | grep "ll")
	if [ ${#check} -gt 0 ] ; then
		run_cond="${run_cond} AND ${low_light}"
	fi
	# Check for high light regime
	check=$(echo ${regime} | grep "hl")
	if [ ${#check} -gt 0 ] ; then
		run_cond="${run_cond} AND ${high_light}"
	fi
	# Check for low voltage regime
	check=$(echo ${regime} | grep "lv")
	if [ ${#check} -gt 0 ] ; then
		run_cond="${run_cond} AND ${low_voltage}"
	fi
	# Check for high voltage regime
	check=$(echo ${regime} | grep "hv")
	if [ ${#check} -gt 0 ] ; then
		run_cond="${run_cond} AND ${high_voltage}"
	fi
fi


# Grab results
if [[ ${id_type} == "run_id" ]] ; then
	query="USE gaindb; SELECT run_id FROM run_params WHERE ${run_cond};"
	count_query="USE gaindb; SELECT COUNT(run_id) FROM run_params WHERE ${run_cond};"
else
	query="USE gaindb; SELECT ${table}.${id_type} FROM ${table} INNER JOIN run_params ON run_params.run_id=${table}.run_id WHERE ${run_cond} AND ${fit_cond};"
	count_query="USE gaindb; SELECT COUNT(${table}.${id_type}) FROM ${table} INNER JOIN run_params ON run_params.run_id=${table}.run_id WHERE ${run_cond} AND ${fit_cond};"
fi

ret=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}")
ret=$(echo ${ret} | sed "s/ /,/g")
echo ${ret} > ${csv_file}

count=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${count_query}")
echo "${count} ${id_type}s selected"
