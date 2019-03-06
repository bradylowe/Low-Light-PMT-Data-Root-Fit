// Brady Lowe // lowebra2@isu.edu

#include <TFile.h>
#include <TDirectory.h>
#include <TTree.h>
#include <TROOT.h>
#include <TMath.h>
#include <TChain.h>
#include <TH1F.h>
#include <TF1.h>

#include "Math/SpecFunc.h"
#include "fit_pmt_functions.c"

#include <TMinuit.h>
#include <TApplication.h>
#include <TCanvas.h>
#include <TStyle.h>
#include <TAxis.h>
#include <TLine.h>


// FIT A DATA RUN TO FIND THE CONTRIBUTING INDIVIDUAL 
// PHOTO-ELECTRON (PE) DISTRIBUTION [FOR LOW LIGHT LEVEL
// PMT DATA]
//
// Take in a large number of extra parameters to have an algorithm that
// is callable and fully capable, and yet able to remain hard-coded for
// a long period of time.
int fit_showermax(
	// In gaindb.run_params mysql table
	string rootFile, 	// File name (something.root)
	Int_t chan, 		// Which ADC channel (0 - 15)
	Int_t adc_range,	// Look at high-range of ADC
	Int_t binWidth, 	// granularity of histogram
	Int_t hv,		// Which hv on the pmt
	Double_t sigPE,		// adc channels of 1-PE signal
	string detector,	// Which detector were we using
	Double_t energy, 	// Beam energy of this run
	// The next 2 parameters are the min and max PE peak to consider
	const int minPE, 	// Lowest #PEs to consider in fit
	const int maxPE, 	// Highest #PEs to consider in fit
	//^^ Add const minPe, maxPe
	// The next 9 parameters are initial conditions.
	Double_t w0, 		Double_t ped0,		Double_t pedrms0, 
	Double_t alpha0,	Double_t mu0,		Double_t sig0, 
	Double_t sigrms0,	Double_t inj0,		Double_t real0,
	// Below are the lower bounds to all 9 parameters
	Double_t wmin, 		Double_t pedmin,	Double_t pedrmsmin, 
	Double_t alphamin, 	Double_t mumin,		Double_t sigmin, 
	Double_t sigrmsmin, 	Double_t injmin,	Double_t realmin,
	// Below are the upper bounds to all 9 parameters
	Double_t wmax, 		Double_t pedmax,	Double_t pedrmsmax, 
	Double_t alphamax, 	Double_t mumax,		Double_t sigmax, 
	Double_t sigrmsmax, 	Double_t injmax,	Double_t realmax
){

	printf("\nEntering fit_showermax.c\n");

	// Define constants
	const Int_t N_FIT_PARAMS = 11;
        const Int_t MAX_BIN = 4096;

	// Check pe bound setup
	const int nPE = maxPE - minPE + 1;
	if ( minPE < 1 || nPE < 0 ) {
		printf("ERROR\n");
		return -4;
	} 
	Float_t MIN_PE = (float)(minPE);
	Float_t MAX_PE = (float)(maxPE);

	// Pack parameters into nice arrays
	// First vector is initial conditions, next two vectors are min and max
	// We must pass in MIN and MAX_PE through the parameters to get them into the fit.
	// We set MIN_PE minimum bound = maximum bound so the parameter is constrained.
	// We also constrain MAX_PE the same way.
	Double_t initial[N_FIT_PARAMS] = {w0, ped0, pedrms0, alpha0, mu0, sig0, sigrms0, inj0, real0, MIN_PE, MAX_PE};
	Double_t min[N_FIT_PARAMS] = {wmin, pedmin, pedrmsmin, alphamin, mumin, sigmin, sigrmsmin, injmin, realmin, MIN_PE, MAX_PE};
	Double_t max[N_FIT_PARAMS] = {wmax, pedmax, pedrmsmax, alphamax, mumax, sigmax, sigrmsmax, injmax, realmax, MIN_PE, MAX_PE};

        // Open .root data file
        printf("Opening file %s\n", rootFile.c_str());
        TFile* f1 = new TFile(rootFile.c_str());
        if ( f1->IsZombie() ) {
                printf("ERROR ==> Couldn't open file %s\n", rootFile.c_str());
                return -5;
        }

	// Define info file for use later 
	string infoFile = rootFile.substr(0, rootFile.length() - 5);
	infoFile.append(".info");

        // Extract data from file, read into memory
        TTree* t1 = (TTree*) f1->Get("T");
        if (t1 == NULL) {
                printf("ERROR ==> Couldn't find \"T\"\n");
                return -6;
        }

        // Get number of events
        Int_t nentries = (Int_t) t1->GetEntries();
        printf("Number of entries:  %d\n", nentries);

	// Define which channel and what data to grab
        char chanStr[32];
        char selection[64];
	sprintf(chanStr, "sbs.sbuscint.ladc%d", chan);
	if ( adc_range == 1) {
		sprintf(chanStr, "sbs.sbuscint.hadc%d", chan);
	}
        sprintf(selection, "%s>2&&%s<%d", chanStr, chanStr, MAX_BIN);

        // Create leaf and branch from tree
        TLeaf* l1 = t1->GetLeaf(chanStr);
        TBranch* b1 = l1->GetBranch();

        // Initialize histogram
        Int_t bins = MAX_BIN / binWidth + 1;
        Float_t minR = -0.5 * (Float_t) binWidth;
        Float_t maxR = MAX_BIN + 0.5 * (Float_t) binWidth;
        TH1F *h_QDC = new TH1F("h_QDC", "QDC spectrum", bins, minR, maxR);

        // Fill histogram
        for (Int_t entry = 0; entry < b1->GetEntries(); entry++) {
                b1->GetEntry(entry);
                h_QDC->Fill(l1->GetValue());
        }

	// Grab fit bounds from user-defined thresholds
	//  - lowest bin will have at least lowRangeThresh items in it.
	Int_t low = h_QDC->FindFirstBinAbove(2) * binWidth - 20;
	Int_t high = h_QDC->FindLastBinAbove(2) * binWidth + 20;
	//Int_t low = 800;
	//Int_t high = 2500;
	printf("low, high: %d, %d\n", low, high);
	
	// If we are overflowing, just don't even run the fit
	if (high >= 4095) return -3.0; 

        // Normalize integral of histogram to 1 (same scaling for error bar)
        Int_t sum = h_QDC->GetSum();
        for (Int_t curBin = 0; curBin < bins; curBin++) {
		Float_t curVal = h_QDC->GetBinContent(curBin); 
                h_QDC->SetBinContent(curBin, curVal / sum);
                h_QDC->SetBinError(curBin, sqrt(curVal) / sum);
        }

	// Define fitting function
	TF1 *fit_func=new TF1("fit_func", low_light_model, 0, MAX_BIN,N_FIT_PARAMS); 
	
	fit_func->SetLineColor(4); // Dark blue
	fit_func->SetNpx(2000);
	fit_func->SetLineWidth(2);
	// 11 parameters
	fit_func->SetParName(0, "W");
	fit_func->SetParName(1, "Q0");
	fit_func->SetParName(2, "S0");
	fit_func->SetParName(3, "alpha");
	fit_func->SetParName(4, "mu");
	fit_func->SetParName(5, "Q1");
	fit_func->SetParName(6, "S1");
	fit_func->SetParName(7, "inj");
	fit_func->SetParName(8, "real");
	fit_func->SetParName(9, "MIN_PE");
	fit_func->SetParName(10, "MAX_PE");

	// Set initial parameters
	fit_func->SetParameters(initial);

	// Constrain the parameters that need to be constrained
	for (int i = 0; i < N_FIT_PARAMS; i++) {
		// Check if there is restraint on this param
		if (min[i] >= 0.0 && max[i] >= 0.0) {
			// Check if param needs to be fixed
			if (min[i] == max[i]) fit_func->FixParameter(i, initial[i]);
			// Otherwise, just bound the param
			else fit_func->SetParLimits(i, min[i], max[i]);
		}
	}

	// Fit to pedestal
	TF1 *fit_gaus_ped = new TF1("fit_gaus_ped", "gaus", initial[1] - initial[2], initial[1] + initial[2]);
	h_QDC->Fit(fit_gaus_ped, "RN", "");

	// Setup histogram for printing
        h_QDC->GetXaxis()->SetTitle("ADC channels");
        h_QDC->GetYaxis()->SetTitle("Counts (integral normalized)");
        h_QDC->SetTitle("Low-light PE fit");
	h_QDC->SetLineColor(1);
	h_QDC->SetMarkerSize(0.7);
	h_QDC->SetMarkerStyle(20);
	h_QDC->GetXaxis()->SetTitle("QDC channel");
	h_QDC->GetYaxis()->SetTitle("Normalized yield");
	h_QDC->GetXaxis()->SetRangeUser(low, high);
	
	// Create canvas and draw histogram
	TCanvas *can = new TCanvas("can","can");
	can->cd();
	gStyle->SetOptFit(1);
	TGaxis::SetMaxDigits(3);
	h_QDC->Draw("same");

	// Define results pointer
	TFitResultPtr res;
	if (true) res = h_QDC->Fit(fit_func, "LRS", "", low, high);
	else res = h_QDC->Fit(fit_func, "RS", "", low, high);

	// Create vector and grab return parameters
	Double_t back[N_FIT_PARAMS];
	fit_func->GetParameters(back);

	// Make signal distribution functions for showing deconvolution in image
	TF1 *fis_from_fit_pe[nPE];
	// Make one for each PE contribution considered
	for ( int bb = minPE; bb < maxPE; bb++) {
		// Set current PE peak in consideration
		fit_func->GetParameters(back);
		back[9] = (double)(bb);
        	fis_from_fit_pe[bb] = new TF1(Form("pe_fit_%d", bb), low_light_model_pe, 0, MAX_BIN, N_FIT_PARAMS);
        	fis_from_fit_pe[bb]->SetParameters(back);
        	fis_from_fit_pe[bb]->SetLineStyle(2);
		fis_from_fit_pe[bb]->SetLineColor(2);
		fis_from_fit_pe[bb]->SetNpx(2000);
		fis_from_fit_pe[bb]->Draw("same");
	}

	// Make background distribution function for printing for user
	TF1 *fis_from_fit_bg = new TF1("fis_from_fit_bg", low_light_model_bg, 0, MAX_BIN, N_FIT_PARAMS);
	fis_from_fit_bg->SetParameters(back);
        fis_from_fit_bg->SetLineStyle(2);
        fis_from_fit_bg->SetLineColor(7); // Cyan
        fis_from_fit_bg->SetNpx(2000);
	fis_from_fit_bg->Draw("same");

////////////////////////////////////////////////////////////
/////////////	DONE FITTING	////////////////////////////
////////////////////////////////////////////////////////////
	printf("\nDone fitting. \n\n");

	// Grab some stats info from the fit
	Double_t chi = fit_func->GetChisquare();
	Int_t ndf = fit_func->GetNDF();
	Int_t nfitpoints = fit_func->GetNumberFitPoints();

	// Get output values
	Double_t wout = back[0];
	Double_t pedout = back[1];
	Double_t pedrmsout = back[2];
	Double_t alphaout = back[3];
	Double_t muout = back[4];
	Double_t sigout = back[5];
	Double_t sigrmsout = back[6];
	Double_t injout = back[7];
	Double_t realout = back[8];
	Double_t wouterr = fit_func->GetParError(0);
	Double_t pedouterr = fit_func->GetParError(1);
	Double_t pedrmsouterr = fit_func->GetParError(2);
	Double_t alphaouterr = fit_func->GetParError(3);
	Double_t muouterr = fit_func->GetParError(4);
	Double_t sigouterr = fit_func->GetParError(5);
	Double_t sigrmsouterr = fit_func->GetParError(6);
	Double_t injouterr = fit_func->GetParError(7);
	Double_t realouterr = fit_func->GetParError(8);

	// CALCULATE PMT GAIN USING AMPLIFICATION SETTING AND ADC CONVERSION FACTOR
	Double_t gain = sigout * 200.0 / 160.217662;
	Double_t gainError = gainError = sigouterr * 200.0 / 160.217662;
	Double_t chiPerNDF = (double)(chi / ndf);
	if (chiPerNDF > 1.0) {
		gainError = gainError * sqrt(chiPerNDF);
	}
	Double_t gainPercentError = gainError / gain * 100.0;
	printf("Run: %s\n", rootFile.c_str());
	printf("HV:  %d\n", hv);
	printf("Detector:  %s\n", detector.c_str());
	printf("Energy:  %.1f\n", energy);
	printf("Ped: %.5f +/- %.5f\n", pedout, pedrmsout);
	printf("Sig: %.5f +/- %.5f\n", sigout, sigrmsout);
	printf("Resolution: %.5f\n", sigrmsout / sigout);
	printf("PE's per electron: %.5f\n", sigout * 8.00 / sigPE);
	can->Update();


	if (chiPerNDF < 0.0) chiPerNDF = -1.0;
	return (int)(chiPerNDF);
}


