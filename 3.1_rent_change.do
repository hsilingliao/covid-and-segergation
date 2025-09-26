********** This script create Figure 4 and examine quarterly rent changes over time.
use "\data\streeteasy_clean.dta", replace

********* Run descriptive regression and estimate quarterly rent changes (2017q1-2022q3)
* use 2022$$
gen cpi_base_2022 = cpi_index if year_end==2022 & month_end==12
egen cpi_base_all_2022 = max(cpi_base_2022)

gen price_adj_2022 = price/(cpi_index/cpi_base_all_2022)

reghdfe price_adj_2022 bedrooms unitsres unitsres_missing build_age agesq yearbuilt_missing alter1_recent alter2_recent bathroom dist_to_park dist_to_park_missing dist_to_subway dist_to_subway_missing ib7.prop_status2 i.quarter_end i.quarter_period_end if year_end>=2017 & quarter_end>=tq(2017q1), absorb(i.tract_id) vce(cluster tract_id)

* Figure 4a
coefplot, keep(*.quarter_end) drop(252.quarter_end 253.quarter_end 254.quarter_end) title("Quarterly Change in Asking Rent", size(5)) graphregion(color(white)) omitted baselevels xline(0) ytitle("") xlabel(,labsize(*1.4)) ylabel(,labsize(*1.1)) msymbol(0) msize(medsmall) pstyle(p1) note("All rents are adjust for inflation and in 2022 dollar", size(medium)) ysize(6)

graph export "\output\rent_coef_tractFE_20250813.png", replace

******** Map rent change by community district (2020 Q1 to 2021 Q1)
* (Figure 4b)
*** Get community district level median rents from lising-level streeteasy data
use "\data\streeteasy_clean.dta", clear
keep if monthlydate_end>=tm(2018m10) & monthlydate_end<=tm(2022m12)

gen n=1
tab quarter_end

collapse (sum) n_all=n (median) median_price = price_adj, by(cd cd_display quarter_end)
drop if cd=="NA"
destring cd, replace

xtset cd quarter_end
tsfill, full

* price change compared to 4 quarters ago
bysort cd (quarter_end): gen price_adj_pctchg = (median_price - median_price[_n-4])/median_price[_n-4]
bysort cd (quarter_end): gen price_adj_levchg = (median_price - median_price[_n-4])

gen price_pctchg_21q1 = (price_adj_pctchg) if quarter_end==tq(2021q1)
gen price_levchg_21q1 = (price_adj_levchg) if quarter_end==tq(2021q1)

bysort cd: egen price_pctchg_21q1_max = max(price_pctchg_21q1)
bysort cd: egen price_levchg_21q1_max = max(price_levchg_21q1)

keep cd *_max
duplicates drop *, force

save "\data\rent_change_all_cd_updated", replace

*** Load community district shape file
cd "\data\CBSA\nycd_23b\nycd_23b"
shp2dta using nycd, database(nycd) coordinates(uscoord) genid(id) replace
use nycd, clear
describe
rename BoroCD cd
merge 1:m cd using "\data\rent_change_all_cd_updated"
keep if _merge==3
drop _merge

format price_* %12.3fc

format price_levchg_21q1_max %12.1g
colorpalette viridis, n(8) nograph
local colors `r(p)'
spmap price_levchg_21q1_max using uscoord, id(id) clnum(8) fcolor("`colors'")    ///
     legstyle(2) legend(pos(10) size(4) region(fcolor(gs15)))   ///
     ocolor(white ..) osize(0.05 ..)  ///
     title("Median Rent Change (2020 Q1 to 2021 Q1)" "by Community District", size(4)) ///
     note("Note: Median rent for all bedroom type", size(3))

graph export "\output\rent_chg_allbedtype_2020q1_2021q1_level_updated.png", replace	  //(Figure 4b)

