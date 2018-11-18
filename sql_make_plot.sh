
# PRINT HELP #
###################################################################################################################
# Get all column names
query="USE gaindb; SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS"
query="${query} WHERE TABLE_SCHEMA = 'gaindb' AND TABLE_NAME = 'run_params' ;"
run_cols=$(mysql --defaults-extra-file=~/.mysql.cnf -e "${query}")
run_cols=${run_cols:12} # Remove "COLUMN_NAME "
query="USE gaindb; SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE"
query="${query} TABLE_SCHEMA = 'gaindb' AND TABLE_NAME = 'fit_results' ;"
fit_cols=$(mysql --defaults-extra-file=~/.mysql.cnf -e "${query}")
fit_cols=${fit_cols:12} # Remove "COLUMN_NAME "

# Check for help option
if [[ $1 == "help" ]] ; then
	echo
	echo run_params: ${run_cols} | sed 's/ /, /g'
	echo
	echo fit_params: ${fit_cols} | sed 's/ /, /g'
	echo
	exit
fi

####################################################################################################################

# Grab independent var
if [ ${#1} -gt 0 ] ; then
	x=$1
else
	x="hv"
fi

# Grab dependent var
if [ ${#2} -gt 0 ] ; then
	y=$2
else
	y="gain"
fi

# Get list of fit ID's
fits=$(head -n 1 selected_fits.csv | sed "s/,/ /g")

rm x_file.txt ; touch x_file.txt
rm y_file.txt ; touch y_file.txt

# Loop through each for sql query
for fitID in ${fits} ; do

	# Grab the run_id for this run
	query="USE gaindb; SELECT run_id FROM fit_results WHERE fit_id=${fitID}"
	runID=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}")

	# Grab x value for this fitID
	in_run_cols=$(echo ${run_cols} | grep ${x})
	if [ ${#in_run_cols} -gt 0 ] ; then
		query="USE gaindb; SELECT ${x} FROM run_params WHERE run_id=${runID}"
		x_out=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}")
	else
		query="USE gaindb; SELECT ${x} FROM fit_results WHERE fit_id=${fitID}"
		x_out=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}")
	fi

	# Grab y value for this runID
	in_run_cols=$(echo ${run_cols} | grep ${y})
	if [ ${#in_run_cols} -gt 0 ] ; then
		query="USE gaindb; SELECT ${y} FROM run_params WHERE run_id=${runID}"
		y_out=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}")
	else
		query="USE gaindb; SELECT ${y} FROM fit_results WHERE fit_id=${fitID}"
		y_out=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}")
	fi

	# Send values to file
	for val in ${y_out} ; do
		if [ ${#val} -gt 0 -a ${#x_out} -gt 0 ] ; then
			echo ${x_out} >> x_file.txt
			echo ${val} >> y_file.txt
		fi
	done
done

if [[ ${x} == "hv" && ${y} == "gain" ]] ; then
	root -l "make_gain_plot.c()"
else
	root -l "make_plot.c()"
fi


