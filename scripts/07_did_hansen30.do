*--------------------------------------------------------------------
* SCRIPT:  07_did_hansen30.do
* PURPOSE: Robustness check. Repeats 06_did_hansen20.do with forest defined at
*          a 30% rather than a 20% canopy threshold.
*
* INPUT:   processed/hansen30pct_matched.dta
*
* OUTPUT:  results/figures/figS5_forest_cover_impact_30pct.png   Figure S5
*          results/tables/tableS7_twfe_30pct.rtf                 Table S7
*          results/diagnostics/diag_pre_trends_30pct.rtf
*          results/diagnostics/diag_parallel_trends_30pct.png
*          results/diagnostics/diag_closeness_gnp_30pct.rtf
*
* DEPENDS: coefplot, estout, grc1leg2
* RUN VIA: run.do (do not run standalone; requires $working_ANALYSIS)
*--------------------------------------------------------------------



* Load cleaned matched cell dataset
clear
use "$working_ANALYSIS/processed/hansen30pct_matched.dta"

*--------------------------
* Post-matching balancing
*--------------------------
egen median_distance_GNP_sccp = median(mean_distance_np) if sccp_treated==1
gen treated_close = 0 if sccp_treated==0
replace treated_close = 1 if mean_distance_np < median_distance_GNP_sccp & sccp_treated==1
gen treated_not_close = 0 if sccp_treated==0
replace treated_not_close = 1 if mean_distance_np > median_distance_GNP_sccp & sccp_treated==1

// Put dataset in long format for regression analysis
reshape long forest30pct , i(id) j(year)
xtset id year
gen post = .
replace post = 0 if year < 2005          // Pre-treatment
replace post = 1 if year >= 2005 & year < 2015   // During treatment
replace post = 2 if year >= 2015         // After project ended
label define postlbl 0 "Pre" 1 "Post2014" 2 "Post2019", replace
label values post postlbl

replace forest30pct = forest30pct*100

 

// GRAPH Parallel TRENDS
*SCCP
preserve
collapse (mean) forest30pct if sccp_weight!=. , by (sccp_treated year)
reshape wide forest30pct, i(year) j(sccp_treated)
lab var forest30pct0 "Control cells" 
lab var forest30pct1 "Treatment cells"
graph twoway (scatter forest30pct0 year, connect(1) lcolor("gs10%80") mcolor("gs10") msymbol(D)) (scatter forest30pct1 year, lcolor("31 119 180%80") msymbol(D) mcolor("31 119 180")  connect(1)),   ytitle(forest cover in %) yla(70(10)100)  xtitle(year) xlab(2000 2005 2014 2019) xline(2005 2014, lpattern(dash) lcolor(black) lwidth(medium))   legend(ring(1) rows(1) pos(6) size(8pt))  title("{bf:A} SCCP area")
gr save "$working_ANALYSIS/results/intermediate/parallel_trends_sccp.gph", replace
restore


*2-km Spillover area
preserve
collapse (mean) forest30pct if spillover2k_weight!=. , by (spillover2k_treated year)
reshape wide forest30pct, i(year) j(spillover)
lab var forest30pct0 "Control cells" 
lab var forest30pct1 "Treatment cells"
graph twoway (scatter forest30pct0 year, connect(1) lcolor("gs10%80") mcolor("gs10") msymbol(D)) (scatter forest30pct1 year, lcolor("31 119 180%80") msymbol(D) mcolor("31 119 180")  connect(1)),   ytitle(forest cover in %)  yla(70(10)100) xtitle(year) xlab(2000 2005  2014 2019) xline(2005 2014, lpattern(dash) lcolor(black) lwidth(medium))   legend(ring(1) rows(1) pos(6) )  title("{bf:B} 2-km Spillover area")
gr save "$working_ANALYSIS/results/intermediate/parallel_trends_spillover2k.gph", replace
restore


*5-km Spillover area
preserve
collapse (mean) forest30pct if spillover5k_weight!=. , by (spillover5k_treated year)
reshape wide forest30pct,  i(year) j(spillover)
lab var forest30pct0 "Control cells" 
lab var forest30pct1 "Treatment cells"
graph twoway (scatter forest30pct0 year, connect(1) lcolor("gs10%80") mcolor("gs10") msymbol(D)) (scatter forest30pct1 year, lcolor("31 119 180%80") msymbol(D) mcolor("31 119 180")  connect(1)),   ytitle(forest cover in %)  yla(70(10)100)  xtitle(year)  xlab(2000 2005  2014 2019) xline(2005 2014, lpattern(dash) lcolor(black) lwidth(medium))   legend(ring(1) rows(1) pos(6))  title("{bf:C} 5-km Spillover area")
gr save "$working_ANALYSIS/results/intermediate/parallel_trends_spillover5k.gph", replace
restore


*10-km Spillover area
preserve
collapse (mean) forest30pct if spillover10k_weight!=. , by (spillover10k_treated year)
reshape wide forest30pct,  i(year) j(spillover)
lab var forest30pct0 "Control cells" 
lab var forest30pct1 "Treatment cells"
graph twoway (scatter forest30pct0 year, connect(1) lcolor("gs10%80") mcolor("gs10") msymbol(D)) (scatter forest30pct1 year, lcolor("31 119 180%80") msymbol(D) mcolor("31 119 180")  connect(1)),   ytitle(forest cover in %)  yla(70(10)100) xtitle(year)  xlab(2000 2005  2014 2019) xline(2005 2014,lpattern(dash) lcolor(black) lwidth(medium))   legend(ring(1) rows(1) pos(6))  title("{bf:D} 10-km Spillover area")
gr save "$working_ANALYSIS/results/intermediate/parallel_trends_spillover10k.gph", replace
restore



*Combined: SCCP & 5-km Spillover area
preserve
collapse (mean) forest30pct if combined_weight!=. , by (combined_treated year)
reshape wide forest30pct,  i(year) j(combined)
lab var forest30pct0 "Control cells" 
lab var forest30pct1 "Treatment cells"
graph twoway (scatter forest30pct0 year, connect(1) lcolor("gs10%80") mcolor("gs10") msymbol(D)) (scatter forest30pct1 year, lcolor("31 119 180%80") msymbol(D) mcolor("31 119 180")  connect(1)),   ytitle(forest cover in %)  yla(70(10)100) xtitle(year)  xlab(2000 2005  2014 2019) xline(2005 2014, lpattern(dash) lcolor(black) lwidth(medium))   legend(ring(1) rows(1) pos(6))  title("{bf:E} Combined: SCCP & 5-km Spillover area")
gr save "$working_ANALYSIS/results/intermediate/parallel_trends_combined.gph", replace
restore

*Any Forest Cover
grc1leg2 "$working_ANALYSIS/results/intermediate/parallel_trends_sccp.gph" "$working_ANALYSIS/results/intermediate/parallel_trends_spillover2k.gph" "$working_ANALYSIS/results/intermediate/parallel_trends_spillover5k.gph" "$working_ANALYSIS/results/intermediate/parallel_trends_spillover10k.gph" "$working_ANALYSIS/results/intermediate/parallel_trends_combined.gph", rows(2) xsize(4) ysize(2) scale(1.2)
gr save  "$working_ANALYSIS/results/intermediate/parallel_trends_30pct.gph", replace
gr export  "$working_ANALYSIS/results/diagnostics/diag_parallel_trends_30pct.png", replace width(4000)



*testing for pre-trends
eststo tableS2_1: xtreg forest30pct i.year##i.sccp_treated if sccp_weight!=. & year < 2005, fe cluster(sccp_pair)
eststo tableS2_2: xtreg forest30pct i.year##i.spillover2k_treated if spillover2k_weight!=. & year < 2005, fe cluster(spillover2k_pair)
eststo tableS2_3: xtreg forest30pct i.year##i.spillover5k_treated if spillover5k_weight!=. & year  < 2005, fe cluster(spillover5k_pair)
eststo tableS2_4: xtreg forest30pct i.year##i.spillover10k_treated if spillover10k_weight!=. & year  < 2005, fe cluster(spillover10k_pair)
eststo tableS2_5: xtreg forest30pct i.year##i.combined_treated if combined_weight!=. & year < 2005, fe cluster(combined_pair)



esttab tableS2_1 tableS2_2 tableS2_3 tableS2_4 tableS2_5 using "$working_ANALYSIS/results/diagnostics/diag_pre_trends_30pct.rtf", rename(2001.year#1.sccp_treated 2001.year#1.combined_treated  2002.year#1.sccp_treated 2002.year#1.combined_treated 2003.year#1.sccp_treated 2003.year#1.combined_treated 2004.year#1.sccp_treated  2004.year#1.combined_treated 2001.year#1.spillover2k_treated 2001.year#1.combined_treated  2002.year#1.spillover2k_treated 2002.year#1.combined_treated 2003.year#1.spillover2k_treated 2003.year#1.combined_treated 2004.year#1.spillover2k_treated  2004.year#1.combined_treated 2001.year#1.spillover5k_treated 2001.year#1.combined_treated  2002.year#1.spillover5k_treated 2002.year#1.combined_treated 2003.year#1.spillover5k_treated 2003.year#1.combined_treated 2004.year#1.spillover5k_treated  2004.year#1.combined_treated 2001.year#1.spillover10k_treated 2001.year#1.combined_treated  2002.year#1.spillover10k_treated 2002.year#1.combined_treated 2003.year#1.spillover10k_treated 2003.year#1.combined_treated 2004.year#1.spillover10k_treated  2004.year#1.combined_treated) keep(2001.year 2002.year 2003.year 2004.year 2001.year#1.combined_treated 2002.year#1.combined_treated 2003.year#1.combined_treated 2004.year#1.combined_treated _cons) label se(%4.2f) transform(ln*: exp(@) exp(@)) mtitles("SCCP area" "2-km Spillover area" "5-km Spillover area" "10-km Spillover area"	"Combined area") nonotes b(%4.2f) stats(N N_clust r2_a, labels("N" "Cluster" "Adjusted R-squared" ) fmt(%4.0f %4.0f %4.2f)) star(* 0.10 ** 0.05 *** 0.01) varlabels(,elist(weight:_cons "{break}{hline @width}")) addnotes("Notes: The outcome variable in all models is forest cover in percent with 2000 as the reference year. Estimates are from panel regression with fixed effects and standard errors clustered at the matched pair level in parentheses: * p < 0.10, ** p < 0.05, *** p < 0.01.")  replace 



*DiD: SCCP area
eststo sccp1: xtreg forest30pct i.sccp_treated##i.post if sccp_weight!=., fe cluster(sccp_pair)
testparm 1.sccp_treated#1.post 1.sccp_treated#2.post, equal
margins sccp_treated#post

*Leakage test: Are cells closer to the GNP Experiencing less deforestation?
eststo rc_closeness_GNP1: xtreg forest30pct i.treated_close##i.post if sccp_weight!=. , fe  cluster(sccp_pair) 
eststo rc_closeness_GNP2: xtreg forest30pct i.treated_not_close##i.post if sccp_weight!=. , fe cluster(sccp_pair) 
esttab rc_closeness_GNP1 rc_closeness_GNP2 using "$working_ANALYSIS/results/diagnostics/diag_closeness_gnp_30pct.rtf", keep( 1.post 2.post 1.treated_close 1.treated_close#1.post 1.treated_close#2.post 1.treated_not_close 1.treated_not_close#1.post 1.treated_not_close#2.post _cons) label se(%4.2f) transform(ln*: exp(@) exp(@)) mtitles("<6km to GNP" ">6km to GNP") nonotes b(%4.2f) stats(N N_clust r2_a, labels("N" "Cluster" "Adjusted R-squared" ) fmt(%4.0f %4.0f %4.2f)) star(* 0.10 ** 0.05 *** 0.01) varlabels(,elist(weight:_cons "{break}{hline @width}")) addnotes("Notes: The outcome variable in all models is forest cover in percent. Estimates are from panel regression with fixed effects and standard errors clustered at the matched pair level in parentheses: * p < 0.10, ** p < 0.05, *** p < 0.01.")  replace 

* DiD: 2km Spillover
eststo sp2k_1: xtreg forest30pct i.spillover2k_treated##i.post if spillover2k_weight!=., fe cluster(spillover2k_pair)

* DiD: 5km Spillover
eststo sp5k_1: xtreg forest30pct i.spillover5k_treated##i.post if spillover5k_weight!=., fe cluster(spillover5k_pair)

* DiD: 10km Spillover
eststo sp10k_1: xtreg forest30pct i.spillover10k_treated##i.post if spillover10k_weight!=., fe cluster(spillover10k_pair)

* DiD: Combined SCCP + 5-km Spillover area
eststo combined1: xtreg forest30pct i.combined_treated##i.post if combined_weight!=., fe cluster(combined_pair) coeflegend

esttab sccp1 sp2k_1 sp5k_1 sp10k_1 combined1 using "$working_ANALYSIS/results/tables/tableS7_twfe_30pct.rtf", rename(1.sccp_treated#1.post 1.combined_treated#1.post 1.sccp_treated#2.post 1.combined_treated#2.post 1.spillover2k_treated#1.post 1.combined_treated#1.post 1.spillover2k_treated#2.post 1.combined_treated#2.post 1.spillover5k_treated#1.post 1.combined_treated#1.post 1.spillover5k_treated#2.post 1.combined_treated#2.post 1.spillover10k_treated#1.post 1.combined_treated#1.post 1.spillover10k_treated#2.post 1.combined_treated#2.post) keep(1.post 2.post 1.combined_treated#1.post 1.combined_treated#2.post _cons)  label se(%4.2f) transform(ln*: exp(@) exp(@)) mtitles("SCCP area" "2-km Spillover area" "5-km Spillover area" "10-km Spillover area"	"Combined area") nonotes b(%4.2f) stats(N N_clust r2_a, labels("N" "Cluster" "Adjusted R-squared" ) fmt(%4.0f %4.0f %4.2f)) star(* 0.10 ** 0.05 *** 0.01) varlabels(,elist(weight:_cons "{break}{hline @width}")) addnotes("Notes: The outcome variable in all models is forest cover in percent with 2000 as the reference year. Estimates are from panel regression with fixed effects and standard errors clustered at the matched pair level in parentheses: * p < 0.10, ** p < 0.05, *** p < 0.01.")  replace 



*Figure 6.	SCCP effects remote sensing outcomes
eststo sccp1: xtreg forest30pct i.sccp_treated##i.post if sccp_weight!=., fe cluster(sccp_pair)
xtreg forest30pct i.sccp_treated##i.post if sccp_weight!=.,re cluster(sccp_pair) 
eststo sp5k_1: xtreg forest30pct i.spillover5k_treated##i.post if spillover5k_weight!=., fe cluster(spillover5k_pair)
eststo combined1: xtreg forest30pct i.combined_treated##i.post if combined_weight!=., fe cluster(combined_pair) coeflegend


coefplot (sccp1, offset(0.2)) (sp5k_1) (combined1, offset(-0.2)), rename(1.sccp_treated = 1.combined_treated 1.spillover2k_treated = 1.combined_treated 1.spillover5k_treated = 1.combined_treated 1.spillover10k_treated = 1.combined_treated 1.sccp_treated#1.post = 1.combined_treated#1.post 1.sccp_treated#2.post = 1.combined_treated#2.post 1.spillover2k_treated#1.post = 1.combined_treated#1.post  1.spillover5k_treated#1.post = 1.combined_treated#1.post 1.spillover10k_treated#1.post = 1.combined_treated#1.post   1.spillover2k_treated#2.post = 1.combined_treated#2.post 1.spillover5k_treated#2.post = 1.combined_treated#2.post  1.spillover10k_treated#2.post = 1.combined_treated#2.post) xla(-2(1)4) title("{bf: A:} DiD estimates") byopts( compact  imargin(*1.2) rows(1) )   drop(_cons 1.post 2.post) coeflabels(1.combined_treated#1.post  = "Treated*During SCCP" 1.combined_treated#2.post = "Treated*Post-SCCP " )  xline(0, lpattern(dash) lcolor(gs3))   xtitle("Regression estimated impact in %-points", ) grid(none) levels(95 90)mlabel(cond(@pval<.005, "***", cond(@pval<.05, "**", cond(@pval<.1, "*", "")))) msize(medium) msymbol(D) mlabsize(6pt) mlabposition(2) mlabgap(-1)  subtitle(,  lstyle(none) margin(medium) nobox justification(center) alignment(top) bmargin(top))  xsize(3) ysize(2) ciopts(lwidth(0.8 2)  lcolor(*1 *.3) recast(rcap)) legend(order(3 "SCCP Area" 6 "5-km Spillover Area" 9 "Combined Area") rows(1))
gr save "$working_ANALYSIS/results/intermediate/did_forest_cover_impact.gph", replace

xtreg forest30pct i.sccp_treated##i.year if sccp_weight!=., re cluster(sccp_pair)
margins i.sccp_treated, at(year=(2000(1)2019)) 

marginsplot, ///
    plot1opts(msymbol(O) mcolor("gs10") lcolor("gs10") msize(small)) ///
    plot2opts(msymbol(D) mcolor("31 119 180") lcolor("31 119 180") msize(small)) ///
    title("{bf: B:} SCCP Area: Predicted marginal effects") ///
    xtitle("Year") ///
    xla(2000(2)2020, nogrid) ///
    legend(order(3 "Control" 4 "Treated")) ///
    yla(70(10)100) ///
    ytitle("Predicted forest cover") ///
    recastci(rarea) ///
    ci1opts(lw(none) fintensity(%40) fcolor("gs10%40")) ///
    ci2opts(lw(none) fintensity(%40) fcolor("31 119 180%40")) ///
    xsize(3) ysize(2) ///
    xline(2005 2014, lpattern(dash) lcolor(black) lwidth(medium))
gr save  "$working_ANALYSIS/results/intermediate/forest_cover_marginal_effects.gph", replace



gr combine "$working_ANALYSIS/results/intermediate/did_forest_cover_impact.gph" "$working_ANALYSIS/results/intermediate/forest_cover_marginal_effects.gph", scale(1.4)  rows(1) graphregion(margin(tiny))  xsize(3.465) ysize(1.6)
gr save "$working_ANALYSIS/results/intermediate/hansen30pct_TWFE.gph", replace
gr export "$working_ANALYSIS/results/figures/figS5_forest_cover_impact_30pct.png", replace width(4000)


** EOF



