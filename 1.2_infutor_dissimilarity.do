************************************************************************************
**** This do file calculates quarterly dissimilarity index using Verisk data     ***
**** (Figure 1b)                                                                 ***
************************************************************************************

******* Calculate tract population using move-ins, move-outs, and population in the preivous period
use "/data/movein_moveout_tract_quarter.dta", clear

gen totalpop_adj = x if year_quarter==tq(2017q1)
bysort tract_2010 (year_quarter): replace totalpop_adj = totalpop_adj[_n-1] + move_in - move_out if year_quarter>=tq(2017q2)

gen race_combined_final_white_adj = race_combined_final_white if year_quarter==tq(2017q1)
bysort tract_2010 (year_quarter): replace race_combined_final_white_adj = race_combined_final_white_adj[_n-1] + move_in_white - move_out_white if year_quarter>=tq(2017q2)

gen race_combined_final_black_adj = race_combined_final_black if year_quarter==tq(2017q1)
bysort tract_2010 (year_quarter): replace race_combined_final_black_adj = race_combined_final_black_adj[_n-1] + move_in_black - move_out_black if year_quarter>=tq(2017q2)

******* Extract in-movers and out-movers data from the corresponding quarters in 2019
foreach var in move_in_white move_in_black move_out_white move_out_black {
	forvalues i = 1/4 {
		gen `var'_q`i' = `var' if year_quarter==tq(2019q`i')
		bysort tract_2010 (year_quarter): egen `var'_q`i'_tract = max(`var'_q`i')
		drop `var'_q`i'
	}
}

****************** Counterfactual: inflate the number based on total population in the city
tabstat totalpop_adj, by(year_quarter) s(sum)
/*
2019q1	6392683
2019q2	6397441
2019q3	6419529
2019q4	6423722
*/

* Create inflation factor: adjusting the number of inmovers and outmovers based on the total population in that year v.s. the population in analagous quarter in 2019
gen pop_2019q1 = 6392683
gen pop_2019q2 = 6397441
gen pop_2019q3 = 6419529
gen pop_2019q4 = 6423722

* total population by quarter
bysort year_quarter: egen total_pop_quarter = total(totalpop_adj) 
tab year_quarter total_pop_quarter

gen inflation=.
forvalues i=1/4 {
	replace inflation = total_pop_quarter/pop_2019q`i' if year_quarter>=tq(2020q3) & quarter==`i' //what is the population in the quarter relative to 2019qX?
}

* Extract counterfactual inmovers/utmovers of different racical groups using the number from corresponding quarters in 2019 adjusted for population variation over time
foreach var in move_in_white move_in_black move_out_white move_out_black {
	gen `var'_cf= `var' if year_quarter<=tq(2020q2)
	bysort tract_2010 (year_quarter): replace `var'_cf = `var'_q1_tract*inflation if year_quarter>=tq(2020q3) & quarter==1
	bysort tract_2010 (year_quarter): replace `var'_cf = `var'_q2_tract*inflation if year_quarter>=tq(2020q3) & quarter==2
	bysort tract_2010 (year_quarter): replace `var'_cf = `var'_q3_tract*inflation if year_quarter>=tq(2020q3) & quarter==3
	bysort tract_2010 (year_quarter): replace `var'_cf = `var'_q4_tract*inflation if year_quarter>=tq(2020q3) & quarter==4
}

* Counterfactual - white inmovers only
gen race_combined_final_white_inw = race_combined_final_white if year_quarter==tq(2017q1)
bysort tract_2010 (year_quarter): replace race_combined_final_white_inw = race_combined_final_white_inw[_n-1] + move_in_white_cf - move_out_white if year_quarter>=tq(2017q2)

* Counterfactual - white outmovers only
gen race_combined_final_white_outw = race_combined_final_white if year_quarter==tq(2017q1)
bysort tract_2010 (year_quarter): replace race_combined_final_white_outw = race_combined_final_white_outw[_n-1] + move_in_white - move_out_white_cf if year_quarter>=tq(2017q2)

* Counterfactual - black inmovers only
gen race_combined_final_black_inb = race_combined_final_black if year_quarter==tq(2017q1)
bysort tract_2010 (year_quarter): replace race_combined_final_black_inb = race_combined_final_black_inb[_n-1] + move_in_black_cf - move_out_black if year_quarter>=tq(2017q2)

* Counterfactual - black outmovers only
gen race_combined_final_black_outb = race_combined_final_black if year_quarter==tq(2017q1)
bysort tract_2010 (year_quarter): replace race_combined_final_black_outb = race_combined_final_black_outb[_n-1] + move_in_black - move_out_black_cf if year_quarter>=tq(2017q2)


******** Merge with tract characteristics ********* 
cap drop _merge
merge m:1 tract_2010 using "/data/infutor/liao/migration/data/tract_2010.dta", keepusing(tract_pct_black tract_pct_white tract_pct_aapi tract_pct_hispanic tract_med_hhinc popdens_sqmi tract_pct_own tract_gross_rent empire tract_pct_college)

cap drop tract_pct_white_group
gen tract_pct_white_group = 1 if tract_pct_white<0.1
replace tract_pct_white_group = 2 if tract_pct_white>=0.1 & tract_pct_white<0.3
replace tract_pct_white_group = 3 if tract_pct_white>=0.3 & tract_pct_white<0.6
replace tract_pct_white_group = 4 if tract_pct_white>=0.6 & tract_pct_white<0.9
replace tract_pct_white_group = 5 if tract_pct_white>0.9 & !missing(tract_pct_white)

tabstat move_in_white move_in_white_cf if tract_pct_white_group ==1, s(sum) by(year_quarter)
tabstat move_in_white move_in_white_cf if tract_pct_white_group ==2, s(sum) by(year_quarter)
tabstat move_in_white move_in_white_cf if tract_pct_white_group ==3, s(sum) by(year_quarter)
tabstat move_in_white move_in_white_cf if tract_pct_white_group ==4, s(sum) by(year_quarter)
tabstat move_in_white move_in_white_cf if tract_pct_white_group ==5, s(sum) by(year_quarter)

tabstat move_out_white move_out_white_cf if tract_pct_white_group ==1, s(sum) by(year_quarter)
tabstat move_out_white move_out_white_cf if tract_pct_white_group ==2, s(sum) by(year_quarter)
tabstat move_out_white move_out_white_cf if tract_pct_white_group ==3, s(sum) by(year_quarter)
tabstat move_out_white move_out_white_cf if tract_pct_white_group ==4, s(sum) by(year_quarter)
tabstat move_out_white move_out_white_cf if tract_pct_white_group ==5, s(sum) by(year_quarter)

tempfile white_black
tempfile white_black_adj
tempfile white_black_inw
tempfile white_black_outw
tempfile white_black_inb
tempfile white_black_outb

seg race_combined_final_white_adj race_combined_final_black_adj, d by(year_quarter) file(`white_black_adj') replace
seg race_combined_final_white_inw race_combined_final_black_adj, d by(year_quarter) file(`white_black_inw') replace
seg race_combined_final_white_outw race_combined_final_black_adj, d by(year_quarter) file(`white_black_outw') replace
seg race_combined_final_white_adj race_combined_final_black_inb, d by(year_quarter) file(`white_black_inb') replace
seg race_combined_final_white_adj race_combined_final_black_outb, d by(year_quarter) file(`white_black_outb') replace

use `white_black', clear
keep year Dseg 
rename Dseg white_black_dis
merge 1:1 year using `white_black_adj'
keep year Dseg 
rename Dseg white_black_dis_adj

merge 1:1 year using `white_black_inw'
rename Dseg white_black_dis_inw
drop _merge
merge 1:1 year using `white_black_outw'
rename Dseg white_black_dis_outw
drop _merge
merge 1:1 year using `white_black_inb'
rename Dseg white_black_dis_inb
drop _merge
merge 1:1 year using `white_black_outb'
rename Dseg white_black_dis_outb

****** Quarterly dissimilarity index (Figure 3)
format white_black_dis_adj white_black_dis_adj white_black_dis_adj white_black_dis_adj %10.2g

twoway connected white_black_dis_adj white_black_dis_inw year_quarter, title("Dissimilarity Index: white in-movers fixed at 2019 level", size(*1.4)) ytitle("") ysc(r(0.78 0.83)) ylabel(0.78(0.01)0.83, labsize(*1.1))  xsc(r(228 250)) xlabel(228(2)250, labsize(*1.5) angle(45)) ylabel(,labsize(*1.5)) legend(size(*1.6) pos(6) label(1 "Actual") label (2 "Counterfactual: fixed white in-movers")) xtitle("Year-Quarter")  lpattern(1 dash 2 solid) xline(242 246, lpattern(dash) lcolor(gray))
graph export "/output/infutor_dissim_white_black_dis_inw.png", replace

twoway connected white_black_dis_adj white_black_dis_outw year_quarter, title("Dissimilarity Index: white out-movers fixed at 2019 level", size(*1.4)) ytitle("") ysc(r(0.78 0.83)) ylabel(0.78(0.01)0.83, labsize(*1.1)) xsc(r(228 250)) xlabel(228(2)250, labsize(*1.5) angle(45)) ylabel(,labsize(*1.5)) legend(size(*1.6) pos(6) label(1 "Actual") label (2 "Counterfactual: fixed white out-movers")) xtitle("Year-Quarter") lpattern(1 dash 2 solid) xline(242 246, lpattern(dash) lcolor(gray))
graph export "/output/infutor_dissim_white_black_dis_outw.png", replace

twoway connected white_black_dis_adj white_black_dis_inb year_quarter, title("Dissimilarity Index: Black in-movers fixed at 2019 level",  size(*1.4)) ytitle("") ysc(r(0.78 0.83)) ylabel(0.78(0.01)0.83, labsize(*1.6)) xsc(r(228 250)) xlabel(228(2)250, labsize(*1.5) angle(45))  legend(size(*1.6) pos(6) label(1 "Actual") label (2 "Counterfactual: fixed black in-movers")) xtitle("Year-Quarter")  lpattern(1 dash 2 solid) xline(242 246, lpattern(dash) lcolor(gray)) 
graph export "/output/infutor_dissim_white_black_dis_inb.png", replace

twoway connected white_black_dis_adj white_black_dis_outb year_quarter, title("Dissimilarity Index: Black out-movers fixed at 2019 level", size(*1.4)) ytitle("") ysc(r(0.78 0.83)) ylabel(0.78(0.01)0.83, labsize(*1.1))  xsc(r(228 250)) xlabel(228(2)250, labsize(*1.5) angle(45)) ylabel(,labsize(*1.6)) legend(size(*1.4) pos(6) label(1 "Actual") label (2 "Counterfactual: fixed black out-movers")) xtitle("Year-Quarter")  lpattern(1 dash 2 solid) xline(242 246, lpattern(dash))
graph export "/output/infutor_dissim_white_black_dis_outb.png", replace

****** Spline regression (Figure 1b)
cap drop xyear_quarter*
mkspline xyear_quarter1 241 xyear_quarter2 245 xyear_quarter3 = year_quarter //241 is 2020q2 and 245 is 2021q2
cap drop int*
generate int2 = 1 
replace  int2 = 0 if year_quarter<=tq(2020q2) | year_quarter>tq(2021q2)
generate int3 = 1 
replace  int3 = 0 if year_quarter<=tq(2021q2) 

reg white_black_dis_adj xyear_quarter1 xyear_quarter2 xyear_quarter3 int2 int3,r
cap drop yhat_whiteblack_adj
predict yhat_whiteblack_adj
	 
twoway line yhat_whiteblack_adj year_quarter if year_quarter<=241, sort || ///
	 line yhat_whiteblack_adj year_quarter if year_quarter>=242 & year_quarter<=245, sort || ///
	 line yhat_whiteblack_adj year_quarter if year_quarter>=246, sort || ///
     scatter white_black_dis_adj year_quarter, mcolor(blue%30) xsc(r(228 250)) xlabel(228(2)250 ,angle(45) labsize(large))  xline(242 246, lpattern(dash) lcolor(gray)) legend(off) xtitle("Year-Quarter", size(large)) yscale(range(0.77(0.01)0.83)) ylabel(0.77(0.01)0.83, labsize(large)) title(Dissimilarity Index: White-Black (Infutor), size(large)) 

graph export "/output/spline_whiteblack_seg_new.png", replace

**** Segmented regression - interaction terms
cap drop group
gen group = 1 if year_quarter<=tq(2020q2)
replace group = 2 if year_quarter>=tq(2020q3)& year_quarter<=tq(2021q2)
replace group = 3 if year_quarter>=tq(2021q3)
tab year_quarter group
label define group 1"2017q1-2020q2" 2"2020q3-2021q2" 3"2021q3-2022q3"
label values group group

eststo clear

gen quarter = quarter(dofq(year_quarter))

reg white_black_dis_adj c.year_quarter##i.group i.quarter,r 