
# Check for input
if [ $# -eq 0 ] ; then
	echo choose a pmt
	exit
fi
pmt=$1

# Define a "good" fit
good_fits_1="pmt=${pmt} AND nevents>=500000 AND ll>=20 AND ll<=50 AND iped=40"
good_fits_2="chi>=0 AND chi<10 AND con_ll>5 AND con_gain>=10 AND gain_percent_error<10 AND gain>0 AND mu_out > mu_out_error"

# Loop through all hv's available and measure the gain
hv_list="2000 1975 1950 1925 1900 1800 1700 1600 1500 1400 1300 1200 1100 1000 900 800 700"
for hv in ${hv_list} ; do
	./sql_select_fits.sh "${good_fits_1} AND hv=${hv}" "${good_fits_2}"
	echo hv = ${hv}
	./sql_ave_errors.sh
done
