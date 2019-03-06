
# PRINT HELP #
#############################################################################
#############################################################################
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
#############################################################################
#############################################################################


# Initialize variables
current_color_index=1
high_light=""
x="hv"
y="gain"
x_error=0.0
y_error=""
z="fit_engine"
z_values="0"
z_names=""
z_title=""
z_round=0
log_x=0
log_y=0
e=""
color="black"
colors_used=""
z_colors="black,red,blue,purple,green,yellow,orange,cyan"
z_markers="cross,circle,star,star,star,star,star,star,star,star"
z_markers="dot,cross,cross3,star,star2,diamond,splat,splat,splat,splat,splat,splat,splat"
png_file=""
csv_file="selected_fits.csv"
fit_list=$(head ${csv_file})
delete=1

# Parse input
for item in $* ; do
        # Decompose input
        name=$(echo ${item} | awk -F'=' '{print $1}')
        val=${item#${name}=}
        if [[ ${name} == "x" ]] ; then
                x=${val}
        elif [[ ${name} == "y" ]] ; then
                y=${val}
        elif [[ ${name} == "x_error" ]] ; then
                x_error=${val}
        elif [[ ${name} == "y_error" ]] ; then
                y_error=${val}
        elif [[ ${name} == "z" ]] ; then
                z=${val}
		in_run_cols=$(echo ${run_cols} | grep ${z})
		if [ ${#in_run_cols} -gt 0 ] ; then
			condition="run_cond"
		else
			condition="fit_cond"
		fi
        elif [[ ${name} == "z_colors" ]] ; then
                z_colors=${val}
        elif [[ ${name} == "z_markers" ]] ; then
                z_markers=${val}
        elif [[ ${name} == "z_values" ]] ; then
                z_values=$(echo ${val} | sed "s/,/ /g")
        elif [[ ${name} == "z_names" ]] ; then
                z_names=${val}
        elif [[ ${name} == "z_title" ]] ; then
                z_title=${val}
        elif [[ ${name} == "z_round" ]] ; then
                z_round=${val}
	elif [[ ${name} == "error" ]] ; then
		e=${val}
        elif [[ ${name} == "x_title" ]] ; then
                x_title=${val}
        elif [[ ${name} == "y_title" ]] ; then
                y_title=${val}
        elif [[ ${name} == "title" ]] ; then
                title=${val}
        elif [[ ${name} == "pngFile" ]] ; then
                png_file=${val}
        elif [[ ${name} == "log_x" ]] ; then
                log_x=${val}
        elif [[ ${name} == "log_y" ]] ; then
                log_y=${val}
        elif [[ ${name} == "no-delete" ]] ; then
                delete=0
        elif [[ ${name} == "high-light" ]] ; then
		high_light=${name}
		table="high_light_results"
		csv_file="selected_high_light_fits.csv"
		fit_list=$(head ${csv_file})
        fi
done

# Maybe delete the previous results
if [ ${delete} -eq 1 ] ; then
	rm ?_file_*.txt
fi

# Default titles
if [ ${#x_title} -eq 0 ] ; then
	if [[ ${x} == "ll" ]] ; then
		x_title="Light-Level-on-Dial"
	elif [[ ${x} == "gain" ]] ; then
		x_title="Gain-(in-Millions)"
	elif [[ ${x} == "mu_out" ]] ; then
		x_title="Observed-Light-Level-(Mu)"
	elif [[ ${x} == "hv" ]] ; then
		x_title="Voltage"
	elif [[ ${x} == "gain_error" ]] ; then
		x_title="Gain-Error"
	else
		x_title=${x}
	fi
fi
if [ ${#y_title} -eq 0 ] ; then
	if [[ ${y} == "ll" ]] ; then
		y_title="Light-Level-on-Dial"
	elif [[ ${y} == "mu_out" ]] ; then
		y_title="Observed-Light-Level-(Mu)"
	elif [[ ${y} == "hv" ]] ; then
		y_title="Voltage"
	elif [[ ${y} == "gain" ]] ; then
		y_title="Gain-(in-Millions)"
	elif [[ ${y} == "gain_error" ]] ; then
		y_title="Gain-Error"
	else
		y_title=${y}
	fi
fi
if [ ${#z} -gt 0 -a ${#z_names} -eq 0 ] ; then
	z_names=$(echo ${z_values} | sed "s/ /,/g")
fi
if [ ${#z} -gt 0 -a ${#z_title} -eq 0 ] ; then
	z_title=${z}
fi
if [[ ${z_title} == "none" ]] ; then
	z_title=""
fi
if [ ${#title} -eq 0 ] ; then
	title="${y_title}-vs-${x_title}"
	if [ ${#z} -gt 0 ] ; then
		title="${title}-spread-over-${z}"
	fi
fi


# Loop over the z values, fill the files one color at a time
max_color_index=$(echo ${z_colors} | awk -F',' '{print NF}')
for cur_val in ${z_values} ; do

	# Create files for this value
	cur_color=$(echo ${z_colors} | awk -v var=${current_color_index} -F',' '{print $var}')
	./sql_select.sh ${high_light} ${condition}="ROUND(${z},${z_round})=${cur_val}" fit_list=${fit_list}
	./sql_write_data_arrays.sh ${high_light} x=${x} y=${y} e=${y_error} color=${cur_color}

	colors_used="${colors_used},${cur_color}"
	check=$(head x_file_${cur_color}.txt)
	current_color_index=$((current_color_index + 1))
	if [ ${current_color_index} -gt ${max_color_index} ] ; then
		current_color_index=1
	fi
done

echo ${fit_list} > ${csv_file}

# Run the root macro that will read the data files and form graph, send in title info
if [ ${#png_file} -gt 0 ] ; then
	root_options="-l -b -q"
else
	root_options="-l"
fi
root ${root_options} "make_plots.c(\"${colors_used}\", \"${title}\", \"${x_title}\", \"${y_title}\", \"${z_names}\", \"${z_title}\", \"${z_markers}\", \"${y_error}\", \"${png_file}\", ${log_x}, ${log_y}, ${x_error})"
