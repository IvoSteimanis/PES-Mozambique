*--------------------------------------------------------------------
* SCRIPT:  01_clean_data.do
* PURPOSE: Builds every analysis-ready dataset from the raw inputs: the
*          grid-cell remote-sensing panels (own miombo classification and
*          Hansen Global Forest Change at 20% and 30% canopy thresholds),
*          the village buffer statistics, and the household survey.
*
* INPUT:   data/remote_sensing/gridcells and maps_2021_12.xlsx
*          data/remote_sensing/gridcells_data_new.csv
*          data/remote_sensing/gridcells_9ha.shp
*          data/remote_sensing/hansen_panel_2000_2019_20pct.csv
*          data/remote_sensing/hansen_panel_2000_2019_30pct.csv
*          data/remote_sensing/Survey-Villages-with-buffer-stats_wo_NP.csv
*          data/survey/sofala_survey.xlsx
*          data/survey/survey_sofala_2022_new.xlsx  (XLSForm)
*
* OUTPUT:  processed/remote_sensing_rdy.dta
*          processed/hansen20pct_rdy.dta
*          processed/hansen30pct_rdy.dta
*          processed/rs_village_data.dta
*          processed/survey_rdy.dta
*          results/tables/tableS18_pca_motivations.rtf     Table S18
*          results/tables/tableS19_pca_loadings.rtf        Table S19
*          results/tables/tableS20_S21_factor_agency.txt   Tables S20, S21
*
* DEPENDS: kobo2stata, shp2dta, winsor2, missings, estout
*
* IMPORTANT: This script CANNOT be run from the published replication package.
*          The raw household survey contains respondent names, phone numbers
*          and GPS coordinates and is therefore not distributed. It is shipped
*          for transparency about how the analysis data were built. The
*          replication package starts from processed/, which this script
*          produces. Raw survey data are available from the authors on request,
*          subject to a confidentiality agreement.
*--------------------------------------------------------------------
clear all



*--------------------------
* (1) REMOTE SENSING DATA
*--------------------------
* Load excel data-sheet and save as dta file
import excel using  "$working_ANALYSIS/data/remote_sensing/gridcells and maps_2021_12.xlsx", firstrow
describe

save "$working_ANALYSIS/processed/grid_cell_information.dta", replace

clear
import delimited using "$working_ANALYSIS/data/remote_sensing/gridcells_data_new.csv"
keep id km_contro km_cont_1 km_sccp_a km_sccp_p surveyvil surveyv_1 surveyv_2 surveyv_3
save "$working_ANALYSIS/processed/grid_cell_information2.dta", replace

use  "$working_ANALYSIS/processed/grid_cell_information.dta"
merge 1:1 id using "$working_ANALYSIS/processed/grid_cell_information2.dta"
drop _merge
save "$working_ANALYSIS/processed/grid_cell_information_complete.dta", replace


// Import shapefile information and merge with remote sensing data
shp2dta using "$working_ANALYSIS/data/remote_sensing/gridcells_9ha", data("$working_ANALYSIS/data/remote_sensing/sccp_db") coord("$working_ANALYSIS/data/remote_sensing/sccp_coord") replace
use "$working_ANALYSIS/data/remote_sensing/sccp_db", clear

*merge both datasets
use "$working_ANALYSIS/processed/grid_cell_information_complete.dta"
merge 1:1 id using "$working_ANALYSIS/data/remote_sensing/sccp_db"
drop _merge

*drop 2005 forest cover data due to quality issues with the sensor and cloud cover
drop *2005  bush96coun bush02coun bush19coun cr_gr96cou cr_gr02cou cr_gr19cou floodcount for96count for02count for19count irrig96cou irrig02cou irrig19cou plant96cou plant02cou plant19cou setl96coun setl02coun setl19coun 
save "$working_ANALYSIS/processed/remote_sensing_raw.dta", replace



** GENERATE ADDITIONAL VARIABLES
clear all
use "$working_ANALYSIS/processed/remote_sensing_raw.dta"
*all potential groups
gen cell_groups = 0 if share_area_north_sccp==0 & share_area_sccp==0
replace cell_groups = 2 if share_area_north_sccp>=0.8 & share_area_sccp >= 0.8
replace cell_groups = 3 if share_area_north_sccp <0.8 & share_area_sccp >= 0.8
replace cell_groups = 4 if share_area_np > 0
* spill over group based on distance to project area (5km radius)
replace cell_groups = 1 if mean_distancetoprojectarea <= 5000 & share_area_sccp < 0.8 & share_area_NP == 0
lab def groupie 0 "Control" 2 "SCCP: EU area" 3 "SCCP: Envirotrade area"  4 "National Park" 1 "Spill-over (5km radius)", replace
lab val cell_groups groupie
tab cell_groups



* Treatment variable 2: control cells, spillover northern project area
*spillover group for northern projectarea
gen spillover_north = 0
replace spillover_north = 1 if mean_distancetoprojectareain <= 5000 & share_area_north_sccp < 0.8 & cell_groups!=3 & share_area_NP==0


*cell groups2 with eu pilot spillover area
gen cell_groups2 = 0 if cell_groups==0
replace cell_groups2 = 1 if cell_groups==2
replace cell_groups2 = 2 if cell_groups==3
replace cell_groups2 = 3 if spillover_north==1
lab def groupie2 0 "Control" 1 "SCCP: EU Pilot area" 2 "SCCP: Envirotrade area" 3 "EU Pilot: Spillover area", replace
lab val cell_groups2 groupie2
tab cell_groups2


* treated north only
gen treated_north = 0 if cell_groups == 0
replace treated_north = 1 if cell_groups == 2
lab def treatie3 0 "Control" 1 "SCCP EU-Phase", replace
lab val treated_north treatie3
tab treated_north 

*squared variables
gen sq_slope = mean_slope*mean_slope
gen sq_elevation = mean_elevation*mean_elevation


*PRE & POST-SCCP land cover changes (REDD+ Component)
sum forest1996 forest2002  forest2014 forest2019 irrigated1996 irrigated2002 irrigated2019 plantation1996 plantation2002 plantation2019 settlement1996 settlement2002 settlment2019 
gen fcc_02_96 =  forest2002 - forest1996
gen fcc_19_14 = forest2019 - forest2014


** LABELLING VARIABLES
lab var mean_distancetoN1andN6 "Distance to main road (m)"
lab var mean_distance_roads "Distance road (m)"
lab var mean_distanceagriculture50 "Distance to next cell with at least 50% cropland (m)"
lab var mean_distance_NP "Distance to Gorongosa National Park (m)"
lab var mean_slope "Average slope (degree)"
lab var sq_slope "Squared slope"
lab var mean_elevation "Average altitude (m)"
lab var sq_slope "Squared slope"
lab var forest2002 "Forest cover in 2002"
lab var fcc_02_96 "Forest cover change 02-96"


*drop irrelevant variables
drop _ID area AI BurnedAreas_2002_croplandpxl BurnedAreas_2002_forestpxl BurnedAreas_2019_croplandpxl BurnedAreas_2019_forestpxl AR DenseForest_1996pxl SparseForest_1996pxl DenseForest_2002pxl SparseForest_2002pxl DenseForest_2019pxl SparseForest_2019pxl irrigated1996 irrigated2002 irrigated2019 plantation1996 plantation2002 plantation2019


save "$working_ANALYSIS/processed/remote_sensing_rdy.dta", replace




** IMPORT EXCEL DATA ON VILLAGE BUFFER REMOTE SENSING INFORMATION
* Load excel data-sheet and save as dta file
clear
import delimited using  "$working_ANALYSIS/data/remote_sensing/Survey-Villages-with-buffer-stats_wo_NP.csv", 
describe
rename v1 village_id

*synchronize village_id with survey village_id
replace village_id = village_id+1 if village_id>3 
replace village_id = village_id+1 if village_id>13
replace village_id = village_id+3 if village_id>17
replace village_id = village_id+1 if village_id>32


lab def area_lab 2 "Buffer zone" 1 "SCCP & Buffer zone", replace
lab val area area_lab

* CONFIDENTIALITY: drop the village name and centroid coordinates. village_id
* is retained as an anonymous numeric code. None of these are used in the
* analysis, and together they would de-anonymise the study villages.
foreach v in name latitude longitude distance_nhambita_m {
	capture drop `v'
}

save "$working_ANALYSIS/processed/rs_village_data.dta", replace





*--------------------------------------
* (3) HANSEN 20pct forest cover data
*--------------------------------------
* Load excel data-sheet and save as dta file
clear all
import delimited using  "$working_ANALYSIS/data/remote_sensing/hansen_panel_2000_2019_20pct.csv", 
describe

save "$working_ANALYSIS/processed/hansen20pct_raw_input.dta", replace

*merge with shape file info
use "$working_ANALYSIS/processed/hansen20pct_raw_input.dta"
rename grid_id id
rename forest_cover_20pct forest20pct
reshape wide forest20pct, i(id) j(year)
merge 1:1 id using "$working_ANALYSIS/data/remote_sensing/sccp_db"
drop _merge

drop unnamed34 unnamed43

save "$working_ANALYSIS/processed/hansen20pct_raw.dta", replace



** GENERATE ADDITIONAL VARIABLES
clear all
use "$working_ANALYSIS/processed/hansen20pct_raw.dta"
*all potential groups
gen cell_groups = 0 if share_area_north_sccp==0 & share_area_sccp==0
replace cell_groups = 2 if share_area_north_sccp>=0.8 & share_area_sccp >= 0.8
replace cell_groups = 3 if share_area_north_sccp <0.8 & share_area_sccp >= 0.8
replace cell_groups = 4 if share_area_np > 0
* spill over group based on distance to project area (5km radius)
replace cell_groups = 1 if mean_distancetoprojectarea <= 5000 & share_area_sccp < 0.8 & share_area_np == 0
lab def groupie 0 "Control" 2 "SCCP: EU area" 3 "SCCP: Envirotrade area"  4 "National Park" 1 "Spill-over (5km radius)", replace
lab val cell_groups groupie
tab cell_groups



* Treatment variable 2: control cells, spillover northern project area
*spillover group for northern projectarea
gen spillover_north = 0
replace spillover_north = 1 if mean_distancetoprojectareain <= 5000 & share_area_north_sccp < 0.8 & cell_groups!=3 & share_area_np==0


*cell groups2 with eu pilot spillover area
gen cell_groups2 = 0 if cell_groups==0
replace cell_groups2 = 1 if cell_groups==2
replace cell_groups2 = 2 if cell_groups==3
replace cell_groups2 = 3 if spillover_north==1
lab def groupie2 0 "Control" 1 "SCCP: EU Pilot area" 2 "SCCP: Envirotrade area" 3 "EU Pilot: Spillover area", replace
lab val cell_groups2 groupie2
tab cell_groups2


* treated north only
gen treated_north = 0 if cell_groups == 0
replace treated_north = 1 if cell_groups == 2
lab def treatie3 0 "Control" 1 "SCCP EU-Phase", replace
lab val treated_north treatie3
tab treated_north 

*squared variables
gen sq_slope = mean_slope*mean_slope
gen sq_elevation = mean_elevation*mean_elevation


*PRE & POST-SCCP land cover changes (REDD+ Component)
sum forest1996 forest2002  forest2014 forest2019 irrigated1996 irrigated2002 irrigated2019 plantation1996 plantation2002 plantation2019 settlement1996 settlement2002 settlment2019 
gen fcc_02_96 =  forest2002 - forest1996
gen fcc_19_14 = forest2019 - forest2014


** LABELLING VARIABLES
lab var mean_distanceton1andn6 "Distance to main road (m)"
lab var mean_distance_roads "Distance road (m)"
lab var mean_distanceagriculture50 "Distance to next cell with at least 50% cropland (m)"
lab var mean_distance_np "Distance to Gorongosa National Park (m)"
lab var mean_slope "Average slope (degree)"
lab var sq_slope "Squared slope"
lab var mean_elevation "Average altitude (m)"
lab var sq_slope "Squared slope"
lab var forest2002 "Forest cover in 2002"
lab var fcc_02_96 "Forest cover change 02-96"


*drop irrelevant variables
drop _ID area  denseforest_1996pxl denseforest_2002pxl denseforest_2019pxl sparseforest_1996pxl sparseforest_2002pxl sparseforest_2019pxl irrigated1996 irrigated2002 irrigated2019 irrig96cou irrig02cou irrig19cou plantation1996 plantation2002 plantation2019 plant96cou plant02cou plant19cou burnedareas_2002_forestpxl burnedareas_2019_forestpxl


save "$working_ANALYSIS/processed/hansen20pct_rdy.dta", replace


*--------------------------------------
* (4) HANSEN 30pct forest cover data
*--------------------------------------
* Load excel data-sheet and save as dta file
clear all
import delimited using  "$working_ANALYSIS/data/remote_sensing/hansen_panel_2000_2019_30pct.csv", 
describe

save "$working_ANALYSIS/processed/hansen30pct_raw_input.dta", replace

*merge with shape file info
use "$working_ANALYSIS/processed/hansen30pct_raw_input.dta"
rename grid_id id
rename forest_cover_30pct forest30pct
reshape wide forest30pct, i(id) j(year)
merge 1:1 id using "$working_ANALYSIS/data/remote_sensing/sccp_db"
drop _merge

drop unnamed34 unnamed43

save "$working_ANALYSIS/processed/hansen30pct_raw.dta", replace



** GENERATE ADDITIONAL VARIABLES
clear all
use "$working_ANALYSIS/processed/hansen30pct_raw.dta"
*all potential groups
gen cell_groups = 0 if share_area_north_sccp==0 & share_area_sccp==0
replace cell_groups = 2 if share_area_north_sccp>=0.8 & share_area_sccp >= 0.8
replace cell_groups = 3 if share_area_north_sccp <0.8 & share_area_sccp >= 0.8
replace cell_groups = 4 if share_area_np > 0
* spill over group based on distance to project area (5km radius)
replace cell_groups = 1 if mean_distancetoprojectarea <= 5000 & share_area_sccp < 0.8 & share_area_np == 0
lab def groupie 0 "Control" 2 "SCCP: EU area" 3 "SCCP: Envirotrade area"  4 "National Park" 1 "Spill-over (5km radius)", replace
lab val cell_groups groupie
tab cell_groups



* Treatment variable 2: control cells, spillover northern project area
*spillover group for northern projectarea
gen spillover_north = 0
replace spillover_north = 1 if mean_distancetoprojectareain <= 5000 & share_area_north_sccp < 0.8 & cell_groups!=3 & share_area_np==0


*cell groups2 with eu pilot spillover area
gen cell_groups2 = 0 if cell_groups==0
replace cell_groups2 = 1 if cell_groups==2
replace cell_groups2 = 2 if cell_groups==3
replace cell_groups2 = 3 if spillover_north==1
lab def groupie2 0 "Control" 1 "SCCP: EU Pilot area" 2 "SCCP: Envirotrade area" 3 "EU Pilot: Spillover area", replace
lab val cell_groups2 groupie2
tab cell_groups2


* treated north only
gen treated_north = 0 if cell_groups == 0
replace treated_north = 1 if cell_groups == 2
lab def treatie3 0 "Control" 1 "SCCP EU-Phase", replace
lab val treated_north treatie3
tab treated_north 

*squared variables
gen sq_slope = mean_slope*mean_slope
gen sq_elevation = mean_elevation*mean_elevation


*PRE & POST-SCCP land cover changes (REDD+ Component)
sum forest1996 forest2002  forest2014 forest2019 irrigated1996 irrigated2002 irrigated2019 plantation1996 plantation2002 plantation2019 settlement1996 settlement2002 settlment2019 
gen fcc_02_96 =  forest2002 - forest1996
gen fcc_19_14 = forest2019 - forest2014


** LABELLING VARIABLES
lab var mean_distanceton1andn6 "Distance to main road (m)"
lab var mean_distance_roads "Distance road (m)"
lab var mean_distanceagriculture50 "Distance to next cell with at least 50% cropland (m)"
lab var mean_distance_np "Distance to Gorongosa National Park (m)"
lab var mean_slope "Average slope (degree)"
lab var sq_slope "Squared slope"
lab var mean_elevation "Average altitude (m)"
lab var sq_slope "Squared slope"
lab var forest2002 "Forest cover in 2002"
lab var fcc_02_96 "Forest cover change 02-96"


*drop irrelevant variables
drop _ID area  denseforest_1996pxl denseforest_2002pxl denseforest_2019pxl sparseforest_1996pxl sparseforest_2002pxl sparseforest_2019pxl irrigated1996 irrigated2002 irrigated2019 irrig96cou irrig02cou irrig19cou plantation1996 plantation2002 plantation2019 plant96cou plant02cou plant19cou burnedareas_2002_forestpxl burnedareas_2019_forestpxl


save "$working_ANALYSIS/processed/hansen30pct_rdy.dta", replace




*------------------
* (5) SURVEY DATA
*------------------
clear all
** Import dataset and automatically label dataset from survey xls form using kobo2stata
kobo2stata using "$working_ANALYSIS/data/survey/sofala_survey.xlsx", xlsform("$working_ANALYSIS/data/survey/survey_sofala_2022_new.xlsx") surveylabel("label::English") choiceslabel("label::English(en)") dropnotes


*Reshape number of animals possessed into wide format
use "$working_ANALYSIS/data/survey/sofala_survey-animals_info.dta", clear
encode animal_selected, gen(animal_)

gen animal = 1 if animal_==7
replace animal = 2 if animal_== 1
replace animal = 3 if animal_== 6
replace animal = 4 if animal_== 2
replace animal = 5 if animal_== 5
replace animal = 6 if animal_== 3
replace animal = 7 if animal_== 4

drop _index animal_selected animal_ _parent_table_name _submission__id _submission__uuid _submission__submission_time _submission__validation_status _submission__notes _submission__status _submission__submitted_by _submission__tags
rename _parent_index _index

reshape wide number_animals, i(_index) j(animal)
save "$working_ANALYSIS/processed/animals_wide.dta", replace


*Reshape information on each owned machamba into wide format
use "$working_ANALYSIS/data/survey/sofala_survey-machamba_info.dta", clear
drop _index _parent_table_name _submission__id _submission__uuid _submission__submission_time _submission__validation_status _submission__notes _submission__status _submission__submitted_by _submission__tags
rename _parent_index _index
reshape wide machamba_size machamba_opened machamba_burned, i(_index) j(machamba_pos)
save "$working_ANALYSIS/processed/machamba_wide.dta", replace


*merge machamba, animal and distance to Nhambita data to main dataset
use "$working_ANALYSIS/data/survey/sofala_survey-survey_sofala_2022_new.dta", clear

* Clear errors in village names and IDs.
* NOTE: this is the only village name left anywhere in the package. It is the
* project's namesake village, which the paper identifies implicitly by naming
* the project, the district and the developer, so it is not treated as
* confidential. Every other village name was removed, and the shipped data
* carry anonymous numeric village IDs only. This block never runs from the
* public package, since the raw survey it operates on is not distributed.
replace village="Nhambita" if village=="Nhambinta"
replace village_id = 1 if village=="Nhambita"
sort village_id


*repeat group: animals
merge 1:1 _index using "$working_ANALYSIS/processed/machamba_wide.dta"
drop _merge

*repeat group: animals
merge 1:1 _index using "$working_ANALYSIS/processed/animals_wide.dta"
drop _merge

*merge distance to nhambita at village level
merge m:1 village_id using  "$working_ANALYSIS/processed/rs_village_data.dta"
drop _merge


* CONFIDENTIALITY: drop direct identifiers before anything is written to disk.
* These variables are not used anywhere in the cleaning or the analysis.
drop phonenumber surname name gps_coord ///
     _gps_coord_latitude _gps_coord_longitude _gps_coord_altitude _gps_coord_precision

save "$working_ANALYSIS/processed/survey_merged.dta", replace

**


*--------------------------------------------------
* General cleaning
*--------------------------------------------------
use "$working_ANALYSIS/processed/survey_merged.dta", clear
* check for duplicate IDs
tab respondent_id
duplicates report respondent_id enumerator
duplicates list respondent_id enumerator

*unique respondent id
rename _index id
lab var id "unique respondent id" 
order id, b(start)

*did participant give consent?
tab consent, m
drop if consent == 0

*recode don't knows and will not say answers
ds, has(type numeric)

foreach v in `r(varlist)' {
	replace `v' = . if `v' == -88 
	replace `v' = . if `v' == -99
}


*fix errors in entered village ids
replace village_id = 1 if today == "2022-07-25"
replace village_id = 15 if respondent_id == 860
tab village_id

tab today

tab enumerator
* One enumerator used the wrong village ID (11) for part of the sample;

*drop variables that are not needed or empty
missings dropvars, force
drop R1 R2 R3 R4 vignette_season_pt vignette_animal_pt _status _submitted_by _uuid start_geopoint _start_geopoint_latitude _start_geopoint_longitude _start_geopoint_altitude _start_geopoint_precision deviceid written_consent written_consent_URL
* -------------------------------------------------




*--------------------------------------------------
* Generate variables
*--------------------------------------------------
*treatment identifier
lab define treatie 0 "Control" 1 "Win-Win" 2 "Trade-off" 3 "Legacy", replace
lab val treat treatie

*SCCP area identifier
gen sccp_area = 0
replace sccp_area = 1 if village_id <20
lab var sccp_area "Participant lives in village that was part of the SCCP project."
lab def sccp_lab 0 "Control" 1 "Treatment", replace
lab val sccp_area sccp_lab

*can respondents in SCCP villages remember the SCCP?
gen recall_SCCP = 0
replace recall_SCCP = 1 if sccp_recall==1 | sccp_recall2 == 1
replace recall_SCCP = . if sccp_area==0

*Calculate survey section durations
generate double start_time = Clock(start, "YMD#hms#",2022)
format start_time %tcHH:MM:SS

generate double end_time = Clock(end, "YMD#hms#",2022)
format end_time %tcHH:MM:SS

* convert time measurements to miliseconds
replace duration_treatment = duration_treatment * 1000
replace duration_treatment = duration_treatment1*1000 if duration_treatment == .
replace duration_treatment = duration_treatment2*1000 if duration_treatment == .
drop duration_treatment1 duration_treatment2

replace duration_tasks = duration_tasks * 1000
replace duration_survey = duration_survey * 1000

* create new duration from beginning of treatments to end of tasks
gen duration_treattask = (endtime_tasks - starttime_treatment)*1000*60*60*24

gen duration_total = (end_time - start_time)
format duration_* %tCHH:MM:SS

tabstat duration_total duration_treatment duration_tasks duration_treattask duration_survey, s(mean p50) f
order duration_treatment duration_tasks duration_treattask duration_survey, a(duration_total)
drop endtime_treatment1 endtime_treatment2 endtime_treatment endtime_tasks endtime_survey starttime_survey starttime_treatment


*DONATION DECISIONS
gen donation_ppf = donation_ppf1
replace donation_ppf = donation_ppf2 if donation_ppf1 == .
drop donation_ppf1 donation_ppf2

gen donation_sef = donation_sef1
replace donation_sef = donation_sef2 if donation_sef1 == .
drop donation_sef1 donation_sef2

gen total_donation = donation_ppf + donation_sef

order donation_ppf donation_sef total_donation, b(impact_ppf)

tabstat donation_ppf donation_sef total_donation, s(mean sd p50)
drop amount_keep1 amount_keep2 amount_left1 amount_left2


*Calculate earnings
gen payoff_final = .
replace payoff_final = coin_self if experiment_payout == 1
replace payoff_final = 160 - donation_ppf - donation_sef if experiment_payout == 2
tab payoff_final


* Machambas owned: size, how many years ago opened, share burned
*average size and total size of all machambas
egen total_size_machambas=rowtotal(machamba_size1 machamba_size2 machamba_size3 machamba_size4 machamba_size5 machamba_size6 machamba_size7)
egen average_size_machambas=rowmean(machamba_size1 machamba_size2 machamba_size3 machamba_size4 machamba_size5 machamba_size6 machamba_size7)
*winsor outliers at 99th percentile
winsor2 total_size_machambas, replace cuts (0 99)

*average time since the machambas were opened, and most recent opened machamba
egen machamba_opened_average=rowmean(machamba_opened1 machamba_opened2 machamba_opened3 machamba_opened4 machamba_opened5 machamba_opened6 machamba_opened7)
egen machamba_last_opened=rowmin(machamba_opened1 machamba_opened2 machamba_opened3 machamba_opened4 machamba_opened5 machamba_opened6 machamba_opened7)

*share of machambas at least partly burned
gen machamba_burned_new1= 0 if machamba_burned1==1
replace machamba_burned_new1= 1 if machamba_burned1>1
gen machamba_burned_new2= 0 if machamba_burned2==1
replace machamba_burned_new2= 1 if machamba_burned2>1
replace machamba_burned_new2= . if machamba_burned2==.
gen machamba_burned_new3= 0 if machamba_burned3==1
replace machamba_burned_new3= 1 if machamba_burned3>1
replace machamba_burned_new3= . if machamba_burned3==.
gen machamba_burned_new4= 0 if machamba_burned4==1
replace machamba_burned_new4= 1 if machamba_burned4>1
replace machamba_burned_new4= . if machamba_burned4==.
gen machamba_burned_new5= 0 if machamba_burned5==1
replace machamba_burned_new5= 1 if machamba_burned5>1
replace machamba_burned_new5= . if machamba_burned5==.
gen machamba_burned_new6= 0 if machamba_burned6==1
replace machamba_burned_new6= 1 if machamba_burned6>1
replace machamba_burned_new6= . if machamba_burned6==.
gen machamba_burned_new7= 0 if machamba_burned7==1
replace machamba_burned_new7= 1 if machamba_burned7>1
replace machamba_burned_new7= . if machamba_burned7==.
egen machamba_burned_average=rowmean(machamba_burned_new1 machamba_burned_new2 machamba_burned_new3 machamba_burned_new4 machamba_burned_new5 machamba_burned_new6 machamba_burned_new7)

*extensive margin
gen burned100=0
replace burned100=100 if machamba_burned_average>0

*intensive margin
replace machamba_burned_average=. if machamba_burned_average==0
gen machamba_burned100 = 100*machamba_burned_average



*Tree planting after the end of the SCCP (since 2016)
gen no_trees1622 = machamba_agroforestry_5years0
gen boundary_1622 = machamba_agroforestry_5years1
egen interplanting_1622 = rowmax(machamba_agroforestry_5years5 machamba_agroforestry_5years6 machamba_agroforestry_5years7)
egen fruit_trees1622 = rowmax(machamba_agroforestry_5years3 machamba_agroforestry_5years4)
egen homestead1622 = rowmax(machamba_agroforestry_5years2 machamba_agroforestry_5years8)

order total_size_machambas average_size_machambas machamba_opened_average machamba_last_opened machamba_burned_average no_trees1622 boundary_1622 interplanting_1622 fruit_trees1622 homestead1622 machamba_size1 machamba_size2 machamba_size3 machamba_size4 machamba_size5 machamba_size6 machamba_size7 machamba_burned1 machamba_burned2 machamba_burned3 machamba_burned4 machamba_burned5 machamba_burned6 machamba_burned7  machamba_opened1 machamba_opened2 machamba_opened3 machamba_opened4 machamba_opened5 machamba_opened6 machamba_opened7, a(number_machambas)

*Agroforestry contracts
replace sccp_agroforestry_number = 0 if recall_SCCP==1 & sccp_agroforestry_number==.
gen sccp_agroforestry = 0 if sccp_agroforestry_number==0
replace sccp_agroforestry = 100 if sccp_agroforestry_number>0
replace sccp_agroforestry = . if sccp_agroforestry_number==.
gen sccp_boundary = 100*sccp_agroforestry_contracts1
egen sccp_interplanting = rowmax(sccp_agroforestry_contracts5 sccp_agroforestry_contracts6)
replace sccp_interplanting = 100*sccp_interplanting
egen sccp_fruit_trees = rowmax(sccp_agroforestry_contracts3 sccp_agroforestry_contracts4)
replace sccp_fruit_trees= 100*sccp_fruit_trees
gen sccp_homestead = 100*sccp_agroforestry_contracts2
gen sccp_woodlot = 100*sccp_agroforestry_contracts7

*Agroforestry systems still in place in 2022
gen sccp_boundary2022 = 100*sccp_agroforestry_inplace1  if sccp_agroforestry_contracts1==1
egen sccp_interplanting2022 = rowmax(sccp_agroforestry_inplace5 sccp_agroforestry_inplace6)  if sccp_agroforestry_contracts5==1 | sccp_agroforestry_contracts6==1
replace sccp_interplanting2022 = 100*sccp_interplanting2022  
egen sccp_fruit_trees2022 = rowmax(sccp_agroforestry_inplace3 sccp_agroforestry_inplace4) if sccp_agroforestry_contracts3==1 | sccp_agroforestry_contracts4==1
replace sccp_fruit_trees2022= 100*sccp_fruit_trees2022
gen sccp_homestead_2022 = 100*sccp_agroforestry_inplace2 if sccp_agroforestry_contracts2==1
gen sccp_woodlot2022 = 100*sccp_agroforestry_inplace7 if sccp_agroforestry_contracts7==1

*percent
foreach x of varlist no_trees1622 boundary_1622 interplanting_1622 fruit_trees1622 homestead1622 sccp_reason_keep1 sccp_reason_keep2 sccp_reason_keep3 sccp_reason_keep4 sccp_reason_keep5 {
    replace `x'=100*`x'
}



* generate Tropical Livestock Units (TLU) based on owned livestock animals
*conversion factors used: cow = 1; pig = 0.2:; goat/sheep = 0.1, poultry = 0.01
gen tlu_animals1 = number_animals1*1
gen tlu_animals2 = number_animals2*0.15
gen tlu_animals3 = number_animals3*0.2
gen tlu_animals4 = number_animals4*0.01
gen tlu_animals5 = number_animals5*0.01
gen tlu_animals6 = number_animals6*0.01
egen TLU = rowtotal(tlu_animals1 tlu_animals2 tlu_animals3 tlu_animals4 tlu_animals5 tlu_animals6)
*winsor outliers at 99th percentile
winsor2 TLU, replace cuts (0 99)
order TLU number_animals1 number_animals2 number_animals3 number_animals4 number_animals5 number_animals6 tlu_animals1 tlu_animals2 tlu_animals3 tlu_animals4 tlu_animals5 tlu_animals6, a(animals99)


*generate wealth index based on owned assets, living conditions, farm land owned, livestock owned
gen roof = 0 if roof_material!=.
replace roof = 1 if roof_material == 1 | roof_material == 2 |roof_material == 3
lab var roof "1= improved roof material such as iron sheets, tiles or concrete"

gen floor = 0 if floor_material!=.
replace floor = 1 if floor_material == 1 | floor_material == 2 |floor_material == 3
lab var floor "1= improved floor material such as concrete, bricks, cement"

gen wall = 0 if wall_material!=.
replace wall = 1 if wall_material == 1 | wall_material == 3
lab var wall "1= improved floor material such as burned bricks and cement blocks"

*set hh_assets to missing if respondent selected dont know or will not say
foreach x of varlist  hh_assets2 hh_assets3 hh_assets4 hh_assets5 hh_assets6 hh_assets7 hh_assets8 hh_assets9 {
	replace `x' = . if hh_assets == "-88" | hh_assets == "-99"
}

egen total_assets_owned=rowtotal(hh_assets1 hh_assets2 hh_assets3 hh_assets4 hh_assets5 hh_assets6 hh_assets7 hh_assets8 hh_assets9)


pca total_assets_owned TLU total_size_machambas
predict wealth_index
lab var wealth_index "Wealth index based on owned assets, farmland, livestock"
egen z_wealth_index = std (wealth_index)
lab var z_wealth_index "Standardized (z-score) wealth index"

xtile cat_wealth=z_wealth_index, nq(5)
label define quints 1 "Poorest" 2 "Poor" 3 "Medium" 4 "Wealthy" 5 "Wealthiest"
label values cat_wealth quints

*Household income: good, bad, average month
sum hh_income_avg hh_income_good hh_income_bad, detail
*restrict outliers in reported incomes: winsor at 1th and 99th percentile
winsor2 hh_income_avg hh_income_good hh_income_bad , replace cuts(1 99)
sum hh_income_avg hh_income_good hh_income_bad, detail
order wealth_index z_wealth_index cat_wealth hh_income_avg hh_income_good hh_income_bad hh_food, b(people_hh)



*Household size: winsor at 1th and 99th percentile
sum people_hh, detail
winsor2 people_hh, replace cuts(1 99)


**generate indeces based on likert items
* Future orientation
alpha check_future1 check_future2 check_future3
* low alpha and interitem covariance, use as single items?

*Mortality salience
gen check_mortality1_r = 6-check_mortality1
gen check_mortality4_r = 6-check_mortality4
alpha check_mortality1_r check_mortality2 check_mortality3 check_mortality4_r
* low alpha and interitem covariance, use as single items?

* Affinity with future generations
alpha check_affinity1 check_affinity2 check_affinity3 check_affinity4
* low alpha and interitem covariance

* Social dominance orientation
gen check_sdo2_r = 6-check_sdo2
gen check_sdo3_r = 6-check_sdo3
alpha check_sdo1 check_sdo2_r check_sdo3_r check_sdo4
* low alpha and interitem covariance

*Economic agency
gen econ_belief6_r = 6-econ_belief6
gen econ_belief7_r = 6-econ_belief7
gen econ_belief8_r = 6-econ_belief8
pca econ_belief1 econ_belief2 econ_belief3 econ_belief4 econ_belief5 econ_belief6_r econ_belief7_r econ_belief8_r econ_belief9
estat kmo
predict econ_agency


*Environmental agency
gen env_belief8_r = 6-env_belief8
gen env_belief9_r = 6-env_belief9
gen env_belief10_r = 6-env_belief10

alpha env_belief1 env_belief2 env_belief3 env_belief4 env_belief5 env_belief6 env_belief7 env_belief8_r env_belief9_r env_belief10_r
*okay aplha


* TABLES S20 and S21: the factor command prints both the eigenvalue table and
* the loadings/uniqueness table. Neither is returned in a form esttab can
* consume, so the printed output is captured in a dedicated text log.
cap log close factor_log
log using "$working_ANALYSIS/results/tables/tableS20_S21_factor_agency.txt", text name(factor_log) replace

di as text "Table S20. Factor analysis: environmental agency (eigenvalues)"
di as text "Table S21. Loadings of the first factor and unexplained variation"
di as text ""
factor env_belief1 env_belief2 env_belief3 env_belief4 env_belief5 env_belief6 env_belief7 env_belief8_r env_belief9_r env_belief10_r, factors(1)

log close factor_log

estat kmo
*okay Kmo score
predict env_agency

* communal environmental agency

*Intrinsic motivation to plant trees on machamba
gen motivation1_r = 6-motivation1
gen motivation7_r = 6-motivation7
alpha motivation1_r motivation2 motivation3 motivation4
alpha motivation5 motivation6 motivation7_r
* relatively good alpha

pca motivation1_r motivation2 motivation3 motivation4, comp(1)
matrix ev = e(Ev)'
matrix roweq ev = ""
matrix colnames ev = "Eigenvalue"

matrix d = ev - ( ev[2...,1] \ . )
matrix colnames d = "Difference"

matrix p = ev[1...,1] / e(trace)
matrix colnames p = "Proportion"

// I don't know a neat way of doing a cumulative sum
matrix c = J(e(trace),1,0)
matrix c[1,1] = p[1,1]
forvalues i=2/`e(trace)' {
    matrix c[`i',1] = c[`=`i'-1',1] + p[`i',1]
    }
matrix colnames c = "Cumulative"

matrix t = ( ev , d , p , c )
matrix list t

estadd matrix table = t

esttab ., ///
    cells("table[Eigenvalue](t fmt(2)) table[Difference](t fmt(2)) table[Proportion](t fmt(2)) table[Cumulative](t fmt(2))") ///
    nogap noobs nonumber nomtitle
esttab . using "$working_ANALYSIS/results/tables/tableS18_pca_motivations.rtf", rtf replace ///
    cells("table[Eigenvalue](t fmt(2)) table[Difference](t fmt(2)) table[Proportion](t fmt(2)) table[Cumulative](t fmt(2))") ///
    nogap noobs nonumber nomtitle
esttab ., ///
    cells("L[Comp1](t fmt(2)) Psi[Unexplained]" ) ///
   nogap noobs nonumber nomtitle
esttab . using "$working_ANALYSIS/results/tables/tableS19_pca_loadings.rtf", rtf replace ///
    cells("L[Comp1](t fmt(2)) Psi[Unexplained]") ///
    nogap noobs nonumber nomtitle label

predict intrinsic_motivations_trees

	
*Extrinsic motivation to plant trees on machamba
pca motivation5 motivation6 motivation7_r, comp(1)
matrix ev = e(Ev)'
matrix roweq ev = ""
matrix colnames ev = "Eigenvalue"

matrix d = ev - ( ev[2...,1] \ . )
matrix colnames d = "Difference"

matrix p = ev[1...,1] / e(trace)
matrix colnames p = "Proportion"

// I don't know a neat way of doing a cumulative sum
matrix c = J(e(trace),1,0)
matrix c[1,1] = p[1,1]
forvalues i=2/`e(trace)' {
    matrix c[`i',1] = c[`=`i'-1',1] + p[`i',1]
    }
matrix colnames c = "Cumulative"

matrix t = ( ev , d , p , c )
matrix list t

estadd matrix table = t

esttab ., ///
    cells("table[Eigenvalue](t fmt(2)) table[Difference](t fmt(2)) table[Proportion](t fmt(2)) table[Cumulative](t fmt(2))") ///
    nogap noobs nonumber nomtitle
esttab . using "$working_ANALYSIS/results/tables/tableS18_pca_motivations.rtf", rtf append ///
    cells("table[Eigenvalue](t fmt(2)) table[Difference](t fmt(2)) table[Proportion](t fmt(2)) table[Cumulative](t fmt(2))") ///
    nogap noobs nonumber nomtitle
esttab ., ///
    cells("L[Comp1](t fmt(2)) Psi[Unexplained]" ) ///
   nogap noobs nonumber nomtitle
esttab . using "$working_ANALYSIS/results/tables/tableS19_pca_loadings.rtf", rtf append ///
    cells("L[Comp1](t fmt(2)) Psi[Unexplained]") ///
    nogap noobs nonumber nomtitle label
	
predict extrinsic_motivations_trees


** Label variables 
lab var female "Female (=1)"
lab var same_place "Born here (=1)"
lab var people_hh "HH size"
lab var people_hh_below14 "HH members < 14 years"
lab var age "Age"
lab var edu_years "Education in years"
** sccp identifier
tab sccp_area
tab hh_food, gen(hh_food)


gen sccp_id = 0 if sccp_area==0
replace sccp_id = 1 if sccp_area==1
replace sccp_id = 2 if sccp_agroforestry==0 & sccp_job==1
replace sccp_id = 3 if sccp_agroforestry==100 & sccp_job==0
replace sccp_id = 4 if sccp_agroforestry==100 & sccp_job==1

lab def sccp_ident 0 "Control" 1 "Community REDD+" 2 "REDD+ & Job" 3 "REDD+ & Agroforestry" 4 "REDD+  & Agroforestry & Job", replace
lab val sccp_id sccp_ident
tab sccp_id


*standardize dependent variables
foreach x of varlist hh_income_avg econ_ladder1 TLU total_size_machambas total_assets_owned {
	egen z_`x' = std(`x')
}

* -------------------------------------------------

*drop variables that would allow identification of participants
* CONFIDENTIALITY: drop the indirect identifiers now that the cleaning steps
* that needed them (village-ID corrections, duplicate checks, interview
* duration) are complete. village_id is retained as an anonymous numeric code;
* the survey duration is retained, the raw timestamps are not.
drop enumerator village respondent_id today start end start_time end_time
capture drop distance_nhambita_m

* CONFIDENTIALITY: drop the remaining timestamps, place names and open-ended
* free-text fields. None are used in the analysis; several could identify a
* respondent in a sample of 738 households across a small number of villages.
foreach v in start_001 end_001 _submission_time origin_village comment ///
             agroforestry_project_orga hh_decision_maker_other ///
             reason_moving_here_oth wildlife_damage_det_oth ///
             wildlife_damage_animal_oth park_advantage_other ///
             park_disadvantage_other sccp_reason_keep_other ///
             sccp_reason_not_keep_other sccp_reason_no_pay_other ///
             sccp_invest_payments_oth sccp_invest_redd_oth ///
             hh_work_np_type_other hh_apply_np_type_other ///
             hh_piecework_type_other floor_material_other ///
             roof_material_other wall_material_other ///
             latitude longitude {
	capture drop `v'
}



save "$working_ANALYSIS/processed/survey_rdy.dta", replace




 
** EOF
