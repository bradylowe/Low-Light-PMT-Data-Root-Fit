
x_title_gain="Voltage"
y_title_gain="Gain-(in-Millions)"
title_gain="Gain-Curve-PMT-${pmt}"

x_title_ll="Light-Level-On-Dial"
y_title_ll="Observed-Light-Level-(Mu)"
title_ll="Light-Curve-PMT-${pmt}"

plot_gain=0
plot_light=0
plot_error=0
pmt=0
voltages="2000,1975,1950,1925,1900,1800,1700,1600"
voltage_names="2000-1900,1800-1600"
highv=""
lowl=""

for item in $* ; do
	name=$(echo ${item} | awk -F'=' '{print $1}')
	val=$(echo ${item} | awk -F'=' '{print $2}')
	if [[ ${name} == "plot_gain" ]] ; then
		plot_gain=${val}
	elif [[ ${name} == "plot_light" ]] ; then
		plot_light=${val}
	elif [[ ${name} == "highv" ]] ; then
		highv="_highv"
	elif [[ ${name} == "lowl" ]] ; then
		highv="_lowl"
	elif [[ ${name} == "all" ]] ; then
		if [ ${val} -eq 1 ] ; then
		plot_gain=1
		plot_light=1
		plot_error=1
		fi
	elif [[ ${name} == "plot_error" ]] ; then
		plot_error=${val}
	elif [[ ${name} == "pmt" ]] ; then
		pmt=${val}
		if [ ${pmt} -eq 5 ] ; then
			voltages="1350,1300,1250,1200,1150,1100,1000,900,800"
			voltage_names="1350-1200,1100-800"
		elif [ ${pmt} -eq 6 ] ; then
			voltages="1000,975,950,925,900,850,800,700"
			voltage_names="1000-900,800-700"
		fi
	fi
done



#### Gain plots
if [ ${plot_gain} -eq 1 ] ; then

	./sql_make_plot.sh pmt=${pmt} x_title=${x_title_gain} y_title=${y_title_gain} title=Gain-Curve-With-Error-PMT-${pmt} z=gain_percent_error z_values=0,1,2,3,4,5 z_colors=black,red,blue,blue,blue,blue z_title=Gain-Error z_names=0\%,1\%,2-5\% pngFile=gain_curve_pmt${pmt}_showing_gain_error${highv}${lowl}.png
	./sql_make_plot.sh pmt=${pmt} x_title=${x_title_gain} y_title=${y_title_gain} title=Chi-Squared-Per-Degree-of-Freedom-For-Different-Gain-Measurements z=chi z_values=0,1,2,3,4,5 z_colors=black,red,blue,purple,purple,purple z_title=Chi-Per-NDF z_names=0,1,2,3-5 pngFile=gain_curve_pmt${pmt}_showing_chi${highv}${lowl}.png
	./sql_make_plot.sh pmt=${pmt} x_title=${x_title_gain} y_title=${y_title_gain} title=Light-Level-Dependence z=ll z_values=100,90,50,40,30,20 z_colors=black,black,red,red,blue,blue z_title=Light-Level z_names=90-100,40-50,20-30 pngFile=gain_curve_pmt${pmt}_showing_ll${highv}${lowl}.png
	./sql_make_plot.sh pmt=${pmt} x_title=${x_title_gain} y_title=${y_title_gain} title=Results-With-Different-Filters z=filter z_values=7,8,1 z_title=Filter-Transmission z_names=100\%,10\%,0.1\% pngFile=gain_curve_pmt${pmt}_showing_filter${highv}${lowl}.png
	#./sql_make_plot.sh pmt=${pmt} x_title=${x_title_gain} y_title=${y_title_gain} title=Results-With-And-Without-The-High-Energy-Noise-Bump z=fit_high z_values=1,150 z_names=Including-Bump,Excluding-Bump pngFile=gain_curve_pmt${pmt}_showing_high_energy_bump${highv}${lowl}.png
	./sql_make_plot.sh pmt=${pmt} x_title=${x_title_gain} y_title=${y_title_gain} title=Fit-Results-Based-On-Range-Of-Allowed-Fit-Values z=con_gain z_values=50,20,10,5,1 z_names=50\%,20\%,10\%,5\%,1\% z_title=Allowed-Deviation-In-Gain pngFile=gain_curve_pmt${pmt}_showing_constraint${highv}${lowl}.png
	./sql_make_plot.sh pmt=${pmt} x_title=${x_title_gain} y=sig_0 y_title=Initial-1-PE-Signal-Guess title=Initial-Gain-Guess-For-Different-Degrees-of-Constraint z=con_gain z_values=50,20,10,5,1 z_names=50\%,20\%,10\%,5\%,1\% z_title=Allowed-Deviation-From-Best-Guess pngFile=gain_curve_pmt${pmt}_showing_initial_guesses${highv}${lowl}.png
	./sql_make_plot.sh pmt=${pmt} x_title=${x_title_gain} y_title=${y_title_gain} title=Trying-Different-Exponential-Decay-Models z=no_expo z_values=0,2,1 z_names=NIM-Model,No-Expo-In-Pedestal,No-Expo-In-Model z_title=none pngFile=gain_curve_pmt${pmt}_showing_expo${highv}${lowl}.png

	montage -label %f -frame 5 -geometry +4+4 gain_curve_pmt${pmt}_showing_gain_error${highv}${lowl}.png gain_curve_pmt${pmt}_showing_chi${highv}${lowl}.png gain_curve_pmt${pmt}_showing_ll${highv}${lowl}.png gain_curve_pmt${pmt}_showing_filter${highv}${lowl}.png gain_curve_pmt${pmt}_showing_constraint${highv}${lowl}.png gain_curve_pmt${pmt}_showing_expo${highv}${lowl}.png montage_gain_curves_pmt${pmt}${highv}${lowl}.png

	montage -label %f -frame 5 -geometry +4+4 gain_curve_pmt${pmt}_showing_constraint${highv}${lowl}.png gain_curve_pmt${pmt}_showing_initial_guesses${highv}${lowl}.png montage_gain_curve_with_initial_guesses_pmt${pmt}${highv}${lowl}.png

fi


##### Light level plots
if [ ${plot_light} -eq 1 ] ; then

	./sql_make_plot.sh pmt=${pmt} x=ll x_title=${x_title_ll} y=mu_out y_title=${y_title_ll} title=Light-Curve-With-Gain-Error-PMT-${pmt} z=gain_percent_error z_values=0,1,2,3,4,5 z_colors=black,red,blue,purple,purple,purple z_title=Gain-Error z_names=0\%,1\%,2\%,3-5\% pngFile=light_curve_pmt${pmt}_showing_gain_error${highv}${lowl}.png log_y=1
	./sql_make_plot.sh pmt=${pmt} x=ll x_title=${x_title_ll} y=mu_out y_title=${y_title_ll} title=Chi-Squared-Per-Degree-of-Freedom-For-Different-Light-Level-Measurements z=chi z_values=5,4,3,2,1,0 z_colors=black,black,black,red,blue,purple z_title=Chi-Per-NDF z_names=3-5,2,1,0 pngFile=light_curve_pmt${pmt}_showing_chi${highv}${lowl}.png log_y=1
	./sql_make_plot.sh pmt=${pmt} x=ll x_title=${x_title_ll} y=mu_out y_title=${y_title_ll} title=Voltage-Dependence z=hv z_values=${voltages} z_colors=black,black,black,black,black,red,red,red z_title=Voltage z_names=${voltage_names} pngFile=light_curve_pmt${pmt}_showing_hv${highv}${lowl}.png log_y=1
	./sql_make_plot.sh pmt=${pmt} x=ll x_title=${x_title_ll} y=mu_out y_title=${y_title_ll} title=Light-Levels-Through-Different-Filters z=filter z_values=7,8,1 z_title=Filter-Transmission z_names=100\%,10\%,0.1\% z_markers=cross,cross,cross pngFile=light_curve_pmt${pmt}_showing_filter${highv}${lowl}.png log_y=1
	#./sql_make_plot.sh pmt=${pmt} x=ll x_title=${x_title_ll} y=mu_out y_title=${y_title_ll} title=Light-Level-With-And-Without-The-High-Energy-Noise-Bump z=fit_high z_values=1,150 z_names=Including-Bump,Excluding-Bump pngFile=light_curve_pmt${pmt}_showing_high_energy_bump${highv}${lowl}.png log_y=1
	./sql_make_plot.sh pmt=${pmt} x=ll x_title=${x_title_ll} y=mu_out y_title=${y_title_ll} title=Light-Level-Based-On-Range-Of-Allowed-Fit-Values z=con_ll z_values=50,20,10,5,1 z_names=50\%,20\%,10\%,5\%,1\% z_title=Allowed-Deviation-In-Light-Level pngFile=light_curve_pmt${pmt}_showing_constraint${highv}${lowl}.png log_y=1
	./sql_make_plot.sh pmt=${pmt} x=ll x_title=${x_title_ll} y=sig_0 y_title=Initial-1-PE-Signal-Guess title=Initial-Mu-Guess-For-Different-Degrees-of-Constraint z=con_ll z_values=50,20,10,5,1 z_names=50\%,20\%,10\%,5\%,1\% z_title=Allowed-Deviation-From-Best-Guess pngFile=light_curve_pmt${pmt}_showing_initial_guesses${highv}${lowl}.png log_y=1
	./sql_make_plot.sh pmt=${pmt} x=ll x_title=${x_title_ll} y=mu_out y_title=${y_title_ll} title=Trying-Different-Exponential-Decay-Models z=no_expo z_values=0,2,1 z_names=NIM-Model,No-Expo-In-Pedestal,No-Expo-In-Model z_title=none pngFile=light_curve_pmt${pmt}_showing_expo${highv}${lowl}.png log_y=1

	montage -label %f -frame 5 -geometry +4+4 light_curve_pmt${pmt}_showing_gain_error${highv}${lowl}.png light_curve_pmt${pmt}_showing_chi${highv}${lowl}.png light_curve_pmt${pmt}_showing_hv${highv}${lowl}.png light_curve_pmt${pmt}_showing_filter${highv}${lowl}.png light_curve_pmt${pmt}_showing_constraint${highv}${lowl}.png light_curve_pmt${pmt}_showing_expo${highv}${lowl}.png montage_light_curves_pmt${pmt}${highv}${lowl}.png

fi


##### Gain error vs chi plots
if [ ${plot_error} -eq 1 ] ; then

	./sql_make_plot.sh pmt=${pmt} x=gain x_title="Gain" y=gain_error y_title="Gain-Error" title=Measurement-Resolution-Dependence-On-Incident-Light-Intensity z=mu_out z_round=-2 z_values=0,100,200,300,400 z_colors=black,red,red,red,red z_names=\<50-PEs-per-flash,\>50-PEs-per-flash pngFile=gain_error_vs_gain_pmt${pmt}_showing_abs_light_level${highv}${lowl}.png log_x=1 log_y=1

fi
