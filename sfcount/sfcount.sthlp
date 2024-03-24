{smcl}
{* *! version 1.1.1  10jul2018}{...}
{viewerjumpto "Title" "sfcount##title"}{...}
{viewerjumpto "Syntax" "sfcount##syntax"}{...}
{viewerjumpto "Description" "sfcount##description"}{...}
{viewerjumpto "Options" "sfcount##options"}{...}
{viewerjumpto "Remarks" "sfcount##remarks"}{...}
{viewerjumpto "Example" "sfcount##example"}{...}
{viewerjumpto "References" "sfcount##references"}{...}
{viewerjumpto "Authors" "sfcount##authors"}{...}
{viewerjumpto "Also see" "sfcount##alsosee"}{...}
{cmd:help sfcount}{right: ({browse "https://doi.org/10.1177/1536867X20953566":SJ20-3: st0607})}
{hline}

{marker title}{...}
{title:Title}

{p2colset 5 16 18 2}{...}
{p2col :{cmd:sfcount} {hline 2}}Count-data stochastic frontier model{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:sfcount}
{depvar} {indepvars}
{ifin}
[{cmd:,} {it:options}]

{pstd}
where {it:depvar} is the dependent variable and {it:indepvars} are the
explanatory variables.

{synoptset 20}{...}
{synopthdr}
{synoptline}
{synopt:{opt draws(#)}}number of Halton draws; default is {cmd:draws(200)}{p_end}
{synopt:{opt technique(string)}}specify the optimization technique{p_end}
{synopt:{opt cost}}cost function; default is production
function/underreporting{p_end}
{synopt:{opt cluster(string)}}specify the name of a variable that creates 
intragroup correlation, relaxing the usual requirement that the
observations be independent{p_end}
{synopt:{opt vce(vcetype)}}specify how the variance-covariance matrix of the estimators is to be calculated{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:sfcount} fits a stochastic frontier model for a discrete dependent
variable, assuming that the probability of a nonnegative outcome is determined
by a mixed Poisson distribution with a log-half-normal mixing parameter.  This
model can be used to estimate the inefficiency in an observed numbers of
counts.  It can also be used for modeling underreported counts as well as
overreported counts.  {cmd:sfcount} can compute cluster-robust standard
errors.


{marker options}{...}
{title:Options}

{phang}
{opt draws(#)} specifies the number of Halton draws.  The default is
{cmd:draws(200)}.  The model is fit via maximum simulated likelihood.  To
approximate the likelihood function of the Poisson log-half-normal model, the
command uses Halton sequences (a low-discrepancy sequence).  Halton sequences
ensure a good coverage of the unit interval.

{phang}
{opt technique(string)} specifies the optimization technique.  The default is
{cmd:technique(nr)}, which is the modified Newton-Raphson.  You can switch
between {cmd:dfp} (Davidon-Fletcher-Powell), {cmd:bhhh}
(Berndt-Hall-Hall-Hausman), and {cmd:bfgs} (Broyden-Fletcher-Goldfarb-Shanno).

{phang}
{opt cost} specifies that the underlying model is a cost function (or,
equivalently, an overreporting or deviation above the minimum-level function).
By default, {cmd:sfcount} estimates a production function (or, equivalently,
an underreporting or deviation below the maximum-level function).

{phang}
{opt cluster(string)} specifies the name of a variable that creates intragroup
correlation, relaxing the usual requirement that the observations be
independent.

{phang}
{opt vce(vcetype)} specifies how the variance-covariance matrix of the
estimators is to be calculated.   Allowed values are the following:

{col 16}{it:vcetype}{col 32}Description
{col 16}{hline 54}
{col 16}{cmd:""}{col 32}use default for {helpb mf_moptimize##def_technique:technique()}
{col 16}{cmd:oim}{col 32}observed information matrix
{col 16}{cmd:opg}{col 32}outer product of gradients
{col 16}{cmd:robust}{col 32}Huber/White/sandwich estimator
{col 16}{cmd:svy}{col 32}survey estimator; equivalent to {cmd:robust}
{col 16}{hline 54}
{col 16}The default is {cmd:vce(oim)} except for {cmd:technique(bhhh)}, 
{col 16}where it is {cmd:vce(opg)}.  If {cmd:cluster()} 
{col 16}is used, the default becomes {cmd:vce(robust)}.


{marker remarks}{...}
{title:Remarks}

{pstd}
The command automatically creates a new variable called {cmd:inefficiency},
which holds the cross-sectional inefficiency scores (obtained following
Jondrow et al. [1982]).


{marker example}{...}
{title:Example}

{pstd}
This example helps users to reproduce the results in section 5 of F{c e'} and
Hofler (2020).  The section illustrates the use of the {cmd:sfcount} command
to model the conditional distribution of infant deaths in England during 2015
and 2016.

{pstd}
Infant deaths have a large opportunity cost for societies and constitute a
marker of the overall health status of a population.  Commonly cited risk
factors are parental risk behavior, pollution, economic deprivation, and the
quality of health providers, although a large proportion of infant deaths are
not attributable to any specific cause (and are cataloged as sudden infant
death syndrome).  If the latter deaths are not randomly distributed across the
population, we are likely to observe systematic variation in deaths across
different areas even after accounting for the distribution of risk factors in
these areas.  This count-data stochastic frontier model can help us to detect
which areas overreport infant deaths conditional on the area's characteristics
(that is, which areas are figuratively inefficient in the "production" of
infant deaths).

{pstd}
To load the data, we use the command

{phang2}
{cmd:. use infant_deaths}{p_end}

{pstd}
We can obtain descriptive statistics using the {cmd:estpost} command, which
can be downloaded and installed as part of the {cmd:estout} package
(Jann 2004):

{phang2}{cmd:. ssc install estout}

{pstd}
After installing the package, produce a table of descriptive statistics as
follows:

{phang2}{cmd:. estpost tabstat deaths nitrogenOxide-Pop employment year2 reg1-reg9, listwise statistics(mean sd min max) columns(statistics)}

{pstd}
Subsequently, a histogram for the distribution of infant deaths can be
obtained as follows

{phang2}{cmd:. histogram deaths, discrete fcolor(black) lcolor(black) barwidth(0.5) gap(2)}

{pstd}
We can then fit various Poisson log-half-normal models by varying the
structure of the conditional mean.  In particular, the four models included in
the accompanying article are obtained as follows:

{phang2}{cmd:. sfcount deaths logPop, cost}

{phang2}{cmd:. sfcount deaths underweight benefits employment logPop, cost}

{phang2}{cmd:. sfcount deaths nitrogenOxide underweight benefits employment logPop, cost}

{phang2}{cmd:. sfcount deaths nitrogenOxide underweight benefits employment logPop year2 reg2-reg9, cost}

{pstd}
Finally, we can explore the distribution of inefficiency.  Descriptive
statistics for this variable can be readily obtained,

{phang2}{cmd:. summarize inef, detail}

{pstd}
whereas the distribution of this variable across regions can be calculated as
follows:

{phang2}{cmd:. estpost tabstat inef, by(region) listwise statistics(mean sd min max) columns(statistics)}


{marker references}{...}
{title:References}

{phang}
F{c e'}, E., and R. Hofler. 2020. sfcount: Command for count-data stochastic
frontiers and underreported and overreported counts.
{it:Stata Journal} 20: 532-547.
{browse "https://doi.org/10.1177/1536867X20953566"}.

{phang}
Jann, B. 2004. estout: Stata module to make regression tables.  Statistical
Software Components S439301, Department of Economics, Boston College.
{browse "https://ideas.repec.org/c/boc/bocode/s439301.html"}.

{phang}
Jondrow, J., C. A. K. Lovell, I. S. Materov, and P. Schmidt. 1982.
On the estimation of technical inefficiency in the stochastic frontier
production function model.
{it:Journal of Econometrics} 19: 233-238.
{browse "https://doi.org/10.1016/0304-4076(82)90004-5"}.


{marker authors}{...}
{title:Authors}

{pstd}
Eduardo F{c e'}{break}
University of Manchester{break}
Manchester, UK{break}
eduardo.fe@manchester.ac.uk

{pstd}
Richard Hofler{break}
University of Central Florida{break}
Orlando, FL{break}
richard.hofler@ucf.edu


{marker alsosee}{...}
{title:Also see}

{p 4 14 2}
Article:  {it:Stata Journal}, volume 20, number 3: {browse "https://doi.org/10.1177/1536867X20953566":st0607}{p_end}
