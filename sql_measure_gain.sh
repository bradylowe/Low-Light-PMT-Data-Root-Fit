
# Parse input
for item in $* ; do
	# Decompose input
	name=$(echo ${item} | awk -F'=' '{print $1}')
	val=$(echo ${item} | awk -F'=' '{print $2}')
	if [[ ${name} == "pmt_list" ]] ; then
		pmt_list=${val}
	elif [[ ${name} == "hv_list" ]] ; then
		hv_list=${val}
	elif [[ ${name} == "sloppy" ]] ; then
		sloppy=${val}
	fi
done

# Initialize any items not received from user
if [ ${#pmt_list} -eq 0 ] ; then
	pmt_list="1 2 3 4"
fi
if [ ${#hv_list} -eq 0 ] ; then
	hv_list="2000 1975 1950 1925 1900"
fi
if [ ${#sloppy} -eq 0 ] ; then
	sloppy=0
fi

# Loop through all pmt's in pmt list
for pmt in ${pmt_list} ; do
	# Define a "good" fit
	good_fits_1="pmt=${pmt} AND nevents>=500000 AND ll>=20 AND ll<=50 AND iped=40"
	if [ ${sloppy} -eq 0 ] ; then
		good_fits_2="chi>=0 AND chi<10 AND con_ll>5 AND con_gain>=10 AND gain_percent_error<10 AND gain>0 AND mu_out > mu_out_error"
	else
		good_fits_2="chi>=0 AND chi<10000"
	fi

	# Loop through all hv's in hv list
	for hv in ${hv_list} ; do
		./sql_select_fits.sh "${good_fits_1} AND hv=${hv}" "${good_fits_2}"
		echo hv = ${hv}
		./sql_ave_errors.sh
	done
done
