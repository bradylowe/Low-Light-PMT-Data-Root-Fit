
# Standard run filter
standard="amp = 1 AND ll >= 30 AND ll <= 60 AND nevents >= 100000"

# This is for a batch of runs (a study) i took to measure the gain curve of pmt 1 (2000V - 700V, 50V step) { 3,888 images }
if [ 0 -eq 1 ] ; then
########################################################################################################################################
# Define run list
runs="510,511,512,513,514,515,516,517,518,519,520,521,522,523,524,525,526,527,528,529,530,531,532,533,534,535"
# Define beginning of montage names
name="hvspread_2000_700_pmt1"
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
./run_fit_pmt.sh savePNG=1 saveNN=1 runs=${runs} fitEngine=${eng} conInj=${conInj} conLL=${conLL} low=${thresh} high=${thresh} pngFile=${pngFile}

			done
		done
	done
done
fi
########################################################################################################################################

./sql_select_runs.sh "run>2192 AND hv=1900 AND ll>0"


# 33 lines
# This is for a batch of runs (a study) i took to get the PMT(1) response at 2000 V over light levels 30 - 100 (no filter)
if [ 0 -eq 1 ] ; then
########################################################################################################################################
# Define run list
runs="542,543,544,545,546,547,548,549,550,551,552,553"
# Define beginning of montage names
name="ll_spread_30_to_100"
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
./run_fit_pmt.sh savePNG=1 saveNN=1 runs=${runs} fitEngine=${eng} conInj=${conInj} conLL=${conLL} low=${thresh} high=${thresh} pngFile=${pngFile}

			done
		done
	done
done
fi
########################################################################################################################################


# 33 lines
# This is for a batch of runs (a study) i took to get the PMT(1) response at 2000 V over light levels 30 - 100 (no filter)
if [ 1 -eq 1 ] ; then
########################################################################################################################################
# Define run list
runs=""
# Define beginning of montage names
name="ll_spread_30_to_100_hv1900"
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
./run_fit_pmt.sh savePNG=1 saveNN=1 runs=${runs} fitEngine=${eng} conInj=${conInj} conLL=${conLL} low=${thresh} high=${thresh} pngFile=${pngFile}

			done
		done
	done
done
fi
########################################################################################################################################





# Very thorough exploration of possible fits producible currently. 
# Around 10000 images total
#  # for each image, there is a human viewable version and a neural network version
#  # and for each one of those, there is a linear scale image and a log scale image (y-axis)
if [ 0 -eq 1 ] ; then
########################################################################################################################################
pmt_list="1 2 3 4"
for pmt in ${pmt_list} ; do
	# Select the runs
	$(./sql_select_runs.sh "${standard} AND pmt=${pmt} AND run_id<509")
	runs=$(head -n 1 selected_runs.sh)
	# Define beginning of montage names
	name="standard_pmt${pmt}"
	./run_fit_pmt.sh savePNG=1 saveNN=1 low=1 high=1 conInj=100 conLL=0 runs=${runs} fitEngine=1 pngFile="${name}_eng1_conInj100_conLL0_low1_high1.png"
	./run_fit_pmt.sh savePNG=1 saveNN=1 low=1 high=1 conInj=0 conLL=0 runs=${runs} fitEngine=1 pngFile="${name}_eng1_conInj0_conLL0_low1_high1.png"
	./run_fit_pmt.sh savePNG=1 saveNN=1 low=1 high=1 conInj=100 conLL=90 runs=${runs} fitEngine=1 pngFile="${name}_eng1_conInj100_conLL90_low1_high1.png"
	./run_fit_pmt.sh savePNG=1 saveNN=1 low=15 high=15 conInj=100 conLL=0 runs=${runs} fitEngine=1 pngFile="${name}_eng1_conInj100_conLL0_low15_high15.png"
	./run_fit_pmt.sh savePNG=1 saveNN=1 low=15 high=15 conInj=0 conLL=0 runs=${runs} fitEngine=1 pngFile="${name}_eng1_conInj0_conLL0_low15_high15.png"
	./run_fit_pmt.sh savePNG=1 saveNN=1 low=15 high=15 conInj=100 conLL=90 runs=${runs} fitEngine=1 pngFile="${name}_eng1_conInj100_conLL90_low15_high15.png"
	./run_fit_pmt.sh savePNG=1 saveNN=1 low=150 high=150 conInj=100 conLL=0 runs=${runs} fitEngine=1 pngFile="${name}_eng1_conInj100_conLL0_low150_high150.png"
	./run_fit_pmt.sh savePNG=1 saveNN=1 low=150 high=150 conInj=0 conLL=0 runs=${runs} fitEngine=1 pngFile="${name}_eng1_conInj0_conLL0_low150_high150.png"
	./run_fit_pmt.sh savePNG=1 saveNN=1 low=150 high=150 conInj=100 conLL=90 runs=${runs} fitEngine=1 pngFile="${name}_eng1_conInj100_conLL90_low150_high150.png"
done
########################################################################################################################################
fi
