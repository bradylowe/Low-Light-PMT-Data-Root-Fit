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

#include <TMinuit.h>
#include <TApplication.h>
#include <TCanvas.h>
#include <TStyle.h>
#include <TAxis.h>
#include <TLine.h>


void make_plot_error(string color = "black", string x_title = "X-axis", string y_title = "Y-axis") {
	
	// Open files to read in values
	ifstream x_file, y_file, ex_file, ey_file;
	x_file.open("x_file.txt");
	y_file.open("y_file.txt");
	ex_file.open("ex_file.txt");
	ey_file.open("ey_file.txt");
	x_file.open(Form("x_file_%s.txt", color.c_str()));
	y_file.open(Form("y_file_%s.txt", color.c_str()));
	ex_file.open(Form("ex_file_%s.txt", color.c_str()));
	ey_file.open(Form("ey_file_%s.txt", color.c_str()));

	// Define arrays
	const int array_size = 100000;
	Double_t x_array[array_size] = {0};
	Double_t y_array[array_size] = {0};
	Double_t ex_array[array_size] = {0};
	Double_t ey_array[array_size] = {0};

	// Read files
	Int_t cx, cy, cex, cey;
	Double_t val;
	Double_t max = -1;
	Double_t min = 1e8;
	// May have multiple y values per x value
	cx = 0;
	while (x_file >> val) {
		x_array[cx++] = val;
		if (val > max) max = val;
		if (val < min) min = val;
	}
	cy = 0;
	while (y_file >> val) {
		y_array[cy++] = val;
	}
	cex = 0;
		if (ex_file.is_open()) {
		while (ex_file >> val) {
			ex_array[cex++] = val;
		}
	}
	cey = 0;
	while (ey_file >> val) {
		ey_array[cey++] = val;
	}
	
	if (cx != cy || cey == 0 || cey != cy) return;
	if (cex == 0) for(int b = 0; b < cx; b++) ex_array[b] = 0.0;
	else if (cex == 1) for(int b = 0; b < cx; b++) ex_array[b] = ex_array[0];

	// Close files
	x_file.close();
	y_file.close();
	ex_file.close();
	ey_file.close();

	// Make plot
	TGraphErrors *gr1 = new TGraphErrors(count, x_array, y_array, ex_array, ey_array);
	gr1->SetTitle(Form("%s vs %s", x_title.c_str(), y_title.c_str()));
	gr1->GetXaxis()->SetTitle(x_title.c_str());
	gr1->GetYaxis()->SetTitle(y_title.c_str());
	TCanvas *c1 = new TCanvas("c1", "Graph", 200, 10, 1000, 618);
	gr1->Draw("A*");

        // Define the fits (depends on which tube you are using)
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
        fit_power2->SetParameter(0, 1e-19);
        fit_power2->SetParameter(1, 8.0);
        TF1 *fit_line = new TF1("fit_func", "pol1", low, max);
        fit_line->SetParName(0, "Line intercept");
        fit_line->SetParName(1, "Line slope");
        fit_line->SetParameter(0, -2.0);
        fit_line->SetParameter(1, 0.001);
        fit_line->SetLineColor(6);
        TF1 *fit_hamamatsu = new TF1("fit_hama", power_curve_hamamatsu, low, max, 1);
        fit_hamamatsu->SetParameter(0, 1e-4);

	// Fit the data
//      gr1->Fit(fit_hamamatsu, "RS", "", max * 0.08, max * 0.9);
        gr1->Fit(fit_power, "RS", "", max * 0.08, max * 0.8);
//      gr1->Fit(fit_power2, "RS+", "", max * 0.85, max * 1.01);
        gr1->Fit(fit_line, "RS+", "", max * 0.8, max * 1.01);
}
