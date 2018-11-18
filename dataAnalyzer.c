static const double degtorad = 3.141592653589793 / 180.;
static const double twopi = 2 * 3.141592653589793;

// String to integer function
int myStoi(string str) { 
	// Return integer value{
	int ret = 0;
	int max = str.length();
	// ASCII offset
	int offset = 48;
	// Loop through digits
	for (int i = 0; i < max; i++) {
		ret += (str[i] - offset) * pow(10, max - i - 1);
	}
	return ret;
}

// String to double function
double myStod(string str) {
	// Return double value
	double ret = 0.0;
	// Decompose string into before and after decimal parts
	string before, after;
	int index = str.find(".");
	before = str.substr(0, index);
	after = str.substr(index + 1);
	if (after.length() > 5) after = after.substr(0, 5);
	// Calculate return value
	ret = (double)(myStoi(before));
	ret += (double)(myStoi(after)) / pow(10.0, after.length());
	return ret;
}

// Returns the run number of a root file that
// is stored within the file name itself:
//  - getRunNumFromFilename("r1729_v965ST_5.root") returns 1729
int getRunNumFromFilename(string rootFile) {
	// Look for first underscore and first period
	Int_t underscoreIndex = rootFile.find("_");
	Int_t extIndex = rootFile.find(".root");
	// MUST first check the underscore because there 
	// is definitely a period
	if (underscoreIndex != string::npos)
		return stoi(rootFile.substr(1, underscoreIndex));
	else if (extIndex != string::npos) 
		return stoi(rootFile.substr(1, extIndex));
	else return 0;
}

// This function attemps to extract an integer from a filename.
// The integer may be absent from the filename (return 0).
//  - getDaqFromFilename("r1729_v965ST_5.root") returns 5
int getDaqFromFilename(string rootFile) {
	// Look for first and second underscores and period
	Int_t us1Index = rootFile.find("_");
	Int_t us2Index = (int)(string::npos);
	Int_t extIndex = rootFile.find(".root");
	// Check for first underscore
	if (us1Index != string::npos) {
		// Only look for 2 underscores if there's at least 1
		us2Index = rootFile.find("_", us1Index);
		// Daq should just be a single digit, and the last thing before 
		// the extension
		if (us2Index != string::npos && us2Index - extIndex == 1)
			return stoi(rootFile.substr(us2Index, extIndex));
		else if (us1Index - extIndex == 1)
			return stoi(rootFile.substr(us1Index, extIndex));
	} 
	return 0;
}

// This function will open a Root data file chosen by the user and calculate
// the average or standard deviation of a gaussian distribution inside the data. 
// The algorithm assumes bimodal data structure (first mode is pedestal, second 
// mode is signal).
//
//  - getDataPedSig("r1729_v965ST_5.root", "pedmean") returns the value of the pedestal mean 
//                                                    of run 1729
//  - getDataPedSig("r1729_v965ST_5.root", "sigrms") returns the rms of the second mode (signal)
double getDataPedSig(string rootFile, Int_t qCh, string paramName = "none", Bool_t saveImage = false) {

	// Initialize histograms
	Int_t binWidth = 1;
	Int_t bins = int(4096/binWidth + 1.);
	Float_t minR = int(0 - binWidth / 2.);
	Float_t maxR = 4096 + binWidth / 2.;
	TH1F* rawData = new TH1F("rawData", "", bins,minR,maxR);
	// For displaying results in fit
	gStyle->SetOptFit(1);

	// Open root file
	TFile *f1 = new TFile(rootFile.c_str());
	if ( f1->IsZombie() ) {
		printf("ERROR ==> Failed to open file %s\n", rootFile.c_str());
		return -1.0;
	}

	// Define tree, leaf, branch
	TTree *tree = (TTree *) f1->Get("ntuple");
	TLeaf *leaf = tree->GetLeaf(Form("ADC%dl", qCh));
	TBranch *branch = leaf->GetBranch();

	// Fill raw data histogram
	for (Int_t entry = 0; entry < branch->GetEntries(); entry++) {    
		branch->GetEntry(entry);
		rawData->Fill(leaf->GetValue());
	}

	// Grab some info from the raw data
	Int_t maxBin = rawData->GetMaximumBin();
	Int_t low = rawData->FindFirstBinAbove(1);
	Int_t high = rawData->FindLastBinAbove(1);
	Double_t rawRMS = rawData->GetRMS();
	Double_t totalIntegral = rawData->Integral(low, high);
	Double_t pedIntegral = rawData->Integral(low, maxBin + rawRMS / 3);

	// Do a calculation to see if this data is bimodal
	Bool_t bimodal = false;
	if (pedIntegral / totalIntegral < 0.65) bimodal = true;
	Int_t beginSignal = high;
	if (bimodal) beginSignal = maxBin + rawRMS / 3;

	// Fit pedestal
	rawData->GetXaxis()->SetRangeUser(low, high);
	TF1* pedFit = new TF1("pedFit", "gaus", low, beginSignal);
	rawData->Fit(pedFit, "RSON", "");

	// Fit Signal
	TF1* sigFit = new TF1("sigFit", "gaus", beginSignal, high);
	sigFit->SetParLimits(1, beginSignal, high);
	rawData->Fit(sigFit, "RSON", "");
	sigFit->SetLineColor(4);

	// Save output png
	if (saveImage) {
		TCanvas* can = new TCanvas("can", "can", 600, 400);
		can->cd();
		rawData->Draw();
		pedFit->Draw("same");
		sigFit->Draw("same");
		can->SaveAs("dataAnalyzerSingle.png");
	}

	// Depending on what the user asks for, return different params
	if (paramName.compare("pedmean") == 0) return pedFit->GetParameter(1);
	if (paramName.compare("pedrms") == 0) return pedFit->GetParameter(2);
	if (paramName.compare("sigmean") == 0) return sigFit->GetParameter(1);
	if (paramName.compare("sigrms") == 0) return sigFit->GetParameter(2);
	return -1.0;
}


// This function returns a cutoff bin value between 0 and 4096 for a given file.
// The input Root files define histograms. "limit" acts as a threshold value, 
// "minmax" acts as a switch for choosing minimum (0) or maximum (1). "qCh" is
// for ADC channel. 
//
//  - getDataMinMax("r1729_v965ST_5.root", 12, 0, 100) will return the lowest bin index
//                                                     that has at least 100 counts
int getDataMinMax(string rootFile, Int_t qCh, Int_t minmax = 0, Int_t limit = 1)
{
	int highlow = 0;
	// Initialize histograms
	Int_t binWidth = 1;
	Int_t bins = int(4096/binWidth + 1.);
	Float_t minR = int(0 - binWidth/2.);
	Float_t maxR = 4096 + binWidth/2.;
	TH1F *rawData = new TH1F("rawData", "", bins,minR,maxR);
  
	// Open root file
	TFile *f1 = new TFile(rootFile.c_str());
	if ( f1->IsZombie() ) {
		printf("ERROR ==> Failed to open file %s\n", rootFile.c_str());
		return 0;
	}

	// Set up Tree structure for reading data
	char channel[32];
	if(highlow==0) sprintf(channel,"ADC%dl",qCh);
	if(highlow==1) sprintf(channel,"ADC%dh",qCh);
	char selection[64];
	if(highlow==0) sprintf(selection,"");
	if(highlow==1) sprintf(selection,"");

	// Define tree, branch, and leaf
	TTree *tree = (TTree *) f1->Get("ntuple");
	TLeaf *leaf = tree->GetLeaf(channel);
	TBranch *branch = leaf->GetBranch();

	// Fill raw data histogram
	for (Int_t entry = 0; entry < branch->GetEntries(); entry++) {
		branch->GetEntry(entry);
		rawData->Fill(leaf->GetValue());
	}

	if (minmax == 0) return rawData->FindFirstBinAbove(limit);
	else return rawData->FindLastBinAbove(limit);
}


// This function takes in a histogram and writes the values to a file.
// The file will have num_bins lines in it, each line with a single integer (bin content).
// The file is called <rootfile name>.root.hist
void writeHistToFile(TH1F *hist, const char* rootFile, Int_t bins) {

	// Get number of leading zeros
        Int_t leadingZeros = 0;
        while (hist->GetBinContent(leadingZeros) == 0)
                leadingZeros++;

        // Get number of trailing zeros
        Int_t trailingZeros = 0;
        while (hist->GetBinContent(bins - trailingZeros - 1) == 0)
                trailingZeros++;

        // Write histogram to file
        ofstream file;
        file.open(Form("%s.hist", rootFile), std::ofstream::out);
        if (file.is_open()) {
		// Print first number of leading and trailing zeros
                file << leadingZeros << " leading zeros" << endl;
                file << trailingZeros << " trailing zeros" << endl;
		// Now, loop through signal and print values
                for (Int_t ii = leadingZeros; ii < bins - trailingZeros; ii++) {
                        file << hist->GetBinContent(ii) << endl;
                }
		// Close the file
                file.close();
        } else printf("\nUnable to write histogram values to file for %s.\n", rootFile);
	return;
}

// This function takes in three numbers and reads a value from
// a line in a file based on the inputs.
Double_t getValueFromCSV(string filename, int head, int valueIndex = 1){
printf("%s, %d, %d\n", filename.c_str(), head, valueIndex);
	// Open the file
	ifstream myfile;
	myfile.open(filename);
	// Check for error
	if (!myfile.is_open()) {
		printf("Error opening calibration file\n");
		return 0.0;
	}
	// Loop through the lines until the desired line if found
	string line;
	Int_t compare;
	Int_t index;
	Int_t end;
	while (getline(myfile, line)) {
		// Grab index of first comma, find correct line
		index = line.find(",");
		compare = myStoi(line.substr(0, index));
		if (compare != head) continue;
		// Find index of value desired
		for (int ii = 1; ii < valueIndex; ii++) 
			index = line.find(",", index + 1);
		// Return the value
		end = line.find(",", index + 1);
		if (end <= 0) return myStod(line.substr(index + 1));
		else return myStod(line.substr(index + 1, end));
	}
	return -1.0;
}

// This function takes in pmt number and high voltage setting and reads from file
// the corresponding initial guess for the signal size of 1-PE for that pmt/hv.
Double_t getSignalFromHV(Int_t pmt, Int_t hv) {
	string filename = Form("calibration/pmt%d_gain.csv", pmt);
	double ret = getValueFromCSV(filename, hv);
	if (ret < 0) return 4.0;
	else return ret;
}
Double_t getSignalRmsFromHV(Int_t pmt, Int_t hv) {
	string filename = Form("calibration/pmt%d_gain.csv", pmt);
	double ret = getValueFromCSV(filename, hv, 2);
	if (ret < 0) return 1.0;
	else return ret;
}

// This function takes in pmt number and light level setting and reads from file
// the corresponding initial guess of mu for that pmt/ll.
Double_t getMuFromLL(Int_t pmt, Int_t ll) {
	string filename = Form("calibration/pmt%d_ll.csv", pmt);
	double ret = getValueFromCSV(filename, ll);
	if (ret < 0) return 1.0;
	else return ret;
}

// This function takes in pmt number and light level setting and reads from file
// the corresponding initial guess of mu for that pmt/ll.
Double_t getTransparencyFromFilter(Int_t filter) {
	string filename = "calibration/filters.csv";
	double ret = getValueFromCSV(filename, filter);
	if (ret < 0) return 1.0;
	else return ret;
}

// This function takes in pmt number and gate length and reads from file
// the corresponding initial guess of pedestal mean and sigma.
Double_t getPedestalFromGate(Int_t pmt, Int_t gate) {
	string filename = Form("calibration/pmt%d_pedestals.csv", pmt);
	double ret = getValueFromCSV(filename, gate);
	if (ret < 0) return 244.0;
	else return ret;
}
Double_t getPedRmsFromGate(Int_t pmt, Int_t gate) {
	string filename = Form("calibration/pmt%d_pedestals.csv", pmt);
	double ret = getValueFromCSV(filename, gate, 2);
	if (ret < 0) return 1.5;
	else return ret;
}

// This function takes in a filename to a .hist file as well as a list of parameters and
// creates a PNG of the fit function described in the parameter vector as well as the data
// points described in the .hist file.
void createPngFromNumbers(string histogram) {
	
	// Initialize data storage
	const Int_t N = 4097;
	Float_t data[N] = {0};
	Float_t dataError[N] = {0};
	Float_t count[N];
	Float_t countError[N];
	for (Int_t i = 0; i < N; i++) {
		count[i] = i;
		countError[i] = 0.5;
	}

	// Open file for reading
	ifstream file;
	file.open(histogram.c_str());
	if (file.is_open()) {
		// Get leading and trailing zeros
		string line;
		getline(file, line);
		line = line.substr(0, line.find(" "));
		Int_t leading = myStoi(line);
		getline(file, line);
		line = line.substr(0, line.find(" "));
		Int_t trailing = myStoi(line);
		// Read the rest of the file
		while (getline(file, line)) {
			data[leading] = myStoi(line);
			dataError[leading] = TMath::Sqrt(data[leading]);
			leading++;
		}
		file.close();
	} else printf("Unable to open %s\n", histogram.c_str());
	
	// Make graph
	TCanvas *c1 = new TCanvas("c1", "c1", 200, 10, 700, 500);
	c1->cd();
	TGraphErrors *gr = new TGraphErrors(N, count, data, countError, dataError);
	gr->Draw();
	c1->Print();
	return;
}

// This function models the distribution of the CAEN v965 ADC.
// This is the distribution received with or without signal present.
//
// This distribution is primarily a single gaussian, but there are two
// smaller gaussians (all three with similar means). One gaussian has
// a larger rms than the other two by a few times.
//
// 8 parameters describe the three relative amplitudes, means, and rms.
// The two amplitude parameters are relative to the first and largest
// gaussian. (mean0, rms0, amp1, mean1, rms1, amp2, mean2, rms2)
Double_t v965_dist(Double_t *x, Double_t *par) {
        Double_t gaus1 = 1.0 / par[1] / sqrt(twopi) * exp( - pow((x[0] - par[0]) / par[1], 2) / 2);
        Double_t gaus2 = par[2] * exp( - pow((x[0] - par[3]) / par[4], 2) / 2);
        Double_t gaus3 = par[5] * exp( - pow((x[0] - par[6]) / par[7], 2) / 2);
        return gaus1 + gaus2 + gaus3;
}


// This function takes in the same parameters from the above fit (+1 extra), and returns
// the signal value from ONLY A SINGLE pe contribution (par[9] = n).
// This will allow us to draw a deconvoluted picture of the fit.
Double_t the_real_deal_yx_pe(Double_t *x, Double_t *par){

	// Grab current x value, current pe, and prepare variables
	Double_t xx = x[0];
	Int_t n = (int)(par[9]);
	Double_t qn, sigma_n, term_1, term_11, term_2, term_3, igne, gn, igne_is;

	// Initialize
	qn = 0.;
	sigma_n = 0.;
	term_1 = 0.;
	term_11 = 0.;
	term_2 = 0.;
	term_3 = 0.;
	igne = 0.;
	gn = 0.;

	// Calculate values to be used for this PE 
	qn = par[1] + n * par[5];				// mean of this PE dist
	sigma_n = sqrt(pow(par[2],2) + n * pow(par[6],2));	// sigma of this PE dist
	term_1 = xx - qn - par[3] * pow(sigma_n,2);		// expo and erf argument
	term_11 = xx - qn - par[3] * pow(sigma_n,2) / 2.0;	// Error or correction
	term_2 = par[1] - qn - par[3] * pow(sigma_n,2);		// Erf argument
	term_3 = xx - qn;					// xx shifted by PE mean

	// Calculate igne
	// Depending on which side of the PE distribution we are on, add or subtract in parentheses
	if (term_1 >= 0.) {
		igne = 	par[3] / 2.0 * exp(-par[3] * term_11) * 
			(
				TMath::Erf(fabs(term_2) / sqrt(2.0) / sigma_n) + 
				TMath::Erf(fabs(term_1) / sqrt(2.0) / sigma_n)
			);
	} else {
		igne = 	par[3] / 2.0 * exp(-par[3] * term_11) * 
		(
			TMath::Erf(fabs(term_2) / sqrt(2.0) / sigma_n) - 
			TMath::Erf(fabs(term_1) / sqrt(2.0) / sigma_n)
		);
	}

	// Calculate gn
	gn = exp(-pow(term_3, 2) / 2.0 / pow(sigma_n, 2)) / (sqrt(twopi) * sigma_n);

	// Put it all together and return
	return TMath::PoissonI(n, par[4]) * par[8] * ((1 - par[0]) * gn + par[0] * igne); 
  
}

// This function returns the background (pedestal) distribution
// which includes real 0-pe events, injected 0-pe events, as
// well as exponential decay distribution of discrete background events.
Double_t the_real_deal_yx_bg(Double_t *x, Double_t *par){

	// Initialize variables, grab current x value
	Double_t xx = x[0];
	Double_t qn, sigma_n, term_1, term_2, term_3, igne, igne_is;
	Double_t poisson_is = exp(-par[4]);
	Double_t gaus_is = exp(-pow(xx - par[1], 2) / 2.0 / pow(par[2], 2)) / par[2] / sqrt(twopi);
  
	// If we are to the right of the pedestal, include the exponential.
	if(xx >= par[1]){
	// Use this line to use noExpoPed fit model
	//if(false){
		igne_is = par[3] * exp(-par[3] * (xx - par[1]));
	} else {
		igne_is = 0.;
	}
	
	// Calculate background portion
	Double_t s_bg = poisson_is * par[8] * ((1 - par[0]) * gaus_is + par[0] * igne_is); 
  
	// Add in clock contribution
	Double_t s_clock = par[7] * ((1-par[0]) * gaus_is + par[0] * igne_is);

	// Sum and return
	return s_bg + s_clock;

}

// This function was written by YuXiang Zhao.
// I had to modify it some amount to get it working on our setup.
// The model used here is described in a NIM publication in the "docs" directory.
Double_t the_real_deal_yx(Double_t *x, Double_t *par){
	Double_t s_real_sum = 0.;
	Double_t initial_par9 = par[9];
	for (int i = (int)(par[9]); i < (int)(par[10]); i++) {
		par[9] = (double)(i);
		s_real_sum += the_real_deal_yx_pe(x, par);
	}
	par[9] = initial_par9;
	Double_t s_bg = the_real_deal_yx_bg(x, par);
	return s_real_sum + s_bg;
}

// This function assumes that there is a certain likelihood of a double-PE 
// ejection for a single photon (motivated by studying many fits).
Double_t double_fit_pmt_bg(Double_t *x, Double_t *par) {
        // Get param vector for the_real_deal_yx_pe
        Double_t par2[11] = {   par[0], par[1], par[2], par[3], par[4],
                                par[5], par[6], par[7], par[8], par[9], par[10] };
        // Return total
        return the_real_deal_yx_bg(x, par2);
}

// This function assumes that there is a non-zero probability
// of experiencing a different light level than provided (cosmic ray)
Double_t double_fit_pmt_pe(Double_t *x, Double_t *par) {
        // Get param vector for the_real_deal_yx_pe
        Double_t par2[11] = {   par[0], par[1], par[2], par[3], par[4],
                                par[5], par[6], par[7], par[8], par[9], par[10] };
        return (1.0 - par[11]) * the_real_deal_yx_pe(x, par2);
}

// This function computes the PE contribution from the extra light source
Double_t double_fit_pmt_pe2(Double_t *x, Double_t *par) {
        // Get param vector for the_real_deal_yx_pe
        Double_t par2[11] = {   par[0], par[1], par[2], par[3], par[12],
                                par[5], par[13], par[7], par[8], par[9], par[10] };
        return par[11] * the_real_deal_yx_pe(x, par2);
}

// par[0] = w
// par[1] = q           // par[2] = s0          // par[3] = alpha
// par[4] = mu          // par[5] = q1          // par[6] = s1
// par[7] = inj         // par[8] = real        // par[9] = min_pe
// par[10] = max_pe     // par[11] = norm2      // par[12] = mu2
// par[13] = s2 (possible different gaussian width from different amplification process)
Double_t double_fit_pmt(Double_t *x, Double_t *par) {
        // Initialize sum  
        Double_t s_real_sum = 0.;
        // Store this for later
        Double_t initial_par9 = par[9];
        // Loop through all PE contributions for normal distribution
        for (int i = (int)(par[9]); i < (int)(par[10]); i++) {
                par[9] = (double)(i); // Select current PE 
                s_real_sum += double_fit_pmt_pe(x, par);
        }
        // Compute minPE to consider
        Int_t minPE = (int)(par[12] - 8);
        if (minPE < 1) minPE = 1;
        Int_t maxPE = (int)(par[12] + 8);
        // Loop over all relavent PE contributions for EXTRA distribution
        for (int i = minPE; i < maxPE; i++) {
                par[9] = (double)(i); // Select current PE 
                s_real_sum += double_fit_pmt_pe2(x, par);
        }
        // Set parameter back to real value
        par[9] = initial_par9;
        // Compute background and return total
        Double_t s_bg = double_fit_pmt_bg(x, par);
        return s_real_sum + s_bg;
}

