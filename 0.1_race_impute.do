********************************************************************************
***** This script implements the Bayesian Improved First Name Surname Geocoding
***** (BIFSG) and Bayesian Improved Surname Geocoding (BISG) method to imputate
***** race/ethnicity for the individuals. 
********************************************************************************
use "/data/nyc_long_202110.dta", clear

***** Merge with address ID-census tract crosswalk (first batch)
merge m:1 addrid using "/data/unique_addrid_nyc_tract.dta", keep(master match)
drop _merge

***** Merge with address ID-census tract crosswalk (second batch)
merge m:1 addrid using "/data/nyc_add_unique_geocoded_new.dta", keep(master match) keepusing(addrid ct lat lon cd bbl bin)
drop _merge
replace ct=. if ct==0

**** Clean census tract to be merged to census summary file
gen str6 tract = string(real(cxy_tract),"%06.0f")
replace tract="" if tract=="."
drop cxy_tract
rename tract cxy_tract

***** Recode geocode (from the first batch of geocoding) to be merged to census summary file
replace cxy_state = string(statefips, "%02.0f") if cxy_state=="" & !missing(statefips)
replace cxy_state_county = string(countyfips, "%05.0f") if cxy_state_county=="" & !missing(countyfips)
replace cxy_tract= string(ct, "%06.0f") if cxy_tract=="" & !missing(ct)
drop ct

count 
count if (cxy_tract=="") & z4type!="P"
count if (cxy_tract=="")

****** Merge with address ID-census tract crosswalk (third batch)
gen nyc = inlist(countyfips,36061,36047,36005,36085,36081) if !missing(countyfips) 
tab nyc if cxy_tract=="" & pobox!=1,mis
merge m:1 addrid zip using "/data/unmatch_full_sample_non_nyc_geocoded.dta", keep(master match)
drop _merge

replace cxy_tract = cxy_tract_id if missing(cxy_tract) & !missing(cxy_tract_id)
replace cxy_state_county = cxt_state_county_id if !missing(cxt_state_county_id)
replace cxy_state = cxy_state_id if !missing(cxy_state_id)
drop cxy_tract_id cxy_county_id cxy_state_id cxt_state_county_id

***** Merge with data file with individual names
merge m:1 pid using "/data/infutor/liao/imputation/pid_names_all_202110.dta", keep(master match)
drop _merge

replace surname = subinstr(surname, " ", "", .)
replace surname = subinstr(surname, "-", "", .)

***** Merge with first name probability
*merge m:1 firstname using "/data/infutor/liao/imputation/bifsg_data/firstnames.dta", keep(master match)
merge m:1 firstname using "/data/infutor/liao/imputation/bifsg_data/fuzzy_firstname_race_prob.dta", keep(master match)
rename _merge _merge_firstname

keep if ratio_firstname>=95

***** Merge with last name probability
merge m:1 surname using "/data/infutor/liao/imputation/bifsg_data/fuzzy_surname_race_prob.dta", keep(master match)
rename _merge _merge_surname

keep if ratio_lastname>=95

****** Merge with census tract geocode 
merge m:1 cxy_state_county cxy_tract using "/data/infutor/liao/imputation/bifsg_data/census_extra_tract_race_clean.dta", keep(master match using)
rename _merge _merge_geo
drop if _merge_geo==2

******* Estimate probability (first name, last name, tract)
gen denominator_bifsg = (pctwhite_sur*share_white_first*share_white_geo) + ///
(pctblack_sur*share_black_first*share_black_geo) + ///
(pcthispanic_sur*share_hispanic_first*share_hispanic_geo) + ///
(pctapi_sur*share_api_first*share_api_geo) + ///
(pctaian_sur*share_aian_first*share_aian_geo) + ///
(pctmultiple_sur*share_multiple_first*share_multiple_geo)

foreach var in white black api hispanic aian multiple {
	gen pct_`var'_bifsg = (pct`var'_sur*share_`var'_first*share_`var'_geo)/denominator_bifsg 
}

******* Estimate probability (last name, tract)
gen denominator_bisg = (pctwhite_sur*share_white_geo) + ///
(pctblack_sur*share_black_geo) + ///
(pcthispanic_sur*share_hispanic_geo) + ///
(pctapi_sur*share_api_geo) + ///
(pctaian_sur*share_aian_geo) + ///
(pctmultiple_sur*share_multiple_geo)

foreach var in white black api hispanic aian multiple {
	gen pct_`var'_bisg = (pct`var'_sur*share_`var'_geo)/denominator_bisg 
}

**** BIFSG
egen pct_race_bifsg = rowmax(pct_white_bifsg pct_black_bifsg pct_api_bifsg pct_aian_bifsg pct_multiple_bifsg pct_hispanic_bifsg)
gen race_bifsg =""
replace race_bifsg ="nh_white" if pct_white_bifsg==pct_race_bifsg & !missing(pct_white_bifsg)
replace race_bifsg ="nh_black" if pct_black_bifsg==pct_race_bifsg & !missing(pct_white_bifsg)
replace race_bifsg ="api" if pct_api_bifsg==pct_race_bifsg & !missing(pct_white_bifsg)
replace race_bifsg ="aian" if pct_aian_bifsg==pct_race_bifsg & !missing(pct_white_bifsg)
replace race_bifsg ="multiple" if pct_multiple_bifsg==pct_race_bifsg & !missing(pct_white_bifsg)
replace race_bifsg ="hispanic" if pct_hispanic_bifsg==pct_race_bifsg & !missing(pct_white_bifsg)

**** BISG
egen pct_race_bisg = rowmax(pct_white_bisg pct_black_bisg pct_api_bisg pct_aian_bisg pct_multiple_bisg pct_hispanic_bisg)
gen race_bisg =""
replace race_bisg ="nh_white" if pct_white_bisg==pct_race_bisg & !missing(pct_white_bisg)
replace race_bisg ="nh_black" if pct_black_bisg==pct_race_bisg & !missing(pct_white_bisg)
replace race_bisg ="api" if pct_api_bisg==pct_race_bisg & !missing(pct_white_bisg)
replace race_bisg ="aian" if pct_aian_bisg==pct_race_bisg & !missing(pct_white_bisg)
replace race_bisg ="multiple" if pct_multiple_bisg==pct_race_bisg & !missing(pct_white_bisg)
replace race_bisg ="hispanic" if pct_hispanic_bisg==pct_race_bisg & !missing(pct_white_bisg)

**** Two-stage  -- combining BIFSG and then BISG
gen race_combined=race_bifsg 
replace race_combined= race_bisg if missing(race_combined) & !missing(race_bisg)

gen pct_race_combined = pct_race_bifsg if !missing(race_combined) & !missing(race_bifsg)
replace pct_race_combined = pct_race_bisg if !missing(race_combined) & missing(race_bifsg) & !missing(race_bisg)

****** Examine why pid-addrid individuals are not imputed
tab _merge_geo _merge_surname if missing(race_combined) 

***** Create unique identifier
bysort pid: gen dup4= cond(_N==1,0,_n)
gen uni_pid = 1 if dup4==0 | dup4==1 //either unique obs or first occurence of duplicates

****** Flag the most current address vs the previous address
drop seq
gsort pid -date
bysort pid: gen order = _n
by pid: egen max_record = max(order)
gsort pid -date

****** Create new variables -- first, second,.. etc address
bysort pid: gen race_combined_adfirst = race_combined[1]
bysort pid: gen race_combined_adsecond = race_combined[2]
bysort pid: gen race_combined_adthird = race_combined[3]
bysort pid: gen race_combined_adfourth = race_combined[4]

****** Default to the second address 
****** Replace the second address imputed results in the order of third, fourth, and first address
* if second address geocode return no results
replace race_combined_adsecond = race_combined_adthird if missing(race_combined_adsecond)
replace race_combined_adsecond = race_combined_adfourth if missing(race_combined_adsecond)
replace race_combined_adsecond = race_combined_adfirst if missing(race_combined_adsecond)

***** Clean up variables 
keep pid race_combined_adsecond
rename race_combined_adsecond race_combined
duplicates drop pid race_combined, force

save "/data/race_combined_202110.dta", replace
