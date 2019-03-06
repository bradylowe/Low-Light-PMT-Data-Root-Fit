# Initialize input parameters
high_light=""
x="hv"
y="gain"
e="\"_\""
color="black"
table="fit_results"
csv_file="selected_fits.csv"
fits=$(head -n 1 ${csv_file} | sed "s/,/ /g")

# Parse input
for item in $* ; do
        # Decompose input
        name=$(echo ${item} | awk -F'=' '{print $1}')
        val=${item#${name}=}
        if [[ ${name} == "fits" ]] ; then
                fits=$(echo ${val} | sed "s/,/ /g")
        elif [[ ${name} == "x" ]] ; then
                x=${val}
        elif [[ ${name} == "y" ]] ; then
                y=${val}
	elif [[ ${name} == "error" ]] ; then
		e=${val}
        elif [[ ${name} == "color" ]] ; then
                color=${val}
        elif [[ ${name} == "high-light" ]] ; then
		table="high_light_results"
		csv_file="selected_high_light_fits.csv"
		fits=$(head -n 1 ${csv_file} | sed "s/,/ /g")
        fi
done

# Default Title
if [ ${#title} -eq 0 -a ${#x_title} -gt 0 -a ${#y_title} -gt 0 ] ; then
	title="${y_title}-vs-${x_title}"
fi


# Loop through each for sql query
for fitID in ${fits} ; do

	# Grab the run_id for this run
	query="USE gaindb; SELECT ${x}, ${y}, ${e} FROM ${table} INNER JOIN run_params ON run_params.run_id=${table}.run_id WHERE fit_id=${fitID} AND ${x} IS NOT NULL AND ${y} IS NOT NULL AND ${e} IS NOT NULL;"
	data=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}")

	# Send values to file
	if [ ${#data} -gt 0 ] ; then
		echo ${data} | awk '{print $1}'  >> x_file_${color}.txt
		echo ${data} | awk '{print $2}'  >> y_file_${color}.txt
		if [ ${#ey_out} -gt 0 ] ; then
			echo ${data} | awk '{print $3}'  >> ey_file_${color}.txt
		fi
	fi
done


