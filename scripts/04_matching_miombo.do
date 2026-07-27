*--------------------------------------------------------------------
* SCRIPT:  04_matching_miombo.do
* PURPOSE: Supplementary specification. Repeats the matching of
*          02_matching_hansen20.do on the project's own miombo-specific
*          remote-sensing classification (1996-2019) rather than on Hansen
*          Global Forest Change.
*
* INPUT:   processed/remote_sensing_rdy.dta
*          data/remote_sensing/sccp_coord.dta   (cell polygons for the maps)
*
* OUTPUT:  processed/remote_sensing_matched.dta
*          results/diagnostics/diag_balancing_before_miombo.xlsx
*          results/diagnostics/diag_support_bias_miombo.png
*          results/diagnostics/diag_matching_maps_miombo.png
*
*          None of the diagnostics above appear in the paper; the miombo
*          results reported in Figures S7-S8 and Tables S12-S16 come from
*          08_did_miombo.do, which uses the matched dataset written here.
*
* DEPENDS: psmatch2, rbounds, iebaltab, spmap
* RUN VIA: run.do (do not run standalone; requires $working_ANALYSIS)
*--------------------------------------------------------------------

clear all
use "$working_ANALYSIS/processed/remote_sensing_rdy.dta"

* Reproducibility: psmatch2 without replacement breaks ties by the current
* sort order, so fix both the seed and the sort before any matching.
set seed 20260727
sort id

*rename variables
rename (*ha) (*)
rename (*_1996) (*1996)
rename (*_2002) (*2002)
rename (*_2019) (*2019)
rename *, lower
rename burnedareas_2002_cropland burned_crop2002
rename burnedareas_2019_cropland burned_crop2019
rename burnedareas_2002_forest burned_forest2002
rename burnedareas_2019_forest burned_forest2019

foreach x of varlist burned_forest2002 burned_forest2019 burned_crop2002 burned_crop2019 denseforest1996 sparseforest1996 denseforest2002 sparseforest2002 denseforest2019 sparseforest2019 potentialpes {
	replace `x' = (`x'/9)*100
}

foreach x of varlist forest1996 forest2002 forest2014 forest2019 {
	replace `x' = `x'*100
}

gen dense_02_96 =  denseforest2002 - denseforest1996
gen sparse_02_96 =  sparseforest2002 - sparseforest1996


* gen new spillover areas: 2km, 3km, 5km
gen spillover_2km = 0
replace spillover_2km = 1 if mean_distancetoprojectareain <=2000
replace spillover_2km = . if mean_distancetoprojectareain==0
replace spillover_2km = . if cell_groups==4

gen spillover_5km = 0
replace spillover_5km = 1 if mean_distancetoprojectareain <=5000
replace spillover_5km = . if mean_distancetoprojectareain==0
replace spillover_5km = . if cell_groups==4

gen spillover_10km = 0
replace spillover_10km = 1 if mean_distancetoprojectareain <=10000
replace spillover_10km = . if mean_distancetoprojectareain==0
replace spillover_10km = . if cell_groups==4


* DEFINE PROJECT AREA
gen sccp=0 
replace sccp=1 if treated_north==1
replace sccp=. if spillover_5km==1
replace sccp=. if cell_groups==4

*Combined area
gen combined = 0 
replace combined = 1 if sccp == 1 | spillover_5km==1
replace combined=. if cell_groups==4


* Pre-treatment balancing table including all the matching variables
global balance mean_distanceurban mean_distance_roads mean_distanceagriculture50  mean_slope mean_elevation forest1996 forest2002 fcc_02_96 sparseforest1996 sparseforest2002 sparse_02_96 denseforest1996 denseforest2002 dense_02_96 burned_forest2002 burned_crop2002
iebaltab $balance, grpvar(sccp) control(0) format(%9.2f) onerow savexlsx("$working_ANALYSIS/results/diagnostics/diag_balancing_before_miombo.xlsx") replace
reg sccp $balance  
 

*--------------------------------------------------
* PROPENSITY SCORE MATCHING (PSM) 
*--------------------------------------------------
* Cells are matched one-to-one without replacement on the propensity score,
* with common support imposed. Standard errors in the downstream DiD are
* clustered at the matched-pair level rather than adjusted for the estimation
* of the propensity score, following Ho, Imai, King and Stuart (2007): the
* analysis run on the matched sample is the one that would have been run on
* the full sample, with no further matching adjustment.



* Set list of confounders on which we want to match control cells with SCCP cells
global confounders mean_distanceurban mean_distance_roads mean_distanceagriculture50 mean_slope sq_slope mean_elevation sq_elevation forest2002 fcc_02_96 burned_forest2002 burned_crop2002 denseforest2002 dense_02_96 sparseforest2002 sparse_02_96 if cell_groups < 4

*Robustness check: Rosenbaum bounds
psmatch2 sccp $confounders, outc(forest2014 forest2019) n(1) noreplacement common
gen delta = forest2014 - _forest2014 if _treat==1 & _support==1
gen delta2 = forest2019 - _forest2019 if _treat==1 & _support==1
rbounds delta, gamma(1 (0.2) 2)  
rbounds delta2, gamma(1 (0.2) 2.6)   


*--------------
*SCCP Area
*--------------
**ATT -> make control cells as similar as treatment, NNM without replacement
psmatch2 sccp $confounders, n(1) noreplacement common
psgraph, title("{bf:A } SCCP area", span pos(11)) legend(rows(2))
gr save "$working_ANALYSIS/results/intermediate/common_support_sccp.gph", replace
pstest $confounders, both graph legend(rows(2) pos(6) size(6pt) ring(1))
gr save "$working_ANALYSIS/results/intermediate/bias_reduction_sccp.gph", replace
* (bias reduction is reported in the run log)
tab _support _treated, column 

gr combine "$working_ANALYSIS/results/intermediate/common_support_sccp.gph" "$working_ANALYSIS/results/intermediate/bias_reduction_sccp.gph", xsize(3.465) ysize(2) rows(1) 
gr save "$working_ANALYSIS/results/intermediate/matching_sccp.gph", replace

* gen matched pair identifier
gen sccp_pair = _id if _treated==0 
replace sccp_pair = _n1 if _treated==1
bysort sccp_pair: egen sccp_paircount = count(sccp_pair)
foreach x of varlist _weight _id _pscore _pdif _n1 _nn _treated _support {
		rename `x'  sccp`x'
}

gen     iptw_sccp = 1 / sccp_pscore if sccp_treated==1
replace iptw_sccp = 1 / (1 - sccp_pscore) if sccp_treated==0



*------------------------------------
* Spillovers: 2km 
*------------------------------------
**ATT -> make control cells as similar as treatment, NNM without replacement
psmatch2 spillover_2km $confounders, n(1) noreplacement  common
psgraph, title("{bf:B } 2-km spillover area", span pos(11)) legend(rows(2))
gr save "$working_ANALYSIS/results/intermediate/common_support_spillover2k.gph", replace
pstest $confounders, both  graph  legend(rows(2) pos(6) size(6pt) ring(1))
gr save "$working_ANALYSIS/results/intermediate/bias_reduction_spillover2k.gph", replace
* (bias reduction is reported in the run log)
tab _support _treated, column 
* (matched-cell counts are reported in the run log)
gr combine "$working_ANALYSIS/results/intermediate/common_support_spillover2k.gph" "$working_ANALYSIS/results/intermediate/bias_reduction_spillover2k.gph", xsize(3.465) ysize(2) rows(1) 
gr save "$working_ANALYSIS/results/intermediate/matching_spillover2k.gph", replace

* gen matched pair identifier
gen spillover2k_pair = _id if _treated==0 
replace spillover2k_pair = _n1 if _treated==1
bysort spillover2k_pair: egen spillover2k_paircount = count(spillover2k_pair)
foreach x of varlist _weight _id _pscore _pdif _n1 _nn _treated _support {
		rename `x'  spillover2k`x'
}

gen     iptw_spillover2k = 1 / spillover2k_pscore if spillover2k_treated==1
replace iptw_spillover2k = 1 / (1 - spillover2k_pscore) if spillover2k_treated==0



*------------------------------------
* Spillovers: 5-km 
*------------------------------------
**ATT -> make control cells as similar as treatment, NNM without replacement
psmatch2 spillover_5km $confounders, n(1) noreplacement  common
psgraph, title("{bf:C } 5-km spillover area", span pos(11)) legend(rows(2))
gr save "$working_ANALYSIS/results/intermediate/common_support_spillover5k.gph", replace
pstest $confounders, both  graph  legend(rows(2) pos(6) size(6pt) ring(1))
gr save "$working_ANALYSIS/results/intermediate/bias_reduction_spillover5k.gph", replace
* (bias reduction is reported in the run log)
tab _support _treated, column 

gr combine "$working_ANALYSIS/results/intermediate/common_support_spillover5k.gph" "$working_ANALYSIS/results/intermediate/bias_reduction_spillover5k.gph", xsize(3.465) ysize(2) rows(1) 
gr save "$working_ANALYSIS/results/intermediate/matching_spillover5k.gph", replace

* gen matched pair identifier
gen spillover5k_pair = _id if _treated==0 
replace spillover5k_pair = _n1 if _treated==1
bysort spillover5k_pair: egen spillover5k_paircount = count(spillover5k_pair)
foreach x of varlist _weight _id _pscore _pdif _n1 _nn _treated _support {
		rename `x'  spillover5k`x'
}

gen     iptw_spillover5k = 1 / spillover5k_pscore if spillover5k_treated==1
replace iptw_spillover5k = 1 / (1 - spillover5k_pscore) if spillover5k_treated==0



*------------------------------------
* Spillovers: 10-km 
*------------------------------------
**ATT -> make control cells as similar as treatment, NNM without replacement
psmatch2 spillover_10km $confounders, n(1) noreplacement  common
psgraph, title("{bf:D } 10-km spillover area", span pos(11)) legend(rows(2))
gr save "$working_ANALYSIS/results/intermediate/common_support_spillover10k.gph", replace
pstest $confounders, both  graph  legend(rows(2) pos(6) size(6pt) ring(1))
gr save "$working_ANALYSIS/results/intermediate/bias_reduction_spillover10k.gph", replace
* (bias reduction is reported in the run log)
tab _support _treated, column 

gr combine "$working_ANALYSIS/results/intermediate/common_support_spillover10k.gph" "$working_ANALYSIS/results/intermediate/bias_reduction_spillover10k.gph", xsize(3.465) ysize(2) rows(1) 
gr save "$working_ANALYSIS/results/intermediate/matching_spillover10k.gph", replace

* gen matched pair identifier
gen spillover10k_pair = _id if _treated==0 
replace spillover10k_pair = _n1 if _treated==1
bysort spillover10k_pair: egen spillover10k_paircount = count(spillover10k_pair)
foreach x of varlist _weight _id _pscore _pdif _n1 _nn _treated _support {
		rename `x'  spillover10k`x'
}

gen     iptw_spillover10k = 1 / spillover10k_pscore if spillover10k_treated==1
replace iptw_spillover10k = 1 / (1 - spillover10k_pscore) if spillover10k_treated==0



*---------------------------------------------------------
* Spillovers: SCCP + 5-km Spillover area
*---------------------------------------------------------
**ATT -> make control cells as similar as treatment, NNM without replacement
psmatch2 combined $confounders, n(1) noreplacement  common
psgraph, title("{bf:E } SCCP + 5km Spillover", span pos(11)) legend(rows(2))
gr save "$working_ANALYSIS/results/intermediate/common_support_combined.gph", replace
pstest $confounders, both  graph  legend(rows(2) pos(6) size(6pt) ring(1))
gr save "$working_ANALYSIS/results/intermediate/bias_reduction_combined.gph", replace
* (bias reduction is reported in the run log)
tab _support _treated, column 
* (matched-cell counts are reported in the run log)
gr combine "$working_ANALYSIS/results/intermediate/common_support_combined.gph" "$working_ANALYSIS/results/intermediate/bias_reduction_combined.gph", xsize(3.465) ysize(2) rows(1) 
gr save "$working_ANALYSIS/results/intermediate/matching_combined.gph", replace

* gen matched pair identifier
gen combined_pair = _id if _treated==0 
replace combined_pair = _n1 if _treated==1
bysort combined_pair: egen combined_paircount = count(combined_pair)
foreach x of varlist _weight _id _pscore _pdif _n1 _nn _treated _support {
		rename `x'  combined`x'
}

gen     iptw_combined = 1 / combined_pscore if combined_treated==1
replace iptw_combined = 1 / (1 - combined_pscore) if combined_treated==0


// COMBINE ALL MATCHING FIGURES
gr combine "$working_ANALYSIS/results/intermediate/matching_sccp" "$working_ANALYSIS/results/intermediate/matching_spillover2k.gph" "$working_ANALYSIS/results/intermediate/matching_spillover5k.gph" "$working_ANALYSIS/results/intermediate/matching_spillover10k.gph" "$working_ANALYSIS/results/intermediate/matching_combined.gph", xsize(4) ysize(4) rows(3) 
gr save "$working_ANALYSIS/results/intermediate/matching_support_bias.gph", replace
gr export  "$working_ANALYSIS/results/diagnostics/diag_support_bias_miombo.png", replace width(4000)



// Draw the map with matching information
** ATT
* SCCP area
gen sccp_mapping = .
replace sccp_mapping = 0 if sccp_weight!=.
replace sccp_mapping =1 if sccp_weight!=. & sccp_treated==1
replace sccp_mapping =2 if sccp_weight==. & sccp_treated!=.
replace sccp_mapping =3 if cell_groups==4

* Free the diagnostic graphs from memory before building the maps. They are all
* saved in results/intermediate/ already. The maps below each carry over half a
* million polygon vertices, and Stata's graph engine can run out of resources
* mid-run if the earlier graphs are still resident.
graph drop _all
lab def sccp_lab 2 "Not matched" 0 "matched controls" 1 "matched treated" 3 "Gorongosa National Park", replace
lab val sccp_mapping sccp_lab
spmap sccp_mapping using "$working_ANALYSIS/data/remote_sensing/sccp_coord" if sccp_mapping!=., title("{bf:A} SCCP area") fcolor("220 38 127" "100 143 255" "255 176 0*0.4" green*0.4) id(id) clmethod(unique) ocolor(white ..) osize(0.05 ..)   legend(pos(6) ring(1) rows(1))
gr save "$working_ANALYSIS/results/intermediate/map_sccp_miombo.gph", replace

* 2-km Spillover area
gen spillover2k_mapping = .
replace spillover2k_mapping = 0 if spillover2k_weight!=. & spillover2k_treated==0
replace spillover2k_mapping =1 if spillover2k_weight!=. & spillover2k_treated==1
replace spillover2k_mapping =2 if spillover2k_weight==. & spillover2k_treated!=.
replace spillover2k_mapping =3 if cell_groups==4
lab val spillover2k_mapping sccp_lab
spmap spillover2k_mapping using "$working_ANALYSIS/data/remote_sensing/sccp_coord" if spillover2k_mapping!=., title("{bf:B} 2-km Spillover area") fcolor("220 38 127" "100 143 255" "255 176 0*0.4" green*0.4) id(id) clmethod(unique) ocolor(white ..) osize(0.05 ..)   legend(pos(6) ring(1) rows(1))
gr save "$working_ANALYSIS/results/intermediate/map_spillover2k_miombo.gph", replace

* 5-km Spillover area
gen spillover5k_mapping = .
replace spillover5k_mapping = 0 if spillover5k_weight!=. & spillover5k_treated==0
replace spillover5k_mapping =1 if spillover5k_weight!=. & spillover5k_treated==1
replace spillover5k_mapping =2 if spillover5k_weight==. & spillover5k_treated!=.
replace spillover5k_mapping =3 if cell_groups==4
lab val spillover5k_mapping sccp_lab
spmap spillover5k_mapping using "$working_ANALYSIS/data/remote_sensing/sccp_coord" if spillover5k_mapping!=., title("{bf:C} 5-km Spillover area") fcolor("220 38 127" "100 143 255" "255 176 0*0.4" green*0.4) id(id) clmethod(unique) ocolor(white ..) osize(0.05 ..)   legend(pos(6) ring(1) rows(1))
gr save "$working_ANALYSIS/results/intermediate/map_spillover5k_miombo.gph", replace

* 10-km Spillover area
gen spillover10k_mapping = .
replace spillover10k_mapping = 0 if spillover10k_weight!=. & spillover10k_treated==0
replace spillover10k_mapping =1 if spillover10k_weight!=. & spillover10k_treated==1
replace spillover10k_mapping =2 if spillover10k_weight==. & spillover10k_treated!=.
replace spillover10k_mapping =3 if cell_groups==4
lab val spillover10k_mapping sccp_lab
spmap spillover10k_mapping using "$working_ANALYSIS/data/remote_sensing/sccp_coord" if spillover10k_mapping!=., title("{bf:D} 10-km Spillover area") fcolor("220 38 127" "100 143 255" "255 176 0*0.4" green*0.4) id(id) clmethod(unique) ocolor(white ..) osize(0.05 ..)   legend(pos(6) ring(1) rows(1))
gr save "$working_ANALYSIS/results/intermediate/map_spillover10k_miombo.gph", replace


* Combined area
gen combined_mapping = .
replace combined_mapping = 0 if combined_weight!=. & combined_treated==0
replace combined_mapping =1 if combined_weight!=. & combined_treated==1
replace combined_mapping =2 if combined_weight==. & combined_treated!=.
replace combined_mapping =3 if cell_groups==4
lab val combined_mapping sccp_lab
spmap combined_mapping using "$working_ANALYSIS/data/remote_sensing/sccp_coord" if combined_mapping!=., title("{bf:E} SCCP + 5-km Spillover area") fcolor("220 38 127" "100 143 255" "255 176 0*0.4" green*0.4) id(id) clmethod(unique) ocolor(white ..) osize(0.05 ..)   legend(pos(6) ring(1) rows(1))
gr save "$working_ANALYSIS/results/intermediate/map_combined_miombo.gph", replace



* The five maps have been written to disk; clear memory so that grc1leg loads
* them into an otherwise empty graph session.
graph drop _all

grc1leg  "$working_ANALYSIS/results/intermediate/map_sccp_miombo.gph"  "$working_ANALYSIS/results/intermediate/map_spillover2k_miombo.gph"  "$working_ANALYSIS/results/intermediate/map_spillover5k_miombo.gph"  "$working_ANALYSIS/results/intermediate/map_spillover10k_miombo.gph"  "$working_ANALYSIS/results/intermediate/map_combined_miombo.gph", rows(2) 
gr save  "$working_ANALYSIS/results/intermediate/matching_maps.gph", replace
gr export  "$working_ANALYSIS/results/diagnostics/diag_matching_maps_miombo.png", replace width(7100)




save "$working_ANALYSIS/processed/remote_sensing_matched.dta", replace






** EOF
