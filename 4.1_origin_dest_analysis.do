************************************************************************************************
** Run individual-level OLS by exploring the origin v.s. destination characteristics (Figure 5)
************************************************************************************************

use "/data/mobility_random_add_quarter_ready.dta", clear

**** Merge with individual-level income data
merge m:1 pid year using "/data/infutor/liao/migration/data/pid_income_by_year.dta"
drop if _merge==2
drop _merge

tab above_median, mis

gen miss_hhinc = missing(above_median)

gen above_median_adj = above_median
replace above_median_adj = 2 if missing(above_median_adj)

tab above_median_adj miss_hhinc,mis

label define above_median 0"lower income" 1"higher income" 2"income missing"
label values above_median above_median_adj above_median
label var above_median_adj "Income level (individual)"

**** Merge with CD-level rent deviation
gen bbl_qdate=year_quarter

merge m:1 bbl_qdate cd using "/data/infutor/liao/migration/data/rent_resid_listing_pretrendonly_cd_yq.dta"
drop if _merge==2

label var mean_pretrend_resid3 "CD 2-bedroom meidan rent deviation from trend (log actual - log predicted)"
label var median_log_price3 "CD 2-bedroom meidan rent (log)"

drop _merge

merge m:1 bbl_qdate cd using "/data/infutor/liao/migration/data/rent_resid_listing_pretrendonly_cd_yq_lag.dta", keepusing(mean_pretrend_resid_lag mean_logprice_lag median_logprice_lag)
drop if _merge==2

label var mean_pretrend_resid_lag "CD 2-bedroom rent deviation (log actual - log predicted) -- lag 1 quarter"
label var median_logprice_lag "CD 2-bedroom rent (log median) -- lag 1 quarter"
label var mean_logprice_lag  "CD 2-bedroom rent (log mean)-- lag 1 quarter"

drop _merge

***** Keep only movers
keep if move_anyS==1 & nyc==1
tab nyc_pre,mis

*********** Sample: Movers that moved within OR into NYC -- origin vs destination neighborhood
tab race_final,mis

**** Relabel 
lab define race 1 "AAPI" 2 "Hispanic" 3 "Non-Hispanic Black" 4 "Non-Hispanic White", replace
label values race_final race

gen tract_id_pre_adj = tract_id_pre
replace tract_id_pre_adj=0 if tract_id_pre_adj==.

***** Property characteristics
tab prop_status_detail_v1, nol
replace prop_status_detail_v1=8 if prop_status_detail_v1==.

******************************************** DV: Destination tract share white **********************************
***** Origin tract FE -- no destination control
eststo clear

eststo: reghdfe tract_pct_white ib1.covid_ind##ib4.race_final##i.above_median_adj ib25.age_bin ib1.gend if move_any_last5==1 & nyc==1 & above_median_adj!=2, absorb(tract_id_pre)

* marginal effect
margins r.covid_ind@race_final, at(above_median_adj=(0(1)1))
margins r.covid_ind@race_final

***** Origin tract FE -- control for destination rent deviation (lag)
eststo: reghdfe tract_pct_white ib1.covid_ind##ib4.race_final##i.above_median_adj ib25.age_bin ib1.gend mean_pretrend_resid_lag if move_any_last5==1 & nyc==1 & above_median_adj!=2, absorb(tract_id_pre)

* marginal effect
margins r.covid_ind@race_final, at(above_median_adj=(0(1)1))
margins r.covid_ind@race_final

***** Origin tract FE -- control for destination rent deviation (lag) + tract income
eststo: reghdfe tract_pct_white ib1.covid_ind##ib4.race_final##i.above_median_adj ib25.age_bin ib1.gend mean_pretrend_resid_lag tract_med_hhinc if move_any_last5==1 & nyc==1 & above_median_adj!=2, absorb(tract_id_pre)

* marginal effect
margins r.covid_ind@race_final, at(above_median_adj=(0(1)1))
margins r.covid_ind@race_final

***** Origin tract FE -- control for destination rent deviation (lag) + tract income + distance to CBD
eststo: reghdfe tract_pct_white ib1.covid_ind##ib4.race_final##i.above_median_adj ib25.age_bin ib1.gend mean_pretrend_resid_lag tract_med_hhinc empire if move_any_last5==1 & nyc==1 & above_median_adj!=2, absorb(tract_id_pre)

* marginal effect
margins r.covid_ind@race_final, at(above_median_adj=(0(1)1))
margins r.covid_ind@race_final

***** Origin tract FE -- control for destination rent level (median no lag)
eststo: reghdfe tract_pct_white ib1.covid_ind##ib4.race_final##i.above_median_adj ib25.age_bin ib1.gend median_log_price3 if move_any_last5==1 & nyc==1 & above_median_adj!=2, absorb(tract_id_pre)

* marginal effect
margins r.covid_ind@race_final, at(above_median_adj=(0(1)1))
margins r.covid_ind@race_final

***** Origin tract FE -- control for destination rent level (median no lag) + tract income
eststo: reghdfe tract_pct_white ib1.covid_ind##ib4.race_final##i.above_median_adj ib25.age_bin ib1.gend median_log_price3 tract_med_hhinc if move_any_last5==1 & nyc==1 & above_median_adj!=2, absorb(tract_id_pre)

* marginal effect
margins r.covid_ind@race_final, at(above_median_adj=(0(1)1))
margins r.covid_ind@race_final

esttab using "/output/move_ind_OLS_all_updated_6.18.25.csv", b(3) se(3) r2 ar2 star(* 0.10 ** 0.05 *** 0.01) title("") s(N r2_a origin_tract_FE, label ("N" "Adjusted r-square" "Origin Tract FE")) label replace

************ Use the marginal effects above to create plots (Figure 5)
import delimited "/output/margins_coef_white.csv", clear
tempfile file1
save `file1', replace

import delimited "/output/margins_coef_white_all.csv", clear
gen allpop=1
append using `file1'
replace allpop=0 if allpop==.

foreach var in white black api hispan lowinc covid1 covid2 {
gen `var' = regexm(group, "`var'")
}

keep if version>=1 & version<=3 | version==6

cap drop order
gen order=1 if lowinc==0 & version==6
replace order=2 if lowinc==1 & version==6
replace order=3 if allpop==1 & version==6
replace order=5 if lowinc==0 & version==3
replace order=6 if lowinc==1 & version==3
replace order=7 if allpop==1 & version==3
replace order=9 if lowinc==0 & version==2
replace order=10 if lowinc==1 & version==2
replace order=11 if allpop==1 & version==2
replace order=13 if lowinc==0 & version==1
replace order=14 if lowinc==1 & version==1
replace order=15 if allpop==1 & version==1

sort order covid1

twoway scatter order b if covid1==1 || ///
rcap max_95 min_95 order if covid1==1 , horizontal lc(stc1) || ///
scatter order b if covid2==1, mc(stc2) || ///
rcap max_95 min_95 order if covid2==1 , horizontal lc(stc2) ///
xline(0) legend(order(1 "Post-COVID (2020q2-2021q2)" 3 "Post-COVID (2021q3-2022q3)") pos(6)) xtitle("COVID Effect on Tract Share White in Destination Tracts for White Movers", size(vsmall)) xlabel(-0.02(0.01)0.05) ///
ylab(1 "White, higher-income" ///
2 "White, lower-income" ///
3 "White" ///
3.6 "{bf:and distance to CBD}" ///
4.2 "{bf:(d) Control for destination rent deviation, income,}" ///
5 "White, higher-income" ///
6 "White, lower-income" ///
7 "White" ///
7.6 "{bf:(c) Control for destination rent deviation and income}" ///
9 "White, higher-income" ///
10 "White, lower-income" ///
11 "White" ///
11.6 "{bf:(b) Control for destination rent deviation}" ///
13 "White, higher-income" ///
14 "White, lower-income" ///
15 "White" ///
15.6 "{bf: (a) No control of destination characteristics}", labsize(small) nogrid noticks) ytitle("") 

graph export "/output/marginal_effect_rentdev.png", replace