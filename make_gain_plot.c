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
#include "fit_pmt_functions.c"
#include "root_models.c"

#include <TMinuit.h>
#include <TApplication.h>
#include <TCanvas.h>
#include <TStyle.h>
#include <TAxis.h>
#include <TLine.h>

void make_gain_plot(string color = "black", string title = "Gain vs. High Voltage", string xTitle = "Voltage", string yTitle = "Gain (x 10^-6)") {
	
	// Open files to read in values
	ifstream x_file, y_file;
	x_file.open(Form("x_file_%s.txt", color.c_str()));
	y_file.open(Form("y_file_%s.txt", color.c_str()));

	// Define arrays
	const int array_size = 100000;
	Double_t x_array[array_size] = {0};
	Double_t y_array[array_size] = {0};

	// Read files
	Int_t count;
	Double_t val;
	Double_t min = 1e8;
	Double_t max = 0.0;
	// May have multiple y values per x value
	count = 0;
	while (x_file >> val) {
		x_array[count++] = val;
		if (val < min) min = val;
		if (val > max) max = val;
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
	gr1->SetTitle(title.c_str());
	gr1->GetXaxis()->SetTitle(xTitle.c_str());
	gr1->GetYaxis()->SetTitle(yTitle.c_str());
	TCanvas *c1 = new TCanvas("c1", "Graph", 200, 10, 1000, 618);
	c1->SetGrid();
	gr1->Draw("A*");

	// Fit data
	Int_t low = 100;
	Int_t high = 2000;
	gStyle->SetOptFit(1);
	TF1 *fit_power = new TF1("fit_func", power_curve, low, max, 2);
	fit_power->SetParName(0, "Amplitude");
	fit_power->SetParName(1, "# of stages");
	fit_power->SetParameter(0, 1e-4);
	fit_power->SetParameter(1, 8.0);
	TF1 *fit_power2 = new TF1("fit_func", power_curve, low, max, 2);
	fit_power2->SetParName(0, "Amplitude (2)");
	fit_power2->SetParName(1, "# of stages (2)");
	fit_power2->SetParameter(0, 1e-15);
	fit_power2->SetParameter(1, 8.0);
	TF1 *fit_line = new TF1("fit_func", "pol1", low, max);
	fit_line->SetParName(0, "Line intercept");
	fit_line->SetParName(1, "Line slope");
	fit_line->SetParameter(0, -2.0);
	fit_line->SetParameter(1, 0.001);
	fit_line->SetLineColor(6);
	//TF1 *fit_hamamatsu = new TF1("fit_hama", power_curve_hamamatsu, low, max, 1);
	//fit_hamamatsu->SetParameter(0, 1e-12);
//	gr1->Fit(fit_hamamatsu, "RS", "", max * 0.08, max * 0.9);
	gr1->Fit(fit_power, "RS", "", max * 0.08, max * 1.00);
//	gr1->Fit(fit_power2, "RS+", "", max * 0.85, max * 1.01);
//  	gr1->Fit(fit_line, "RS+", "", max * 0.8, max * 1.01);
}
