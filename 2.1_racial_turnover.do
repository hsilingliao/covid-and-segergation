******* This do-file runs the racial turnover OLS and produce ***** 
use "/data/block_turnover_by_quarter_20230106_cd.dta", clear 

***** Create additional variables needed
gen covid_ind=.
replace covid_ind = 1 if bbl_qdate>=tq(2017q3) & bbl_qdate<=tq(2020q1)
replace covid_ind =2 if bbl_qdate>=tq(2020q2) & bbl_qdate<=tq(2021q2)
replace covid_ind =3 if bbl_qdate>=tq(2021q3) & bbl_qdate<=tq(2022q3)
keep if covid_ind !=.

label define covid_ind 1"Pre-COVID(2017q1-2020q1)" 2"Post-COVID(2020q2-2021q2)" 3"Post-COVID(2021q3-2022q3)", replace
label values covid_ind covid_ind

***** In-mover vs out-mover ratio -- race
gen in_white_ratio = move_in_white/move_in_bbl
gen in_black_ratio = move_in_black/move_in_bbl
gen in_hispan_ratio = move_in_hispan/move_in_bbl
gen in_api_ratio = move_in_api/move_in_bbl
gen in_norace_ratio = move_in_norace/move_in_bbl

gen out_white_ratio = move_out_white /move_out_bbl
gen out_black_ratio  = move_out_black /move_out_bbl
gen out_hispan_ratio  = move_out_hispan /move_out_bbl
gen out_api_ratio  = move_out_api /move_out_bbl
gen out_norace_ratio  = move_out_norace /move_out_bbl

gen inout_white_diff = in_white_ratio - out_white_ratio
gen inout_black_diff= in_black_ratio - out_black_ratio
gen inout_hispan_diff= in_hispan_ratio - out_hispan_ratio
gen inout_api_diff = in_api_ratio - out_api_ratio
gen inout_norace_diff = in_norace_ratio -  out_norace_ratio

***** Labeling
label var in_white_ratio "Share of in-movers: white"
label var out_white_ratio "Share of out-movers: white"
label var in_black_ratio "Share of in-movers: black"
label var out_black_ratio "Share of out-movers: black"
label var in_hispan_ratio "Share of in-movers: hispanic"
label var out_hispan_ratio "Share of out-movers: hispanic"
label var in_api_ratio "Share of in-movers: api"
label var out_api_ratio "Share of out-movers: api"
label var in_norace_ratio "Share of in-movers: undefined race"
label var out_norace_ratio "Share of out-movers: undefined race"

label var inout_white_diff "probability of white in-movers - probability of white out-movers"
label var inout_black_diff "probability of black in-movers - probability of black out-movers"
label var inout_hispan_diff "probability of hispanic in-movers - probability of hispanic out-movers"
label var inout_api_diff "probability of api in-movers - probability of api out-movers"
label var inout_norace_diff "probability of in-movers being undefined race - probability of out-movers being undefined race"

***** Log tract median income
gen log_tract_med_hhinc = log(tract_med_hhinc)
label var log_tract_med_hhinc "Log (tract median household income)"

***** Merge with CD-level rent deviastion streeteasy data
merge m:1 bbl_qdate cd using "/data/rent_resid_listing_pretrendonly_cd_yq.dta"
drop if _merge==2
drop _merge

label var mean_pretrend_resid3 "CD 2-bedroom median rent deviation from trend (log actual - log predicted)"

merge m:1 bbl_qdate cd using "/data/rent_resid_listing_pretrendonly_cd_yq_lag.dta", keepusing(mean_pretrend_resid_lag mean_pretrend_resid_lag2)
drop if _merge==2

label var mean_pretrend_resid_lag "CD 2-bedroom rent deviation (log actual - log predicted) -- lag 1 quarter"
label var mean_pretrend_resid_lag2 "CD 2-bedroom rent deviation (log actual - log predicted) -- lag 2 quarters"

****** Baseline
tabstat inout_white_diff_probany inout_black_diff_probany inout_hispan_diff_probany inout_api_diff_probany inout_norace_diff_probany, s(mean) by(covid_ind)

gen miss_move_in_bbl = move_in_bbl==0
gen miss_move_out_bbl = move_out_bbl==0
gen miss_move_in_or_out = move_in_bbl==0 | move_out_bbl==0

tabstat miss_move_in_bbl miss_move_out_bbl miss_move_in_or_out, by(covid_ind) format(%12.2g)
tabstat move_in_bbl move_out_bbl, by(covid_ind) format(%12.2g) s(mean)
tabstat miss_move_in_bbl miss_move_out_bbl miss_move_in_or_out, by(bbl_qdate) format(%12.2g)
tabstat in_norace_ratio_prob8 in_norace_ratio_prob6 in_norace_ratio_probany ///
out_norace_ratio_prob8 out_norace_ratio_prob6 out_norace_ratio_probany , by(covid_ind) format(%12.2g)

****** Racial turnover regression and marginal effect plots
eststo clear
* white households
eststo: reghdfe inout_white_diff_probany c.mean_pretrend_resid_lag##i.covid_ind##c.tract_pct_white if tract_pct_white>=0.1 & tract_pct_white<=0.9, absorb(boroblock)

margins covid_ind, at(tract_pct_white=(0.1) (p25) mean_pretrend_resid_lag) ////
		   at(tract_pct_white=(0.5) (p25) mean_pretrend_resid_lag) ////
		   at(tract_pct_white=(0.9) (p25) mean_pretrend_resid_lag) noestimcheck

marginsplot,  title(Predicted Values at 25th Percentile Rent Deviation) xtitle("") ytitle("Share of white in-movers -" "Share of white out-movers", size(large)) legend(size(*1.4) pos(6)) xlabel(,labsize(*1)) plot(,label ("Tract share white 10%" "Tract share white 50%" "Tract share white 90%")) note("Rent Deviation at 25th percentile = -0.046", size(medium)) xscale(range(0.5 (1) 3.5))xlabel(1 `" "Pre-COVID""(2017q1-2020q1)" "'2 `" "Post-COVID""(2020q2-2021q2)" "'3`" "Post-COVID""(2021q3-2022q3)" "', valuelabel noticks labsize(*1.3)) yscale(range(-0.06 0.02)) ylabel(-0.06(0.02)0.02, labsize(*1.5)) plot1opts(mc(orange) lc(orange)) plot2opts(mc(navy) lc(navy)) plot3opts(mc(dkgreen) lc(dkgreen) lp(solid)) ci1opt(lcolor(orange)) ci2opt(lcolor(navy)) ci3opt(lcolor(dkgreen))

graph export "/output/marginal_effect_whiteracialturnover_rentdev_25.png", replace

margins covid_ind, at(tract_pct_white=(0.1) (p50) mean_pretrend_resid_lag) ////
		   at(tract_pct_white=(0.5) (p50) mean_pretrend_resid_lag) ////
		   at(tract_pct_white=(0.9) (p50) mean_pretrend_resid_lag) noestimcheck

marginsplot,  title(Predicted Values at Median Rent Deviation, size(*1.3) span) xtitle("") ytitle("Share of white in-movers -" "Share of white out-movers", size(large)) legend(size(*1.4) pos(6))  plot(,label ("Tract share white 10%" "Tract share white 50%" "Tract share white 90%")) note("Rent Deviation at 50 percentile = -0.006", size(medium)) xscale(range(0.5 (1) 3.5)) xlabel(1 `" "Pre-COVID""(2017q1-2020q1)" "'2 `" "Post-COVID""(2020q2-2021q2)" "'3`" "Post-COVID""(2021q3-2022q3)" "', valuelabel noticks labsize(*1.3)) yscale(range(-0.06 0.02)) ylabel(-0.06(0.02)0.02, labsize(*1.5)) plot1opts(mc(orange) lc(orange)) plot2opts(mc(navy) lc(navy)) plot3opts(mc(dkgreen) lc(dkgreen) lp(solid)) ci1opt(lcolor(orange)) ci2opt(lcolor(navy)) ci3opt(lcolor(dkgreen))

graph export "/output/marginal_effect_whiteracialturnover_rentdev_50.png", replace

margins covid_ind, at(tract_pct_white=(0.1) (p75) mean_pretrend_resid_lag) ////
		   at(tract_pct_white=(0.5) (p75) mean_pretrend_resid_lag) ////
		   at(tract_pct_white=(0.9) (p75) mean_pretrend_resid_lag) noestimcheck

marginsplot,  title(Predicted Values at Rent Deviation at 75 percentile) xtitle("") ytitle("Share of white in-movers -" "Share of white out-movers", size(large)) legend(size(*1.4) pos(6))  plot(,label ("Tract share white 10%" "Tract share white 50%" "Tract share white 90%")) note("Rent Deviation at 75th percentile = 0.029", size(medium)) xscale(range(0.5 (1) 3.5)) xlabel(1 `" "Pre-COVID""(2017q1-2020q1)" "'2 `" "Post-COVID""(2020q2-2021q2)" "'3`" "Post-COVID""(2021q3-2022q3)" "', valuelabel noticks labsize(*1.3)) yscale(range(-0.06 0.02)) ylabel(-0.06(0.02)0.02, labsize(*1.5)) plot1opts(mc(orange) lc(orange)) plot2opts(mc(navy) lc(navy)) plot3opts(mc(dkgreen) lc(dkgreen) lp(solid)) ci1opt(lcolor(orange)) ci2opt(lcolor(navy)) ci3opt(lcolor(dkgreen))

graph export "//marginal_effect_whiteracialturnover_rentdev_75.png", replace


margins covid_ind, at(tract_pct_white=(0.5) (p25) mean_pretrend_resid_lag) ////
		   at(tract_pct_white=(0.5) (p50) mean_pretrend_resid_lag) ////
		   at(tract_pct_white=(0.5) (p75) mean_pretrend_resid_lag) noestimcheck 

marginsplot,  title(Predicted Values: Tract share white at 50%) xtitle("") ytitle(Share of white in-movers - Share of white out-movers, size(small)) legend(size(*1.4) pos(6)) xlabel(,labsize(*1)) plot(,label ("Rent deviation at 25 perentile" "Rent deviation at 50 perentile" "Rent deviation at 75 perentile")) note(Tract share white at 50%) xscale(range(0.5 (1) 3.5)) xlabel(1 2 3, valuelabel noticks) 

graph export "//marginal_effect_whiteracialturnover_tractwhite_50.png", replace

margins covid_ind, at(tract_pct_white=(0.1) (p25) mean_pretrend_resid_lag) ////
		   at(tract_pct_white=(0.1) (p50) mean_pretrend_resid_lag) ////
		   at(tract_pct_white=(0.1) (p75) mean_pretrend_resid_lag) noestimcheck

marginsplot,  title(Adjusted Predicted Values: Tract share white at 10%) xtitle("") ytitle(Share of white in-movers - Share of white out-movers, size(small)) legend(size(*1.4) pos(6)) xlabel(,labsize(*1)) plot(,label ("Rent deviation at 25 perentile" "Rent deviation at 50 perentile" "Rent deviation at 75 perentile"))  note(Tract share white at 50%) xscale(range(0.5 (1) 3.5)) xlabel(1 2 3, valuelabel noticks) yscale(range(-0.08 0.02)) ylabel(-0.08(0.02)0.02)

graph export "/output/marginal_effect_whiteracialturnover_tractwhite_10.png", replace


margins covid_ind, at(tract_pct_white=(0.9) (p25) mean_pretrend_resid_lag) ////
		   at(tract_pct_white=(0.9) (p50) mean_pretrend_resid_lag) ////
		   at(tract_pct_white=(0.9) (p75) mean_pretrend_resid_lag) noestimcheck

marginsplot,  title(Adjusted Predicted Values: Tract share white at 90%) xtitle("") ytitle(Share of white in-movers - Share of white out-movers, size(small)) legend(size(*1.4) pos(6)) xlabel(,labsize(*1)) plot(,label ("Rent deviation at 25 perentile" "Rent deviation at 50 perentile" "Rent deviation at 75 perentile"))  note(Tract share white at 90%) xscale(range(0.5 (1) 3.5)) xlabel(1 2 3, valuelabel noticks) yscale(range(-0.08 0.02)) ylabel(-0.08(0.02)0.02)

graph export "/output/marginal_effect_whiteracialturnover_tractwhite_90.png", replace

* black households
eststo: reghdfe inout_black_diff_probany c.mean_pretrend_resid_lag##i.covid_ind##c.tract_pct_white if tract_pct_white>=0.1 & tract_pct_white<=0.9, absorb(boroblock)

margins covid_ind, at(tract_pct_white=(0.1) (p50) mean_pretrend_resid_lag) ////
		   at(tract_pct_white=(0.5) (p50) mean_pretrend_resid_lag) ////
		   at(tract_pct_white=(0.9) (p50) mean_pretrend_resid_lag) noestimcheck ///
		   
marginsplot,  title(Predicted Values at Median Rent Deviation, size(*1.3) span) xtitle("") ytitle("Share of Black in-movers -" "Share of Black out-movers", size(large)) legend(size(*1.4) pos(6))  plot(,label ("Tract share white 10%" "Tract share white 50%" "Tract share white 90%")) note("Rent Deviation at 50 percentile = -0.006", size(medium)) xscale(range(0.5 (1) 3.5)) xlabel(1 `" "Pre-COVID""(2017q1-2020q1)" "'2 `" "Post-COVID""(2020q2-2021q2)" "'3`" "Post-COVID""(2021q3-2022q3)" "', valuelabel noticks labsize(*1.3)) yscale(range(-0.01 0.03))  ylabel(-0.01(0.01)0.03, labsize(*1.5)) plot1opts(mc(orange) lc(orange)) plot2opts(mc(navy) lc(navy)) plot3opts(mc(dkgreen) lc(dkgreen) lp(solid)) ci1opt(lcolor(orange)) ci2opt(lcolor(navy)) ci3opt(lcolor(dkgreen))

graph export "/output/marginal_effect_blackracialturnover_rentdev_55.png", replace

* hispanic households
eststo: reghdfe inout_hispan_diff_probany c.mean_pretrend_resid_lag##i.covid_ind##c.tract_pct_white if tract_pct_white>=0.1 & tract_pct_white<=0.9, absorb(boroblock)

margins covid_ind, at(tract_pct_white=(0.1) (p50) mean_pretrend_resid_lag) ////
		   at(tract_pct_white=(0.5) (p50) mean_pretrend_resid_lag) ////
		   at(tract_pct_white=(0.9) (p50) mean_pretrend_resid_lag) noestimcheck
		   
marginsplot,  title(Predicted Values at Median Rent Deviation, size(*1.3) span) xtitle("") ytitle("Share of Hispanic in-movers -" "Share of Hispanic out-movers", size(large)) legend(size(*1.4) pos(6))  plot(,label ("Tract share white 10%" "Tract share white 50%" "Tract share white 90%")) note("Rent Deviation at 50 percentile = -0.006", size(medium)) xscale(range(0.5 (1) 3.5)) xlabel(1 `" "Pre-COVID""(2017q1-2020q1)" "'2 `" "Post-COVID""(2020q2-2021q2)" "'3`" "Post-COVID""(2021q3-2022q3)" "', valuelabel noticks labsize(*1.3)) ylabel(, labsize(*1.5)) plot1opts(mc(orange) lc(orange)) plot2opts(mc(navy) lc(navy)) plot3opts(mc(dkgreen) lc(dkgreen) lp(solid)) ci1opt(lcolor(orange)) ci2opt(lcolor(navy)) ci3opt(lcolor(dkgreen))

graph export "/output/marginal_effect_Hispanicracialturnover_rentdev_50.png", replace

* api households
eststo: reghdfe inout_api_diff_probany c.mean_pretrend_resid_lag##i.covid_ind##c.tract_pct_white if tract_pct_white>=0.1 & tract_pct_white<=0.9, absorb(boroblock)

margins covid_ind, at(tract_pct_white=(0.1) (p50) mean_pretrend_resid_lag) ////
		   at(tract_pct_white=(0.5) (p50) mean_pretrend_resid_lag) ////
		   at(tract_pct_white=(0.9) (p50) mean_pretrend_resid_lag) noestimcheck 

marginsplot,  title(Predicted Values at Median Rent Deviation, size(*1.3) span) xtitle("") ytitle("Share of API in-movers -" "Share of API out-movers", size(large)) legend(size(*1.4) pos(6))  plot(,label ("Tract share white 10%" "Tract share white 50%" "Tract share white 90%")) note("Rent Deviation at 50 percentile = -0.006", size(medium)) xscale(range(0.5 (1) 3.5)) xlabel(1 `" "Pre-COVID""(2017q1-2020q1)" "'2 `" "Post-COVID""(2020q2-2021q2)" "'3`" "Post-COVID""(2021q3-2022q3)" "', valuelabel noticks labsize(*1.3)) ylabel(, labsize(*1.5)) plot1opts(mc(orange) lc(orange)) plot2opts(mc(navy) lc(navy)) plot3opts(mc(dkgreen) lc(dkgreen) lp(solid)) ci1opt(lcolor(orange)) ci2opt(lcolor(navy)) ci3opt(lcolor(dkgreen))

graph export "/output/marginal_effect_APIracialturnover_rentdev_50.png", replace

** Export regression table
esttab using "/output/inout_race_block_full_tracts.csv", ///
b(3) se(3) r2 ar2 star(* 0.10 ** 0.05 *** 0.01) title("") ///
alignment(D{.}{.}{-1}) ///
s(N r2_a, label ("N" "Adjusted r-square" "Boro block FE")) label replace

esttab using "/output/inout_race_block_full_tracts.tex", ///
b(3) se(3) r2 ar2 star(* 0.10 ** 0.05 *** 0.01) title("") ///
alignment(D{.}{.}{-1}) ///
s(N r2_a, label ("N" "Adjusted r-square" "Block FE")) label replace