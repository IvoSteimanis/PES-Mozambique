*--------------------------------------------------------------------
* SCRIPT:  10_gnp_leakage.do
* PURPOSE: Tests whether deforestation was displaced from the SCCP area
*          into Gorongosa National Park (GNP). Compares GNP grid cells
*          near the SCCP boundary with GNP cells further away.
*
* INPUT:   processed/hansen20pct_rdy.dta
*
* OUTPUT:  results/figures/figS6_gnp_leakage.png          Figure S6
*          results/tables/tableS10_gnp_leakage.rtf        Table S10
*          results/diagnostics/diag_gnp_leakage_continuous.png
*
* DEPENDS: coefplot, estout
* RUN VIA: run.do (do not run standalone; requires $working_ANALYSIS)
*--------------------------------------------------------------------

clear all
set more off

* ============================================================================
* 1. Load data and keep only GNP cells
* ============================================================================
use "$working_ANALYSIS/processed/hansen20pct_rdy.dta", clear

keep if cell_groups == 4
di as text "Number of GNP grid cells: " _N

* ============================================================================
* 2. Create proximity to SCCP indicator
* ============================================================================
* Use distance to the NORTHERN (analyzed) part of the SCCP only.
* The main DiD analysis treats only the northern section (around Nhambita);
* cells further south in the nominal project area are not in our treatment sample.
gen distance_to_sccp = mean_distancetoprojectareain
label var distance_to_sccp "Distance to analyzed (northern) SCCP boundary, meters"

gen close_to_sccp = (distance_to_sccp <= 2000) if !missing(distance_to_sccp)
label var close_to_sccp "Within 2km of SCCP boundary"
label define close_lbl 0 "Far from SCCP (>2km)" 1 "Close to SCCP (<=2km)"
label values close_to_sccp close_lbl
tab close_to_sccp, missing

gen distance_km = distance_to_sccp / 1000
label var distance_km "Distance to SCCP boundary (km)"

* ============================================================================
* 3. Reshape to long panel (2000-2019)
* ============================================================================
reshape long forest20pct, i(id) j(year)
replace forest20pct = forest20pct * 100
rename forest20pct forest_cover
label var forest_cover "Forest cover in % (Hansen 20% threshold)"
xtset id year

* ============================================================================
* 4. Parallel trends figure
* ============================================================================
preserve
collapse (mean) mean_forest=forest_cover ///
	(sd) sd_forest=forest_cover ///
	(count) n=forest_cover, by(year close_to_sccp)

gen se = sd_forest / sqrt(n)
gen ci_lo = mean_forest - 1.96*se
gen ci_hi = mean_forest + 1.96*se

reshape wide mean_forest sd_forest n se ci_lo ci_hi, i(year) j(close_to_sccp)
* Labels must match close_to_sccp, which is defined at 2 km above.
label var mean_forest0 "Far from SCCP (>2km)"
label var mean_forest1 "Close to SCCP (<=2km)"

twoway ///
	(rarea ci_lo1 ci_hi1 year, fcolor("220 38 127%20") lcolor(%0)) ///
	(rarea ci_lo0 ci_hi0 year, fcolor("31 119 180%20") lcolor(%0)) ///
	(connected mean_forest1 year, lcolor("220 38 127") mcolor("220 38 127") msymbol(D)) ///
	(connected mean_forest0 year, lcolor("31 119 180") mcolor("31 119 180") msymbol(D)), ///
	xline(2005 2014, lcolor(black) lpattern(dash) lwidth(medium)) ///
	ytitle("Forest cover (%)") xtitle("Year") ///
	xlabel(2000(2)2019) yla(, format(%9.0f) nogrid) ///
	legend(order(3 "Close to SCCP ({&le}2km)" 4 "Far from SCCP (>2km)") ring(1) rows(1) pos(6) size(8pt)) ///
	title("{bf:A} Forest cover in Gorongosa National Park") ///
	xsize(4) ysize(2.5)

* Panel A of Figure S6; combined with panel B below.
gr save "$working_ANALYSIS/results/intermediate/gnp_leakage_parallel_trends.gph", replace
restore

* ============================================================================
* 5. Event-study: year-by-year interactions (binary, 2004 reference)
* ============================================================================
eststo clear

eststo gnp_binary: xtreg forest_cover ib2004.year##i.close_to_sccp, fe cluster(id)
estimates store gnp_binary_est

coefplot gnp_binary_est, ///
	keep(*.year#1.close_to_sccp) ///
	rename( ///
		2000.year#1.close_to_sccp = "2000" ///
		2001.year#1.close_to_sccp = "2001" ///
		2002.year#1.close_to_sccp = "2002" ///
		2003.year#1.close_to_sccp = "2003" ///
		2005.year#1.close_to_sccp = "2005" ///
		2006.year#1.close_to_sccp = "2006" ///
		2007.year#1.close_to_sccp = "2007" ///
		2008.year#1.close_to_sccp = "2008" ///
		2009.year#1.close_to_sccp = "2009" ///
		2010.year#1.close_to_sccp = "2010" ///
		2011.year#1.close_to_sccp = "2011" ///
		2012.year#1.close_to_sccp = "2012" ///
		2013.year#1.close_to_sccp = "2013" ///
		2014.year#1.close_to_sccp = "2014" ///
		2015.year#1.close_to_sccp = "2015" ///
		2016.year#1.close_to_sccp = "2016" ///
		2017.year#1.close_to_sccp = "2017" ///
		2018.year#1.close_to_sccp = "2018" ///
		2019.year#1.close_to_sccp = "2019" ///
	) ///
	vertical ///
	yline(0, lcolor(gs3) lpattern(solid)) ///
	xline(4.5 14.5, lcolor(black) lpattern(dash) lwidth(medium)) ///
	ciopts(lwidth(0.8 2) lcolor(*1 *.3) recast(rcap)) ///
	levels(95 90) ///
	msize(4pt) msymbol(D) mcolor("220 38 127") ///
	ytitle("DiD estimate (pp forest cover)") ///
	xtitle("Year") ///
	yla(, nogrid) ///
	title("{bf:B} GNP cells near ({&le}2km) vs far from SCCP") ///
	note("Reference year: 2004. Cell FE. SE clustered at cell level.") ///
	xlabel(, angle(45)) xsize(4) ysize(2.5)

* Panel B of Figure S6.
gr save "$working_ANALYSIS/results/intermediate/gnp_leakage_eventstudy.gph", replace

* ============================================================================
* 6. Event-study: continuous distance specification
* ============================================================================
eststo gnp_continuous: xtreg forest_cover ib2004.year##c.distance_km, fe cluster(id)
estimates store gnp_continuous_est

coefplot gnp_continuous_est, ///
	keep(*.year#c.distance_km) ///
	rename( ///
		2000.year#c.distance_km = "2000" ///
		2001.year#c.distance_km = "2001" ///
		2002.year#c.distance_km = "2002" ///
		2003.year#c.distance_km = "2003" ///
		2005.year#c.distance_km = "2005" ///
		2006.year#c.distance_km = "2006" ///
		2007.year#c.distance_km = "2007" ///
		2008.year#c.distance_km = "2008" ///
		2009.year#c.distance_km = "2009" ///
		2010.year#c.distance_km = "2010" ///
		2011.year#c.distance_km = "2011" ///
		2012.year#c.distance_km = "2012" ///
		2013.year#c.distance_km = "2013" ///
		2014.year#c.distance_km = "2014" ///
		2015.year#c.distance_km = "2015" ///
		2016.year#c.distance_km = "2016" ///
		2017.year#c.distance_km = "2017" ///
		2018.year#c.distance_km = "2018" ///
		2019.year#c.distance_km = "2019" ///
	) ///
	vertical ///
	yline(0, lcolor(gs3) lpattern(solid)) ///
	xline(4.5 14.5, lcolor(black) lpattern(dash) lwidth(medium)) ///
	ciopts(lwidth(0.8 2) lcolor(*1 *.3) recast(rcap)) ///
	levels(95 90) ///
	msize(4pt) msymbol(D) mcolor("31 119 180") ///
	ytitle("Coefficient on Year {&times} Distance (km)") ///
	xtitle("Year") ///
	yla(, nogrid) ///
	title("{bf:C} Distance gradient within GNP") ///
	note("Reference year: 2004. Positive = more forest farther from SCCP. Cell FE. SE clustered at cell level.") ///
	xlabel(, angle(45)) xsize(4) ysize(2.5)

* Diagnostic only; the continuous-distance gradient is not reported in the paper.
gr export "$working_ANALYSIS/results/diagnostics/diag_gnp_leakage_continuous.png", replace width(4000)

* ============================================================================
* 6b. FIGURE S6: parallel trends (panel A) + binary event study (panel B)
* ============================================================================
gr combine ///
	"$working_ANALYSIS/results/intermediate/gnp_leakage_parallel_trends.gph" ///
	"$working_ANALYSIS/results/intermediate/gnp_leakage_eventstudy.gph", ///
	rows(1) xsize(7) ysize(2.5) scale(1.3) graphregion(margin(tiny))

gr export "$working_ANALYSIS/results/figures/figS6_gnp_leakage.png", replace width(4000)


* ============================================================================
* 7. Collapsed post-treatment specifications
* ============================================================================
gen period = 0 if year < 2005
replace period = 1 if year >= 2005 & year <= 2014
replace period = 2 if year >= 2015 & year <= 2019
label define period_lbl 0 "Pre (before 2005)" 1 "During (2005-2014)" 2 "Post (2015-2019)"
label values period period_lbl

gen close_5km = (distance_to_sccp <= 5000) if !missing(distance_to_sccp)
label var close_5km "Within 5km of SCCP boundary"

eststo gnp_post_2k:   xtreg forest_cover i.period##i.close_to_sccp, fe cluster(id)
eststo gnp_post_5k:   xtreg forest_cover i.period##i.close_5km, fe cluster(id)
eststo gnp_post_cont: xtreg forest_cover i.period##c.distance_km, fe cluster(id)

* ============================================================================
* 8. Export regression table
* ============================================================================
esttab gnp_post_2k gnp_post_5k gnp_post_cont ///
    using "$working_ANALYSIS/results/tables/tableS10_gnp_leakage.rtf", ///
    keep(1.period#1.close_to_sccp 2.period#1.close_to_sccp 1.period#1.close_5km 2.period#1.close_5km 1.period#c.distance_km 2.period#c.distance_km 1.period 2.period _cons) ///
    label se(%4.3f) b(%4.3f) nogaps ///
    mtitles("Close <2km" "Close <5km" "Distance (km)") ///
    stats(N N_clust r2_a, labels("N" "Cells" "Adjusted R-squared") fmt(%4.0f %4.0f %4.3f)) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    nonotes addnotes("Notes: All models include cell fixed effects. Dependent variable: forest cover (Hansen 20% threshold)." ///
    "Sample: grid cells within Gorongosa National Park. Distance is measured to the SCCP boundary." ///
    "SE clustered at cell level. Periods: during SCCP (2005–2014) and post-SCCP (2015–2019), relative to pre-period (before 2005)." ///
    "A negative interaction coefficient indicates accelerated forest loss in GNP cells near the SCCP boundary, consistent with illegal displacement." ///
    "* p<0.10, ** p<0.05, *** p<0.01.") ///
    replace
	
* ============================================================================
* 9. Summary
* ============================================================================
di _newline(2) as text "============================================"
di as text "GNP LEAKAGE ANALYSIS — KEY RESULTS"
di as text "============================================"
* period: 0 = pre (<2005), 1 = during (2005-2014), 2 = post (2015-2019)
estimates restore gnp_post_2k
di as text "During x Close (2km, primary):"
lincom 1.period#1.close_to_sccp
di as text "Post x Close (2km, primary):"
lincom 2.period#1.close_to_sccp
di _newline
estimates restore gnp_post_5k
di as text "During x Close (5km, robustness):"
lincom 1.period#1.close_5km
di as text "Post x Close (5km, robustness):"
lincom 2.period#1.close_5km
di _newline
di as text "Negative & significant => evidence of leakage"
di as text "Insignificant => no evidence of leakage"
di as text "============================================"

** EOF
