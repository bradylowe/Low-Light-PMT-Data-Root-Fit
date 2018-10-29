#include "fit_pmt.c"
using namespace std;

// Define filter transmittion vector for use later
Double_t filterMap[9] = {0.0, 0.001, 0.444, 0.592, 0.201, 0.771, 0.337, 1.0, 0.056};

// ADC factor (THERE IS A FACTOR OF 10^6 FLOATING AROUND INVISIBLY HERE)
Double_t gainToChannels = 160.2 / 25.0; // 160.2 femtoCoulombs per electron / 25.0 femtoCoulombs per channel = 6.408 chan / electron
Double_t channelsToGain = 25.0 / 160.2; // (25 fC / chan) / (160.2 fC / electron) = 0.15606 electron / chan

// This function is made for users or scripts to call. This function will take some input and call a much more complicated 
// function (fit_pmt.c) which is very ugly and nearly impossible to call by hand.
// All inputs into fit_pmt.c should be implemented in this function. This function should provide full
// functionality of fit_pmt.c while also allowing the user to diagnose and test values as well as record
// and keep track of previous fits to data files.
Int fit_pmt_wrapper(string rootFile, Int_t runID, Int_t fitID, Int_t runNum, Int_t daq, Int_t pedRate, Int_t dataRate, Int_t chan, Int_t pmt, Int_t base, Int_t hv, Int_t ll, Int_t filter, Int_t lowRangeThresh = 15, Int_t highRangeThresh = 15, Int_t constrainInj = 100, Int_t constrainGain = -1, Int_t constrainLL = -1, Int_t saveResults = 0, Int_t saveNN = 0, Int_t fitEngine = 0, Int_t noExpo = 0){

	///////////////////////////////////////////////////////////////////////////////////////////////////
	///// SET UP HARD-CODED VALUES PERTAINING TO PMTS AND LIGHT SOURCE
	//////////////////////////////////////////////////////////////////////
	// Define constants associated with PMTs
	const Int_t numPMTs = 4 + 1;
	const Int_t hvMapSize = 19;
	const Int_t llMapSize = 101;
	Double_t gainLevels[numPMTs][hvMapSize] = {0};  // Q0  @ (2000, 1900, 1800, 1700, 1600)
	Double_t lightLevels[numPMTs][llMapSize] = {0};
	Double_t hvMap[hvMapSize] = {2000, 1950, 1900, 1850, 1800, 1750, 1700, 1650, 1600, 1550, 1500, 1400, 1300, 1200, 1100, 1000, 900, 800, 700};
	// Setup PMT 1
	gainLevels[1][0] = 6.23;
	gainLevels[1][1] = 5.6;
	gainLevels[1][2] = 5.05;
	gainLevels[1][3] = 4.5;
	gainLevels[1][4] = 3.99;
	gainLevels[1][5] = 3.55;
	gainLevels[1][6] = 3.10;
	gainLevels[1][7] = 2.8;
	gainLevels[1][8] = 2.5;
	gainLevels[1][9] = 2.2;
	gainLevels[1][10] = 1.8;
	gainLevels[1][11] = 1.1;
	gainLevels[1][12] = 0.7;
	gainLevels[1][13] = 0.4;
	gainLevels[1][14] = 0.3;
	gainLevels[1][15] = 0.2;
	gainLevels[1][16] = 0.11;
	gainLevels[1][17] = 0.07;
	gainLevels[1][18] = 0.04;
	lightLevels[1][30] = 0.13;
	lightLevels[1][31] = 0.17;
	lightLevels[1][32] = 0.191;
	lightLevels[1][33] = 0.22;
	lightLevels[1][34] = 0.249;
	lightLevels[1][35] = 0.28;
	lightLevels[1][36] = 0.343;
	lightLevels[1][37] = 0.4;
	lightLevels[1][38] = 0.444;
	lightLevels[1][39] = 0.527;
	lightLevels[1][40] = 0.63;
	lightLevels[1][41] = 0.7;
	lightLevels[1][42] = 0.8;
	lightLevels[1][43] = 0.94;
	lightLevels[1][44] = 1.168;
	lightLevels[1][45] = 1.42;
	lightLevels[1][46] = 1.612;
	lightLevels[1][47] = 1.931;
	lightLevels[1][48] = 2.299;
	lightLevels[1][49] = 2.626;
	lightLevels[1][50] = 3.1;
	lightLevels[1][51] = 3.5;
	lightLevels[1][52] = 4.066;
	lightLevels[1][53] = 4.9;
	lightLevels[1][54] = 5.9;
	lightLevels[1][55] = 6.7;
	lightLevels[1][56] = 8.3;
	lightLevels[1][57] = 9.7;
	lightLevels[1][58] = 10.81;
	lightLevels[1][59] = 11.47;
	lightLevels[1][60] = 14.2;
	lightLevels[1][70] = 51.6;
	lightLevels[1][80] = 155.0;
	lightLevels[1][90] = 383.0;
	lightLevels[1][100] = 600.0;
	// Setup PMT 2
	gainLevels[2][0] = 6.1;
	gainLevels[2][1] = 5.6;
	gainLevels[2][2] = 5.1;
	gainLevels[2][3] = 4.5;
	gainLevels[2][4] = 3.9;
	gainLevels[2][5] = 3.3;
	gainLevels[2][6] = 2.7;
	gainLevels[2][7] = 2.1;
	gainLevels[2][8] = 1.5;
	gainLevels[2][9] = 0.9;
	gainLevels[2][10] = 0.5;
	gainLevels[2][11] = 0.3;
	gainLevels[2][12] = 0.2;
	gainLevels[2][13] = 0.15;
	gainLevels[2][14] = 0.13;
	gainLevels[2][15] = 0.12;
	gainLevels[2][16] = 0.11;
	gainLevels[2][17] = 0.10;
	gainLevels[2][18] = 0.09;
	lightLevels[2][30] = 0.138;
	lightLevels[2][31] = 0.17;
	lightLevels[2][32] = 0.191;
	lightLevels[2][33] = 0.22;
	lightLevels[2][34] = 0.249;
	lightLevels[2][35] = 0.30;
	lightLevels[2][36] = 0.343;
	lightLevels[2][37] = 0.4;
	lightLevels[2][38] = 0.444;
	lightLevels[2][39] = 0.527;
	lightLevels[2][40] = 0.64;
	lightLevels[2][41] = 0.7;
	lightLevels[2][42] = 0.8;
	lightLevels[2][43] = 0.94;
	lightLevels[2][44] = 1.168;
	lightLevels[2][45] = 1.3;
	lightLevels[2][46] = 1.612;
	lightLevels[2][47] = 1.931;
	lightLevels[2][48] = 2.219;
	lightLevels[2][49] = 2.626;
	lightLevels[2][50] = 3.0;
	lightLevels[2][51] = 3.5;
	lightLevels[2][52] = 4.066;
	lightLevels[2][53] = 0.64;
	lightLevels[2][54] = 0.645;
	lightLevels[2][55] = 0.64;
	lightLevels[2][56] = 0.645;
	lightLevels[2][57] = 0.64;
	lightLevels[2][58] = 10.29;
	lightLevels[2][59] = 11.47;
	lightLevels[2][60] = 14.61;
	lightLevels[2][70] = 65.0;
	lightLevels[2][80] = 200.0;
	// Setup PMT 3
	gainLevels[3][0] = 5.95;
	gainLevels[3][1] = 5.5;
	gainLevels[3][2] = 5.0;
	gainLevels[3][3] = 4.5;
	gainLevels[3][4] = 4.0;
	gainLevels[3][5] = 3.4;
	gainLevels[3][6] = 2.8;
	gainLevels[3][7] = 2.1;
	gainLevels[3][8] = 1.3;
	gainLevels[3][9] = 0.8;
	gainLevels[3][10] = 0.5;
	gainLevels[3][11] = 0.3;
	gainLevels[3][12] = 0.2;
	gainLevels[3][13] = 0.15;
	gainLevels[3][14] = 0.13;
	gainLevels[3][15] = 0.12;
	gainLevels[3][16] = 0.11;
	gainLevels[3][17] = 0.10;
	gainLevels[3][18] = 0.09;
	lightLevels[3][30] = 0.138;
	lightLevels[3][31] = 0.17;
	lightLevels[3][32] = 0.191;
	lightLevels[3][33] = 0.22;
	lightLevels[3][34] = 0.249;
	lightLevels[3][35] = 0.28;
	lightLevels[3][36] = 0.343;
	lightLevels[3][37] = 0.4;
	lightLevels[3][38] = 0.444;
	lightLevels[3][39] = 0.527;
	lightLevels[3][40] = 0.64;
	lightLevels[3][41] = 0.7;
	lightLevels[3][42] = 0.8;
	lightLevels[3][43] = 1.0;
	lightLevels[3][44] = 1.2;
	lightLevels[3][45] = 1.5;
	lightLevels[3][46] = 1.8;
	lightLevels[3][47] = 2.2;
	lightLevels[3][48] = 2.4;
	lightLevels[3][49] = 2.5;
	lightLevels[3][50] = 2.8;
	lightLevels[3][51] = 3.2;
	lightLevels[3][52] = 3.8;
	lightLevels[3][53] = 4.5;
	lightLevels[3][54] = 5.0;
	lightLevels[3][55] = 5.8;
	lightLevels[3][56] = 7.2;
	lightLevels[3][57] = 8.1;
	lightLevels[3][58] = 9.0;
	lightLevels[3][59] = 10.0;
	lightLevels[3][60] = 12.0;
	lightLevels[3][70] = 55.0;
	lightLevels[3][80] = 200.0;
	// Setup PMT 4
	gainLevels[4][0] = 4.0;
	gainLevels[4][1] = 3.7;
	gainLevels[4][2] = 3.3;
	gainLevels[4][3] = 2.9;
	gainLevels[4][4] = 2.6;
	gainLevels[4][5] = 2.2;
	gainLevels[4][6] = 1.8;
	gainLevels[4][7] = 1.4;
	gainLevels[4][8] = 1.0;
	gainLevels[4][9] = 0.6;
	gainLevels[4][10] = 0.5;
	gainLevels[4][11] = 0.3;
	gainLevels[4][12] = 0.2;
	gainLevels[4][13] = 0.15;
	gainLevels[4][14] = 0.13;
	gainLevels[4][15] = 0.12;
	gainLevels[4][16] = 0.11;
	gainLevels[4][17] = 0.10;
	gainLevels[4][18] = 0.09;
	lightLevels[4][30] = 0.138;
	lightLevels[4][31] = 0.17;
	lightLevels[4][32] = 0.191;
	lightLevels[4][33] = 0.22;
	lightLevels[4][34] = 0.249;
	lightLevels[4][35] = 0.30;
	lightLevels[4][36] = 0.343;
	lightLevels[4][37] = 0.4;
	lightLevels[4][38] = 0.444;
	lightLevels[4][39] = 0.527;
	lightLevels[4][40] = 0.64;
	lightLevels[4][41] = 0.7;
	lightLevels[4][42] = 0.8;
	lightLevels[4][43] = 0.94;
	lightLevels[4][44] = 1.0;
	lightLevels[4][45] = 1.14;
	lightLevels[4][46] = 1.38;
	lightLevels[4][47] = 1.64;
	lightLevels[4][48] = 1.88;
	lightLevels[4][49] = 2.20;
	lightLevels[4][50] = 2.56;
	lightLevels[4][51] = 2.87;
	lightLevels[4][52] = 3.85;
	lightLevels[4][53] = 3.96;
	lightLevels[4][54] = 4.65;
	lightLevels[4][55] = 5.46;
	lightLevels[4][56] = 6.5;
	lightLevels[4][57] = 8.0;
	lightLevels[4][58] = 9.5;
	lightLevels[4][59] = 11.5;
	lightLevels[4][60] = 13.5;
	lightLevels[4][70] = 50.0;
	lightLevels[4][80] = 100.0;

	///////////////////////////////////////////////////////////////////////////////////////////////////
	///////////////////////////////////////////////////////////////////////////////////////////////////

	// Define "off" value
	Double_t off = -1.0;

	// w - probability of type II background
	Double_t w0 		= 0.01;
	Double_t wmin 		= 0.0001;
	Double_t wmax 		= 1.0;
	// If we are not considering exponential, set these to zero
	if (noExpo == 1) {
		w0 = 0.0;
		wmin = w0;
		wmax = w0;
	}

	// ped - mean of pedestal
	Double_t ped0 		= getDataPedSig(rootFile, chan, "pedmean");
	Double_t pedmin 	= off;
	Double_t pedmax 	= off;

	// pedrms - rms of pedestal
	Double_t pedrms0 	= getDataPedSig(rootFile, chan, "pedrms");
	Double_t pedrmsmin 	= 0.0;
	Double_t pedrmsmax 	= 10.0;

	// alpha - exponential decay rate
	Double_t alpha0 	= 0.005;
	Double_t alphamin 	= 0.00001;
	Double_t alphamax 	= 1.0;
	// If we are not considering exponential, set these to zero
	if (noExpo == 1) {
		alpha0 = 0.0;
		alphamin = alpha0;
		alphamax = alpha0;
	}

	// mu - average # of PE's per event
	Double_t mu0 = lightLevels[pmt][ll];
	// Adjust values based on filter setting
	mu0 = mu0 * filterMap[filter];
	Double_t mumin = off;
	Double_t mumax = off;
	// If constraining the light level
	if (constrainLL >= 0) {
		// Set mumin and max based on constraint
		mumin = mu0 * (1.0 - double(constrainLL) * 0.01);
		if (mumin < 0.0) mumin = 0.0;
		mumax = mu0 * (1.0 + double(constrainLL) * 0.01);
	}

	// sig - ped. corrected mean of signal
	Double_t sig0 		= 4.0;
	// If user sent in initial gain value, use it
	if (g0 > 0.0) sig0	= g0 * gainToChannels;
	Double_t sigmin		= off;
	Double_t sigmax 	= off;

	// If we are constraining the gain
	if (constrainGain >= 0) {
		// Reverse-lookup defaults for this voltage 
		for (int b = 0; b < hvMapSize; b++) {
			if (hv >= hvMap[b]) {
				sig0 = gainLevels[pmt][b];
				break;
			}
		}
		// Set the gain bounds based on high voltage setting.
		sigmin = sig0 * (1.0 - double(constrainGain) * 0.01);
		if (sigmin < 0.0) sigmin = 0.0;
		sigmax = sig0 * (1.0 + double(constrainGain) * 0.01);
	}
	// sigrms - rms of signal
	Double_t sigrms0 	= 1.8;
	Double_t sigrmsmin 	= 0.0;
	Double_t sigrmsmax 	= 2.5;
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
	int tempMinPE = 1, tempMaxPE = 20;
	if (mu0 > 10.0) {
		tempMinPE = (int)(mu0 - 2.0 * sqrt(mu0));
		tempMaxPE = (int)(mu0 - 2.0 * sqrt(mu0));
	}
	const int minPE = tempMinPE;
	const int maxPE = tempMaxPE;

	// Call the function with the appropriate params
	return fit_pmt(
		rootFile, runID, fitID, runNum, daq, chan, pmt, // 7 params
		dataRate, pedRate, hv, ll, filter,		// 5 params
		constrainGain, constrainLL, constrainInj, noExpo,// 4 params
		saveResults, saveNN, fitEngine, lowRangeThresh, // 4 params
		highRangeThresh, minPE, maxPE,			// 3 params
		w0, ped0, pedrms0, alpha0, mu0, 		// 5 params
		sig0, sigrms0, inj0, real0,			// 4 params
		wmin, pedmin, pedrmsmin, alphamin, mumin, 	// 5 params
		sigmin, sigrmsmin, injmin, realmin,		// 4 params
		wmax, pedmax, pedrmsmax, alphamax, mumax, 	// 5 params
		sigmax, sigrmsmax, injmax, realmax		// 4 params
	);							// 48 params
}


