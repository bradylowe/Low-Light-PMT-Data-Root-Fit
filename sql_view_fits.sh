
# Initialize 
im_dir="$(grep im_dir setup.txt | awk -F'=' '{print $2}')"
table="fit_results"
csv_file="selected_fits.csv"
col="human_png"

# Parse input
for item in $* ; do
	name=$(echo ${item} | awk -F'=' '{print $1}')
	val=${item#${name}=}
	if [[ ${name} == "high-light" ]] ; then
		table="high_light_results"
		csv_file="selected_high_light_fits.csv"
		col="png_file"
	elif [[ ${name} == "nn" ]] ; then
		col="nn_png"
	fi
done

# Grab fits
output=$(head -n 1 ${csv_file})
if [ ${#output} -eq 0 ] ; then
	echo no fits
	exit
fi

# Grab png filenames and display
query="USE gaindb; SELECT CONCAT('${im_dir}/', ${col}) FROM ${table} WHERE fit_id IN (${output});"
pngs=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}")
if [ ${#pngs} -eq 0 ] ; then
	echo no images
	exit
fi
eog ${pngs}
