************************************************************************************
**** This script calculates dissimilarity index using ACS 5-year tract-level data***
**** (Figure 1a)                                                                 ***
************************************************************************************
* https://nariyoo.com/stata-calculating-segregation-indices-using-seg-and-getcensus-packages/
* ssc install seg
* Use tract-level population data created with 0_extract_ACS_tract_population.R
use "/data/tract_acs_seg_index.dta", clear

rename geoid tract
destring tract, replace force
format tract %11.0f
gen nonwhite = pop_num- pop_race_white_num

***** Dissimilarity index
tempfile white_black
tempfile white_nonwhite

seg pop_race_white_num pop_race_black_num , d x by(year) file(`white_black') replace
seg pop_race_white_num nonwhite, d x by(year) file(`white_nonwhite') replace

use `white_black', clear
keep year Dseg Xseg
rename Dseg white_black_dis
rename Xseg white_black_exp
merge 1:1 year using `white_nonwhite'
rename Dseg white_nonwhite_dis
rename Xseg white_nonwhite_exp
keep year white_*

***** Plot dissimilarity over time
label var white_black_dis "White - Non-Hispanic Black"
label var white_nonwhite_dis "White - Non-white"

* white-black dissimilarity (Figure 1a)
format  white_black_dis %10.2g
twoway connected white_black_dis year if year>=2017, title("Dissimilarity Index: White-Black (ACS 5-year data)",size(large)) ytitle("Dissim. Index") xscale(r(2017 2022)) xlabel(2017(1)2022,labsize(large)) legend(position(5)) yscale(range(0.77 0.83)) ylabel(0.77(0.01)0.83, labsize(large))

* white-nonwhite dissimilarity
format  white_nonwhite_dis %10.2g
twoway connected white_nonwhite_dis year if year>=2017, title("Dissimilarity Index: White - Non-white (ACS 5-year data)") ytitle("Dissim. Index") note("Calculated at the census tract level in NYC") xscale(r(2017 2022)) xlabel(2017(1)2022,labsize(large)) legend(position(5)) ylabel(, labsize(large))
