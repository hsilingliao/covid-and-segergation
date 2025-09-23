******** This script detrends the streeteasy rent data to evaluate 
******** the deviation away from the trend during COVID-19
******** This will be used in the racial turnover analysis

******* 5/6 updated analysis: listing-level predictinon using only pre-COVID data -- up to 2019 Q4
use "J:\DEPT\REUP\Projects\COVID and migration\Data\streeteasy_temp.dta", clear

gen bedroom_type = 1 if bedrooms==0
replace bedroom_type = 2 if bedrooms==1
replace bedroom_type = 3 if bedrooms==2
replace bedroom_type = 4  if bedrooms>=3 & !missing(bedrooms)

label define bedroom_type 1"studio" 2"1 bedroom" 3"2 bedrooms" 4"3+ bedrooms"
label values bedroom_type bedroom_type

tab bedroom_type
tab monthlydate_end

keep if monthlydate_end>=tm(2013m1) & monthlydate_end<=tm(2022m12)

** Create a new continuous quarter indicator
gen quarter = quarter_end
tab quarter
tab quarter quarter_end

** Create indicators for quarters
cap drop qq
gen qq = quarter(dofq(quarter_end))

** Collapse to cd-quarter-bedroom type
drop if cd=="NA" 

** Create log price
gen log_price = log(price_adj)

destring cd, replace

*** Run listing-level regression using data<=2019m12
reg log_price bedrooms unitsres unitsres_missing build_age agesq yearbuilt_missing alter1_recent alter2_recent bathroom dist_to_park dist_to_park_missing dist_to_subway dist_to_subway_missing i.qq ib7.prop_status i.cd##c.quarter_end if monthlydate_end<=tm(2019m12), r cluster(cd)

* Predict rents using the estimates in the above regression
predict predict_price_reg, xb
predict resid, res
predict yhat 

* Calculate residual to use as rent deviation
gen resid_new =  log_price - yhat

* Get mean/median of residual (or deviation) at the community district level by bedrrom types
collapse (count) n=price_adj (mean) mean_resid = resid_new mean_log_price = log_price (median) median_log_price = log_price median_resid = resid_new, by(cd cd_display bedroom_type quarter_end)

****** Store the regression slopes
levelsof quarter_end, local(levels)
 foreach quarter of local levels {
 reg mean_resid mean_log_price if bedroom_type==3 &quarter_end==`quarter',r
 local eq1 = `"`eq1' `: display %4.1f _b[tract_pct_white]'"'
}

**** Prepare to merge with map data
rename cd BoroCD

*** Save CD-level residual data to match with the infutor data as input for racial turnover analysis -- year-quarter specific
* For different bedroom types
rename n n_pretrend_listing
rename mean_resid mean_pretrend_resid
keep if quarter_end>=tq(2017q1) & quarter_end<=tq(2022q3)
keep BoroCD bedroom_type mean_pretrend_resid n quarter_end mean_log_price median_log_price

gen bed = bedroom_type*1
drop bedroom_type

reshape wide mean_pretrend_resid n_pretrend_listing  mean_log_price median_log_price, i(BoroCD quarter_end) j(bed)
rename BoroCD cd
rename quarter_end bbl_qdate
	
save "J:\DEPT\REUP\Projects\COVID and migration\Data\rent_resid_listing_pretrendonly_cd_yq", replace

*** Create a lag version -- lagg for 1 or 2 quarters
use "J:\DEPT\REUP\Projects\COVID and migration\Data\rent_resid_listing_pretrendonly_cd_yq", clear
by cd (bbl_qdate): gen mean_pretrend_resid_lag = mean_pretrend_resid3[_n-1]
by cd (bbl_qdate): gen mean_pretrend_resid_lag2 = mean_pretrend_resid3[_n-2]
by cd (bbl_qdate): gen mean_logprice_lag = mean_log_price3[_n-1]
by cd (bbl_qdate): gen mean_logprice_lag2 = mean_log_price3[_n-2]
by cd (bbl_qdate): gen median_logprice_lag = median_log_price3[_n-1]
by cd (bbl_qdate): gen median_logprice_lag2 = median_log_price3[_n-2]
save "J:\DEPT\REUP\Projects\COVID and migration\Data\rent_resid_listing_pretrendonly_cd_yq_lag", replace
