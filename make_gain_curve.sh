
# PRINT HELP #
###################################################################################################################
# Get all column names
run_cols=$(mysql --defaults-extra-file=~/.mysql.cnf -e "USE gaindb; SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = 'gaindb' AND TABLE_NAME = 'run_params' ;")
run_cols=${run_cols:12} # Remove "COLUMN_NAME "
fit_cols=$(mysql --defaults-extra-file=~/.mysql.cnf -e "USE gaindb; SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = 'gaindb' AND TABLE_NAME = 'fit_results' ;")
fit_cols=${fit_cols:12} # Remove "COLUMN_NAME "

# Check for help option
if [[ $1 == "help" ]] ; then
	echo
	echo run_params: ${run_cols} | sed 's/ /, /g'
	echo fit_params: ${fit_cols} | sed 's/ /, /g'
	echo
	exit
fi

####################################################################################################################

# Grab independent var
if [ ${#1} -gt 0 ] ; then
	x=$1
else
	echo Error
	exit
fi

# Grab dependent var
if [ ${#2} -gt 0 ] ; then
	y=$2
else
	echo Error
	exit
fi

# Get list of fit ID's
if [ ${#3} -gt 0 ] ; then
	run_cond=$3
fi
if [ ${#4} -gt 0 ] ; then
	fit_cond=$4
fi
./sql_select_fits.sh "${run_cond}" "${fit_cond}"
fits=$(head -n 1 selected_fits.txt)

# Delete all info in array files
if [ ${#5} -gt 0 ] ; then
	rm x_file_$5.txt ; touch x_file_$5.txt
	rm y_file_$5.txt ; touch y_file_$5.txt
else
	rm x_file.txt ; touch x_file.txt
	rm y_file.txt ; touch y_file.txt
fi

# Loop through each for sql query
for fitID in ${fits} ; do

	# Grab the run_id for this run
	runID=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "USE gaindb; SELECT run_id FROM fit_results WHERE fit_id=${fitID}")

	# Grab x value for this fitID
	in_run_cols=$(echo ${run_cols} | grep ${x})
	if [ ${#in_run_cols} -gt 0 ] ; then
		x_out=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "USE gaindb; SELECT ${x} FROM run_params WHERE run_id=${runID}")
	else
		x_out=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "USE gaindb; SELECT ${x} FROM fit_results WHERE fit_id=${fitID}")
	fi

	# Grab y value for this runID
	in_run_cols=$(echo ${run_cols} | grep ${y})
	if [ ${#in_run_cols} -gt 0 ] ; then
		y_out=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "USE gaindb; SELECT ${y} FROM run_params WHERE run_id=${runID}")
	else
		y_out=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "USE gaindb; SELECT ${y} FROM fit_results WHERE fit_id=${fitID}")
	fi

	# Send values to file
	for val in ${y_out} ; do
		if [ ${#val} -gt 0 -a ${#x_out} -gt 0 ] ; then
			if [ ${#5} -gt 0 ] ; then
				echo ${x_out} >> x_file_$5.txt
				echo ${val} >> y_file_$5.txt
			else
				echo ${x_out} >> x_file.txt
				echo ${val} >> y_file.txt
			fi
		fi
	done
done

root -l "make_gain_curve.c()"


