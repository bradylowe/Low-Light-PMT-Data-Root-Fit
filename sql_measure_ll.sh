
# Check for input
if [ $# -eq 0 ] ; then
	echo choose a pmt
	exit
fi
pmt=$1

####### DO LOW LIGHT FIRST ########
# Define a "good" fit
good_fits_1="pmt=${pmt} AND nevents>=500000 AND hv > 1550 AND iped=40"
good_fits_2="chi>=0 AND chi<10 AND con_ll>=10 AND con_gain>=0 AND con_gain<=10 AND gain>0 AND mu_out > mu_out_error"

# Loop through all hv's available and measure the gain
ll_list="20 30 40 50 60"
for ll in ${ll_list} ; do
	./sql_select_fits.sh "${good_fits_1} AND ll=${ll}" "${good_fits_2}"
	echo ll = ${ll}
	./sql_ave_errors.sh mu_out
done

####### NOW DO HIGH LIGHT FIRST ########
# Define a "good" fit
good_fits_1="pmt=${pmt} AND nevents>=500000 AND hv > 1550 AND iped=40"
good_fits_2="chi>=0 AND chi<100 AND con_ll>=10 AND con_gain>=0 AND con_gain<=10 AND gain>0 AND mu_out > mu_out_error"

# Loop through all hv's available and measure the gain
ll_list="70 80 90 100"
for ll in ${ll_list} ; do
	./sql_select_fits.sh "${good_fits_1} AND ll=${ll}" "${good_fits_2}"
	echo ll = ${ll}
	./sql_ave_errors.sh mu_out
done
