// Brady Lowe // lowebra2@isu.edu

#include <TFile.h>
#include <TDirectory.h>
#include <TTree.h>
#include <TROOT.h>
#include <TMath.h>
#include <TChain.h>
#include <TH1F.h>
#include <TF1.h>

#include "Math/SpecFunc.h"
#include "dataAnalyzer.c"

#include <TMinuit.h>
#include <TApplication.h>
#include <TCanvas.h>
#include <TStyle.h>
#include <TAxis.h>
#include <TLine.h>


double testDataAnalyzer(int pmt, int val, int choice){

	//createPngFromNumbers(histogram);
	if (choice == 0)
		return getSignalFromHV(pmt, val);
	else if (choice == 1)
		return getMuFromLL(pmt, val);
	else return getTransparencyFromFilter(val);
}


