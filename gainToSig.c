// Brady Lowe // lowebra2@isu.edu

#include <TROOT.h>
#include <TMath.h>
#include <TChain.h>
#include <TApplication.h>


// This function takes in a PMT gain (and optionally a light level)
// and returns the number of ADC channels that represent a single PE
// signal on the given ADC sensitivity range.
double gainToSig(double gain, double mu = 1.0, int scale = 0){
	double adc_factor = 25.0;
	if (scale > 0) adc_factor *= 8.0;
	return mu * 160.217662 * gain / adc_factor;
}


