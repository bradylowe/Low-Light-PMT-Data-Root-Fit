# PNG location
im_dir="$(grep im_dir setup.txt | awk -F'=' '{print $2}')"

fit_type="low_light"

if [ $# -gt 0 ] ; then
	fit_type=$1
fi

if [[ ${fit_type} == "low_light" ]] ; then
	im_dir="${im_dir}/png_fit/"
	column="human_png"
	table="fit_results"
	output=$(head -n 1 selected_fits.csv)
elif [[ ${fit_type} == "high_light" ]] ; then
	im_dir="${im_dir}/png_high_light/"
	column="png_file"
	table="high_light_results"
	output=$(head -n 1 selected_high_light_fits.csv)
fi

# Qeury for filename and append path
query="USE gaindb; SELECT CONCAT('${im_dir}', ${column}) FROM ${table} WHERE fit_id IN (${output});"
pngs=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}")

# Show image(s)
eog ${pngs}
