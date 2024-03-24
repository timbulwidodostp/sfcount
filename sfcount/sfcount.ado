//clear mata
// program drop sfcount
/*

	COUNT DATA STOCHASTIC FRONTIER MODEL (CDSF)

	Code by Eduardo Fe (University of Manchester)
	
	This version: 14 July 2019
	
	Developed using Stata v.15.
	
	
	The Stata command cdsf estimates the Poisson Log-Half-Normal model 
	in Fe, E. and Hofler, R. (2013) "Count Data Stochastic Frontier Models, 
	with an application to the patents-R&D Relationship", Journal of 
	Productivity Analysis.
	
	A NOTE ABOUT THE CROSS-SECTIONAL INEFFICIENCY SCORES.
	
	The cross-sectional inefficiency scores are calculated following Jondrow et
	al (1982). Specifically, the scores depend on P(exp(x'b +/- s|fhat|)) where
	s is the variance of the inefficiency variable and fhat is a draw from a 
	normal distribution. If the mean of this distribution, exp(x'b +/- s|fhat|), 
	is too large in relation to Y for any one observation, then 
	P(exp(x'b +/- s|fhat|)) will be approximately 0. Therefore, for that 
	observation the cross-sectional estimate of inefficiency will be 0/0 which
	Stata reports as missing value. 
	
	We thus recommend researchers to ensure that the explanatory variables are
	handle in meaningful units, albeit of small magnitude. 


*/

program sfcount, rclass
	
	syntax varlist [if] [in] [,COST draws(int 200) cluster(string) ///
		technique(string) vce(string)]
	
	capture confirm variable inefficiency
	
	if (_rc==0) {
		di in red "Variable inefficiency exists; please delete or rename"
		
	}
	else  {
			
		gettoken y xvars : varlist
			
		marksample touse
		
		qui gen  ___mytemp = `touse'
		
		recast byte ___mytemp 		//required for clustered standard errors.
		
		if("`technique'"=="bhhh"){
		
			local technik = "bhhh"
		
		}
		else if ("`technique'"=="bfgs"){
		
			local technik = "bfgs"
		}
		else if ("`technique'"=="dfp"){
		
			local technik = "dfp"
		}
		else{
			
			local technik = "nr"
		}
		
		qui poisson `y' `xvars' if `touse'
		
		local logLike_p = e(ll)
		
		qui gen inefficiency=.
		
		if "`cost'" != "" { 
			local cst = 1 
		}
		else {
			
			local cst = 0
		} 
		
		mata: fn("`y'", "`xvars'", `draws', `cst', "`cluster'", "`technik'", "`vce'")
		
		qui replace inefficiency = . if !___mytemp
		
		drop ___mytemp
		
		local logLike_phn = logLike_phn
		
 		local chi2_test = 2*(`logLike_phn' - `logLike_p')
		local chi2_tail = chi2tail(1, 2*(`logLike_phn' - `logLike_p'))
		return scalar chi2_test = `chi2_test'
		return scalar chi2_tail = `chi2_tail'
		di as input "Note: _cons in eq2 corresponds to the log of the standard error"
		di as input "of the mixing log-half-normal parameter"
		di  ""
		di as input "Ho: Inefficiency not present in the sample"
		di as input "chi2(1) =  " _column(16) %9.2f  2*(`logLike_phn' - `logLike_p')
		di as input "Prob > chi2 = " _column(16) %9.2f  chi2tail(1, 2*(`logLike_phn' - `logLike_p'))
		
	}
	
end 
 
 
clear mata
mata:

 

void ehat(transmorphic M, string scalar dep, string scalar xvars){

	real scalar N, K, s
	
	real matrix mH, fhat, beta, mX, theta, sh,  vY, kernel, phat, num, den, uhat, xhat, xhatsh, term1, term2, term3, vY1, lphat
	
	external draws
	
	external sign
	
	external lds
	
	mH = lds 
	
	fhat = invnormal(mH)
		
	theta =  moptimize_result_eq_coefs(M [, 1])
	
	mX = st_data(.,xvars)
	
	vY = st_data(.,dep)
	
	N = rows(mX)
	
	K = cols(theta)
	
	beta = theta[1..K-1]'
	
	s = exp(theta[K])	
		
	mX = (mX,J(N,1,1) )
	
	xhat = mX*beta		
	
	sh = J(N,1,1)#sign*s*abs(fhat) 
	
	kernel = exp(xhat :+ sh)
	
	//phat = poissonp(kernel, vY)
	
	// We don't use poissonp to compute the mass function.
	// This is because it returns missing value for relatively large 
	// (but reasonable) values of Y. Instead, we compute the mass function
	// as follows
	
	// 1. Compute exp(xb) using the expression exp(x) = 2^( x/ln(2)) 
		xhatsh = xhat :+ sh
 		term1 = (-1) * (2 :^ (xhatsh / ln(2)))
		 
	// 2. Compute y*xb
		term2 = vY :* xhatsh
		 
	// 3. Computer log factorial using the following approximation
		vY1 = vY :+ 1
		term3 = (vY1:-0.5):*ln(vY1) :- vY1 :+ 0.5*ln(2*pi()) :+ (1:/(12*vY1))
		lphat = term1 :+ term2 :-term3
	
	// 4. Compute phat.
	phat = exp(lphat)
	// End method.
	
	den = rowsum(phat)
	
	num = rowsum(exp(sh) :* phat)
	
	uhat = num:/den
	
	st_store(.,"inefficiency", uhat)
	
	
}

function cdsf(transmorphic M, real rowvector b, real colvector lnf)
{
	real scalar D, R, start
	
	real matrix mH, fhat, xb, s, y, q, d, c 
	
	external draws
	
	external sign
	
	external lds
		
	R = draws // Number of Halton draws
	 
	D = 1 // Number of mixing variables (just one for the base model)
	
	start = 50 // Starting point of the Halton sequence.
	
	mH = lds 
	
	fhat = invnormal(mH)
	
	xb = moptimize_util_xb(M, b, 1)
	
	s = moptimize_util_xb(M, b, 2)
	
	y = moptimize_util_depvar(M,1)
	
	s = exp(s)
	  
	d = sign * (s :* J(rows(y),1,1)#abs(fhat) )
	
	c = exp(xb :+ d )
	
	lnf=ln(rowsum(poissonp(c, y))/R)
	 
}

void fn(string scalar dep, ///
			string scalar xvars, ///
			real scalar R, ///
			real scalar cost, ///
			string scalar clustervar, 
			string scalar technique,
			string scalar vcetype)
{
	
	external real scalar draws
	
	external real scalar sign
	
	external real vector lds
	
	lds = halton(R, 1, 100)'

	draws = R

	if(cost == 0) {
	
		sign = -1
	}
	else if (cost == 1) {
		
		sign = 1
	}
	
	transmorphic M
	
	M = moptimize_init()
		moptimize_init_conv_maxiter(M, 50)
		moptimize_init_conv_warning(M, "on")
		moptimize_init_touse(M, "___mytemp")
		moptimize_init_evaluator(M, &cdsf())
		moptimize_init_evaluatortype(M, "lf")
		moptimize_init_depvar(M, 1, dep)
		moptimize_init_eq_indepvars(M, 1, xvars)
		moptimize_init_eq_indepvars(M, 2, "")
		moptimize_init_eq_cons(M, 1, "on" ) 
		moptimize_init_technique(M, technique)
		moptimize_init_cluster(M, clustervar)
		moptimize_init_vcetype(M, vcetype)
		moptimize(M)
		moptimize_result_display(M)
		moptimize_result_post(M)
		
	
	
	real scalar logLike
	logLike = moptimize_result_value(M) 
	 
	st_numscalar("logLike_phn", logLike)
	
	
	ehat(M, dep, xvars)
 
}



end
