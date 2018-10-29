
if [[ $1 == "scale=1" ]] ; then
	scale=1
else
	scale=0
fi

files=$(head selected_runs.txt)

for id in ${files} ; do
	filename=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "USE gaindb; SELECT rootfile FROM run_params WHERE run_id=${id};")
	res=$(root -b -q -l "fit_high_light.c(\"/media/data/Projects/fit_pmt/data/${filename}\", ${scale})")
	res=$(echo ${res} | awk '{print $NF}')
	echo run:${id} scale:${scale} signal:${res} >> ped_results.txt
done
