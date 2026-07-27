*--------------------------------------------------------------------
* SCRIPT:  05_event_study.do
* PURPOSE: Year-by-year (event-study) DiD estimates of the SCCP effect on
*          forest cover, with 2004 as the reference year, and the flow-based
*          benchmark of avoided emissions against claimed and sold credits.
*
* INPUT:   processed/hansen20pct_matched.dta
*          processed/remote_sensing_matched.dta
*
* OUTPUT:  results/tables/tableS1_emission_benchmark.csv    Table S1
*          results/tables/tableS6_event_study.rtf           Table S6
*          results/intermediate/event_study_sccp_hansen20.gph
*                                                  panel C of Figure 4,
*                                                  combined in 06_did_hansen20.do
*          results/diagnostics/diag_event_study_all_areas.png
*          results/diagnostics/diag_event_study_miombo.png
*          processed/flow_based_comparison.dta (intermediate)
*
* DEPENDS: coefplot, estout
* RUN VIA: run.do. This script must run BEFORE 06_did_hansen20.do, which
*          combines the event-study graph saved here as panel C of Figure 4.
*--------------------------------------------------------------------

clear all
set more off

* ============================================================================
* 1. EVENT STUDY using Hansen 20% data (annual, primary specification)
* ============================================================================
use "$working_ANALYSIS/processed/hansen20pct_matched.dta", clear

* Reshape to panel
reshape long forest20pct, i(id) j(year)
replace forest20pct = forest20pct*100
rename forest20pct forest
xtset id year

* --------------------------------------------------------
* 1a. SCCP Area: Year-by-year DiD with 2004 as reference
* --------------------------------------------------------
eststo clear

eststo es_sccp: xtreg forest ib2004.year##i.sccp_treated if sccp_weight!=., fe cluster(sccp_pair)

coefplot es_sccp, ///
	keep(*.year#1.sccp_treated) ///
	rename( ///
		2000.year#1.sccp_treated = "2000" ///
		2001.year#1.sccp_treated = "2001" ///
		2002.year#1.sccp_treated = "2002" ///
		2003.year#1.sccp_treated = "2003" ///
		2005.year#1.sccp_treated = "2005" ///
		2006.year#1.sccp_treated = "2006" ///
		2007.year#1.sccp_treated = "2007" ///
		2008.year#1.sccp_treated = "2008" ///
		2009.year#1.sccp_treated = "2009" ///
		2010.year#1.sccp_treated = "2010" ///
		2011.year#1.sccp_treated = "2011" ///
		2012.year#1.sccp_treated = "2012" ///
		2013.year#1.sccp_treated = "2013" ///
		2014.year#1.sccp_treated = "2014" ///
		2015.year#1.sccp_treated = "2015" ///
		2016.year#1.sccp_treated = "2016" ///
		2017.year#1.sccp_treated = "2017" ///
		2018.year#1.sccp_treated = "2018" ///
		2019.year#1.sccp_treated = "2019" ///
	) ///
	vertical ///
	yline(0, lcolor(gs3) lpattern(solid)) ///
	xline(4.5 14.5, lcolor(black) lpattern(dash) lwidth(medium)) ///
	ciopts(lwidth(0.8 2) lcolor(*1 *.3) recast(rcap)) ///
	levels(95 90) ///
	msize(4pt) msymbol(D) mcolor("31 119 180") ///
	ytitle("DiD estimate (pp forest cover)") ///
	xtitle("Year") yla(, nogrid) ///
	title("{bf:C} SCCP area: Event Study") ///
	xlabel(, angle(45)) xsize(3) ysize(2)

* Panel letter is C because 06_did_hansen20.do combines this graph as the third
* panel of Figure 4. It keeps that letter in the diagnostic figure below.
gr save "$working_ANALYSIS/results/intermediate/event_study_sccp_hansen20.gph", replace

* --------------------------------------------------------
* 1b. 5-km Spillover Area
* --------------------------------------------------------
eststo es_sp5k: xtreg forest ib2004.year##i.spillover5k_treated if spillover5k_weight!=., fe cluster(spillover5k_pair)

coefplot es_sp5k, ///
	keep(*.year#1.spillover5k_treated) ///
	rename( ///
		2000.year#1.spillover5k_treated = "2000" ///
		2001.year#1.spillover5k_treated = "2001" ///
		2002.year#1.spillover5k_treated = "2002" ///
		2003.year#1.spillover5k_treated = "2003" ///
		2005.year#1.spillover5k_treated = "2005" ///
		2006.year#1.spillover5k_treated = "2006" ///
		2007.year#1.spillover5k_treated = "2007" ///
		2008.year#1.spillover5k_treated = "2008" ///
		2009.year#1.spillover5k_treated = "2009" ///
		2010.year#1.spillover5k_treated = "2010" ///
		2011.year#1.spillover5k_treated = "2011" ///
		2012.year#1.spillover5k_treated = "2012" ///
		2013.year#1.spillover5k_treated = "2013" ///
		2014.year#1.spillover5k_treated = "2014" ///
		2015.year#1.spillover5k_treated = "2015" ///
		2016.year#1.spillover5k_treated = "2016" ///
		2017.year#1.spillover5k_treated = "2017" ///
		2018.year#1.spillover5k_treated = "2018" ///
		2019.year#1.spillover5k_treated = "2019" ///
	) ///
	vertical ///
	yline(0, lcolor(gs3) lpattern(solid)) ///
	xline(4.5, lcolor(black) lpattern(dash) lwidth(medium)) ///
	xline(14.5, lcolor(black) lpattern(dash) lwidth(medium)) ///
	ciopts(lwidth(0.8 2) lcolor(*1 *.3) recast(rcap)) ///
	levels(95 90) ///
	msize(4pt) msymbol(D) mcolor("220 38 127") ///
	ytitle("DiD estimate (pp forest cover)") ///
	xtitle("Year") yla(, nogrid) ///
	title("{bf:B} 5-km spillover area") ///
	note("Reference: 2004. Cell FE. SE clustered at matched-pair level.") ///
	xlabel(, angle(45)) xsize(3.5) ysize(2.5)

gr save "$working_ANALYSIS/results/intermediate/event_study_sp5k_hansen20.gph", replace

* --------------------------------------------------------
* 1c. Combined Area (SCCP + 5km spillover)
* --------------------------------------------------------
eststo es_combined: xtreg forest ib2004.year##i.combined_treated if combined_weight!=., fe cluster(combined_pair)

coefplot es_combined, ///
	keep(*.year#1.combined_treated) ///
	rename( ///
		2000.year#1.combined_treated = "2000" ///
		2001.year#1.combined_treated = "2001" ///
		2002.year#1.combined_treated = "2002" ///
		2003.year#1.combined_treated = "2003" ///
		2005.year#1.combined_treated = "2005" ///
		2006.year#1.combined_treated = "2006" ///
		2007.year#1.combined_treated = "2007" ///
		2008.year#1.combined_treated = "2008" ///
		2009.year#1.combined_treated = "2009" ///
		2010.year#1.combined_treated = "2010" ///
		2011.year#1.combined_treated = "2011" ///
		2012.year#1.combined_treated = "2012" ///
		2013.year#1.combined_treated = "2013" ///
		2014.year#1.combined_treated = "2014" ///
		2015.year#1.combined_treated = "2015" ///
		2016.year#1.combined_treated = "2016" ///
		2017.year#1.combined_treated = "2017" ///
		2018.year#1.combined_treated = "2018" ///
		2019.year#1.combined_treated = "2019" ///
	) ///
	vertical ///
	yline(0, lcolor(gs3) lpattern(solid)) ///
	xline(4.5, lcolor(black) lpattern(dash) lwidth(medium)) ///
	xline(14.5, lcolor(black) lpattern(dash) lwidth(medium)) ///
	ciopts(lwidth(0.8 2) lcolor(*1 *.3) recast(rcap)) ///
	levels(95 90) ///
	msize(4pt) msymbol(D) mcolor("254 97 0") ///
	ytitle("DiD estimate (pp forest cover)") ///
	xtitle("Year") yla(, nogrid) ///
	title("{bf:C} Combined area") ///
	note("Reference: 2004. Cell FE. SE clustered at matched-pair level.") ///
	xlabel(, angle(45)) xsize(3.5) ysize(2.5)

gr save "$working_ANALYSIS/results/intermediate/event_study_combined_hansen20.gph", replace

* --------------------------------------------------------
* 1d. Combined panel figure
* --------------------------------------------------------
gr combine ///
	"$working_ANALYSIS/results/intermediate/event_study_sccp_hansen20.gph" ///
	"$working_ANALYSIS/results/intermediate/event_study_sp5k_hansen20.gph" ///
	"$working_ANALYSIS/results/intermediate/event_study_combined_hansen20.gph", ///
	rows(1) xsize(7) ysize(2.5) scale(1.3) graphregion(margin(tiny))

* Diagnostic only; the paper reports the SCCP panel as Figure 4C and the
* full set of coefficients as Table S6.
gr export "$working_ANALYSIS/results/diagnostics/diag_event_study_all_areas.png", replace width(4000)


* ============================================================================
* 2. EVENT STUDY using primary remote sensing data (5 time points)
* ============================================================================
clear
use "$working_ANALYSIS/processed/remote_sensing_matched.dta"

reshape long forest denseforest sparseforest burned_forest burned_crop, i(id) j(year)
xtset id year

* SCCP area with 2002 as reference (last pre-treatment year in this dataset)
eststo es_rs_sccp: xtreg forest ib2002.year##i.sccp_treated if sccp_weight!=., fe cluster(sccp_pair)

coefplot es_rs_sccp, ///
	keep(*.year#1.sccp_treated) ///
	coeflabels( ///
		1996.year#1.sccp_treated = "1996" ///
		2005.year#1.sccp_treated = "2005" ///
		2014.year#1.sccp_treated = "2014" ///
		2019.year#1.sccp_treated = "2019" ///
	) ///
	vertical ///
	yline(0, lcolor(gs3) lpattern(solid)) ///
	xline(1.5, lcolor(black) lpattern(dash) lwidth(medium)) ///
	ciopts(lwidth(0.8 2) lcolor(*1 *.3) recast(rcap)) ///
	levels(95 90) ///
	msize(6pt) msymbol(D) mcolor("31 119 180") ///
	mlabel format(%9.1f) mlabposition(2) mlabgap(*2) mlabsize(7pt) ///
	ytitle("DiD estimate (pp forest cover)") ///
	xtitle("Year") yla(, nogrid) ///
	title("SCCP area: Event study (miombo classification)") ///
	note("Reference: 2002. Cell FE. SE clustered at matched-pair level.") ///
	xsize(3) ysize(2.5)

* Diagnostic only; not reported in the paper.
gr export "$working_ANALYSIS/results/diagnostics/diag_event_study_miombo.png", replace width(4000)


* ============================================================================
* 3. TABLE S6: Year-by-year DiD coefficients (Hansen 20%)
* ============================================================================
esttab es_sccp es_sp5k es_combined using "$working_ANALYSIS/results/tables/tableS6_event_study.rtf", ///
	keep(*.year#1.sccp_treated *.year#1.spillover5k_treated *.year#1.combined_treated) ///
	label se(%4.3f) b(%4.3f) ///
	mtitles("SCCP Area" "5-km Spillover" "Combined") ///
	stats(N N_clust r2_a, labels("N" "Cluster" "Adjusted R-squared") fmt(%4.0f %4.0f %4.2f)) ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	nonotes addnotes("Notes: Event-study specification using Hansen 20% canopy threshold data (2000-2019)." ///
		"2004 is the omitted reference year. Cell FE with SE clustered at matched-pair level." ///
		"* p<0.10, ** p<0.05, *** p<0.01.") ///
	replace


*============================================================================
* 4. TABLE S1: Flow-based benchmark of cumulative avoided emissions
*============================================================================
* Reuse es_sccp estimates; beta_t = cumulative avoided deforestation (pp) at year t
* (with 2004 as the reference year, so beta_2004 = 0 by construction).
* Converts the stock differential to hectares and tCO2e, then expresses it as a
* share of claimed sequestration and of credits actually sold.
*
* Sources for the constants below are documented in docs/data_provenance.md:
* project area and credit volumes come from the project design document and the
* registry; the carbon stock per hectare is the mature-miombo value used in the
* project's own accounting.

estimates restore es_sccp

local area    = 21725     // total project area, ha
local stock   = 83.7      // tCO2e per ha, mature miombo woodland
local claimed = 571690    // net claimed sequestration, tCO2e (post-buffer)
local sold    = 159817    // credits actually sold, tCO2e

tempname results
postfile `results' int year double beta double cum_ha double cum_tco2 ///
    double pct_claimed double pct_sold ///
    using "$working_ANALYSIS/processed/flow_based_comparison.dta", replace

foreach y of numlist 2000/2003 2005/2019 {
    capture local b = _b[`y'.year#1.sccp_treated]
    if _rc {
        di as error "Missing event-study coefficient for `y'; check the estimation above."
        exit 111
    }
    local cum_ha = `b' * `area' / 100
    local cum_co = `cum_ha' * `stock'
    local pct_c  = (`cum_co' / `claimed') * 100
    local pct_s  = (`cum_co' / `sold') * 100
    post `results' (`y') (`b') (`cum_ha') (`cum_co') (`pct_c') (`pct_s')
}
postclose `results'

use "$working_ANALYSIS/processed/flow_based_comparison.dta", clear
label var beta "beta_t (pp, cumulative avoided deforestation vs 2004)"
label var cum_ha "Cumulative avoided ha"
label var cum_tco2 "Cumulative avoided tCO2e"
label var pct_claimed "% of claimed sequestration (571,690 tCO2e)"
label var pct_sold "% of credits sold (159,817)"
list year beta cum_ha cum_tco2 pct_claimed pct_sold, sep(0) abbreviate(16)

export delimited "$working_ANALYSIS/results/tables/tableS1_emission_benchmark.csv", replace


** EOF
