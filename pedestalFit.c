
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



Double_t triple_gaus(Double_t *x, Double_t *par) {
	Double_t gaus1 = par[0] * exp( - pow((x[0] - par[1]) / par[2], 2) / 2);
	Double_t gaus2 = par[3] * exp( - pow((x[0] - par[4]) / par[5], 2) / 2);
	Double_t gaus3 = par[6] * exp( - pow((x[0] - par[7]) / par[8], 2) / 2);
	return gaus1 + gaus2 + gaus3;
}

void pedestalFit(string rootFile, Int_t qCh = 11, Int_t savePNG = 0) {

	// Define canvas
	gStyle->SetOptFit(11111111);
	TGaxis::SetMaxDigits(2);
	TCanvas* canvas = new TCanvas("canvas", "canvas", 1000, 618);
	canvas->cd();
	canvas->SetLogy();
	
	// Initialize histograms
	Int_t binWidth = 1;
	Int_t bins = int(4096 / binWidth + 1.);
	Float_t minR = int(0 - binWidth / 2.);
	Float_t maxR = int(4096 + binWidth / 2.);
	TH1F* rawData = new TH1F("rawData", "", bins,minR,maxR);

	// Open root file
	TFile *file = new TFile(rootFile.c_str());
	if (file->IsZombie()) {
		printf("Error opening %s\n", rootFile.c_str());
		return;
	}

	// Define tree, leaf, branch
	TTree *tree = (TTree *) file->Get("ntuple");
	TLeaf *leaf = tree->GetLeaf(Form("ADC%dl", qCh));
	TBranch *branch = leaf->GetBranch();

	// Fill raw data histogram
	for (Int_t entry = 0; entry < branch->GetEntries(); entry++) {
		branch->GetEntry(entry);
		rawData->Fill(leaf->GetValue());
	}

	// Find out where to set the bounds and do it
	Int_t maxBin = rawData->GetMaximumBin();
	Int_t low = rawData->FindFirstBinAbove(1) - 5;
	Int_t high = rawData->FindLastBinAbove(1) + 15;
	Double_t rawRMS = rawData->GetRMS();
	Double_t integral = rawData->Integral(low, high);
	rawData->GetXaxis()->SetRangeUser(low, high);

	// Get info about data
	Double_t amp = rawData->GetMaximum();
	Double_t mean = rawData->GetMean();
	Double_t rms = rawData->GetRMS();


	// Make triple gaussian fit
	TF1 *fit_gaus3 = new TF1("fit_gaus3", triple_gaus, low, high, 9);
	// Customize fit
	fit_gaus3->SetLineColor(4);
	// Name parameters
	fit_gaus3->SetParName(0, "amp0");
	fit_gaus3->SetParName(1, "mean0");
	fit_gaus3->SetParName(2, "rms0");
	fit_gaus3->SetParName(3, "amp1");
	fit_gaus3->SetParName(4, "mean1");
	fit_gaus3->SetParName(5, "rms1");
	fit_gaus3->SetParName(6, "amp2");
	fit_gaus3->SetParName(7, "mean2");
	fit_gaus3->SetParName(8, "rms2");
	// Initialize parameters
	fit_gaus3->SetParameter(0, amp / 100);
	fit_gaus3->SetParameter(1, mean - 2 * rms);
	fit_gaus3->SetParameter(2, rms);
	fit_gaus3->SetParameter(3, amp);
	fit_gaus3->SetParameter(4, mean);
	fit_gaus3->SetParameter(5, rms);
	fit_gaus3->SetParameter(6, amp / 50);
	fit_gaus3->SetParameter(7, mean + 2 * rms);
	fit_gaus3->SetParameter(8, rms);
	// Set limits
	fit_gaus3->SetParLimits(0, 0, 1e8);
	fit_gaus3->SetParLimits(1, 0, mean);
	fit_gaus3->SetParLimits(3, 0, 1e7);
	fit_gaus3->SetParLimits(4, mean - 2 * rms, mean + 2 * rms);
	fit_gaus3->SetParLimits(6, 0, 1e7);
	fit_gaus3->SetParLimits(7, mean, 4000);
	

	// Fit the data
	rawData->Fit(fit_gaus3, "RSO", "");

	// Make functions for plotting
	TF1 *trip_gaus[3];
	trip_gaus[0] = new TF1("trip_gaus0", "gaus", low, high);
	trip_gaus[0]->SetParameter(0, fit_gaus3->GetParameter(0));
	trip_gaus[0]->SetParameter(1, fit_gaus3->GetParameter(1));
	trip_gaus[0]->SetParameter(2, fit_gaus3->GetParameter(2));
	trip_gaus[0]->SetLineColor(2);
	trip_gaus[1] = new TF1("trip_gaus1", "gaus", low, high);
	trip_gaus[1]->SetParameter(0, fit_gaus3->GetParameter(3));
	trip_gaus[1]->SetParameter(1, fit_gaus3->GetParameter(4));
	trip_gaus[1]->SetParameter(2, fit_gaus3->GetParameter(5));
	trip_gaus[1]->SetLineColor(2);
	trip_gaus[2] = new TF1("trip_gaus2", "gaus", low, high);
	trip_gaus[2]->SetParameter(0, fit_gaus3->GetParameter(6));
	trip_gaus[2]->SetParameter(1, fit_gaus3->GetParameter(7));
	trip_gaus[2]->SetParameter(2, fit_gaus3->GetParameter(8));
	trip_gaus[2]->SetLineColor(2);

	// Draw data
	rawData->Draw();
	// Draw fit
	fit_gaus3->Draw("same");
	// Draw fit contributions
	trip_gaus[0]->Draw("same");
	trip_gaus[1]->Draw("same");
	trip_gaus[2]->Draw("same");
	canvas->Update();

	// Save PNG
	char pngFileName[64];
	sprintf(pngFileName, "%s.png", rootFile.substr(19).c_str());
	if (savePNG == 1) canvas->Print(pngFileName);

}
