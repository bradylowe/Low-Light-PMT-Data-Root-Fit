// Brady Lowe // lowebra2@isu.edu

#include <TROOT.h>
#include <TMath.h>
#include <TChain.h>
#include <TApplication.h>


double divide(double x = 0.0, double y = 0.0){
	if (x < 1e-10 && x > -1e-10) return 0.0;
	else if (y < 1e-10 && y > -1e-10) return 1e10;
	else return x / y;
}


