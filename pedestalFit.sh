
data_dir="/media/brady/4be7777f-c84c-40ca-af3a-b8c6e4f2f90d/brady/Projects/fit_pmt/data"
runs=$(head selected_runs.txt)

if [ $# -eq 1 ] ; then
	savePNG=$1
else
	savePNG=0
fi

for run_id in ${runs} ; do
	rootfile=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "USE gaindb; SELECT rootfile FROM run_params WHERE run_id=${run_id};")
	root -l "pedestalFit.c(\"${data_dir}/${rootfile}\", 11, ${savePNG})"
	echo "Continue? (y/n)"
	read -n 1 choice 
	if [[ ${choice} == "n" || ${choice} == "N" ]] ; then
		exit
	fi
done
