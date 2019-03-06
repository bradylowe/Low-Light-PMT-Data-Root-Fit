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


void make_plot(string color = "black", string title = "Title", string x_title = "X-axis", string y_title = "Y-axis") {
	
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
        gr1->SetTitle(title.c_str());
        gr1->GetXaxis()->SetTitle(x_title.c_str());
        gr1->GetYaxis()->SetTitle(y_title.c_str());
	TCanvas *c1 = new TCanvas("c1", "Graph", 200, 10, 1000, 618);
	gr1->SetTitle("Title");
	gr1->Draw("A*");
}
