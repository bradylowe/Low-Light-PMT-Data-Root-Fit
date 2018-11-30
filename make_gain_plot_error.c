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

void make_gain_plot_error(Int_t files = -1) {
	
	// Open files to read in values
	ifstream x_file, y_file, ex_file, ey_file;
	x_file.open("x_file.txt");
	y_file.open("y_file.txt");
	ex_file.open("ex_file.txt");
	ey_file.open("ey_file.txt");

	// Define arrays
	const int array_size = 100000;
	Double_t x_array[array_size] = {0};
	Double_t y_array[array_size] = {0};
	Double_t ex_array[array_size] = {0};
	Double_t ey_array[array_size] = {0};

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
	count = 0;
	while (ex_file >> val) {
		ex_array[count++] = val;
	}
	count = 0;
	while (ey_file >> val) {
		ey_array[count++] = val;
	}

	// Close files
	x_file.close();
	y_file.close();
	ex_file.close();
	ey_file.close();

	// Make plot
	TGraphErrors *gr1 = new TGraphErrors(count, x_array, y_array, ex_array, ey_array);
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
	fit_func->SetParameter(0, 1e-6);
	gr1->Fit(fit_func, "RS", "", low, high);
}
