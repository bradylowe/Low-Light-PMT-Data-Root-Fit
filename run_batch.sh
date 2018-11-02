

iped=80
iped=40
# Select ONLY recent runs that are non-pedestal with enough statistics
default="iped=${iped} AND nevents>=500000 AND datarate>=3000 AND ll>0 AND filter=7"


# Select the low light, high gain runs
./sql_select_runs.sh "ll<=50 AND hv>=1900 AND ${default}"
# Run fitting algorithm to measure gain and light level
./run_fit_pmt.sh conGain=20 conLL=10
./run_fit_pmt.sh conGain=20 conLL=10 noExpo=1
./run_fit_pmt.sh conGain=20 conLL=10 fitEngine=1
./run_fit_pmt.sh conGain=20 conLL=10 conInj=10

# Select the low light, low gain runs
./sql_select_runs.sh "ll<=50 AND hv<1900 AND ${default}"
# Run fitting algorithm to measure gain
./run_fit_pmt.sh conGain=10 conLL=1
./run_fit_pmt.sh conGain=10 conLL=1 noExpo=1

# Select the high light, high gain runs
./sql_select_runs.sh "ll>50 AND hv>=1900 AND ${default}"
# Run fitting algorithm to measure light level
./run_fit_pmt.sh conGain=1 conLL=20
./run_fit_pmt.sh conGain=0 conLL=20

# Select the high light, low gain runs
./sql_select_runs.sh "ll>50 AND hv<1900 AND ${default}"
# Run fitting algorithm to measure gain
./run_fit_pmt.sh conGain=20 conLL=1
./run_fit_pmt.sh conGain=20 conLL=0


########
# Now run the filter data.
# Filter 8 has high light at ll=100
# Filter 1 has low light at ll=100
default="iped=40 AND nevents>=500000 AND datarate>=3000 AND ll>0"

# Filter 8
./sql_select_runs.sh "filter=8 AND ll=100 AND ${default}"
./run_fit_pmt.sh conGain=1 conLL=20
./run_fit_pmt.sh conGain=0 conLL=20

# Filter 1
./sql_select_runs.sh "filter=1 AND ll=100 AND ${default}"
./run_fit_pmt.sh conGain=5 conLL=20
./run_fit_pmt.sh conGain=0 conLL=20
