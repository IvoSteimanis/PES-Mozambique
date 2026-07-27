*--------------------------------------------------------------------
* SCRIPT:  08_did_miombo.do
* PURPOSE: Supplementary specification. Difference-in-differences estimates of
*          the SCCP effect on miombo-specific forest cover (1996-2019), using
*          the project's own remote-sensing classification rather than Hansen
*          Global Forest Change. Also reports the village-level balance and
*          trend diagnostics referenced in the Methods.
*
* INPUT:   processed/rs_village_data.dta
*          processed/remote_sensing_matched.dta
*
* OUTPUT:  results/figures/figS7_miombo_forest_cover.png   Figure S7
*          results/figures/figS8_miombo_impact.png         Figure S8
*          results/tables/tableS12_miombo_sccp.rtf         Table S12
*          results/tables/tableS13_miombo_sp2k.rtf         Table S13
*          results/tables/tableS14_miombo_sp5k.rtf         Table S14
*          results/tables/tableS15_miombo_sp10k.rtf        Table S15
*          results/tables/tableS16_miombo_combined.rtf     Table S16
*          results/diagnostics/  village balance, pre-trends, GNP closeness
*
* DEPENDS: coefplot, estout, iebaltab, grc1leg2
* RUN VIA: run.do (do not run standalone; requires $working_ANALYSIS)
*--------------------------------------------------------------------


*--------------------------------------------------------------
* Balancing survey villages in terms of remote sensing characteristics
*--------------------------------------------------------------
use "$working_ANALYSIS/processed/rs_village_data.dta", replace

global balance_5k buff5km_forest1996 buff5km_forest2002 buff5km_fcc9602 buff5km_slope buff5km_elevation buff5km_dist_road buff5km_dist_np 
sum $balance_5k
iebaltab $balance_5k, grpvar(area)   rowvarlabels format(%9.2f) tblnonote savexlsx("$working_ANALYSIS/results/diagnostics/diag_villages_balance_5k.xlsx") replace
reg area $balance_5k

global balance_10k buff10km_forest1996 buff10km_forest2002 buff10km_fcc9602 buff10km_slope buff10km_elevation buff10km_dist_road buff10km_dist_np
sum $balance_10k
iebaltab $balance_10k, grpvar(area) rowvarlabels format(%9.2f) tblnonote savexlsx("$working_ANALYSIS/results/diagnostics/diag_villages_balance_10k.xlsx") replace

global balance_5k_wonp buff5km_wonp_forest1996 buff5km_wonp_forest2002 buff5km_wonp_fcc9602 buff5km_wonp_slope buff5km_wonp_elevation buff5km_wonp_dist_roadn1n6 buff5km_wonp_dist_np buff5km_wonp_dist_agri50
sum $balance_5k_wonp
iebaltab $balance_5k_wonp, grpvar(area)   rowvarlabels format(%9.2f) tblnonote savexlsx("$working_ANALYSIS/results/diagnostics/diag_villages_balance_5k_wonp.xlsx") replace
reg area $balance_5k_wonp

global balance_10k_wonp buff10km_wonp_forest1996 buff10km_wonp_forest2002   buff10km_wonp_fcc9602  buff10km_wonp_slope buff10km_wonp_elevation buff10km_wonp_dist_roadn1n6 buff10km_wonp_dist_np buff10km_wonp_dist_agri50
sum $balance_10k_wonp

iebaltab $balance_10k_wonp, grpvar(area)   rowvarlabels format(%9.2f) tblnonote savexlsx("$working_ANALYSIS/results/diagnostics/diag_villages_balance_10k_wonp.xlsx") replace
reg area $balance_10k_wonp




** SAME ANALYSIS AT VILLAGE LEVEL WITH BUFFER INSTEAD OF CELLS WITH AREAS
gen treatment = 0 if area==2
replace treatment = 1 if area==1
lab def treatie 0 "Control" 1 "Treatment",replace
lab val treatment treatie
bys  treatment : sum buff5km_forest1996 buff5km_forest2002 buff5km_forest2005 buff5km_forest2014 buff5km_forest2019 

// Put dataset in long format for regression analysis
reshape long buff5km_forest buff10km_forest buff5km_wonp_forest buff10km_wonp_forest, i(village_id) j(year)

gen post = 0
replace post = 1 if year >2005
replace buff5km_forest=100*buff5km_forest
replace buff10km_forest=100*buff10km_forest
replace buff5km_wonp_forest=100*buff5km_wonp_forest
replace buff10km_wonp_forest=100*buff10km_wonp_forest

// GRAPH Parallel TRENDS
*5km radius
preserve
collapse (mean) buff5km_forest , by(treatment year)
reshape wide buff5km_forest , i(year) j(treatment)
lab var buff5km_forest0 "Control" 
lab var buff5km_forest1 "Treatment"
graph twoway (scatter buff5km_forest0 year, connect(1) lcolor("220 38 127") mcolor("220 38 127") msymbol(D)) (scatter buff5km_forest1 year, lcolor("100 143 255") msymbol(D) mcolor("100 143 255")  connect(1)),   ytitle(% forest) yla(0(20)100) xlab(1996 2002 2005 2014 2019) xtitle(year) xline(2005 2014, lpattern(dash) lcolor(black) lwidth(medium))   legend(ring(1) rows(1) pos(6) )  title("{bf:A} 5km radius")
gr save "$working_ANALYSIS/results/intermediate/parallell_trends_village_5km.gph", replace
restore

*5km radius wonp
preserve
collapse (mean) buff5km_wonp_forest , by(treatment year)
reshape wide buff5km_wonp_forest , i(year) j(treatment)
lab var buff5km_wonp_forest0 "Control" 
lab var buff5km_wonp_forest1 "Treatment"
graph twoway (scatter buff5km_wonp_forest0 year, connect(1) lcolor("220 38 127") mcolor("220 38 127") msymbol(D)) (scatter buff5km_wonp_forest1 year, lcolor("100 143 255") msymbol(D) mcolor("100 143 255")  connect(1)),   ytitle(% forest) yla(0(20)100) xlab(1996 2002 2005 2014 2019) xtitle(year) xline(2005 2014, lpattern(dash) lcolor(black) lwidth(medium))   legend(ring(1) rows(1) pos(6) )  title("{bf:A} 5km radius WONP")
gr save "$working_ANALYSIS/results/intermediate/parallell_trends_village_5km_wonp.gph", replace
restore

*10km radius
preserve
collapse (mean) buff10km_forest , by(treatment year)
reshape wide buff10km_forest , i(year) j(treatment)
lab var buff10km_forest0 "Control" 
lab var buff10km_forest1 "Treatment"
graph twoway (scatter buff10km_forest0 year, connect(1) lcolor("220 38 127") mcolor("220 38 127") msymbol(D)) (scatter buff10km_forest1 year, lcolor("100 143 255") msymbol(D) mcolor("100 143 255")  connect(1)),   ytitle(% forest) yla(0(20)100) xlab(1996 2002 2005 2014 2019) xtitle(year) xline(2005 2014, lpattern(dash) lcolor(black) lwidth(medium))   legend(ring(1) rows(1) pos(6) )  title("{bf:B} 10km radius")
gr save "$working_ANALYSIS/results/intermediate/parallell_trends_village_10km.gph", replace
restore

*10km radius WONP
preserve
collapse (mean) buff10km_wonp_forest , by(treatment year)
reshape wide buff10km_wonp_forest , i(year) j(treatment)
lab var buff10km_wonp_forest0 "Control" 
lab var buff10km_wonp_forest1 "Treatment"
graph twoway (scatter buff10km_wonp_forest0 year, connect(1) lcolor("220 38 127") mcolor("220 38 127") msymbol(D)) (scatter buff10km_wonp_forest1 year, lcolor("100 143 255") msymbol(D) mcolor("100 143 255")  connect(1)),   ytitle(% forest) yla(0(20)100) xlab(1996 2002 2005 2014 2019) xtitle(year) xline(2005 2014, lpattern(dash) lcolor(black) lwidth(medium))   legend(ring(1) rows(1) pos(6) )  title("{bf:B} 10km radius WONP")
gr save "$working_ANALYSIS/results/intermediate/parallell_trends_village_10km_wonp.gph", replace
restore


grc1leg "$working_ANALYSIS/results/intermediate/parallell_trends_village_5km.gph" "$working_ANALYSIS/results/intermediate/parallell_trends_village_5km_wonp.gph"  "$working_ANALYSIS/results/intermediate/parallell_trends_village_10km.gph" "$working_ANALYSIS/results/intermediate/parallell_trends_village_10km_wonp.gph"  , rows(2) 
gr save  "$working_ANALYSIS/results/intermediate/parallel_trends_villages.gph", replace
gr export  "$working_ANALYSIS/results/diagnostics/diag_parallel_trends_villages.png", replace width(4000)

*pre-trends significant?
xtset village_id year
xtreg buff5km_forest i.year##i.treatment if year < 2005, fe cluster(village_id)
xtreg buff10km_forest i.year##i.treatment if year < 2005, fe cluster(village_id)
xtreg buff5km_wonp_forest i.year##i.treatment if year < 2005, fe cluster(village_id)
xtreg buff10km_wonp_forest i.year##i.treatment if year < 2005, fe cluster(village_id)


* DiD: Effects of the SCCP
eststo village_5k: xtreg buff5km_forest i.year##i.treatment if year > 2002 , fe cluster(village_id)
testparm 2014.year#1.treatment 2019.year#1.treatment, equal
eststo village_5k_wonp: xtreg buff5km_wonp_forest i.year##i.treatment if year > 2002 , fe cluster(village_id)
testparm 2014.year#1.treatment 2019.year#1.treatment, equal
eststo village_10k: xtreg buff10km_forest i.year##i.treatment if year > 2002 , fe cluster(village_id)
testparm 2014.year#1.treatment 2019.year#1.treatment, equal
eststo village_10k_wonp: xtreg buff10km_wonp_forest i.year##i.treatment if year > 2002 , fe cluster(village_id)

coefplot (village_5k_wonp,offset(-0.2)) (village_10k_wonp,offset(0.2)), keep(2014.year#1.treatment 2019.year#1.treatment) coeflabels(2014.year#1.treatment = "2014" 2019.year#1.treatment = "2019") vertical  yline(0, lpattern(solid) lcolor(gs3)) ytitle("DiD estimate on forest cover (in %)") yla(-30(10)10, format(%9.0f) nogrid) grid(none) levels(95 90) ciopts(lwidth(0.8 2)  lcolor(*1 *.3) recast(rcap))  msize(4pt) msymbol(D)  mlabel format(%9.1f) mlabposition(3) mlabgap(*2) mlabsize(6pt) mlabpos(9) subtitle(, size(10pt) lstyle(none) margin(small) justification(left)  bmargin(top)) xsize(4) ysize(3)  legend(order(3 "Treatment (5km)" 6 "Treatment (10km)") rows(1))
gr save "$working_ANALYSIS/results/intermediate/diag_forest_cover_village_level.gph", replace
gr export "$working_ANALYSIS/results/diagnostics/diag_forest_cover_village_level.png", replace







* Load cleaned matched cell dataset
clear
use "$working_ANALYSIS/processed/remote_sensing_matched.dta"


*--------------------------
* Post-matching balancing
*--------------------------
egen median_distance_GNP_sccp = median(mean_distance_np) if sccp_treated==1
gen treated_close = 0 if sccp_treated==0
replace treated_close = 1 if mean_distance_np < median_distance_GNP_sccp & sccp_treated==1
gen treated_not_close = 0 if sccp_treated==0
replace treated_not_close = 1 if mean_distance_np > median_distance_GNP_sccp & sccp_treated==1

// Put dataset in long format for regression analysis
reshape long forest denseforest sparseforest burned_forest burned_crop, i(id) j(year)
xtset id year
gen post = 0
replace post = 1 if year==2014
replace post = 2 if year==2019


lab def posto 0 "<2003" 1 "2014" 2 "2019", replace
lab val post posto

replace potentialpes = (potentialpes/9)*100
replace potentialpes = . if year!=2019
* (Descriptive summaries of forest cover by year were used during development.
*  They produced no reported output and referenced a variable that no longer
*  exists in the matched dataset, so they have been removed.)


// GRAPH Parallel TRENDS
*SCCP
preserve
collapse (mean) forest if sccp_weight!=. , by (sccp_treated year)
reshape wide forest, i(year) j(sccp_treated)
lab var forest0 "Control cells" 
lab var forest1 "Treatment cells"
graph twoway (scatter forest0 year, connect(1) lcolor("220 38 127") mcolor("220 38 127") msymbol(D)) (scatter forest1 year, lcolor("100 143 255") msymbol(D) mcolor("100 143 255")  connect(1)),   ytitle(forest cover in %) yla(0(20)100) xlab(1996 2002 2014 2019) xtitle(year) xline(2003 2014, lpattern(dash) lcolor(black) lwidth(medium))   legend(ring(1) rows(1) pos(6) size(8pt))  title("{bf:A} SCCP area")
gr save "$working_ANALYSIS/results/intermediate/parallel_trends_sccp.gph", replace
restore

preserve
collapse (mean) denseforest if sccp_weight!=. , by (sccp_treated year)
reshape wide denseforest, i(year) j(sccp_treated)
lab var denseforest0 "Control cells" 
lab var denseforest1 "Treatment cells"
graph twoway (scatter denseforest0 year, connect(1) lcolor("220 38 127") mcolor("220 38 127") msymbol(D)) (scatter denseforest1 year, lcolor("100 143 255") msymbol(D) mcolor("100 143 255")  connect(1)),   ytitle(% forest) yla(0(20)100) xlab(1996 2002 2014 2019) xtitle(year) xline(2003 2014, lpattern(dash) lcolor(black) lwidth(medium))   legend(ring(1) rows(1) pos(6) )  title("{bf:A} SCCP area")
gr save "$working_ANALYSIS/results/intermediate/parallel_trends_dense_sccp.gph", replace
restore

preserve
collapse (mean) sparseforest if sccp_weight!=. , by (sccp_treated year)
reshape wide sparseforest, i(year) j(sccp_treated)
lab var sparseforest0 "Control cells" 
lab var sparseforest1 "Treatment cells"
graph twoway (scatter sparseforest0 year, connect(1) lcolor("220 38 127") mcolor("220 38 127") msymbol(D)) (scatter sparseforest1 year, lcolor("100 143 255") msymbol(D) mcolor("100 143 255")  connect(1)),   ytitle(% forest) yla(0(20)100) xlab(1996 2002 2014 2019) xtitle(year) xline(2003 2014, lpattern(dash) lcolor(black) lwidth(medium))   legend(ring(1) rows(1) pos(6) )  title("{bf:A} SCCP area")
gr save "$working_ANALYSIS/results/intermediate/parallel_trends_sparse_sccp.gph", replace
restore

preserve
collapse (mean) burned_forest if sccp_weight!=. , by (sccp_treated year)
reshape wide burned_forest, i(year) j(sccp_treated)
lab var burned_forest0 "Control cells" 
lab var burned_forest1 "Treatment cells"
graph twoway (scatter burned_forest0 year, connect(1) lcolor("220 38 127") mcolor("220 38 127") msymbol(D)) (scatter burned_forest1 year, lcolor("100 143 255") msymbol(D) mcolor("100 143 255")  connect(1)),   ytitle(% forest) yla(0(20)100) xlab(1996 2002 2014 2019) xtitle(year) xline(2003 2014, lpattern(dash) lcolor(black) lwidth(medium))   legend(ring(1) rows(1) pos(6) )  title("{bf:A} SCCP area")
gr save "$working_ANALYSIS/results/intermediate/parallel_trends_burned_forest_sccp.gph", replace
restore

preserve
collapse (mean) burned_crop if sccp_weight!=. , by (sccp_treated year)
reshape wide burned_crop, i(year) j(sccp_treated)
lab var burned_crop0 "Control cells" 
lab var burned_crop1 "Treatment cells"
graph twoway (scatter burned_crop0 year, connect(1) lcolor("220 38 127") mcolor("220 38 127") msymbol(D)) (scatter burned_crop1 year, lcolor("100 143 255") msymbol(D) mcolor("100 143 255")  connect(1)),   ytitle(% forest) yla(0(20)100) xlab(1996 2002 2014 2019) xtitle(year) xline(2003 2014, lpattern(dash) lcolor(black) lwidth(medium))   legend(ring(1) rows(1) pos(6) )  title("{bf:A} SCCP area")
gr save "$working_ANALYSIS/results/intermediate/parallel_trends_burned_crop_sccp.gph", replace
restore


*2-km Spillover area
preserve
collapse (mean) forest if spillover2k_weight!=. , by (spillover2k_treated year)
reshape wide forest, i(year) j(spillover)
lab var forest0 "Control cells" 
lab var forest1 "Treatment cells"
graph twoway (scatter forest0 year, connect(1) lcolor("220 38 127") mcolor("220 38 127") msymbol(D)) (scatter forest1 year, lcolor("100 143 255") msymbol(D) mcolor("100 143 255")  connect(1)),   ytitle(forest cover in %)  yla(0(20)100) xlab(1996 2002  2014 2019) xtitle(year) xline(2003 2014, lpattern(dash) lcolor(black) lwidth(medium))   legend(ring(1) rows(1) pos(6) )  title("{bf:B} 2-km Spillover area")
gr save "$working_ANALYSIS/results/intermediate/parallel_trends_spillover2k.gph", replace
restore

preserve
collapse (mean) denseforest if spillover2k_weight!=. , by (spillover2k_treated year)
reshape wide denseforest, i(year) j(spillover)
lab var denseforest0 "Control cells" 
lab var denseforest1 "Treatment cells"
graph twoway (scatter denseforest0 year, connect(1) lcolor("220 38 127") mcolor("220 38 127") msymbol(D)) (scatter denseforest1 year, lcolor("100 143 255") msymbol(D) mcolor("100 143 255")  connect(1)),   ytitle(% forest) yla(0(20)100) xlab(1996 2002  2014 2019) xtitle(year) xline(2003 2014, lpattern(dash) lcolor(black) lwidth(medium))   legend(ring(1) rows(1) pos(6) )  title("{bf:B} 2-km Spillover area")
gr save "$working_ANALYSIS/results/intermediate/parallel_trends_dense_spillover2k.gph", replace
restore


preserve
collapse (mean) sparseforest if spillover2k_weight!=. , by (spillover2k_treated year)
reshape wide sparseforest, i(year) j(spillover)
lab var sparseforest0 "Control cells" 
lab var sparseforest1 "Treatment cells"
graph twoway (scatter sparseforest0 year, connect(1) lcolor("220 38 127") mcolor("220 38 127") msymbol(D)) (scatter sparseforest1 year, lcolor("100 143 255") msymbol(D) mcolor("100 143 255")  connect(1)),   ytitle(% forest) yla(0(20)100) xlab(1996 2002  2014 2019) xtitle(year) xline(2003 2014, lpattern(dash) lcolor(black) lwidth(medium))   legend(ring(1) rows(1) pos(6) )  title("{bf:B} 2-km Spillover area")
gr save "$working_ANALYSIS/results/intermediate/parallel_trends_sparse_spillover2k.gph", replace
restore

preserve
collapse (mean) burned_forest if spillover2k_weight!=. , by (spillover2k_treated year)
reshape wide burned_forest, i(year) j(spillover)
lab var burned_forest0 "Control cells" 
lab var burned_forest1 "Treatment cells"
graph twoway (scatter burned_forest0 year, connect(1) lcolor("220 38 127") mcolor("220 38 127") msymbol(D)) (scatter burned_forest1 year, lcolor("100 143 255") msymbol(D) mcolor("100 143 255")  connect(1)),   ytitle(% forest) yla(0(20)100) xlab(1996 2002  2014 2019) xtitle(year) xline(2003 2014, lpattern(dash) lcolor(black) lwidth(medium))   legend(ring(1) rows(1) pos(6) )  title("{bf:B} 2-km Spillover area")
gr save "$working_ANALYSIS/results/intermediate/parallel_trends_burned_forest_spillover2k.gph", replace
restore

preserve
collapse (mean) burned_crop if spillover2k_weight!=. , by (spillover2k_treated year)
reshape wide burned_crop, i(year) j(spillover)
lab var burned_crop0 "Control cells" 
lab var burned_crop1 "Treatment cells"
graph twoway (scatter burned_crop0 year, connect(1) lcolor("220 38 127") mcolor("220 38 127") msymbol(D)) (scatter burned_crop1 year, lcolor("100 143 255") msymbol(D) mcolor("100 143 255")  connect(1)),   ytitle(% forest) yla(0(20)100) xlab(1996 2002  2014 2019) xtitle(year) xline(2003 2014, lpattern(dash) lcolor(black) lwidth(medium))   legend(ring(1) rows(1) pos(6) )  title("{bf:B} 2-km Spillover area")
gr save "$working_ANALYSIS/results/intermediate/parallel_trends_burned_crop_spillover2k.gph", replace
restore


*5-km Spillover area
preserve
collapse (mean) forest if spillover5k_weight!=. , by (spillover5k_treated year)
reshape wide forest,  i(year) j(spillover)
lab var forest0 "Control cells" 
lab var forest1 "Treatment cells"
graph twoway (scatter forest0 year, connect(1) lcolor("220 38 127") mcolor("220 38 127") msymbol(D)) (scatter forest1 year, lcolor("100 143 255") msymbol(D) mcolor("100 143 255")  connect(1)) , ytitle(forest cover in %) yla(0(20)100) xlab(1996 2002  2014 2019) xtitle(year) xline(2003 2014, lpattern(dash) lcolor(black) lwidth(medium))   legend(ring(1) rows(1) pos(6))  title("{bf:C} 5-km Spillover area")
gr save "$working_ANALYSIS/results/intermediate/parallel_trends_spillover5k.gph", replace
restore

preserve
collapse (mean) denseforest if spillover5k_weight!=. , by (spillover5k_treated year)
reshape wide denseforest, i(year) j(spillover)
lab var denseforest0 "Control cells" 
lab var denseforest1 "Treatment cells"
graph twoway (scatter denseforest0 year, connect(1) lcolor("220 38 127") mcolor("220 38 127") msymbol(D)) (scatter denseforest1 year, lcolor("100 143 255") msymbol(D) mcolor("100 143 255")  connect(1)),   ytitle(% forest) yla(0(20)100) xlab(1996 2002  2014 2019) xtitle(year) xline(2003 2014, lpattern(dash) lcolor(black) lwidth(medium))   legend(ring(1) rows(1) pos(6) )  title("{bf:C} 5-km Spillover area")
gr save "$working_ANALYSIS/results/intermediate/parallel_trends_dense_spillover5k.gph", replace
restore


preserve
collapse (mean) sparseforest if spillover5k_weight!=. , by (spillover5k_treated year)
reshape wide sparseforest, i(year) j(spillover)
lab var sparseforest0 "Control cells" 
lab var sparseforest1 "Treatment cells"
graph twoway (scatter sparseforest0 year, connect(1) lcolor("220 38 127") mcolor("220 38 127") msymbol(D)) (scatter sparseforest1 year, lcolor("100 143 255") msymbol(D) mcolor("100 143 255")  connect(1)),   ytitle(% forest) yla(0(20)100) xlab(1996 2002  2014 2019) xtitle(year) xline(2003 2014, lpattern(dash) lcolor(black) lwidth(medium))   legend(ring(1) rows(1) pos(6) )  title("{bf:C} 5-km Spillover area")
gr save "$working_ANALYSIS/results/intermediate/parallel_trends_sparse_spillover5k.gph", replace
restore

preserve
collapse (mean) burned_forest if spillover5k_weight!=. , by (spillover5k_treated year)
reshape wide burned_forest, i(year) j(spillover)
lab var burned_forest0 "Control cells" 
lab var burned_forest1 "Treatment cells"
graph twoway (scatter burned_forest0 year, connect(1) lcolor("220 38 127") mcolor("220 38 127") msymbol(D)) (scatter burned_forest1 year, lcolor("100 143 255") msymbol(D) mcolor("100 143 255")  connect(1)),   ytitle(% forest) yla(0(20)100) xlab(1996 2002  2014 2019) xtitle(year) xline(2003 2014, lpattern(dash) lcolor(black) lwidth(medium))   legend(ring(1) rows(1) pos(6) ) title("{bf:C} 5-km Spillover area")
gr save "$working_ANALYSIS/results/intermediate/parallel_trends_burned_forest_spillover5k.gph", replace
restore

preserve
collapse (mean) burned_crop if spillover5k_weight!=. , by (spillover5k_treated year)
reshape wide burned_crop, i(year) j(spillover)
lab var burned_crop0 "Control cells" 
lab var burned_crop1 "Treatment cells"
graph twoway (scatter burned_crop0 year, connect(1) lcolor("220 38 127") mcolor("220 38 127") msymbol(D)) (scatter burned_crop1 year, lcolor("100 143 255") msymbol(D) mcolor("100 143 255")  connect(1)),   ytitle(% forest) yla(0(20)100) xlab(1996 2002  2014 2019) xtitle(year) xline(2003 2014, lpattern(dash) lcolor(black) lwidth(medium))   legend(ring(1) rows(1) pos(6) )  title("{bf:C} 5-km Spillover area")
gr save "$working_ANALYSIS/results/intermediate/parallel_trends_burned_crop_spillover5k.gph", replace
restore


*10-km Spillover area
preserve
collapse (mean) forest if spillover10k_weight!=. , by (spillover10k_treated year)
reshape wide forest,  i(year) j(spillover)
lab var forest0 "Control cells" 
lab var forest1 "Treatment cells"
graph twoway (scatter forest0 year, connect(1) lcolor("220 38 127") mcolor("220 38 127") msymbol(D)) (scatter forest1 year, lcolor("100 143 255") msymbol(D) mcolor("100 143 255")  connect(1)) , ytitle(forest cover in %)yla(0(20)100) xlab(1996 2002  2014 2019) xtitle(year) xline(2003 2014, lpattern(dash) lcolor(black) lwidth(medium))   legend(ring(1) rows(1) pos(6))  title("{bf:D} 10-km Spillover area")
gr save "$working_ANALYSIS/results/intermediate/parallel_trends_spillover10k.gph", replace
restore

preserve
collapse (mean) denseforest if spillover10k_weight!=. , by (spillover10k_treated year)
reshape wide denseforest, i(year) j(spillover)
lab var denseforest0 "Control cells" 
lab var denseforest1 "Treatment cells"
graph twoway (scatter denseforest0 year, connect(1) lcolor("220 38 127") mcolor("220 38 127") msymbol(D)) (scatter denseforest1 year, lcolor("100 143 255") msymbol(D) mcolor("100 143 255")  connect(1)),   ytitle(% forest) yla(0(20)100) xlab(1996 2002  2014 2019) xtitle(year) xline(2003 2014, lpattern(dash) lcolor(black) lwidth(medium))   legend(ring(1) rows(1) pos(6) )  title("{bf:D} 10-km Spillover area")
gr save "$working_ANALYSIS/results/intermediate/parallel_trends_dense_spillover10k.gph", replace
restore


preserve
collapse (mean) sparseforest if spillover10k_weight!=. , by (spillover10k_treated year)
reshape wide sparseforest, i(year) j(spillover)
lab var sparseforest0 "Control cells" 
lab var sparseforest1 "Treatment cells"
graph twoway (scatter sparseforest0 year, connect(1) lcolor("220 38 127") mcolor("220 38 127") msymbol(D)) (scatter sparseforest1 year, lcolor("100 143 255") msymbol(D) mcolor("100 143 255")  connect(1)),   ytitle(% forest) yla(0(20)100) xlab(1996 2002  2014 2019) xtitle(year) xline(2003 2014, lpattern(dash) lcolor(black) lwidth(medium))   legend(ring(1) rows(1) pos(6) )  title("{bf:D} 10-km Spillover area")
gr save "$working_ANALYSIS/results/intermediate/parallel_trends_sparse_spillover10k.gph", replace
restore

preserve
collapse (mean) burned_forest if spillover10k_weight!=. , by (spillover10k_treated year)
reshape wide burned_forest, i(year) j(spillover)
lab var burned_forest0 "Control cells" 
lab var burned_forest1 "Treatment cells"
graph twoway (scatter burned_forest0 year, connect(1) lcolor("220 38 127") mcolor("220 38 127") msymbol(D)) (scatter burned_forest1 year, lcolor("100 143 255") msymbol(D) mcolor("100 143 255")  connect(1)),   ytitle(% forest) yla(0(20)100) xlab(1996 2002  2014 2019) xtitle(year) xline(2003 2014, lpattern(dash) lcolor(black) lwidth(medium))   legend(ring(1) rows(1) pos(6) )  title("{bf:D} 10-km Spillover area")
gr save "$working_ANALYSIS/results/intermediate/parallel_trends_burned_forest_spillover10k.gph", replace
restore

preserve
collapse (mean) burned_crop if spillover10k_weight!=. , by (spillover10k_treated year)
reshape wide burned_crop, i(year) j(spillover)
lab var burned_crop0 "Control cells" 
lab var burned_crop1 "Treatment cells"
graph twoway (scatter burned_crop0 year, connect(1) lcolor("220 38 127") mcolor("220 38 127") msymbol(D)) (scatter burned_crop1 year, lcolor("100 143 255") msymbol(D) mcolor("100 143 255")  connect(1)),   ytitle(% forest) yla(0(20)100) xlab(1996 2002  2014 2019) xtitle(year) xline(2003 2014, lpattern(dash) lcolor(black) lwidth(medium))   legend(ring(1) rows(1) pos(6) )  title("{bf:D} 10-km Spillover area")
gr save "$working_ANALYSIS/results/intermediate/parallel_trends_burned_crop_spillover10k.gph", replace
restore


*Combined: SCCP & 5-km Spillover area
preserve
collapse (mean) forest if combined_weight!=. , by (combined_treated year)
reshape wide forest,  i(year) j(combined)
lab var forest0 "Control cells" 
lab var forest1 "Treatment cells"
graph twoway (scatter forest0 year, connect(1) lcolor("220 38 127") mcolor("220 38 127") msymbol(D)) (scatter forest1 year, lcolor("100 143 255") msymbol(D) mcolor("100 143 255")  connect(1)) ,  ytitle(forest cover in %)yla(0(20)100) xlab(1996 2002  2014 2019) xtitle(year) xline(2003 2014, lpattern(dash) lcolor(black) lwidth(medium))   legend(ring(1) rows(1) pos(6))  title("{bf:E} Combined: SCCP & 5-km Spillover area")
gr save "$working_ANALYSIS/results/intermediate/parallel_trends_combined.gph", replace
restore

preserve
collapse (mean) denseforest if combined_weight!=. , by (combined_treated year)
reshape wide denseforest, i(year) j(combined)
lab var denseforest0 "Control cells" 
lab var denseforest1 "Treatment cells"
graph twoway (scatter denseforest0 year, connect(1) lcolor("220 38 127") mcolor("220 38 127") msymbol(D)) (scatter denseforest1 year, lcolor("100 143 255") msymbol(D) mcolor("100 143 255")  connect(1)),   ytitle(% forest) yla(0(20)100) xlab(1996 2002  2014 2019) xtitle(year) xline(2003 2014, lpattern(dash) lcolor(black) lwidth(medium))   legend(ring(1) rows(1) pos(6) )  title("{bf:E} Combined: SCCP & 5-km Spillover area")
gr save "$working_ANALYSIS/results/intermediate/parallel_trends_dense_combined.gph", replace
restore


preserve
collapse (mean) sparseforest if combined_weight!=. , by (combined_treated year)
reshape wide sparseforest, i(year) j(combined)
lab var sparseforest0 "Control cells" 
lab var sparseforest1 "Treatment cells"
graph twoway (scatter sparseforest0 year, connect(1) lcolor("220 38 127") mcolor("220 38 127") msymbol(D)) (scatter sparseforest1 year, lcolor("100 143 255") msymbol(D) mcolor("100 143 255")  connect(1)),   ytitle(% forest) yla(0(20)100) xlab(1996 2002  2014 2019) xtitle(year) xline(2003 2014, lpattern(dash) lcolor(black) lwidth(medium))   legend(ring(1) rows(1) pos(6) )   title("{bf:E} Combined: SCCP & 5-km Spillover area")
gr save "$working_ANALYSIS/results/intermediate/parallel_trends_sparse_combined.gph", replace
restore

preserve
collapse (mean) burned_forest if combined_weight!=. , by (combined_treated year)
reshape wide burned_forest, i(year) j(combined)
lab var burned_forest0 "Control cells" 
lab var burned_forest1 "Treatment cells"
graph twoway (scatter burned_forest0 year, connect(1) lcolor("220 38 127") mcolor("220 38 127") msymbol(D)) (scatter burned_forest1 year, lcolor("100 143 255") msymbol(D) mcolor("100 143 255")  connect(1)),   ytitle(% forest) yla(0(20)100) xlab(1996 2002  2014 2019) xtitle(year) xline(2003 2014, lpattern(dash) lcolor(black) lwidth(medium))   legend(ring(1) rows(1) pos(6) )   title("{bf:E} Combined: SCCP & 5-km Spillover area")
gr save "$working_ANALYSIS/results/intermediate/parallel_trends_burned_forest_combined.gph", replace
restore

preserve
collapse (mean) burned_crop if combined_weight!=. , by (combined_treated year)
reshape wide burned_crop, i(year) j(combined)
lab var burned_crop0 "Control cells" 
lab var burned_crop1 "Treatment cells"
graph twoway (scatter burned_crop0 year, connect(1) lcolor("220 38 127") mcolor("220 38 127") msymbol(D)) (scatter burned_crop1 year, lcolor("100 143 255") msymbol(D) mcolor("100 143 255")  connect(1)),   ytitle(% forest) yla(0(20)100) xlab(1996 2002  2014 2019) xtitle(year) xline(2003 2014, lpattern(dash) lcolor(black) lwidth(medium))   legend(ring(1) rows(1) pos(6) )   title("{bf:E} Combined: SCCP & 5-km Spillover area")
gr save "$working_ANALYSIS/results/intermediate/parallel_trends_burned_crop_combined.gph", replace
restore


*Any Forest Cover
grc1leg2 "$working_ANALYSIS/results/intermediate/parallel_trends_sccp.gph" "$working_ANALYSIS/results/intermediate/parallel_trends_spillover2k.gph" "$working_ANALYSIS/results/intermediate/parallel_trends_spillover5k.gph" "$working_ANALYSIS/results/intermediate/parallel_trends_spillover10k.gph" "$working_ANALYSIS/results/intermediate/parallel_trends_combined.gph", rows(2) xsize(4) ysize(2)
gr save  "$working_ANALYSIS/results/intermediate/parallel_trends.gph", replace
gr export  "$working_ANALYSIS/results/figures/figS7_miombo_forest_cover.png", replace width(4000)



*testing for pre-trends
eststo tableS2_1: xtreg forest i.year##i.sccp_treated if sccp_weight!=. & year < 2005, fe cluster(sccp_pair)
eststo tableS2_2: xtreg forest i.year##i.spillover2k_treated if spillover2k_weight!=. & year < 2005, fe cluster(spillover2k_pair)
eststo tableS2_3: xtreg forest i.year##i.spillover5k_treated if spillover5k_weight!=. & year  < 2005, fe cluster(spillover5k_pair)
eststo tableS2_4: xtreg forest i.year##i.spillover10k_treated if spillover10k_weight!=. & year  < 2005, fe cluster(spillover10k_pair)
eststo tableS2_5: xtreg forest i.year##i.combined_treated if combined_weight!=. & year < 2005, fe cluster(combined_pair)


esttab tableS2_1 tableS2_2 tableS2_3 tableS2_4 tableS2_5 using "$working_ANALYSIS/results/diagnostics/diag_pre_trends_miombo.rtf", rename(2002.year#1.sccp_treated 2002.year#1.combined_treated 2002.year#1.spillover2k_treated 2002.year#1.combined_treated 2002.year#1.spillover5k_treated 2002.year#1.combined_treated 2002.year#1.spillover10k_treated 2002.year#1.combined_treated) keep(2002.year 2002.year#1.combined_treated _cons) label se(%4.2f) transform(ln*: exp(@) exp(@)) mtitles("SCCP area" "2-km Spillover area" "5-km Spillover area" "10-km Spillover area"	"Combined area") nonotes b(%4.2f) stats(N N_clust r2_a, labels("N" "Cluster" "Adjusted R-squared" ) fmt(%4.0f %4.0f %4.2f)) star(* 0.10 ** 0.05 *** 0.01) varlabels(,elist(weight:_cons "{break}{hline @width}")) addnotes("Notes: The outcome variable in all models is forest cover in percent with 1996 as the reference year. Estimates are from panel regression with fixed effects and standard errors clustered at the matched pair level in parentheses: * p < 0.10, ** p < 0.05, *** p < 0.01.")  replace 



*DiD: SCCP area
eststo sccp1: xtreg forest i.sccp_treated##i.post if sccp_weight!=., fe cluster(sccp_pair)
testparm 1.sccp_treated#1.post 1.sccp_treated#2.post, equal
margins sccp_treated#post
eststo sccp2: xtreg denseforest i.sccp_treated##i.post if sccp_weight!=., fe cluster(sccp_pair)
eststo sccp3: xtreg sparseforest i.sccp_treated##i.post if sccp_weight!=., fe cluster(sccp_pair)
eststo sccp4: xtreg burned_forest i.sccp_treated##i.post if sccp_weight!=., fe cluster(sccp_pair)
eststo sccp5: xtreg burned_crop i.sccp_treated##i.post if sccp_weight!=., fe cluster(sccp_pair)
eststo sccp6: reg potentialpes i.sccp_treated if sccp_weight!=., cluster(sccp_pair)

esttab sccp1 sccp2 sccp3 sccp4 sccp5 sccp6 using "$working_ANALYSIS/results/tables/tableS12_miombo_sccp.rtf", keep( 1.post 2.post 1.sccp_treated 1.sccp_treated#1.post 1.sccp_treated#2.post _cons) label se(%4.2f) transform(ln*: exp(@) exp(@)) mtitles("Any Forest %" "Dense Forest %" "Sparse Forest %" "Burned Forest %" "Burned Cropland %" "Agroforestry %") nonotes b(%4.2f) stats(N N_clust r2_a, labels("N" "Cluster" "Adjusted R-squared" ) fmt(%4.0f %4.0f %4.2f)) star(* 0.10 ** 0.05 *** 0.01) varlabels(,elist(weight:_cons "{break}{hline @width}")) addnotes("Notes: The outcome variable in all models is forest cover in percent. Estimates are from panel regression with fixed effects and standard errors clustered at the matched pair level in parentheses: * p < 0.10, ** p < 0.05, *** p < 0.01.")  replace 

*Leakage test: Are cells closer to the GNP Experiencing less deforestation?
eststo rc_closeness_GNP1: xtreg forest i.treated_close##i.post if sccp_weight!=. , fe  cluster(sccp_pair) 
eststo rc_closeness_GNP2: xtreg forest i.treated_not_close##i.post if sccp_weight!=. , fe cluster(sccp_pair) 
esttab rc_closeness_GNP1 rc_closeness_GNP2 using "$working_ANALYSIS/results/diagnostics/diag_closeness_gnp_miombo.rtf", keep( 1.post 2.post 1.treated_close 1.treated_close#1.post 1.treated_close#2.post 1.treated_not_close 1.treated_not_close#1.post 1.treated_not_close#2.post _cons) label se(%4.2f) transform(ln*: exp(@) exp(@)) mtitles("<6km to GNP" ">6km to GNP") nonotes b(%4.2f) stats(N N_clust r2_a, labels("N" "Cluster" "Adjusted R-squared" ) fmt(%4.0f %4.0f %4.2f)) star(* 0.10 ** 0.05 *** 0.01) varlabels(,elist(weight:_cons "{break}{hline @width}")) addnotes("Notes: The outcome variable in all models is forest cover in percent. Estimates are from panel regression with fixed effects and standard errors clustered at the matched pair level in parentheses: * p < 0.10, ** p < 0.05, *** p < 0.01.")  replace 

* DiD: 2km Spillover
eststo sp2k_1: xtreg forest i.spillover2k_treated##i.post if spillover2k_weight!=., fe cluster(spillover2k_pair)
eststo sp2k_2: xtreg denseforest i.spillover2k_treated##i.post if spillover2k_weight!=., fe cluster(spillover2k_pair)
eststo sp2k_3: xtreg sparseforest i.spillover2k_treated##i.post if spillover2k_weight!=., fe cluster(spillover2k_pair)
eststo sp2k_4: xtreg burned_forest i.spillover2k_treated##i.post if spillover2k_weight!=., fe cluster(spillover2k_pair)
eststo sp2k_5: xtreg burned_crop i.spillover2k_treated##i.post if spillover2k_weight!=., fe cluster(spillover2k_pair)
eststo sp2k_6: reg potentialpes i.spillover2k_treated if spillover2k_weight!=., cluster(spillover2k_pair)

esttab sp2k_1 sp2k_2 sp2k_3 sp2k_4 sp2k_5 sp2k_6 using "$working_ANALYSIS/results/tables/tableS13_miombo_sp2k.rtf", keep( 1.post 2.post 1.spillover2k_treated 1.spillover2k_treated#1.post 1.spillover2k_treated#2.post _cons) label se(%4.2f) transform(ln*: exp(@) exp(@)) mtitles("Any Forest %" "Dense Forest %" "Sparse Forest %" "Burned Forest %" "Burned Cropland %" "Agroforestry %") nonotes b(%4.2f) stats(N N_clust r2_a, labels("N" "Cluster" "Adjusted R-squared" ) fmt(%4.0f %4.0f %4.2f)) star(* 0.10 ** 0.05 *** 0.01) varlabels(,elist(weight:_cons "{break}{hline @width}")) addnotes("Notes: The outcome variable in all models is forest cover in percent. Estimates are from panel regression with fixed effects and standard errors clustered at the matched pair level in parentheses: * p < 0.10, ** p < 0.05, *** p < 0.01.")  replace 


* DiD: 5km Spillover
eststo sp5k_1: xtreg forest i.spillover5k_treated##i.post if spillover5k_weight!=., fe cluster(spillover5k_pair)
eststo sp5k_2: xtreg denseforest i.spillover5k_treated##i.post if spillover5k_weight!=., fe cluster(spillover5k_pair)
eststo sp5k_3: xtreg sparseforest i.spillover5k_treated##i.post if spillover5k_weight!=., fe cluster(spillover5k_pair)
eststo sp5k_4: xtreg burned_forest i.spillover5k_treated##i.post if spillover5k_weight!=., fe cluster(spillover5k_pair)
eststo sp5k_5: xtreg burned_crop i.spillover5k_treated##i.post if spillover5k_weight!=., fe cluster(spillover5k_pair)
eststo sp5k_6: reg potentialpes i.spillover5k_treated if spillover5k_weight!=., cluster(spillover5k_pair)

esttab sp5k_1 sp5k_2 sp5k_3 sp5k_4 sp5k_5 sp5k_6 using "$working_ANALYSIS/results/tables/tableS14_miombo_sp5k.rtf", keep( 1.post 2.post 1.spillover5k_treated 1.spillover5k_treated#1.post 1.spillover5k_treated#2.post _cons) label se(%4.2f) transform(ln*: exp(@) exp(@)) mtitles("Any Forest %" "Dense Forest %" "Sparse Forest %" "Burned Forest %" "Burned Cropland %" "Agroforestry %") nonotes b(%4.2f) stats(N N_clust r2_a, labels("N" "Cluster" "Adjusted R-squared" ) fmt(%4.0f %4.0f %4.2f)) star(* 0.10 ** 0.05 *** 0.01) varlabels(,elist(weight:_cons "{break}{hline @width}")) addnotes("Notes: The outcome variable in all models is forest cover in percent. Estimates are from panel regression with fixed effects and standard errors clustered at the matched pair level in parentheses: * p < 0.10, ** p < 0.05, *** p < 0.01.")  replace 

* DiD: 10km Spillover
eststo sp10k_1: xtreg forest i.spillover10k_treated##i.post if spillover10k_weight!=., fe cluster(spillover10k_pair)
eststo sp10k_2: xtreg denseforest i.spillover10k_treated##i.post if spillover10k_weight!=., fe cluster(spillover10k_pair)
eststo sp10k_3: xtreg sparseforest i.spillover10k_treated##i.post if spillover10k_weight!=., fe cluster(spillover10k_pair)
eststo sp10k_4: xtreg burned_forest i.spillover10k_treated##i.post if spillover10k_weight!=., fe cluster(spillover10k_pair)
eststo sp10k_5: xtreg burned_crop i.spillover10k_treated##i.post if spillover10k_weight!=., fe cluster(spillover10k_pair)
eststo sp10k_6: reg potentialpes i.spillover10k_treated if spillover10k_weight!=., cluster(spillover10k_pair)

esttab sp10k_1 sp10k_2 sp10k_3 sp10k_4 sp10k_5 sp10k_6 using "$working_ANALYSIS/results/tables/tableS15_miombo_sp10k.rtf", keep( 1.post 2.post 1.spillover10k_treated 1.spillover10k_treated#1.post 1.spillover10k_treated#2.post _cons) label se(%4.2f) transform(ln*: exp(@) exp(@)) mtitles("Any Forest %" "Dense Forest %" "Sparse Forest %" "Burned Forest %" "Burned Cropland %" "Agroforestry %") nonotes b(%4.2f) stats(N N_clust r2_a, labels("N" "Cluster" "Adjusted R-squared" ) fmt(%4.0f %4.0f %4.2f)) star(* 0.10 ** 0.05 *** 0.01) varlabels(,elist(weight:_cons "{break}{hline @width}")) addnotes("Notes: The outcome variable in all models is forest cover in percent. Estimates are from panel regression with fixed effects and standard errors clustered at the matched pair level in parentheses: * p < 0.10, ** p < 0.05, *** p < 0.01.")  replace 

* DiD: Combined SCCP + 5-km Spillover area
eststo combined1: xtreg forest i.combined_treated##i.post if combined_weight!=., fe cluster(combined_pair) coeflegend
eststo combined2: xtreg denseforest i.combined_treated##i.post if combined_weight!=., fe cluster(combined_pair)
eststo combined3: xtreg sparseforest i.combined_treated##i.post if combined_weight!=., fe cluster(combined_pair)
eststo combined4: xtreg burned_forest i.combined_treated##i.post if combined_weight!=., fe cluster(combined_pair)
eststo combined5: xtreg burned_crop i.combined_treated##i.post if combined_weight!=., fe cluster(combined_pair)
eststo combined6: reg potentialpes i.combined_treated if combined_weight!=., cluster(combined_pair)

esttab combined1 combined2 combined3 combined4 combined5 combined6 using "$working_ANALYSIS/results/tables/tableS16_miombo_combined.rtf", keep( 1.post 2.post 1.combined_treated 1.combined_treated#1.post 1.combined_treated#2.post _cons) label se(%4.2f) transform(ln*: exp(@) exp(@)) mtitles("Any Forest %" "Dense Forest %" "Sparse Forest %" "Burned Forest %" "Burned Cropland %" "Agroforestry %") nonotes b(%4.2f) stats(N N_clust r2_a, labels("N" "Cluster" "Adjusted R-squared" ) fmt(%4.0f %4.0f %4.2f)) star(* 0.10 ** 0.05 *** 0.01) varlabels(,elist(weight:_cons "{break}{hline @width}")) addnotes("Notes: The outcome variable in all models is forest cover in percent. Estimates are from panel regression with fixed effects and standard errors clustered at the matched pair level in parentheses: * p < 0.10, ** p < 0.05, *** p < 0.01.")  replace 


*Figure 6.	SCCP effects remote sensing outcomes
eststo sccp1: xtreg forest i.sccp_treated##i.post if sccp_weight!=., fe cluster(sccp_pair)

xtreg forest i.sccp_treated##i.post if sccp_weight!=.,re cluster(sccp_pair) 
eststo sp5k_1: xtreg forest i.spillover5k_treated##i.post if spillover5k_weight!=., fe cluster(spillover5k_pair)
eststo combined1: xtreg forest i.combined_treated##i.post if combined_weight!=., fe cluster(combined_pair) coeflegend


coefplot (sccp1, offset(0.2)) (sp5k_1) (combined1, offset(-0.2)), rename(1.sccp_treated = 1.combined_treated 1.spillover2k_treated = 1.combined_treated 1.spillover5k_treated = 1.combined_treated 1.spillover10k_treated = 1.combined_treated 1.sccp_treated#1.post = 1.combined_treated#1.post 1.sccp_treated#2.post = 1.combined_treated#2.post 1.spillover2k_treated#1.post = 1.combined_treated#1.post  1.spillover5k_treated#1.post = 1.combined_treated#1.post 1.spillover10k_treated#1.post = 1.combined_treated#1.post   1.spillover2k_treated#2.post = 1.combined_treated#2.post 1.spillover5k_treated#2.post = 1.combined_treated#2.post  1.spillover10k_treated#2.post = 1.combined_treated#2.post) xla(-10(5)20) title("{bf: A:} DiD estimates") byopts( compact  imargin(*1.2) rows(1) )   drop(_cons 1.post 2.post) coeflabels(1.combined_treated#1.post  = "Treated*2014" 1.combined_treated#2.post = "Treated*2019" 1.post = "2014" 2.post = "2019")  xline(0, lpattern(dash) lcolor(gs3))   xtitle("Regression estimated impact in %-points", ) grid(none) levels(95 90)mlabel(cond(@pval<.005, "***", cond(@pval<.05, "**", cond(@pval<.1, "*", "")))) msize(3pt) msymbol(D) mlabsize(8pt) mlabposition(2) mlabgap(-1)  subtitle(,  lstyle(none) margin(medium) nobox justification(center) alignment(top) bmargin(top))  xsize(3.465) ysize(2) ciopts(lwidth(0.8 2)  lcolor(*1 *.3) recast(rcap)) legend(order(3 "SCCP Area" 6 "5-km Spillover Area" 9 "Combined Area") rows(2))
gr save "$working_ANALYSIS/results/intermediate/did_forest_cover_impact.gph", replace

xtreg forest i.sccp_treated##i.post if sccp_weight!=., re cluster(sccp_pair)
margins i.sccp_treated, at(post=(0 1 2)) 
marginsplot, title("{bf: B:} SCCP Area: Predicted marginal effects")  xtitle("") yline(0, lpattern(solid)) xla(0 "Before SCCP" 1 "2014" 2 "2019", nogrid) legend(order(1 "Control" 2 "Treated")) yla(0(20)100) ytitle(" Predicted forest cover") recastci(rarea) ciopts(lw(none) fcolor(%50)) xsize(3) ysize(2)
gr save  "$working_ANALYSIS/results/intermediate/forest_cover_marginal_effects.gph", replace

gr combine "$working_ANALYSIS/results/intermediate/did_forest_cover_impact.gph" "$working_ANALYSIS/results/intermediate/forest_cover_marginal_effects.gph", scale(1.3) rows(1) graphregion(margin(tiny))  xsize(4) ysize(2)
gr export "$working_ANALYSIS/results/figures/figS8_miombo_impact.png", replace width(4000)


** EOF
