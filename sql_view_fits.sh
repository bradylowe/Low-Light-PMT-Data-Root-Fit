# Initialize
im_dir="$(grep im_dir setup.txt | awk -F'=' '{print $2}')"
table="fit_results"
csv_file="selected_fits.csv"
column="human_png"

# Parse input parameters
for item in $* ; do
	name=$(echo ${item} | awk -F'=' '{print $1}')
	val=${item#${name}=}
	# Grab fit type (low/high light fitter)
	if [[ ${name} == "high-light" ]] ; then
		table="high_light_results"
		csv_file="selected_high_light_fits.csv"
		column="png_file"
	elif [[ ${name} == "nn" ]] ; then
		column="nn_png"
	fi
done

output=$(head -n 1 ${csv_file})

# Query for filename and append path
query="USE gaindb; SELECT CONCAT('${im_dir}/', ${column}) FROM ${table} WHERE fit_id IN (${output});"
pngs=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}")

# Exit if no images
if [ ${#pngs} -eq 0 ] ; then
	echo no images
	exit
fi

# Show image(s)
eog ${pngs}
