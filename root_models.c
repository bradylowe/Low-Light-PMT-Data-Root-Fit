
// This function returns the background (pedestal) distribution
// which includes real 0-pe events, injected 0-pe events, as
// well as exponential decay distribution of discrete background events.
Double_t low_light_model_bg(Double_t *x, Double_t *par){

        // Initialize variables, grab current x value
        Double_t qn, sigma_n, term_1, term_2, term_3, igne, igne_is;
        Double_t poisson_is = exp(-par[4]);
        Double_t gaus_is = exp(-pow(x[0] - par[1], 2) / 2.0 / pow(par[2], 2)) / par[2] / sqrt(twopi);

        // If we are to the right of the pedestal, include the exponential.
        if(x[0] >= par[1]){
        // Use this line to use noExpoPed fit model
        //if(false){
                igne_is = par[3] * exp(-par[3] * (x[0] - par[1]));
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

Double_t low_light_model_bg_no_expo(Double_t *x, Double_t *par){

        // Initialize variables, grab current x value
        Double_t poisson_is = exp(-par[4]);
        Double_t gaus_is = exp(-pow(x[0] - par[1], 2) / 2.0 / pow(par[2], 2)) / par[2] / sqrt(twopi);

        // Calculate background portion
        Double_t s_bg = poisson_is * par[8] * gaus_is;

        // Add in clock contribution
        Double_t s_clock = par[7] * gaus_is;

        // Sum and return
        return s_bg + s_clock;

}

// This function takes in the same parameters from the above fit (+1 extra), and returns
// the signal value from ONLY A SINGLE pe contribution (par[9] = n).
// This will allow us to draw a deconvoluted picture of the fit.
Double_t low_light_model_pe(Double_t *x, Double_t *par){

        // Grab current x value, current pe, and prepare variables
        Int_t n = (int)(par[9]);
        Double_t qn, sigma_n, term_1, term_11, term_2, term_3, igne, gn, igne_is;

        // Calculate values to be used for this PE 
        qn = par[1] + n * par[5];                               // mean of this PE dist
        sigma_n = sqrt(pow(par[2],2) + n * pow(par[6],2));      // sigma of this PE dist
        term_1 = x[0] - qn - par[3] * pow(sigma_n,2);             // expo and erf argument
        term_11 = x[0] - qn - par[3] * pow(sigma_n,2) / 2.0;      // Error or correction
        term_2 = par[1] - qn - par[3] * pow(sigma_n,2);         // Erf argument
        term_3 = x[0] - qn;                                       // x[0] shifted by PE mean

        // Calculate igne
        // Depending on which side of the PE distribution we are on, add or subtract in parentheses
        if (term_1 >= 0.) {
                igne =  par[3] / 2.0 * exp(-par[3] * term_11) *
                        (
                                TMath::Erf(fabs(term_2) / sqrt(2.0) / sigma_n) +
                                TMath::Erf(fabs(term_1) / sqrt(2.0) / sigma_n)
                        );
        } else {
                igne =  par[3] / 2.0 * exp(-par[3] * term_11) *
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

Double_t low_light_model_pe_no_expo(Double_t *x, Double_t *par){

        // Grab current x value, current pe, and prepare variables
        Int_t n = (int)(par[9]);
        Double_t qn, sigma_n, gn;

        // Calculate values to be used for this PE 
        qn = par[1] + n * par[5];                               // mean of this PE dist
        sigma_n = sqrt(pow(par[2],2) + n * pow(par[6],2));      // sigma of this PE dist
        gn = exp(-pow(x[0] - qn, 2) / 2.0 / pow(sigma_n, 2)) / (sqrt(twopi) * sigma_n);

        // Put it all together and return
        return TMath::PoissonI(n, par[4]) * par[8] * gn;

}

// The model used here is described in a NIM publication in the "docs" directory.
Double_t low_light_model(Double_t *x, Double_t *par){
        Double_t s_real_sum = 0.;
        Double_t initial_par9 = par[9];
        for (int i = (int)(par[9]); i < (int)(par[10]); i++) {
                par[9] = (double)(i);
                s_real_sum += low_light_model_pe(x, par);
        }
        par[9] = initial_par9;
        Double_t s_bg = low_light_model_bg(x, par);
        return s_real_sum + s_bg;
}

// This is the same as the above model, except the exponential decay
// is not included in the background
Double_t low_light_pmt_model_without_expo_in_pedestal(Double_t *x, Double_t *par) {
        Double_t s_real_sum = 0.;
        Double_t initial_par9 = par[9];
        for (int i = (int)(par[9]); i < (int)(par[10]); i++) {
                par[9] = (double)(i);
                s_real_sum += low_light_model_pe(x, par);
        }
        par[9] = initial_par9;
        Double_t s_bg = low_light_model_bg_no_expo(x, par);
	
        return s_real_sum + s_bg;
}

// This function assumes that there is a certain likelihood of a double-PE 
// ejection for a single photon (motivated by studying many fits).
Double_t double_fit_pmt_bg(Double_t *x, Double_t *par) {
        // Get param vector for low_light_model_pe
        Double_t par2[11] = {   par[0], par[1], par[2], par[3], par[4],
                                par[5], par[6], par[7], par[8], par[9], par[10] };
        // Return total
        return low_light_model_bg(x, par2);
}

// This function assumes that there is a non-zero probability
// of experiencing a different light level than provided (cosmic ray)
Double_t double_fit_pmt_pe(Double_t *x, Double_t *par) {
        // Get param vector for low_light_model_pe
        Double_t par2[11] = {   par[0], par[1], par[2], par[3], par[4],
                                par[5], par[6], par[7], par[8], par[9], par[10] };
        return (1.0 - par[11]) * low_light_model_pe(x, par2);
}

// This function computes the PE contribution from the extra light source
Double_t double_fit_pmt_pe2(Double_t *x, Double_t *par) {
        // Get param vector for low_light_model_pe
        Double_t par2[11] = {   par[0], par[1], par[2], par[3], par[12],
                                par[5], par[13], par[7], par[8], par[9], par[10] };
        return par[11] * low_light_model_pe(x, par2);
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

// These plots model the gain vs voltage curve for the 6 tubes
Double_t power_curve(Double_t *x, Double_t *par){ return par[0] * TMath::Power(x[0] / par[1] / 100.0, par[1]); }
Double_t power_curve_hamamatsu(Double_t *x, Double_t *par){ return par[0] * (x[0] * 4.0 / 1400.0) * (x[0] / 1400.0) * (x[0] * 2.0 / 1400.0) * (x[0] / 1400.0) * (x[0] / 1400.0) * (x[0] / 1400.0) * (x[0] / 1400.0) * (x[0] * 2.0/ 1400.0) * (x[0] / 1400.0); }
Double_t power_curve_et_a(Double_t *x, Double_t *par){ return par[0] * (x[0] * 3.0 / 1300.0) * (x[0] / 1300.0) * (x[0] / 1300.0) * (x[0] / 1300.0) * (x[0] / 1300.0) * (x[0] / 1300.0) * (x[0] / 1300.0) * (x[0] / 1300.0) * (x[0] / 1300.0) * (x[0] / 1300.0) * (x[0] / 1300.0); }
Double_t power_curve_et_b(Double_t *x, Double_t *par){ return par[0] * (x[0] * 3.0 / 2100.0) * (x[0] / 2100.0) * (x[0] / 2100.0) * (x[0] / 2100.0) * (x[0] / 2100.0) * (x[0] / 2100.0) * (x[0] / 2100.0) * (x[0] * 2.0 / 2100.0) * (x[0] * 3.0 / 2100.0) * (x[0] * 4.0 / 2100.0) * (x[0] * 3.0 / 2100.0); }

// Three gaussians for modeling v965 pedestal
Double_t triple_gaus(Double_t *x, Double_t *par) {
	Double_t gaus1 = par[0] * exp( - pow((x[0] - par[1]) / par[2], 2) / 2);
	Double_t gaus2 = par[3] * exp( - pow((x[0] - par[4]) / par[5], 2) / 2);
	Double_t gaus3 = par[6] * exp( - pow((x[0] - par[7]) / par[8], 2) / 2);
	return gaus1 + gaus2 + gaus3;
}

