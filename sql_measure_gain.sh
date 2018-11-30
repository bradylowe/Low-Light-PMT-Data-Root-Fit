
# Initialize input parameters
pmt_list=""
quality=3
regime="all"

# Parse input
for item in $* ; do
	# Decompose input
	name=$(echo ${item} | awk -F'=' '{print $1}')
	val=${item#${name}=}
	if [[ ${name} == "pmt" ]] ; then
		pmt_list=${val}
	elif [[ ${name} = "hv" ]] ; then
		hv=${val}
	elif [[ ${name} == "quality" ]] ; then
		quality=${val}
	elif [[ ${name} == "regime" ]] ; then
		regime=${val}
	fi
done

# Loop through all pmt's in pmt list
for pmt in ${pmt_list} ; do
	# Select hv_list
	if [ ${pmt} -le 4 ] ; then
		hv_list="2000 1975 1950 1925 1900 1800 1700 1600 1500 1400 1300 1200 1100 1000 900 800 700"
	else
		hv_list="1350 1300 1250 1200 1150 1100 1050 1000 900 800 700 600 500"
	fi
	if [ ${#hv} -gt 0 ] ; then
		hv_list=${hv}
	fi

	# Clear files for making plot of output
	rm x_file.txt
	rm y_file.txt
	rm ex_file.txt
	rm ey_file.txt
	rm pmt${pmt}_gain.txt
	# Loop through all hv's in hv list
	for hv in ${hv_list} ; do
		nfits=$(./sql_select_fits.sh pmt=${pmt} regime=${regime} recent=1 quality=${quality} hv=${hv} | awk '{print $1}')
		if [ ${nfits} -eq 0 ] ; then
			continue
		fi
		ret=$(./sql_ave_errors.sh error=gain_error)
		gain=$(echo ${ret} | awk -F'(' '{print $3}')
		gain=${gain%,*}
		gain_error=$(echo ${ret} | awk -F'(' '{print $5}')
		gain_error=${gain_error%,*}
		echo "gain (${hv}V): ${gain} +/- ${gain_error}" >> pmt${pmt}_gain.txt
		echo ${hv} >> x_file.txt
		echo ${gain} >> y_file.txt
		echo "5.0" >> ex_file.txt
		echo ${gain_error} >> ey_file.txt
		#./sql_ave_errors.sh sig_out
	done

	root -l "make_gain_plot_error.c()"
done
