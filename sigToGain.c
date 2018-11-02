// Brady Lowe // lowebra2@isu.edu

#include <TROOT.h>
#include <TMath.h>
#include <TChain.h>
#include <TApplication.h>


double sigToGain(double sig, double mu, int scale=0){
	double adc_factor = 25.0;
	if (scale > 0) adc_factor *= 8.0;
	return sig * adc_factor / mu / 160.217662;
}


