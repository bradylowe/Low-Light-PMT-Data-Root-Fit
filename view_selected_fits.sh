# PNG location
im_dir="/media/data/Projects/fit_pmt/images/png_fit/"

# Grab input from user or file
if [ $# -eq 1 ] ; then
	output=$1
else
	output=$(head selected_fits.txt | sed "s/ /,/g")
fi

# Qeury for filename and append path
pngs=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "USE gaindb; SELECT CONCAT('${im_dir}', human_png) FROM fit_results WHERE fit_id IN (${output});")

# Show image(s)
eog ${pngs}