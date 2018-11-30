
# PRINT HELP #
##############
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

######################################################################

# Initialize input parameters
pmt_list=""
quality=4
x="hv"
y="gain"
e=""
table="fit_results"
csv_file="selected_fits.csv"

# Parse input
for item in $* ; do
        # Decompose input
        name=$(echo ${item} | awk -F'=' '{print $1}')
        val=${item#${name}=}
        if [[ ${name} == "pmt" ]] ; then
                pmt_list=${val}
        elif [[ ${name} == "x" ]] ; then
                x=${val}
        elif [[ ${name} == "y" ]] ; then
                y=${val}
	elif [[ ${name} == "error" ]] ; then
		e=${val}
        elif [[ ${name} == "high-light" ]] ; then
                table="high_light_results"
		csv_file="selected_high_light_runs.csv"
        fi
done

# Get list of fit ID's
fits=$(head -n 1 ${csv_file} | sed "s/,/ /g")

rm x_file.txt 
rm y_file.txt 
rm ex_file.txt
rm ey_file.txt

# Loop through each for sql query
for fitID in ${fits} ; do

	# Grab the run_id for this run
	query="USE gaindb; SELECT run_id FROM ${table} WHERE fit_id=${fitID}"
	runID=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}")

	# Grab x value for this fitID
	in_run_cols=$(echo ${run_cols} | grep ${x})
	if [ ${#in_run_cols} -gt 0 ] ; then
		query="USE gaindb; SELECT ${x} FROM run_params WHERE run_id=${runID}"
		x_out=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}")
	else
		query="USE gaindb; SELECT ${x} FROM ${table} WHERE fit_id=${fitID}"
		x_out=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}")
	fi

	# Grab y value for this runID
	in_run_cols=$(echo ${run_cols} | grep ${y})
	if [ ${#in_run_cols} -gt 0 ] ; then
		query="USE gaindb; SELECT ${y} FROM run_params WHERE run_id=${runID}"
		y_out=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}")
	else
		query="USE gaindb; SELECT ${y} FROM ${table} WHERE fit_id=${fitID}"
		y_out=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}")
	fi

	# Grab error value for this runID
	if [ ${#e} -gt 0 ] ; then
		in_fit_cols=$(echo ${fit_cols} | grep ${e})
	fi
	if [ ${#in_fit_cols} -gt 0 ] ; then
		query="USE gaindb; SELECT ${e} FROM ${table} WHERE fit_id=${fitID}"
		ey_out=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}")
	fi

	# Send values to file
	for val in ${y_out} ; do
		if [ ${#val} -gt 0 -a ${#x_out} -gt 0 ] ; then
			echo ${x_out} >> x_file.txt
			echo ${val} >> y_file.txt
			if [ ${#ey_out} -gt 0 ] ; then
				echo ${ey_out} >> ey_file.txt
			fi
		fi
	done
done


if [[ ${x} == "hv" && ${y} == "gain" ]] ; then
	if [ ${#ey_out} -gt 0 ] ; then
		root -l "make_gain_plot_error.c()"
	else
		root -l "make_gain_plot.c()"
	fi
else
	if [ ${#ey_out} -gt 0 ] ; then
		root -l "make_plot_error.c()"
	else
		root -l "make_plot.c()"
	fi
fi


