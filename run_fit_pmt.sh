
# run_fit_pmt.sh
# Brady Lowe # lowebra2@isu.edu
#
#################################################################
# This script will call a root analyzer for every data run in
# the current directory with a .root file associated 
# with it. PNGs will be output for each data file.  
##################################################################

# Quickly grab the output from the run_id selection
run_list=$(head -n 1 selected_runs.csv | sed "s/,/ /g")

# This is where data/images are stored
data_dir=$(grep data_dir setup.txt | awk -F'=' '{print $2}')
im_dir=$(grep im_dir setup.txt | awk -F'=' '{print $2}')


adc_range=0
legend=0
conInj=0
conGain=20
conLL=20
randomChanges=20
low=1000
high=150
savePNG=1
saveNN=0
fitEngine=0
noExpo=2
noSQL=0

# Decode input parameters
for item in $* ; do
	name=$(echo ${item} | awk -F'=' '{print $1 }')
	val=${item#${name}=}
	# Check for some words
	if [[ ${val} == "true" || ${val} == "True" ]] ; then
		val=1
	elif [[ ${val} == "false" || ${val} == "False" ]] ; then
		val=0
	fi
	# Percent gain is allowed to vary
	if [[ ${name} == "conGain" ]] ; then
		conGain=${val}
	# Percent ll is allowed to vary
	elif [[ ${name} == "conLL" ]] ; then
		conLL=${val}
	# Initial ped injection guess
	elif [[ ${name} == "pedInj" ]] ; then
		pedInj=${val}
	# Percent pedInj is allowed to vary
	elif [[ ${name} == "conInj" ]] ; then
		conInj=${val}
	# Get rid of exponential
	elif [[ ${name} == "noExpo" ]] ; then
		noExpo=${val}
	elif [[ ${name} == "randomChanges" ]] ; then
		randomChanges=${val}
	# Root Filename (if null, all will be used)
	elif [[ ${name} == "rootFile" ]] ; then
		rootFile=${val}
	# Low data bin threshold (counts)
	elif [[ ${name} == "low" ]] ; then
		low=${val}
	# High data bin threshold (counts)
	elif [[ ${name} == "high" ]] ; then
		high=${val}
	# Fit engine option choice (integer)
	elif [[ ${name} == "fitEngine" ]] ; then
		fitEngine=${val}
	# Save png output (human format)
	elif [[ ${name} == "savePNG" ]] ; then
		savePNG=${val}
	# Save png output (neural network format)
	elif [[ ${name} == "saveNN" ]] ; then
		saveNN=${val}
	# Single run_id
	elif [[ ${name} == "run_id" ]] ; then
		run_list=${val}
	# Display images through eog when finished
	elif [[ ${name} == "showImages" ]] ; then
		showImages=${val}
	# Can turn off storing in mysql database
	elif [[ ${name} == "noSQL" ]] ; then
		noSQL=${val}
	# Set label at fit time
	elif [[ ${name} == "label" ]] ; then
		label=${val}
	elif [[ ${name} == "legend" ]] ; then
		legend=${val}
	# Choose ADC range to look at
	elif [[ ${name} == "adc_range" ]] ; then
		adc_range=${val}
	fi	
done

##########################################################
# Check all necessary input values, initialize if needed
# Correct errors
##########################################################


# Check for filename and grab corresponding run_id
if [ ${#rootFile} -gt 0 -a ${#run_id} -eq 0 ] ; then
	run_id=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "USE gaindb; SELECT run_id FROM run_params WHERE rootfile = '${rootfile}';")
fi

# Initialize lists for loop
created_pngs=""
# Loop through all files in list, run macro to create png and numbers each time
for cur_id in ${run_list} ; do

	# Grab the run parameters from the database
	allitems=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "USE gaindb; SELECT * FROM run_params WHERE run_id = '${cur_id}';")
	if [ ${#allitems} -eq 0 ] ; then
		continue
	fi
	set -- ${allitems}

	# Insert a new row in the fit_results table and grab the fit_id
	if [ ${noSQL} -eq 0 ] ; then
		mysql --defaults-extra-file=~/.mysql.cnf -Bse "USE gaindb; INSERT INTO fit_results (run_id) VALUES(${cur_id});"
		fitID=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "USE gaindb; SELECT fit_id FROM fit_results WHERE run_id=${cur_id} ORDER BY fit_id DESC LIMIT 1;")
	else
		fitID=0
	fi

	# Define sql output file for grabbing the output from the root file and storing it
	sqlfile="sql_output_${fitID}.csv"
	
	# If user sent in single run_id, DONT DO BATCH MODE
	single_run=$(echo ${run_list} | grep \ )
	if [ ${#single_run} -eq 0 ] ; then
		rootOptions="-l"
	else
		rootOptions="-l -b -q"
	fi
	# Fit the data, grab chi squared per ndf
	chi2=$(root ${rootOptions} "fit_pmt_wrapper.c(\"${data_dir}/${15}\", ${cur_id}, ${fitID}, $2, $3, ${11}, ${10}, $5, $6, $7, $8, $9, ${12}, ${13}, ${adc_range}, ${low}, ${high}, ${conInj}, ${conGain}, ${conLL}, ${savePNG}, ${saveNN}, ${fitEngine}, ${noExpo}, ${randomChanges})")
	chi2=$(echo ${chi2} | awk -F' ' '{print $NF}')
	
	# Process the human-viewable output pngs
	png=""
	logpng=""
	bothpng=""
	if [ ${savePNG} -eq 1 ] ; then
		# Grab the freshly-made png filename from this directory
		png=$(ls fit_pmt__fitID${fitID}_runID${1}_*log0.png)
		# Get the corresponding log plot filename 
		logpng=$(echo ${png} | sed 's/log0/log1/g')
		# Create filename for linear/log montage for this fit_id
		bothpng=$(echo ${png} | sed 's/log0/logX/g')
		# Create the montage and put it where it goes
		montage -label "%f" -frame 5 -geometry 500x400+1+1 ${png} ${logpng} ${bothpng}
		# Delete single images, keep montage of both images
		created_pngs="${created_pngs} ${im_dir}/png_fit/${bothpng}"
		rm ${png} ${logpng}
	fi

	# Repeat the above process for neural network style images (fewer steps necessary)
	nnpng=""
	nnlogpng=""
	if [ ${saveNN} -eq 1 ] ; then
		nnpng=$(ls fit_pmt_nn__fitID${fitID}_runID${1}_*log0.png)
		nnlogpng=$(echo ${nnpng} | sed 's/log0/log1/g')
	fi

	# Query the database to store all output info from this fit
	if [ -f ${sqlfile} -a ${noSQL} -eq 0 ] ; then
		# Move the images to the storage directories
		dir_num=$((fit_id/1000))
		if [ ${savePNG} -gt 0 ] ; then
			if [ ! -d ${im_dir}/png_fit/${dir_num} ] ; then
				mkdir ${im_dir}/png_fit/${dir_num} 
			fi
			mv ${bothpng} ${im_dir}/png_fit/${dir_num}/.
		fi
		if [ ${saveNN} -gt 0 ] ; then
			if [ ! -d ${im_dir}/png_fit_nn/${dir_num} ] ; then
				mkdir ${im_dir}/png_fit_nn/${dir_num} 
			fi
			mv ${nnpng} ${nnlogpng} ${im_dir}/png_fit_nn/${dir_num}/.
		fi
		# Initialize the update query
		query="USE gaindb; UPDATE fit_results SET $(head -n 1 ${sqlfile})"
		# If we are saving png output, update database with absolute file path
		if [ ${savePNG} -gt 0 ] ; then
			query="${query},human_png='png_fit/${dir_num}/${bothpng}'"
		fi 
		if [ ${saveNN} -gt 0 ] ; then
			query="${query},nn_png='png_fit_nn/${dir_num}/${nnpng}'"
		fi 
		query="${query} WHERE fit_id=${fitID};"
		# We don't want anything that is "not a number"
		query=$(echo ${query} | sed "s/nan/-1.0/g")
		res=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}")
		# Delete file after query submission to avoid double submission
		if [[ ${res:0:5} != "ERROR" ]] ; then
			rm ${sqlfile}
		# If there was an error with this query, drop the row from the table
		else
			mysql --defaults-extra-file=~/.mysql.cnf -Bse "USE gaindb; DELETE FROM fit_results WHERE fit_id=${fitID};"
		fi

		# If no exponential on ped, set label=10 as a hack
		if [ ${#label} -gt 0 ] ; then
			mysql --defaults-extra-file=~/.mysql.cnf -Bse "USE gaindb; UPDATE fit_results SET label=${label} WHERE fit_id=${fitID};"
		fi
	# If error, write error value to fit_results table in chi column
	elif [ ${chi2} -lt 0 ] ; then
		query="USE gaindb; UPDATE fit_results SET chi=${chi2} WHERE fit_id=${fitID};"
		res=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "${query}")
	fi

	# Make sure to break from loop if only one run_id
	if [ ${#run_id} -gt 0 ] ; then
		break
	fi
done

