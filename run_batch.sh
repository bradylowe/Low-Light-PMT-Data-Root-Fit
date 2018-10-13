
hv_list="2000"
for hv in ${hv_list} ; do
	# This is for a batch of runs (a study) i took to get the PMT(1) response at 2000 V over light levels 30 - 100 (no filter)
	########################################################################################################################################
	# Define run list
	# Define beginning of montage names
	./sql_select_runs.sh "run>=2419"
	name="stats_10pow3_to_10pow7_pmt1_hv${hv}"
	# List all the different ways we want to process this data
	eng_list="0 1"
	conInj_list="0 100" 
	conLL_list="0 90 100" 
	thresh_list="1 15 150" 
	# 36 total executions of the run_fit_pmt.sh algorithm
	#  # each execution involves executing the fit_pmt algo once per data run in the list (27)
	#  # each time fit_pmt is ran, we will get 4 saved pngs (if producing nn AND human pngs)
	#  # this would result in a total of 3,888 pngs produced (1944 human viewable [972 log, 972 linear])
	for eng in ${eng_list} ; do
		for conInj in ${conInj_list} ; do
			for conLL in ${conLL_list} ; do
				for thresh in ${thresh_list} ; do
	
	pngFile="${name}_eng${eng}_conInj${conInj}_conLL${conLL}_low${thresh}_high${thresh}.png"
	./run_fit_pmt.sh savePNG=1 saveNN=1 fitEngine=${eng} conInj=${conInj} conLL=${conLL} low=${thresh} high=${thresh} pngFile=${pngFile}
	
				done
			done
		done
	done
	########################################################################################################################################
done
