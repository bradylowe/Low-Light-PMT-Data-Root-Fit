
# Initialize input parameters
pmt_list=""
quality=4
regime="all"
calibrate=0

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
	elif [[ ${name} == "calibrate" ]] ; then
		calibrate=1
	fi
done

# Loop through all pmt's in pmt list
for pmt in ${pmt_list} ; do

	# Select hv_list
	if [ ${pmt} -le 4 ] ; then
		hv_list="2000 1975 1950 1925 1900 1800 1700 1600 1500 1400 1300 1200 1100 1000 900 800 700"
	elif [ ${pmt} -eq 5 ] ; then
		hv_list="1350 1300 1250 1200 1150 1100 1050 1000 900 800 700 600 500"
	else
		hv_list="1000 975 950 925 900 850 800 700 600 500 400"
	fi
	if [ ${#hv} -gt 0 ] ; then
		hv_list=${hv}
	fi

	echo hv,avg-gain,root-error,gain-rms > gain_measurement/pmt${pmt}_gain.csv
	echo pmt,hv,onePEsig > gain_measurement/pmt${pmt}_onePEsig.csv

	if [ ${calibrate} -ne 1 ] ; then
		echo "HV,Gain,Root-Error,Gain-RMS,1-PE-signal,1-PE-rms,reduced-1-PE-sig"
	fi

	for hv in ${hv_list} ; do

		# Select appropriate fit results
		nfits=$(./sql_select.sh pmt=${pmt} regime=${regime} recent=1 quality=${quality} hv=${hv} | awk '{print $1}')
		if [ ${nfits} -eq 0 ] ; then
			continue
		fi

		# Calculate gain and error
		ret=$(./sql_ave_errors.sh error=gain_error)
		gain=$(echo ${ret} | awk -F'(' '{print $3}' | awk -F',' '{print $1}')
		gain_error=$(echo ${ret} | awk -F'(' '{print $5}' | awk -F',' '{print $1}')
		gain_rms=$(echo ${ret} | awk -F'(' '{print $3}' | awk '{print $2}' | awk -F')' '{print $1}')

		# Calculate 1-PE signal size on ADC low and high ranges
		sig=$(./sql_average.sh col=sig_out)
		sig=$(echo ${sig} | awk -F'(' '{print $3}' | awk -F',' '{print $1}')
		sig_rms=$(./sql_average.sh col=sig_rms_out)
		sig_rms=$(echo ${sig_rms} | awk -F'(' '{print $3}' | awk -F',' '{print $1}')
		reduced_sig=$(root -l -q -b "divide.c(${sig}, 8.00)")
		reduced_sig=$(echo ${reduced_sig} | awk '{print $NF}')

		# Update the measurement files
		echo "${hv},${gain},${gain_error},${gain_rms}" >> gain_measurement/pmt${pmt}_gain.csv
		echo "${pmt},${hv},${reduced_sig}" >> gain_measurement/pmt${pmt}_onePEsig.csv
		
		# Maybe update the calibration files
		if [ ${calibrate} -eq 1 ] ; then
			# Grab current values from file
			old_line=$(grep ${hv}, calibration/pmt${pmt}_gain.csv | head -n 1)
			old_sig=$(echo ${old_line} | awk -F',' '{print $2}')
			old_rms=$(echo ${old_line} | awk -F',' '{print $3}')
			sed -i "s/${hv},${old_sig},${old_rms}/${hv},${sig},${sig_rms}/g" calibration/pmt${pmt}_gain.csv
		else
			echo "${hv},${gain},${gain_error},${gain_rms},${sig},${sig_rms},${reduced_sig}"
		fi
	done
done
