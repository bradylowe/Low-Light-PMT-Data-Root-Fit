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


void make_plot_color(int x = -1) {
	
	// Open files to read in values
	const Int_t num_colors = 10;
	ifstream x_file, y_file;
	//TGraph *gr[num_colors];
	TCanvas *c1 = new TCanvas("c1", "Graph", 200, 10, 1000, 618);
	Int_t colors_list[num_colors] = {1, 2, 3, 4, 6, 7, 8, 9, 5, 10};
	Int_t markers_list[num_colors] = {30, 22, 3, 33, 50, 34, 41, 47, 37, 38};
	Int_t size_list[num_colors] = {1, 1, 1, 1, 1, 1, 1, 1, 1, 1};
	Int_t colors_used = 0;
	Int_t count;
	TGraph *gr[num_colors];

	// Loop through all colors
	Int_t limit = 100;
	if (x > -1) limit = x;
	if (limit > num_colors) limit = num_colors;
	for(int i = 0; i < limit; i++) {
		// Open files
		char x_file_name[32];
		char y_file_name[32];
		sprintf(x_file_name, "x_file_%d.txt", i);
		sprintf(y_file_name, "y_file_%d.txt", i);
		printf("opening file %d\n", i);
		x_file.open(x_file_name);
		y_file.open(y_file_name);
	
		// Check for error
		if (!x_file) {
			break;
		}
		if (!y_file) {
			break;
		}

		// Define arrays
		const int array_size = 100000;
		Double_t x_array[array_size] = {0};
		Double_t y_array[array_size] = {0};

		// Read files
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

		// Count the number of files read
		gr[i] = new TGraph(count, x_array, y_array);
		gr[i]->SetMarkerColor(colors_list[colors_used]);
		gr[i]->SetMarkerStyle(markers_list[colors_used]);
		gr[i]->SetMarkerSize(size_list[colors_used]);
		colors_used++;
	}
	TMultiGraph *mg = new TMultiGraph();
	for (int i = 0; i < colors_used; i++) mg->Add(gr[i]);
	mg->Draw("AP");
}
