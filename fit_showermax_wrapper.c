#include "fit_showermax.c"
using namespace std;

// ADC factor (THERE IS A FACTOR OF 10^6 FLOATING AROUND INVISIBLY HERE)
Double_t gainToChannels = 160.2 / 25.0; // 160.2 femtoCoulombs per electron / 25.0 femtoCoulombs per channel = 6.408 chan / electron
Double_t channelsToGain = 25.0 / 160.2; // (25 fC / chan) / (160.2 fC / electron) = 0.15606 electron / chan

// This function is made for users or scripts to call. This function will take some input and call a much more complicated 
// function (fit_pmt.c) which is very ugly and nearly impossible to call by hand.
// All inputs into fit_pmt.c should be implemented in this function. This function should provide full
// functionality of fit_pmt.c while also allowing the user to diagnose and test values as well as record
// and keep track of previous fits to data files.
Int_t fit_showermax_wrapper(string rootFile, Int_t chan = 2, Int_t adc_range = 1, Int_t binWidth = 1, Int_t signal = 120, Int_t sigrms = 28, Int_t ped = 882, Int_t pedrms = 6, Int_t mu = 1, Int_t hv = 0, Double_t sigPE = 0.1, string detector = "", Double_t energy = 0.0){

	// Define "off" value
	Double_t off = -1.0;

	// w - probability of type II background
	Double_t w0 		= 0.08;
	Double_t wmin 		= 0.0;
	Double_t wmax 		= 1.0;

	// ped - mean of pedestal
	Double_t ped0 		= ped;
	Double_t pedmin 	= off;
	Double_t pedmax 	= off;

	// pedrms - rms of pedestal
	Double_t pedrms0 	= pedrms;
	Double_t pedrmsmin 	= off;
	Double_t pedrmsmax 	= off;

	// alpha - exponential decay rate
	Double_t alpha0 	= 0.01;
	Double_t alphamin 	= off;
	Double_t alphamax 	= off;

	// mu - average # of PE's per event
	Double_t mu0 = mu;
	Double_t mumin = off;
	Double_t mumax = off;

	// sig - Grab the predefined "good guess" for this parameter from file.
	Double_t sig0 		= signal;
	// If user sent in initial gain value, use it
	Double_t sigmin		= 0.9 * signal;
	Double_t sigmax 	= 1.1 * signal;

	// sigrms - rms of signal
	Double_t sigrms0 	= sigrms;
	Double_t sigrmsmin 	= off;
	Double_t sigrmsmax 	= off;
	// inj - proportion of data that are injected pedestal
	Double_t inj0 		= 0.0;
	Double_t injmin		= 0.0;
	Double_t injmax		= 0.1;
	// real - proportion of data that are real events
	Double_t real0 		= 1.0;
	Double_t realmin 	= 0.0;
	Double_t realmax 	= 1.0;

	// Decide which PE peaks to consider 
	const int minPE = 1;
	const int maxPE = 15;

	// Call the function with the appropriate params
	return fit_showermax(
		rootFile, chan, adc_range, binWidth, hv,
		sigPE, detector, energy, minPE, maxPE,
		w0, ped0, pedrms0, alpha0, mu0, 	
		sig0, sigrms0, inj0, real0,	
		wmin, pedmin, pedrmsmin, alphamin, mumin, 
		sigmin, sigrmsmin, injmin, realmin,	
		wmax, pedmax, pedrmsmax, alphamax, mumax,
		sigmax, sigrmsmax, injmax, realmax	
	);					
}


