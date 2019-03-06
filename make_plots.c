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


vector<float> ReadArrayFromFile(string filename) {
	// Read files
	ifstream cur_file;
	const int max_array_size = 10000;
	vector<float> cur_array;
	cur_file.open(filename.c_str());
	Float_t cur_val;
	while (cur_file >> cur_val) {
		cur_array.push_back(cur_val);
	}
	cur_file.close();
	return cur_array;
}

Int_t GetColorIndex(string color) {
	if (!color.compare("black")) 		return 1;
	else if (!color.compare("red")) 	return 2;
	else if (!color.compare("cyan")) 	return 7;
	else if (!color.compare("blue")) 	return 4;
	else if (!color.compare("purple")) 	return 6;
	else if (!color.compare("green")) 	return 8;
	else if (!color.compare("yellow")) 	return 41;
	else if (!color.compare("orange")) 	return 46;
	else 					return 0;
}

Int_t GetMarkerIndex(string color = "", string marker = "") {
	// Check for marker
	if (marker.compare("")) {
		if (!marker.compare("circle"))		return 4;
		else if (!marker.compare("star"))	return 29;
		else if (!marker.compare("star2"))	return 43;
		else if (!marker.compare("triangle"))	return 23;
		else if (!marker.compare("cross"))	return 34;
		else if (!marker.compare("cross2"))	return 48;
		else if (!marker.compare("cross3"))	return 38;
		else if (!marker.compare("cross4"))	return 40;
		else if (!marker.compare("cross5"))	return 45;
		else if (!marker.compare("cross6"))	return 41;
		else if (!marker.compare("dot"))	return 8;
		else if (!marker.compare("diamond"))	return 33;
		else if (!marker.compare("splat"))	return 31;
	// Check for color
	} else if (color.compare("")) {
		if (!color.compare("black")) 		return 8;
		else if (!color.compare("red")) 	return 8;
		//else if (!color.compare("red")) 	return 29;
		else if (!color.compare("blue")) 	return 8;
		else if (!color.compare("yellow")) 	return 8;
		else if (!color.compare("purple")) 	return 8;
		else if (!color.compare("green")) 	return 8;
		else if (!color.compare("orange")) 	return 8;
		else if (!color.compare("cyan")) 	return 8;
	} 
	return 8;
}

vector<string> MakeVectorFromCSV(string csv_list) {
	vector<string> vector_list;
	Int_t begin = 0;
	Int_t end = csv_list.find(",", begin);
	string cur_string;
	while (end != string::npos) {
		cur_string = csv_list.substr(begin, end - begin);
		vector_list.push_back(cur_string);
		begin = end + 1;
		end = csv_list.find(",", begin);
	}
	cur_string = csv_list.substr(begin);
	vector_list.push_back(cur_string);
	return vector_list;
}





void make_plots(string colors = "black", string title = "Title", string x_title = "X-axis", string y_title = "Y-axis", string z_names = "", string z_header = "", string z_markers = "", string error = "", string png_file = "", int log_x = 0, int log_y = 0, float ex = 0.0) {
	
	// Define things
	Int_t first = 1;
	TCanvas *c1 = new TCanvas("c1", "Graph", 200, 10, 1000, 618);
	c1->SetGridy();
	Int_t abs_min = 999999999;
	Int_t abs_max = 0;
	ifstream x_file, y_file;
	vector<float> x_vector, y_vector, ex_vector, ey_vector;
	Int_t cur_index = 0;
	TMultiGraph* multi_graph = new TMultiGraph();
	TLegend* legend = new TLegend(0.1, 0.7, 0.48, 0.9);
	if (z_header.compare("")) legend->SetHeader(z_header.c_str(), "C");
	vector<string> z_names_vector = MakeVectorFromCSV(z_names);
	vector<string> markers_vector = MakeVectorFromCSV(z_markers);

	// Parse colors string
	vector<string> colors_vector;
	if (colors.find("black") != string::npos) colors_vector.push_back("black");
	if (colors.find("red") != string::npos) colors_vector.push_back("red");
	if (colors.find("cyan") != string::npos) colors_vector.push_back("cyan");
	if (colors.find("blue") != string::npos) colors_vector.push_back("blue");
	if (colors.find("purple") != string::npos) colors_vector.push_back("purple");
	if (colors.find("green") != string::npos) colors_vector.push_back("green");
	if (colors.find("yellow") != string::npos) colors_vector.push_back("yellow");
	if (colors.find("orange") != string::npos) colors_vector.push_back("orange");
	
	for(int i = 0; i < colors_vector.size(); i++) {
		string cur_color = "black";
		string cur_marker = "";
		if (i < colors_vector.size()) cur_color = colors_vector.at(i);
		if (i < markers_vector.size()) cur_marker = markers_vector.at(i);
		x_vector = ReadArrayFromFile(Form("x_file_%s.txt", cur_color.c_str()));
		y_vector = ReadArrayFromFile(Form("y_file_%s.txt", cur_color.c_str()));
		if (error.compare("")) {
			ey_vector = ReadArrayFromFile(Form("ey_file_%s.txt", cur_color.c_str()));
			for (int j = 0; j < ey_vector.size(); j++) {
				ex_vector.push_back(ex);
			}
		}

		// Make plot
		Int_t count = x_vector.size();
		if (count > 0) {
			if(error.compare("")) {
				TGraphErrors *graph = new TGraphErrors(count, &x_vector[0], &y_vector[0], &ex_vector[0], &ey_vector[0]);
				graph->SetMarkerColor(GetColorIndex(cur_color));
				graph->SetMarkerStyle(GetMarkerIndex(cur_color, cur_marker));
				if (error.compare("")) multi_graph->Add(graph, "ep");
				else multi_graph->Add(graph, "p");
				if (i < z_names_vector.size())
					legend->AddEntry(graph, z_names_vector.at(i).c_str(), "p");
			}
			else {
				TGraph *graph = new TGraph(count, &x_vector[0], &y_vector[0]);
				graph->SetMarkerColor(GetColorIndex(cur_color));
				graph->SetMarkerStyle(GetMarkerIndex(cur_color, cur_marker));
				if (error.compare("")) multi_graph->Add(graph, "ep");
				else multi_graph->Add(graph, "p");
				if (i < z_names_vector.size())
					legend->AddEntry(graph, z_names_vector.at(i).c_str(), "p");
			}
		}
	}

       	multi_graph->SetTitle(title.c_str());
       	multi_graph->GetXaxis()->SetTitle(x_title.c_str());
       	multi_graph->GetYaxis()->SetTitle(y_title.c_str());
       	multi_graph->GetXaxis()->SetTitle(x_title.c_str());
       	multi_graph->GetYaxis()->SetTitle(y_title.c_str());
	multi_graph->Draw("a");
	if (z_names.compare("")) legend->Draw();
	
	if (log_x > 0) c1->SetLogx();
	if (log_y > 0) c1->SetLogy();

	if (png_file.compare("")) c1->Print(png_file.c_str());


}
