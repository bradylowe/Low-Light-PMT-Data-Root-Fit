#include "fit_pmt.c"
#include "fit_pedestal.c"
using namespace std;

// ADC factor (THERE IS A FACTOR OF 10^6 FLOATING AROUND INVISIBLY HERE)
Double_t gainToChannels = 160.2 / 25.0; // 160.2 femtoCoulombs per electron / 25.0 femtoCoulombs per channel = 6.408 chan / electron
Double_t channelsToGain = 25.0 / 160.2; // (25 fC / chan) / (160.2 fC / electron) = 0.15606 electron / chan

// This function is made for users or scripts to call. This function will take some input and call a much more complicated 
// function (fit_pmt.c) which is very ugly and nearly impossible to call by hand.
// All inputs into fit_pmt.c should be implemented in this function. This function should provide full
// functionality of fit_pmt.c while also allowing the user to diagnose and test values as well as record
// and keep track of previous fits to data files.
Int_t fit_pmt_wrapper(string rootFile, Int_t runID, Int_t fitID, Int_t runNum, Int_t daq, Int_t pedRate, Int_t dataRate, Int_t chan, Int_t gate, Int_t pmt, Int_t base, Int_t hv, Int_t ll, Int_t filter, Int_t adc_range = 0, Int_t lowRangeThresh = 15, Int_t highRangeThresh = 15, Int_t constrainInj = 100, Int_t constrainGain = -1, Int_t constrainLL = -1, Int_t saveResults = 0, Int_t saveNN = 0, Int_t fitEngine = 0, Int_t noExpo = 0, Int_t randomChanges = 0){

	// Make a random number for shifting the signal and light initial guess
        Float_t dSig, dLL;
        TRandom* rand = new TRandom(fitID);
        dSig = rand->Rndm();
        dLL = rand->Rndm();
printf("sig: %.4f, LL: %.4f\n", dSig, dLL);
        if (rand->Rndm() > 0.5) dSig = dSig * -1;
        if (rand->Rndm() > 0.5) dLL = dLL * -1;
printf("sig: %.4f, LL: %.4f\n", dSig, dLL);
	if (randomChanges > constrainGain)
        	dSig = dSig * (float)(constrainGain) * 0.01;
	else
        	dSig = dSig * (float)(randomChanges) * 0.01;
	if (randomChanges > constrainLL)
        	dLL = dLL * (float)(constrainLL) * 0.01;
	else
        	dLL = dLL * (float)(randomChanges) * 0.01;
printf("sig: %.4f, LL: %.4f\n", dSig, dLL);

	// Define "off" value
	Double_t off = -1.0;

	// w - probability of type II background
	Double_t w0 		= 0.4;
	Double_t wmin 		= 0.0;
	Double_t wmax 		= 1.0;
	// If we are not considering exponential, set these to zero
	if (noExpo == 1) {
		w0 = 0.0;
		wmin = w0;
		wmax = w0;
	}

	// ped - mean of pedestal
	Double_t ped0 		= fit_pedestal(rootFile, adc_range);
	Double_t pedmin 	= off;
	Double_t pedmax 	= off;

	// pedrms - rms of pedestal
	Double_t pedrms0 	= fit_pedestal(rootFile, adc_range, 2);
	Double_t pedrmsmin 	= off;
	Double_t pedrmsmax 	= off;

	// alpha - exponential decay rate
	Double_t alpha0 	= 0.02;
	Double_t alphamin 	= 0.001;
	Double_t alphamax 	= 0.999;
	// If we are not considering exponential, set these to zero
	if (noExpo == 1) {
		alpha0 = 0.0;
		alphamin = alpha0;
		alphamax = alpha0;
	}

	// mu - average # of PE's per event
	Double_t mu0 = getMuFromLL(pmt, ll);
	if (randomChanges > 0) mu0 = mu0 * (1 + dLL);
	// Adjust values based on filter setting
	mu0 = mu0 * getTransparencyFromFilter(filter);
	Double_t mumin = off;
	Double_t mumax = off;
	// If constraining the light level
	if (constrainLL >= 0) {
		// Set mumin and max based on constraint
		mumin = mu0 * (1.0 - double(constrainLL) * 0.01);
		if (mumin < 0.0) mumin = 0.0;
		mumax = mu0 * (1.0 + double(constrainLL) * 0.01);
	}

	// sig - Grab the predefined "good guess" for this parameter from file.
	Double_t sig0 		= getSignalFromHV(pmt, hv);
	if (randomChanges > 0) sig0 = sig0 * (1 + dSig);
	// If user sent in initial gain value, use it
	Double_t sigmin		= off;
	Double_t sigmax 	= off;

	// If we are constraining the gain
	if (constrainGain >= 0) {
		// Set the gain bounds based on high voltage setting.
		sigmin = sig0 * (1.0 - double(constrainGain) * 0.01);
		if (sigmin < 0.0) sigmin = 0.0;
		sigmax = sig0 * (1.0 + double(constrainGain) * 0.01);
	}
	// sigrms - rms of signal
	Double_t sigrms0 	= getSignalRmsFromHV(pmt, hv);
	Double_t sigrmsmin 	= off;
	Double_t sigrmsmax 	= off;
	// inj - proportion of data that are injected pedestal
	Double_t inj0 		= 0.5;
	Double_t injmin		= 0.0;
	Double_t injmax		= 1.0;
	// real - proportion of data that are real events
	Double_t real0 		= 0.5;
	Double_t realmin 	= 0.0;
	Double_t realmax 	= 1.0;

	// If we are constraining the pedestal injection, then enforce it here
	if (constrainInj >= 0) {
		// Calculate injection proportion from data and ped rates
		if (pedRate == 0 && dataRate == 0) inj0 = 0.0;
		else inj0 = (double)(pedRate) / (double)(pedRate + dataRate);
		// Set min and max to initial value to constrain
		injmin = inj0 * (1.0 - double(constrainInj) * 0.01); 
		if (injmin < 0.0) injmin = 0.0;
		injmax = inj0 * (1.0 + double(constrainInj) * 0.01); 
		// Set the real rate to the compliment
		real0 = 1.0 - inj0;
		realmin = real0 * (1.0 - double(constrainInj) * 0.01); 
		if (realmin < 0.0) realmin = 0.0;
		realmax = real0 * (1.0 + double(constrainInj) * 0.01); 
	}

	// Decide which PE peaks to consider 
	int tempMinPE = 1, tempMaxPE = 25;
	if (mu0 > 50.0) {
		tempMinPE = (int)(mu0 - 2.0 * sqrt(mu0));
		tempMaxPE = (int)(mu0 + 4.5 * sqrt(mu0));
	} else if (mu0 > 10.0) {
		tempMinPE = (int)(mu0 - 4.0 * sqrt(mu0));
		tempMaxPE = (int)(mu0 + 7.0 * sqrt(mu0));
	}
	if (tempMinPE < 1) tempMinPE = 1;
	const int minPE = tempMinPE;
	const int maxPE = tempMaxPE;

	// Call the function with the appropriate params
	return fit_pmt(
		rootFile, runID, fitID, runNum, daq, chan, pmt, // 7 params
		dataRate, pedRate, hv, ll, filter, adc_range,	// 6 params
		constrainGain, constrainLL, constrainInj, 	// 3 params
		noExpo, randomChanges,				// 2 params
		saveResults, saveNN, fitEngine, lowRangeThresh, // 4 params
		highRangeThresh, minPE, maxPE,			// 3 params
		w0, ped0, pedrms0, alpha0, mu0, 		// 5 params
		sig0, sigrms0, inj0, real0,			// 4 params
		wmin, pedmin, pedrmsmin, alphamin, mumin, 	// 5 params
		sigmin, sigrmsmin, injmin, realmin,		// 4 params
		wmax, pedmax, pedrmsmax, alphamax, mumax, 	// 5 params
		sigmax, sigrmsmax, injmax, realmax		// 4 params
	);							// 52 params
}


