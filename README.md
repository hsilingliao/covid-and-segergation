# COVID and Segregation

This readme file docuemnts the steps taken to produce the analysis for Measuring the Effects of Short-Term Shocks on Racial Segregation: The Case of the Pandemic by Ingrid Gould Ellen, Amrita Kulka, and Hsi-Ling Liao.
__________________________________________________________________________________________________________

## Script:

0.1_race_imputation.do: This script implements the Bayesian Improved First Name Surname Geocoding (BIFSG) and Bayesian Improved Surname Geocoding (BISG) method to imputate race/ethnicity for the individuals. 

0.2_rent_deviation.do: This script calculates the rent deviation from existing pre-pandmic (2013-2019) trend during COVID-19 (2020 Q2 and later) for different communicty districts.

1.1_acs_dissimilarity.do: This script uses tract-level ACS data to calculate the annual dissimilarity index in NYC from 2017-2022. It produces Figure 1a.

1.2_infutor_dissimilarity.do: This script first uses Verisk data to calculate quarterly dissimilarity index in NYC from 2017Q1-2022Q3. It also uses the number of inmovers and outmovers of different racial groups by quarter to calculate the "counterfactual" number of movers using pre-pandemic (2019) data. It then constructs the counterfactual dissimilarity index by fixing the white or Black inmovers/outmovers at the pre-pandemic level (adjusted for population change over time) one at a time. It produces Figure 1b and Figure 3.

2.1_racial_turnover.do
-- This script uses Verisk data to construct racial turnover ratios for differnt racial and ethnic groups at the block level (difference between the share of inmovers who belong to a racial group and the share of outmovers who belong to the same racial group on the block in that year-quarter). It then runs OLS regressions to examine how the ratio in different types of neighborhood (different racial composition and rent deviation) changed after the pandemix. It produces Figure 2 and Table B1.

3.1_rent_change.do: This script uses Streeteasy data to estimate quarterly rent change from 2017Q1 to 2022Q3. It also plot the map of meidian rent change by community district between 2020Q1 2021Q1. It produces Figure 4.

4.1_origin_dest_analysis.do: This script uses Verisk data to run OLS regressions at the individual level among those who moved to examine how the share of white populations that are white changed after COVID for white individuals of different income groups, adjusting for other destination tract chacteristics. It produces Figure 5.

Note: Scripts used to clean the Verisk and StreetEasy data are not included due to restrictions that apply to the availability of detailed variable names. The Verisk data contain individual-level information, including names, the ten most recent addresses, move-in month for each address, and demographic characteristics such as date of birth and gender. We geocoded street addresses and linked them to 2010 Census Tracts and Blocks to track neighborhood residence over time. The StreetEasy data provide listing-level information on asking rents, posting dates, addresses, and unit characteristics, such as the number of bedrooms and bathrooms. We also geocode addresses and link them to the community district and census tracts/blocks. The data structure and additional details are described in Section 4.1 of the paper.

## Raw Data:
- American Community Survey data is obtained from the U.S. Census Bureau.
- Verisk data is proprietary consumer reference data obtained from Verisk Analytics. 
- StreetEasy data is proprietary rent data obtained from StreetEasy.
- Primary Land Use Tax Lot Output (PLUTO) is obtained from the New York City Open data (https://www.nyc.gov/content/planning/pages/resources/datasets/mappluto-pluto-change)

## Data availability:
This study uses several data sources. Migration data were obtained from Verisk Analytics under a license agreement; these data are proprietary and cannot be shared publicly. Rent data were obtained from StreetEasy and are also proprietary, so we do not have permission to share them. Researchers with questions regarding data access can contact the authors at hsilingliao@uchicago.edu and amrita.kulka@warwick.ac.uk. 

Other datasets used in this study are publicly available. The American Community Survey can be downloaded at https://data.census.gov/
, and the Primary Land Use Tax Lot Output (PLUTO) dataset is available from New York City Open Data at https://www.nyc.gov/content/planning/pages/resources/datasets/mappluto-pluto-change.
