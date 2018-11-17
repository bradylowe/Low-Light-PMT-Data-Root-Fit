
# Initialize input parameters
pmt_list=""
ll_list="20 25 30 35 40 45 50 55 60 70 80 90 100"

# Parse input
for item in $* ; do
	# Decompose input
	name=$(echo ${item} | awk -F'=' '{print $1}')
	val=${item#${name}=}
	if [[ ${name} == "pmt" ]] ; then
		pmt_list=${val}
	elif [[ ${name} = "ll" ]] ; then
		ll_list=${val}
	fi
done

# Loop through all pmt's in pmt list
for pmt in ${pmt_list} ; do

	# Pick the right calibration file
	csv_file="calibration/pmt${pmt}_ll.csv"
	
	# Loop through all ll's in ll list
	for ll in ${ll_list} ; do
		./sql_select_ids.sh id="fit_id" recent=1 good=1 ll=${ll} pmt=${pmt} >> /dev/null
		out=$(./sql_average.sh sig_out)
		new_val=${out#*:  (}
		new_val=${new_val%,*}
		check=$(echo ${new_val} | grep .)
		if [[ ${check} != "no fits" && ${check:0:1} != "-" ]] ; then
			old_line=$(grep ${ll} ${csv_file})
			old_val=$(echo ${old_line} | awk -F',' '{print $2}')
			new_line=$(echo ${old_line} | sed "s/${old_val}/${new_val}/g")
			sed -i "s/${old_line}/${new_line}/g" ${csv_file}
			echo updated pmt${pmt} ll${ll} with ${new_val}
		fi
	done
done
