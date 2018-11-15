// Brady Lowe // lowebra2@isu.edu

#include <TFile.h>
#include <TDirectory.h>
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


// kinked exponential (two different exponentials)
// [0] - kink location
// [1], [2] - left exponent params
// [3], [4] - right exponent params
double two_expo(Double_t *x, Double_t *par){
	if (x[0] > par[0]) return par[3] * TMath::Exp(par[4]);
	else return par[1] * TMath::Exp(par[2]);
}

void make_gain_plot(Int_t files = -1) {
	
	// Open files to read in values
	ifstream x_file, y_file;
	if (files == -1) {
		x_file.open("x_file.txt");
		y_file.open("y_file.txt");
	} else {
		x_file.open(Form("x_file_%d.txt", files));
		y_file.open(Form("y_file_%d.txt", files));
	}

	// Define arrays
	const int array_size = 100000;
	Double_t x_array[array_size] = {0};
	Double_t y_array[array_size] = {0};

	// Read files
	Int_t count;
	Double_t val;
	// May have multiple y values per x value
	count = 0;
	while (x_file >> val) {
		x_array[count++] = val;
	}
	count = 0;
	while (y_file >> val) {
		y_array[count++] = val;
	}

	// Close files
	x_file.close();
	y_file.close();

	// Make plot
	TGraph *gr1 = new TGraph(count, x_array, y_array);
	gr1->SetTitle("Gain vs High-voltage");
	gr1->GetXaxis()->SetTitle("High-voltage");
	gr1->GetYaxis()->SetTitle("Gain (x 10^6)");
	TCanvas *c1 = new TCanvas("c1", "Graph", 200, 10, 1000, 618);
	gr1->Draw("A*");

	// Fit data
	Int_t low = 1000;
	Int_t high = 2000;
	gStyle->SetOptFit(1);
	TF1 *fit_func = new TF1("fit_func", "expo", low, high);
	gr1->Fit(fit_func, "RS", "", low, high);
}
