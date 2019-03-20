// Brady Lowe // lowebra2@isu.edu

#include <TROOT.h>
#include <TMath.h>
#include <TChain.h>
#include <TApplication.h>


// This function takes in the signal size (in ADC channels)
// of a single photoelectron ejection from the cathode and
// returns the gain measurement from this value.

// Optionally, a light level can be sent in to measure the gain
// at a calibrated high light level.

// scale = 0 means that the CAEN V965 ADC was on low-range mode
// scale = 1 means that the ADC was on high-range mode
double sigToGain(double sig, double mu = 1.0, int scale = 0){
	double adc_factor = 25.0;
	if (scale > 0) adc_factor *= 8.0;
	return sig * adc_factor / (mu * 160.217662);
}


