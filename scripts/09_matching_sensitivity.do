*--------------------------------------------------------------------
* SCRIPT:  09_matching_sensitivity.do
* PURPOSE: Tests whether the forest-cover DiD estimate is robust to the
*          matching specification: caliper width (0.01/0.05/0.10),
*          matching with versus without replacement, Mahalanobis distance
*          matching, and three nearest neighbours.
*
* INPUT:   processed/hansen20pct_rdy.dta
*
* OUTPUT:  results/tables/tableS8_matching_sensitivity.rtf   Table S8
*
* DEPENDS: psmatch2, estout
* RUN VIA: run.do (do not run standalone; requires $working_ANALYSIS)
*
* NOTE:    The data preparation below repeats 02_matching_hansen20.do so that
*          each sensitivity specification starts from the same unmatched data.
*          Any change to the preparation in 02 must be mirrored here.
*--------------------------------------------------------------------

*--------------------------------------------------
* (1) Load and prepare the unmatched Hansen 20% data
*--------------------------------------------------

clear all
use "$working_ANALYSIS/processed/hansen20pct_rdy.dta"

* Reproducibility: psmatch2 without replacement breaks ties by the current
* sort order, so fix both the seed and the sort before any matching.
set seed 20260727
sort id

* Rename variables (same as 02_matching_hansen20.do)
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

* Pre-post forest change (Hansen-specific)
gen fc_change00_04 = forest20pct2004 - forest20pct2000

* Define spillover and SCCP treatment (same as 02_matching_hansen20.do)
gen spillover_5km = 0
replace spillover_5km = 1 if mean_distancetoprojectareain <=5000
replace spillover_5km = . if mean_distancetoprojectareain==0
replace spillover_5km = . if cell_groups==4

gen sccp=0
replace sccp=1 if treated_north==1
replace sccp=. if spillover_5km==1
replace sccp=. if cell_groups==4

* Confounders for matching (Hansen pre-treatment forest vars)
global confounders mean_distanceurban mean_distance_roads mean_distanceagriculture50 mean_slope sq_slope mean_elevation sq_elevation forest20pct2000 forest20pct2001 forest20pct2002 forest20pct2003 forest20pct2004 fc_change00_04

* Store estimates
eststo clear


*--------------------------------------------------
* A) Loop over caliper specifications (PSM, no replacement)
*--------------------------------------------------
foreach cal in 0.01 0.05 0.10 {

	preserve

	psmatch2 sccp $confounders if cell_groups < 4, n(1) noreplacement common caliper(`cal')
	tab _support _treated, column

	gen pair = _id if _treated==0
	replace pair = _n1 if _treated==1

	keep if _weight!=.
	reshape long forest20pct, i(id) j(year)
	replace forest20pct = forest20pct*100
	xtset id year

	gen post = 0
	replace post = 1 if year >= 2005 & year < 2015
	replace post = 2 if year >= 2015

	local calname = subinstr("`cal'",".","_",.)
	eststo cal`calname': xtreg forest20pct i.sccp##i.post, fe cluster(pair)

	restore
}


*--------------------------------------------------
* B) With replacement (caliper 0.05)
*--------------------------------------------------
preserve

psmatch2 sccp $confounders if cell_groups < 4, n(1) common caliper(0.05)
tab _support _treated, column

gen pair = _id if _treated==0
replace pair = _n1 if _treated==1

keep if _weight!=.
reshape long forest20pct, i(id) j(year)
replace forest20pct = forest20pct*100
xtset id year

gen post = 0
replace post = 1 if year >= 2005 & year < 2015
replace post = 2 if year >= 2015

eststo cal005_repl: xtreg forest20pct i.sccp##i.post, fe cluster(pair)

restore


*--------------------------------------------------
* C) Mahalanobis distance matching
*--------------------------------------------------
* psmatch2 with mahal() matches on Mahalanobis distance rather than on the
* propensity score; no propensity score is estimated in this specification.

preserve

keep if cell_groups < 4
psmatch2 sccp, n(1)   mahal($confounders)
tab _support _treated, column

gen pair = _id if _treated==0
replace pair = _n1 if _treated==1

keep if _weight!=.
reshape long forest20pct, i(id) j(year)
replace forest20pct = forest20pct*100
xtset id year

gen post = 0
replace post = 1 if year >= 2005 & year < 2015
replace post = 2 if year >= 2015

eststo mahal: xtreg forest20pct i.sccp##i.post, fe cluster(pair)

restore


*--------------------------------------------------
* D) N(3) nearest neighbors with replacement (caliper 0.05)
*--------------------------------------------------
preserve

psmatch2 sccp $confounders if cell_groups < 4, n(3) common caliper(0.05)
tab _support _treated, column

gen pair = _id if _treated==0
replace pair = _n1 if _treated==1

keep if _weight!=.
reshape long forest20pct, i(id) j(year)
replace forest20pct = forest20pct*100
xtset id year

gen post = 0
replace post = 1 if year >= 2005 & year < 2015
replace post = 2 if year >= 2015

eststo nn3: xtreg forest20pct i.sccp##i.post, fe cluster(pair)

restore


*--------------------------------------------------
* TABLE S8: DiD estimates across alternative matching specifications
*--------------------------------------------------
esttab cal0_01 cal0_05 cal0_10 cal005_repl mahal nn3 ///
	using "$working_ANALYSIS/results/tables/tableS8_matching_sensitivity.rtf", ///
	keep(1.sccp#1.post 1.sccp#2.post) ///
	label se(%4.2f) b(%4.2f) ///
	mtitles("Caliper=0.01" "Caliper=0.05 (main)" "Caliper=0.10" "With replacement" "Mahalanobis" "N(3) w/ repl.") ///
	stats(N N_clust r2_a, labels("N" "Cluster" "Adjusted R-squared") fmt(%4.0f %4.0f %4.2f)) ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	nonotes addnotes("Notes: All models use cell FE with SE clustered at the matched-pair level." ///
		"Outcome: forest cover (%, Hansen 20% threshold). Annual panel 2000-2019." ///
		"Post periods: During SCCP (2005-2014) and Post-SCCP (2015-2019) vs Pre (2000-2004)." ///
		"Caliper=0.05, N(1), no replacement is the main specification." ///
		"* p<0.10, ** p<0.05, *** p<0.01.") ///
	replace


** EOF
