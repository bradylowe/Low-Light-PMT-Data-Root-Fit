

# Loop over some inputs


no_expo_list="0 1 2"
low_list="10 1000"
high_list="1 150"
con_gain_list="20"

stats=4
while [ ${stats} -gt 0 ] ; do

	for cur_expo in ${no_expo_list} ; do
	for cur_low in ${low_list} ; do
	for cur_high in ${high_list} ; do
	for cur_con_gain in ${con_gain_list} ; do
	
# Run the analyzer, give a little time for MySQL to avoid collisions
./run_fit_pmt.sh noExpo=${cur_expo} low=${cur_low} high=${cur_high} conGain=${cur_con_gain} conLL=10 randomChanges=${cur_con_gain} &
sleep 0.1


	done
	done
	done
	done

stats=$((stats - 1))
done
