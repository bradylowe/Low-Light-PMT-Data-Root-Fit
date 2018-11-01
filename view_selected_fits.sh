# PNG location
im_dir="$(grep im_dir setup.txt | awk -F'=' '{print $2}')"

# Grab input from user or file
if [ $# -eq 1 ] ; then
	output=$1
else
	output=$(head selected_fits.txt | sed "s/ /,/g")
fi

# Qeury for filename and append path
pngs=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "USE gaindb; SELECT CONCAT('${im_dir}/png_fit/', human_png) FROM fit_results WHERE fit_id IN (${output});")

# Show image(s)
eog ${pngs}
