
# run_fit_pmt.sh
# Brady Lowe # lowebra2@isu.edu
#
#################################################################
# This script will call a root analyzer for every data run in
# the current directory with a .root file associated 
# with it. PNGs will be output for each data file.  
##################################################################

########################
# Define constants ###
######################

# This is a file used to pass data back from the Root
# macro to this script
sqlfile="sql_output.txt"

# This is where images are stored
data_dir=$(grep data_dir setup.txt | awk -F'=' '{print $2}')
im_dir=$(grep im_dir setup.txt | awk -F'=' '{print $2}')

# This is where data is stored


#######################################################
# Decode input parameters
######################################################
#  ## Should have the form:  optionName=optionValue
#  ## Example:               conGain=90
#  ## This means we will constrain the gain to within
#  ## 90% of what we think it really is.
#######################################################

# Loop through input parameters
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
	# List of run_id's 
	elif [[ ${name} == "runs" ]] ; then
		runs=${val}
	# Single run_id
	elif [[ ${name} == "run_id" ]] ; then
		run_id=${val}
	# Display images through eog when finished
	elif [[ ${name} == "showImages" ]] ; then
		showImages=${val}
	# Can turn off storing in mysql database
	elif [[ ${name} == "noSQL" ]] ; then
		noSQL=${val}
	# Set label at fit time
	elif [[ ${name} == "label" ]] ; then
		label=${val}
	fi	
done

##########################################################
# Check all necessary input values, initialize if needed
# Correct errors
##########################################################

# Initialize no gain constrain
if [ ${#conGain} -eq 0 ] ; then
	conGain=10
fi
# Initialize full ped injection rate constrain
if [ ${#conInj} -eq 0 ] ; then
	conInj=0
fi
# Initialize no light level constraint
if [ ${#conLL} -eq 0 ] ; then
	conLL=10
fi
# Initialize low threshold
if [ ${#low} -eq 0 ] ; then
	low=1000
fi
# Initialize high threshold
if [ ${#high} -eq 0 ] ; then
	high=1
fi
# Initialize savePNG
if [ ${#savePNG} -eq 0 ] ; then
	savePNG=1
fi
# Initialize saveNN
if [ ${#saveNN} -eq 0 ] ; then
	saveNN=0
fi
# Initialize fitEngine selection
if [ ${#fitEngine} -eq 0 ] ; then
	fitEngine=0
fi
# Init noExpo to false
if [ ${#noExpo} -eq 0 ] ; then
	noExpo=0
fi
# Init noSQL to false
if [ ${#noSQL} -eq 0 ] ; then
	noSQL=0
fi
# Check for filename and grab corresponding run_id
if [ ${#rootFile} -gt 0 -a ${#run_id} -eq 0 ] ; then
	run_id=$(mysql --defaults-extra-file=~/.mysql.cnf -Bse "USE gaindb; SELECT run_id FROM run_params WHERE rootfile = '${rootfile}';")
fi

################################################################################
# If the user doesn't send in a root file, read the numbers in selected_runs.txt
# You can set the values in selected_runs.txt via the script sql_select_data.sh
################################################################################

# Check for a list  of runs from user input or stored in selected_runs.txt
if [ ! -f selected_runs.txt -a ${#runs} -eq 0 -a ${#run_id} -eq 0 ] ; then
	echo "No files to process. Exiting..."
	exit
fi

# Single run_id takes priority, leave Root running for user interaction
if [ ${#run_id} -gt 0 ] ; then
	run_list=${run_id}
# If not executing single run, grab list of run_id's from user
elif [ ${#runs} -gt 0 ] ; then
	run_list=${runs}
# If no list of runs from user input, we must be using the selected_runs.txt file
else
	run_list=$(head -n 1 selected_runs.txt)
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

	# If user sent in single run_id, DONT DO BATCH MODE
	if [ ${#run_id} -eq 0 ] ; then
		rootOptions="-l -b -q"
	else
		rootOptions="-l"
	fi
	# Fit the data, grab chi squared per ndf
	chi2=$(root ${rootOptions} "fit_pmt_wrapper.c(\"${data_dir}/${15}\", ${cur_id}, ${fitID}, $2, $3, ${11}, ${10}, $5, $7, $8, $9, ${12}, ${13}, ${low}, ${high}, ${conInj}, ${conGain}, ${conLL}, ${savePNG}, ${saveNN}, ${fitEngine}, ${noExpo})")
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
		if [ ${savePNG} -gt 0 ] ; then
			mv fit_pmt__fitID${fitID}_*.png ${im_dir}/png_fit/.
		fi
		if [ ${saveNN} -gt 0 ] ; then
			mv fit_pmt_nn__fitID${fitID}_*.png ${im_dir}/png_fit_nn/.
		fi
		# Initialize the update query
		query="USE gaindb; UPDATE fit_results SET $(head -n 1 ${sqlfile})"
		# If we are saving png output, update database with absolute file path
		if [ ${savePNG} -gt 0 ] ; then
			query="${query},human_png='${bothpng}'"
		fi 
		if [ ${saveNN} -gt 0 ] ; then
			query="${query},nn_png='${nnpng}'"
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
		
	fi

	# Make sure to break from loop if only one run_id
	if [ ${#run_id} -gt 0 ] ; then
		break
	fi
done

