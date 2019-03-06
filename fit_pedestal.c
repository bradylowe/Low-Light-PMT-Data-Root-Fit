
#include <TTree.h>
#include <TROOT.h>
#include <TMath.h>
#include <TChain.h>
#include <TH1F.h>
#include <TF1.h>
#include <TTimeStamp.h>
#include <fstream>

#include "Math/SpecFunc.h"

#include <TMinuit.h>
#include <TApplication.h>
#include <TCanvas.h>
#include <TStyle.h>
#include <TAxis.h>
#include <TLine.h>


double fit_pedestal(string rootFile, Int_t scale = 0, Int_t choice = 1) {

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

	// Open root file
	TFile *file = new TFile(rootFile.c_str());
	if (file->IsZombie()) {
		printf("Error opening %s\n", rootFile.c_str());
		return -1.0;
	}

	// Define tree, leaf, branch
	TTree *tree = (TTree *) file->Get("ntuple");
	//TTree *tree = (TTree *) file->Get("T");
	TLeaf *leaf;
	if (scale == 0) {leaf = tree->GetLeaf(Form("ADC%dl", 12));}
	else {leaf = tree->GetLeaf(Form("ADC%dh", 12));}
	//leaf = tree->GetLeaf(Form("sbs.sbuscint.hadc%d", 2));
	TBranch *branch = leaf->GetBranch();

	// Fill raw data histogram
	for (Int_t entry = 0; entry < branch->GetEntries(); entry++) {
		branch->GetEntry(entry);
		rawData->Fill(leaf->GetValue());
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
	Double_t rawEnd = rawData->FindLastBinAbove(10);

	// Find a low point between the signal and pedestal
	Int_t pedPeak = pedBegin;
	Double_t value;
	Double_t lastValue = rawData->GetBinContent(pedBegin - 1);
	// Start at the pedestal and work to the right, find the pedestal peak
	for (int ii = pedBegin; ii < rawEnd; ii++) {
		value = rawData->GetBinContent(ii);
		if (value < lastValue) break;
		pedPeak = ii;
		lastValue = value;
	}
	// Now, start at the pedestal peak and find the low point (or first empty bin)
	for (int ii = pedPeak; ii < rawEnd; ii++) {
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
	// Name parameters
	fit_ped->SetParName(0, "amplitude");
	fit_ped->SetParName(1, "mean");
	fit_ped->SetParName(2, "rms");
	// Initialize parameters
	fit_ped->SetParameter(0, pedestal->GetMaximum());
	fit_ped->SetParameter(1, pedestal->GetMean());
	fit_ped->SetParameter(2, pedestal->GetRMS());
	// Perform gaussian fit to pedestal
	pedestal->Fit(fit_ped, "RSON", "");
	
	// Grab pedestal mean
	return fit_ped->GetParameter(choice);
}
