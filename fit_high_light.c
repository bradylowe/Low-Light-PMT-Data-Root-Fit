
#include <TTree.h>
#include <TROOT.h>
#include <TMath.h>
#include <TChain.h>
#include <TH1F.h>
#include <TF1.h>
#include <TTimeStamp.h>
#include <fstream>

#include "Math/SpecFunc.h"
#include "dataAnalyzer.c"

#include <TMinuit.h>
#include <TApplication.h>
#include <TCanvas.h>
#include <TStyle.h>
#include <TAxis.h>
#include <TLine.h>


// gaussian plus expo decay tail to the right
double sig_fit(Double_t *x, Double_t *par) {
	Double_t ret = par[3] / 2.0;
	Double_t arg = 2.0 * par[1] + par[3] * TMath::Power(par[2], 2) - 2.0 * x[0];
	ret *= TMath::Exp(par[3] / 2.0 * arg);
	arg = par[1] + par[3] * TMath::Power(par[2], 2) - x[0];
	arg = arg / (TMath::Sqrt(2.0) * par[2]);
	ret *= TMath::Erfc(arg);
	return par[0] * ret;
}

double fit_high_light(string rootFile, Int_t runID = 0, Int_t fitID = 0, Int_t savePNG = 0, Int_t range = 0) {

	// Make output png filename
	string pngFile = Form("high_light_%d.png", fitID);

	// Define canvas
	gStyle->SetOptFit(11111111);
	TGaxis::SetMaxDigits(2);
	TCanvas* canvas = new TCanvas("canvas", "canvas", 1618, 618);
	canvas->Divide(3);
	canvas->cd(1);
	
	// Initialize histograms
	Int_t binWidth = 1;
	Int_t bins = int(4096 / binWidth + 1.);
	Float_t minR = int(0 - binWidth / 2.);
	Float_t maxR = int(4096 + binWidth / 2.);
	TH1F* rawData = new TH1F("rawData", "", bins,minR,maxR);
	TH1F* pedestal = new TH1F("pedestal", "", bins,minR,maxR);
	TH1F* signal = new TH1F("signal", "", bins,minR,maxR);

	// Open root file
	TFile *file = new TFile(rootFile.c_str());
	if (file->IsZombie()) {
		printf("Error opening %s\n", rootFile.c_str());
		return -1.0;
	}

	// Define tree, leaf, branch
	TTree *tree = (TTree *) file->Get("ntuple");
	TLeaf *leaf;
	if (scale == 0) {leaf = tree->GetLeaf(Form("ADC%dl", 12));}
	else {leaf = tree->GetLeaf(Form("ADC%dh", 12));}
	TBranch *branch = leaf->GetBranch();

	// Fill raw data histogram
	for (Int_t entry = 0; entry < branch->GetEntries(); entry++) {
		branch->GetEntry(entry);
		rawData->Fill(leaf->GetValue());
	}
	
	if (rawData->GetMaximumBin() > 4093) {
		// If we go off low range, reload with high range
		if (range == 0) return fit_high_light(rootFile, runID, fitID, savePNG, 1); 
		// If we go off high range, return -2 error.
		else return -2.0;
	}

	// Grab a few statistics from the raw data
	Int_t nevents = rawData->GetEntries();
	Int_t maxVal = rawData->GetMaximum();
	Int_t low = rawData->FindFirstBinAbove(1) - 15;
	Int_t high = rawData->FindLastBinAbove(1) + 15;
	if (low < 0) low = 0;
	if (high > 4095) high = 4095;
	rawData->GetXaxis()->SetRangeUser(low, high);
	Double_t pedBegin = rawData->FindFirstBinAbove(10);
	Double_t pedEnd = rawData->FindLastBinAbove(10);
	Double_t sigEnd = pedEnd;

	// Find a low point between the signal and pedestal
	Int_t pedPeak = pedBegin;
	Double_t value;
	Double_t lastValue = rawData->GetBinContent(pedBegin - 1);
	// Start at the pedestal and work to the right, find the pedestal peak
	for (int ii = pedBegin; ii < sigEnd; ii++) {
		value = rawData->GetBinContent(ii);
		if (value < lastValue) break;
		pedPeak = ii;
		lastValue = value;
	}
	// Now, start at the pedestal peak and find the low point (or first empty bin)
	for (int ii = pedPeak; ii < sigEnd; ii++) {
		value = rawData->GetBinContent(ii);
		if (value > lastValue) break;
		pedEnd = ii;
		lastValue = value;
		if (value < 0.5) break;
	}

	// Create histogram that only contains pedestal
	for (Int_t entry = 0; entry < branch->GetEntries(); entry++) {
		branch->GetEntry(entry);
		value = leaf->GetValue();
		if (value < pedEnd) pedestal->Fill(value);
	}
	// Update range of histogram now that it is filled
	low = pedestal->FindFirstBinAbove(1);
	high = pedestal->FindLastBinAbove(1);
	pedestal->GetXaxis()->SetRangeUser(low, high);

	// Make pedestal fit
	TF1 *fit_ped = new TF1("fit_ped", "gaus", low, high);
	// Customize fit
	fit_ped->SetLineColor(7);
	// Name parameters
	fit_ped->SetParName(0, "amplitude");
	fit_ped->SetParName(1, "mean");
	fit_ped->SetParName(2, "rms");
	// Initialize parameters
	fit_ped->SetParameter(0, pedestal->GetMaximum());
	fit_ped->SetParameter(1, pedestal->GetMean());
	fit_ped->SetParameter(2, pedestal->GetRMS());
	// Perform gaussian fit to pedestal
	pedestal->Fit(fit_ped, "RS", "");
	// Grab pedestal mean
	Double_t pedMean = fit_ped->GetParameter(1);

	// Create histogram that only contains signal
	for (Int_t entry = 0; entry < branch->GetEntries(); entry++) {
		branch->GetEntry(entry);
		value = leaf->GetValue();
		if (value >= pedEnd) signal->Fill(value);
	}

	// Update range of histogram now that it is filled
	low = signal->FindFirstBinAbove(signal->GetMaximum() / 100);
	high = signal->FindLastBinAbove(signal->GetMaximum() / 100);
	signal->GetXaxis()->SetRangeUser(low, high);

	// Make signal fit
	TF1 *fit_sig = new TF1("fit_sig", sig_fit, low, high, 4);
	// Customize fit
	fit_sig->SetLineColor(2);
	// Name parameters
	fit_sig->SetParName(0, "amplitude");
	fit_sig->SetParName(1, "mean");
	fit_sig->SetParName(2, "rms");
	fit_sig->SetParName(3, "lambda");
	// Initialize parameters
	fit_sig->SetParameter(0, signal->GetMaximum());
	fit_sig->SetParameter(1, signal->GetMean());
	fit_sig->SetParameter(2, signal->GetRMS());
	fit_sig->SetParameter(3, 0.01);
	// Set parameter limits
	fit_sig->SetParLimits(2, fit_ped->GetParameter(2), 200.0);

	// Fit to signal
	signal->Fit(fit_sig, "RS", "");

	// Draw raw data
	canvas->cd(1);
	rawData->Draw();
	// Draw pedestal and fit	
	canvas->cd(2);
	pedestal->Draw();
	fit_ped->Draw("same");
	// Draw fit
	canvas->cd(3);
	signal->Draw();	
	fit_sig->Draw("same");
	// Cut off path to file from filename
	Int_t cut = rootFile.find("/daq") + 1;
	cut = rootFile.find("/r") + 1;
	rootFile = rootFile.substr(cut);
	canvas->Update();
	canvas->Print(pngFile.c_str());

	// Grab parameters
	Double_t ped = fit_ped->GetParameter(1);
	Double_t pedrms = fit_ped->GetParameter(2);
	Double_t pederr = fit_ped->GetParError(1);
	Double_t pedrmserr = fit_ped->GetParError(2);
	Double_t sig = fit_sig->GetParameter(1) - ped;
	Double_t sigrms = fit_sig->GetParameter(2);
	Double_t sigerr = fit_sig->GetParError(1);
	Double_t sigrmserr = fit_sig->GetParError(2);
	Double_t alpha = fit_sig->GetParameter(3);
	Double_t alphaerr = fit_sig->GetParError(3);
	if (scale == 1) {
		ped *= 8.00;
		pedrms *= 8.00;
		pederr *= 8.00;
		pedrmserr *= 8.00;
		sig *= 8.00;
		sigrms *= 8.00;
		sigerr *= 8.00;
		sigrmserr *= 8.00;
	}
	Int_t chi = (int)(fit_sig->GetChisquare() / fit_sig->GetNDF());
	// Create SQL query for storing all the output of this run in the gaindb
	ofstream sqlfile;
	char queryLine[2048];
	sprintf(queryLine,
		"run_id='%d',ped_out='%.8f',ped_rms_out='%.8f',ped_out_error='%.8f',ped_rms_out_error='%.8f',sig_out='%.8f',sig_rms_out='%.8f',sig_out_error='%.8f',sig_rms_out_error='%.8f',alpha_out='%.8f',alpha_out_error='%.8f',scale='%d',chi='%d',png_file='%s'",
		runID, 
		ped, pedrms, pederr, pedrmserr,
		sig, sigrms, sigerr, sigrmserr,
		alpha, alphaerr, 
		scale, chi, pngFile.c_str()
	);
	sqlfile.open(Form("sql_output_high_light_%d.csv", fitID), std::ofstream::out);
	if (sqlfile.is_open()) {
		sqlfile << queryLine << endl;
		sqlfile.close();
	} else printf("\nUnable to output the following to SQL file:\n%s\n", queryLine);
	
	// Return signal mean
	return sig;

}
