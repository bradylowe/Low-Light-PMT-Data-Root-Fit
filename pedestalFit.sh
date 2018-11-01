
data_dir=$(grep data_dir setup.txt | awk -F'=' '{print $2}')
runs=$(head selected_runs.txt)

if [ $# -eq 1 ] ; then
	runs=$1
fi

savePNG=0

for run_id in ${runs} ; do
	rootfile=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "USE gaindb; SELECT rootfile FROM run_params WHERE run_id=${run_id};")
	root -l "pedestalFit.c(\"${data_dir}/${rootfile}\", 11, ${savePNG})"
	echo "Continue? (y/n)"
	read -n 1 choice 
	if [[ ${choice} == "n" || ${choice} == "N" ]] ; then
		exit
	fi
done
