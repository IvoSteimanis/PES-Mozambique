*--------------------------------------------------------------------
* SCRIPT:  11_survey_analysis.do
* PURPOSE: Household-survey results. Estimates the association between SCCP
*          participation and farming practices, agroforestry permanence,
*          wealth and income, motivations and environmental agency, and
*          employment in Gorongosa National Park. Missing values are handled
*          by multiple imputation through chained equations (MICE).
*
* INPUT:   processed/survey_rdy.dta
*
* OUTPUT:  results/figures/fig5_agroforestry_permanence.png   Figure 5
*          results/figures/fig6_motivation_agency.png         Figure 6
*          results/figures/fig7_wealth_income.png             Figure 7
*          results/figures/fig8_gnp_employment.png            Figure 8
*          results/figures/figS10_farming_plots.png           Figure S10
*          results/figures/figS11_gender_effects.png          Figure S11
*          results/tables/tableS17_balancing_stable.xlsx      Table S17
*          results/tables/tableS22_selection_agroforestry.rtf Table S22
*          results/tables/tableS23_wealth_index.rtf           Table S23
*          results/tables/tableS24_hh_income.rtf              Table S24
*          results/tables/tableS25_economic_ladder.rtf        Table S25
*          results/tables/tableS26_intrinsic.rtf              Table S26
*          results/tables/tableS27_env_agency.rtf             Table S27
*          results/diagnostics/diag_extrinsic_motivations.rtf
*
* DEPENDS: estout, coefplot, betterbar, iebaltab
* RUN VIA: run.do (do not run standalone; requires $working_ANALYSIS)
*
* NOTE:    Village identifiers in the shipped data are numeric codes only.
*          The village-name key that previously appeared in this file was
*          removed to protect respondent confidentiality.
*--------------------------------------------------------------------




clear
* Load dataset 
use "$working_ANALYSIS/processed/survey_rdy.dta", replace


* Buffer-zone villages are the reference group; the seven villages listed
* below by numeric ID are the SCCP and control villages.
gen bufferzone=1
replace bufferzone=0 if village_id==9 | village_id==10 | village_id==11 | village_id==13 | village_id==17 | village_id==29 | village_id==30

*additional vars etc-
egen z_intrinsic = std(intrinsic_motivations_trees)
egen z_extrinsic = std(extrinsic_motivations_trees)
egen z_agency = std(env_agency)

gen treatment = 0 if sccp_area==0 & bufferzone==0
replace treatment = 1 if sccp_area==0 & buffer==1
replace treatment = 2 if sccp_area==1 & buffer==0
replace treatment = 3 if sccp_area==1 & buffer==1

lab def treatie2 0 "Control (n=43)" 1 "GNP (n=344)" 2 "SCCP (n=102)" 3 "SCCP&GNP (n=249)", replace
lab val treatment treatie2


replace sccp_hh_benefit_now = 3 if sccp_area==1 & sccp_hh_benefit_now==.
tab sccp_hh_benefit_now
gen sccp_benefit_today = 0 if sccp_area == 0
replace sccp_benefit_today = 1 if sccp_hh_benefit_now==3
replace sccp_benefit_today = 2 if  sccp_hh_benefit_now==1 | sccp_hh_benefit_now==2
lab def benefit 0 "GNP" 1 "SCCP: no perceived benefits today" 2 "SCCP: perceived benefits today", replace
lab val sccp_benefit_today benefit

egen agroforestry_inplace = rownonmiss(sccp_agroforestry_inplace1 sccp_agroforestry_inplace2 sccp_agroforestry_inplace3 sccp_agroforestry_inplace4 sccp_agroforestry_inplace5 sccp_agroforestry_inplace6 sccp_agroforestry_inplace7) if sccp_area==1
replace agroforestry_inplace = 1 if agroforestry_inplace==0
replace agroforestry_inplace=0 if sccp_area==0
replace agroforestry_inplace=2 if agroforestry_inplace==7
lab def  aggro 0 "GNP only" 1 "Agroforestry not inplace" 2 "Agroforestry still inplace", replace
lab val agroforestry_inplace aggro
tab agroforestry_inplace

* Different classifications which we could use:
*(1) exogeneous based on location
tab treatment
tab sccp_area
*(2) endogeneous based on self-reported benefits of the SCCP
tab sccp_id

gen sccp_id2 = 0 if sccp_id==0
replace sccp_id2 = 1 if sccp_id==1
replace sccp_id2 = 2 if sccp_id==2 | sccp_id==3
replace sccp_id2 = 3 if sccp_id==4

lab def sccp_idie2 0 "Control (GNP)" 1 "Community REDD+" 2 "REDD+ & Agroforestry or Job" 3 "REDD+ & Agroforestry & Job", replace
lab val sccp_id2 sccp_idie2



*-------------------------------------------------------------------
* What can explain the observed slower deforestation in SCCP areas?
*-------------------------------------------------------------------
*farming practices: size of machambas, age, burning, opening of new machambas (after SCCP end)
*panel A: number of machambas, total size and average size
reg number_machambas i.treatment, cluster(village_id)
reg total_size_machambas i.treatment, cluster(village_id)
reg average_size_machambas i.treatment, cluster(village_id)

betterbarci average_size_machambas total_size_machambas number_machambas, over(sccp_id2) vertical barlab format(%5.1f)  xla(7 "Number" 22 "Total (ha)" 36 "Plot (ha)")   title("{bf: A} Farming plots", size(10pt))  yla(0(1)5.8) ytitle("Mean", size(6pt))  xsize(3) ysize(2)  legend(ring(1) pos(6) rows(1) size(6pt))
gr_edit plotregion1.plot6.style.editstyle label(textstyle(size(8-pt))) editcopy
gr_edit plotregion1.plot1.style.editstyle area(shadestyle(color("3 57 108"))) editcopy
gr_edit plotregion1.plot2.style.editstyle area(shadestyle(color("238 69 64"))) editcopy
gr_edit plotregion1.plot3.style.editstyle area(shadestyle(color("199 44 65"))) editcopy
gr_edit plotregion1.plot4.style.editstyle area(shadestyle(color("128 19 54"))) editcopy
gr save  "$working_ANALYSIS/results/intermediate/figure_7a.gph", replace 

*panel B: age of plots
reg machamba_opened_average i.treatment, cluster(village_id)
reg machamba_last_opened i.treatment, cluster(village_id)

betterbarci  machamba_last_opened machamba_opened_average, over(sccp_id2) vertical barlab format(%5.1f)  xla(6 "Average" 18 "Last one" )   title("{bf: B} When opened?", size(10pt))  yla(0(5)15) ytitle("Mean in years", size(6pt))  xsize(3) ysize(2)  legend(ring(1) pos(6) cols(1)  size(6pt))
gr_edit plotregion1.plot6.style.editstyle label(textstyle(size(8-pt))) editcopy
gr_edit plotregion1.plot1.style.editstyle area(shadestyle(color("3 57 108"))) editcopy
gr_edit plotregion1.plot2.style.editstyle area(shadestyle(color("238 69 64"))) editcopy
gr_edit plotregion1.plot3.style.editstyle area(shadestyle(color("199 44 65"))) editcopy
gr_edit plotregion1.plot4.style.editstyle area(shadestyle(color("128 19 54"))) editcopy 
gr save  "$working_ANALYSIS/results/intermediate/figure_7b.gph", replace 

*panel C: share of plots partially burned
probit burned100 i.treatment, cluster(village_id)
margins, dydx(*)
reg machamba_burned100 i.treatment, cluster(village_id)

betterbarci machamba_burned100 burned100, over(sccp_id2) vertical barlab format(%5.1f)  xla(6 "Extensive" 18 "Intensive")   title("{bf: C} Burned plots last 12 months", size(10pt))  yla(0(20)100) ytitle("Share (in %)", size(6pt))  xsize(3) ysize(2)  legend(ring(1) pos(6) cols(1) size(6pt))
gr_edit plotregion1.plot6.style.editstyle label(textstyle(size(8-pt))) editcopy
gr_edit plotregion1.plot1.style.editstyle area(shadestyle(color("3 57 108"))) editcopy
gr_edit plotregion1.plot2.style.editstyle area(shadestyle(color("238 69 64"))) editcopy
gr_edit plotregion1.plot3.style.editstyle area(shadestyle(color("199 44 65"))) editcopy
gr_edit plotregion1.plot4.style.editstyle area(shadestyle(color("128 19 54"))) editcopy 
gr save  "$working_ANALYSIS/results/intermediate/figure_7c.gph", replace 

*panel D: Tree planting on (farming) land
sum boundary_1622 interplanting_1622 fruit_trees1622 homestead1622 no_trees1622
tab agroforestry_project
* (the open-ended organisation name is not shipped; see 01_clean_data.do)
betterbarci boundary_1622 interplanting_1622 fruit_trees1622 homestead1622 no_trees1622 , over(sccp_id2) vertical barlab format(%5.1f)  xla(7 "None" 18 "Homestead" 30 "Fruit orchard" 43 "Interplanting" 54 "Boundary") title("{bf: D} Trees planted 2016-2022", size(10pt))  yla(0(10)50) ytitle("Share (in %)", size(6pt))  xsize(5) ysize(2)  legend(ring (1) pos(6) rows(1) size(6pt))
gr_edit plotregion1.plot6.style.editstyle label(textstyle(size(6-pt))) editcopy
gr_edit plotregion1.plot1.style.editstyle area(shadestyle(color("3 57 108"))) editcopy
gr_edit plotregion1.plot2.style.editstyle area(shadestyle(color("238 69 64"))) editcopy
gr_edit plotregion1.plot3.style.editstyle area(shadestyle(color("199 44 65"))) editcopy
gr_edit plotregion1.plot4.style.editstyle area(shadestyle(color("128 19 54"))) editcopy 
gr save  "$working_ANALYSIS/results/intermediate/figure_7d.gph", replace 


grc1leg2   "$working_ANALYSIS/results/intermediate/figure_7a" "$working_ANALYSIS/results/intermediate/figure_7b" "$working_ANALYSIS/results/intermediate/figure_7c" , graphregion(margin(0 0 0 0)) xsize(5) ysize(2) rows(1) legendfrom("$working_ANALYSIS/results/intermediate/figure_7a")
gr save  "$working_ANALYSIS/results/intermediate/figure7_ac.gph", replace

grc1leg2  "$working_ANALYSIS/results/intermediate/figure7_ac" "$working_ANALYSIS/results/intermediate/figure_7d", graphregion(margin(0 0 0 0)) xsize(5) ysize(4) rows(2) legendfrom("$working_ANALYSIS/results/intermediate/figure7_ac")
gr_edit legend.DragBy 4.694323144104804 1.9650655021834
gr_edit legend.plotregion1.label[1].style.editstyle size(small) editcopy
gr_edit legend.Edit, style(labelstyle(size(small))) style(labelstyle(color(custom)))
gr_edit legend.Edit , style(rows(2)) style(cols(0)) keepstyles 
gr_edit legend.Edit, style(labelstyle(color(custom)))
gr_edit legend.Edit, style(labelstyle(color(custom)))
gr_edit plotregion1.graph1.plotregion1.graph1.xaxis1.style.editstyle majorstyle(tickstyle(textstyle(size(small)))) editcopy
gr_edit plotregion1.graph1.plotregion1.graph1.xaxis1.style.editstyle majorstyle(tickstyle(textstyle(size(medsmall)))) editcopy
gr_edit plotregion1.graph1.plotregion1.graph2.xaxis1.style.editstyle majorstyle(tickstyle(textstyle(size(medsmall)))) editcopy
gr_edit plotregion1.graph1.plotregion1.graph1.yaxis1.title.style.editstyle size(medium) editcopy
gr_edit plotregion1.graph1.plotregion1.graph2.yaxis1.title.style.editstyle size(medsmall) editcopy
gr_edit plotregion1.graph1.plotregion1.graph1.yaxis1.title.style.editstyle size(medsmall) editcopy
gr_edit plotregion1.graph1.plotregion1.graph3.yaxis1.title.style.editstyle size(medsmall) editcopy
gr_edit plotregion1.graph1.plotregion1.graph3.xaxis1.style.editstyle majorstyle(tickstyle(textstyle(size(small)))) editcopy
gr_edit plotregion1.graph1.plotregion1.graph3.xaxis1.style.editstyle majorstyle(tickstyle(textstyle(size(medsmall)))) editcopy
gr_edit plotregion1.graph1.plotregion1.graph1.yaxis1.style.editstyle majorstyle(tickstyle(textstyle(size(vsmall)))) editcopy
gr_edit plotregion1.graph1.plotregion1.graph1.yaxis1.style.editstyle majorstyle(tickstyle(textstyle(size(medsmall)))) editcopy
gr_edit plotregion1.graph1.plotregion1.graph2.yaxis1.style.editstyle majorstyle(tickstyle(textstyle(size(medsmall)))) editcopy
gr_edit plotregion1.graph1.plotregion1.graph3.yaxis1.style.editstyle majorstyle(tickstyle(textstyle(size(medsmall)))) editcopy
gr_edit plotregion1.graph2.yaxis1.style.editstyle majorstyle(tickstyle(textstyle(size(medsmall)))) editcopy
gr_edit plotregion1.graph2.yaxis1.title.style.editstyle size(medium) editcopy
gr_edit plotregion1.graph2.yaxis1.title.style.editstyle size(medsmall) editcopy
gr_edit plotregion1.graph2.yaxis1.title.style.editstyle size(small) editcopy
gr_edit plotregion1.graph2.yaxis1.style.editstyle majorstyle(tickstyle(textstyle(size(small)))) editcopy
gr_edit plotregion1.graph2.yaxis1.style.editstyle majorstyle(tickstyle(textstyle(size(vsmall)))) editcopy
gr_edit plotregion1.graph2.yaxis1.style.editstyle majorstyle(tickstyle(textstyle(size(small)))) editcopy
gr_edit plotregion1.graph1.plotregion1.graph1.style.editstyle declared_xsize(3.165) editcopy
gr_edit plotregion1.graph1.plotregion1.graph1.style.editstyle declared_xsize(4) editcopy
gr_edit plotregion1.graph1.plotregion1.graph1.style.editstyle declared_xsize(3) editcopy
gr_edit plotregion1.graph1.plotregion1.graph1.xaxis1.style.editstyle majorstyle(tickstyle(textstyle(size(small)))) editcopy
gr save  "$working_ANALYSIS/results/intermediate/figure7_farming_plots.gph", replace
gr export "$working_ANALYSIS/results/figures/figS10_farming_plots.png", replace width(3800)




* Agroforestry disadoption in SCCP villages
sum sccp_agroforestry_number if sccp_agroforestry_number>0, detail
tab sccp_agroforestry_number 

egen total_contracts=rowtotal(sccp_agroforestry_contracts1 sccp_agroforestry_contracts2 sccp_agroforestry_contracts3 sccp_agroforestry_contracts4 sccp_agroforestry_contracts5 sccp_agroforestry_contracts6 sccp_agroforestry_contracts7)
replace total_contracts = . if total_contracts==0
tab total_contracts 

*panel A: Types of contracts
*reshape long
preserve
rename sccp_agroforestry_contracts1 agro1
rename sccp_agroforestry_contracts5 agro2 
rename sccp_agroforestry_contracts6 agro3 
rename sccp_agroforestry_contracts3 agro4 
rename sccp_agroforestry_contracts4 agro5 
rename sccp_agroforestry_contracts2 agro6
rename sccp_agroforestry_contracts7 agro7
reshape long  agro,  i(id) j(agro_type)
sum agro
tab agro
lab def type_agro 1 "Boundary"  2 "Interplanting: Glircidia" 3 "Interplanting: Faidherbia" 4 "Mango" 5 "Cashew" 6 "Homestead" 7 "Woodlot", replace
lab val agro_type type_agro
replace agro = agro*100
betterbarci agro, over(agro_type) vertical barlab  format(%5.1f) title("{bf: A} Types of contracts", size(10pt))  yla(0(20)110) ytitle("Share (in %)", size(6pt))  legend(size(6pt) rows(4)) xsize(3) ysize(2) xla("") xtitle("N=188 respondents, 320 contracts", size(6-pt)) 
gr save  "$working_ANALYSIS/results/intermediate/figure_8a.gph", replace 
restore 


*panel B: Agroforestry still in place in 2022
gen inplace1 = sccp_agroforestry_contracts1+sccp_agroforestry_inplace1
replace inplace1=. if inplace1==0
replace inplace1=inplace1-1
gen inplace2 = sccp_agroforestry_contracts5+sccp_agroforestry_inplace5
replace inplace2=. if inplace2==0
replace inplace2=inplace2-1
gen inplace3 = sccp_agroforestry_contracts6+sccp_agroforestry_inplace6
replace inplace3=. if inplace3==0
replace inplace3=inplace3-1
gen inplace4 = sccp_agroforestry_contracts3+sccp_agroforestry_inplace3
replace inplace4=. if inplace4==0
replace inplace4=inplace4-1
gen inplace5 = sccp_agroforestry_contracts4+sccp_agroforestry_inplace4
replace inplace5=. if inplace5==0
replace inplace5=inplace5-1
gen inplace6 = sccp_agroforestry_contracts2+sccp_agroforestry_inplace2
replace inplace6=. if inplace6==0
replace inplace6=inplace6-1
gen inplace7 = sccp_agroforestry_contracts7+sccp_agroforestry_inplace7
replace inplace7=. if inplace7==0
replace inplace7=inplace7-1

egen inplace_min = rowmin(inplace1 inplace2 inplace3 inplace4 inplace5 inplace6 inplace7)

preserve
reshape long inplace,  i(id) j(inplace_type)
sum inplace
tab inplace
replace inplace=. if total_contracts==. 
lab def type_agro 1 "Boundary"  2 "Interplanting: Glircidia" 3 "Interplanting: Faidherbia" 4 "Mango" 5 "Cashew" 6 "Homestead" 7 "Woodlot", replace
lab val inplace_type type_agro
replace inplace = inplace*100
tab inplace
betterbarci inplace, over(inplace_type) vertical barlab  format(%5.1f) title("{bf: B} Permanence (2022)", size(10pt))  yla(0(20)110) ytitle("Share (in %)", size(6pt))  legend(size(6pt) rows(4)) xsize(3) ysize(2) xla("") xtitle("N=188 respondents", size(6-pt)) 
gr save  "$working_ANALYSIS/results/intermediate/figure_8b.gph", replace 
bys inplace_type: tab inplace
restore 


*Reasons for keeping systems
*panel C: Reasons for keeping systems
preserve
drop sccp_reason_keep
reshape long sccp_reason_keep,  i(id) j(reason)
replace sccp_reason_keep=100 if sccp_reason_keep==1
replace sccp_reason_keep=. if inplace_min==0 |inplace_min==.
tab sccp_reason_keep
lab def keep_reason 1 "Future payments"  2 "Micro climate" 3 "Soil Quality" 4 "Fruits" 5 "Timber/firewood" 66 "Other" 88 "Don't know", replace
lab val reason keep_reason

betterbarci sccp_reason_keep if reason!=99,  over(reason) vertical barlab  format(%5.1f)  title("{bf: C} Reasons for permanence", size(10pt)) yla(0(20)110) ytitle("Share (in %)", size(6pt))  legend(size(6pt) rows(4)) xsize(3) ysize(2) xla("") xtitle("N=160 respondents", size(6-pt))
gr save "$working_ANALYSIS/results/intermediate/figure_8C.gph", replace
restore 


*panel D: Reasons for not keeping systems
preserve
drop sccp_reason_not_keep
reshape long sccp_reason_not_keep,  i(id) j(reason_not)
tab sccp_reason_not_keep, nola
replace sccp_reason_not_keep=. if inplace_min==1 |inplace_min==.
replace sccp_reason_not_keep=100*sccp_reason_not_keep
tab sccp_reason_not_keep
lab def not_reason 1 "Sold for timber"  2 "Firewood" 3 "Farmland" 66 "No benefits" 88 "Don't know", replace
lab val reason_not not_reason
betterbarci sccp_reason_not_keep if reason_not!=99,  over(reason_not) vertical barlab  format(%5.1f)  title("{bf: D} Reasons for abandon", size(10pt))  yla(0(20)110) ytitle("Share (in %)", size(6pt))  legend(size(6pt) rows(4)) xsize(3) ysize(2) xla("") xtitle("N=14 respondents", size(6-pt)) 
gr save "$working_ANALYSIS/results/intermediate/figure_8D.gph", replace 
restore 


gr combine  "$working_ANALYSIS/results/intermediate/figure_8a"  "$working_ANALYSIS/results/intermediate/figure_8b" "$working_ANALYSIS/results/intermediate/figure_8c" "$working_ANALYSIS/results/intermediate/figure_8d"  , graphregion(margin(0 0 0 0)) xsize(4) ysize(3.165) rows(2) 
gr save  "$working_ANALYSIS/results/intermediate/figure8_agroforestry_disadoption.gph", replace
gr export "$working_ANALYSIS/results/figures/fig5_agroforestry_permanence.png", replace width(3800)


*what explains whether respondents from SCCP villages could remember the SCCP?
gen aux_age=age-14
gen age2008=0 if aux_age<18
replace age2008=1 if  aux_age>=18

global x1 female age2008 edu_years people_hh people_hh_below14 z_wealth_index z_hh_income_avg
egen remember_sccp=rowmax(sccp_recall2 sccp_recall)
replace remember_sccp=0 if sccp_area==1 & remember_sccp==.
replace years_living_here=age if same_place==1
gen less_than10y = 0 if years_living_here>10
replace less_than10y = 1 if years_living_here<=10
probit remember_sccp less_than10y $x1, cluster(village_id)
eststo m1_remember: margins, dydx(*) post


gen d_agroforestry = 0 if sccp_agroforestry_number==0
replace d_agroforestry = 1 if sccp_agroforestry_number>0
replace d_agroforestry = . if remember_sccp==. | remember_sccp==0
probit d_agroforestry $x1, cluster(village_id)
eststo m2_extensive: margins, dydx(*) post
eststo m3_intensive: tobit sccp_agroforestry_number $x1, ll(0) vce(cluster village_id)

esttab m1_remember m2_extensive m3_intensive     using "$working_ANALYSIS/results/tables/tableS22_selection_agroforestry.rtf", label se(%4.2f) transform(ln*: exp(@) exp(@)) b(%4.2f)  mtitle("Remember SCCP (=1)" "Agroforestry (=1)" "# contracts") stats(N N_clust r2 r2_a , labels("N" "Village cluster" "Adjusted R-squared" ) fmt(%4.0f %4.0f %4.0f %4.2f %4.2f)) star(* 0.10 ** 0.05 *** 0.01) varlabels(,elist(weight:_cons "{break}{hline @width}"))  nonotes addnotes("Notes:  Standard errors clustered at the village level in parentheses: * p < 0.10, ** p < 0.05, *** p < 0.01.")  replace 



*----------------------------------------------------------------
* Hypothesis 1: Wellbeing is higher in areas that were exposed to
* both PES and GNP than in areas only exposed to the GNP activities.
*----------------------------------------------------------------
global controls female age edu_years same_place people_hh people_hh_below14 
sum $controls
* missing values for age edu_years people_hh_below14 --> use multiple imputation to impute values

*wealth index:
eststo wealth1_1: reg z_wealth_index i.sccp_area $controls, cluster(village_id)
estadd local controls "Yes"
estadd local imputations "None"
eststo wealth1_2: reg z_wealth_index i.sccp_id   $controls, cluster(village_id)
estadd local controls "Yes"
estadd local imputations "None"
eststo wealth1_3: reg z_wealth_index i.sccp_benefit_today $controls, cluster(village_id)
estadd local controls "Yes"
estadd local imputations "None"

*hh income
eststo wealth2_1: reg z_hh_income_avg i.sccp_area $controls, cluster(village_id)
estadd local controls "Yes"
estadd local imputations "None"
eststo wealth2_2: reg z_hh_income_avg i.sccp_id $controls, cluster(village_id)
estadd local controls "Yes"
estadd local imputations "None"
eststo wealth2_3: reg z_hh_income_avg i.sccp_benefit_today $controls, cluster(village_id)
estadd local controls "Yes"
estadd local imputations "None"

*perceived economic situation
eststo wealth3_1: reg z_econ_ladder1 i.sccp_area $controls, cluster(village_id)
estadd local controls "Yes"
estadd local imputations "None"
eststo wealth3_2: reg z_econ_ladder1 i.sccp_id $controls, cluster(village_id) 
estadd local controls "Yes"
estadd local imputations "None"
eststo wealth3_3: reg z_econ_ladder1 i.sccp_benefit_today $controls, cluster(village_id)
estadd local controls "Yes"
estadd local imputations "None"
eststo wealth3_gender: reg z_econ_ladder1 i.sccp_area##i.female $controls, cluster(village_id)
estadd local controls "Yes"
estadd local imputations "None"

preserve
** Set dataset in memory as MI dataset
mi set flong // set dataset in memory as "MI" dataset; _mi_miss, _mi_m, and _mi_id generated to track imputed datasets and values

** Inspect missing values
mi misstable summarize age edu_years people_hh_below14 z_hh_income_avg z_econ_ladder1
mi misstable patterns age edu_years people_hh_below14 z_hh_income_avg z_econ_ladder1

/* Imputation model specification
- Include in the imputation model all the variables (also interaction-terms) that will be included in the analysis model
- Include in the imputation model the outcome variable for the analysis model
- Include variables that are related to the missingness and variables that are correlated with variables of interest (recommendation r>.4)
*/

*variables to be imputed
mi register imputed age edu_years people_hh_below14 z_hh_income_avg z_econ_ladder1
mi describe

mi impute chained (pmm, knn(5)) age edu_years people_hh_below14 z_hh_income_avg z_econ_ladder1 = i.sccp_id people_hh female same_place z_wealth_index, add(20) rseed(1234) force

/*
Imputation diagnostics
After performing an imputation it is also useful to look at means, frequencies and box plots comparing observed and imputed values to assess if the range appears reasonable. You may also want to examine plots of residuals and outliers for each imputed dataset individually. If anomalies are evident in only a small number of imputations then this indicates a problem with the imputation model (White et al, 2010).
*/

mi xeq 0 1 20: summarize age edu_years people_hh_below14 z_hh_income_avg z_econ_ladder1
mi describe

eststo mi_wealth1: mi estimate, post: reg z_wealth_index i.sccp_area $controls, cluster(village_id)
estadd local controls "Yes"
estadd local imputations "20"
eststo mi_wealth1_1: mi estimate, post: reg z_wealth_index i.sccp_id $controls, cluster(village_id)
estadd local controls "Yes"
estadd local imputations "20"
eststo mi_wealth1_2: mi estimate, post: reg z_wealth_index i.sccp_benefit_today $controls, cluster(village_id)
estadd local controls "Yes"
estadd local imputations "20"

eststo mi_wealth2: mi estimate, post: reg z_hh_income_avg i.sccp_area $controls, cluster(village_id)
estadd local controls "Yes"
estadd local imputations "20"
eststo mi_wealth2_1: mi estimate, post: reg z_hh_income_avg i.sccp_id $controls, cluster(village_id)
estadd local controls "Yes"
estadd local imputations "20"
eststo mi_wealth2_2: mi estimate, post: reg z_hh_income_avg i.sccp_benefit_today $controls, cluster(village_id)
estadd local controls "Yes"
estadd local imputations "20"

eststo mi_wealth3: mi estimate, post: reg z_econ_ladder1 i.sccp_area $controls, cluster(village_id)
estadd local controls "Yes"
estadd local imputations "20"
eststo mi_wealth3_1: mi estimate, post: reg z_econ_ladder1 i.sccp_id $controls, cluster(village_id)
estadd local controls "Yes"
estadd local imputations "20"
eststo mi_wealth3_2: mi estimate, post: reg z_econ_ladder1 i.sccp_benefit_today $controls, cluster(village_id)
estadd local controls "Yes"
estadd local imputations "20"

eststo mi_wealth_gender: mi estimate, post: reg z_econ_ladder1 i.sccp_area##i.female $controls, cluster(village_id)
estadd local controls "Yes"
estadd local imputations "20"

restore


/*
Imputation estimation diagnostics
- RVI (Relative Increase in Variance): Proportional increase in total sampling variance that is due to missing information ([VB + VB/m]/VW), i.e. estimated increase of sampling variance due to missing data when compared to a situation where no data is missing

- FMI (Fraction of Missing Information): Proportion of the total sampling variance that is due to missing data ([VB+ VB/m ]/VT). Interpretation similiar to R2: Total sampling variance that is attributable to missing data

- RE (Relative Efficiency): Estimate of the efficiency relative to performing an infinite number of imputations ([1/(1+FMI/m)]). Related to both the amount of missing information as well as the number (m) of imputations performed. 

- DF (Degrees of Freedom): Unlike analysis with non-imputed data, sample size does not directly influence the estimate of DF. DF actually continues to increase as the number of imputations increase.
*/



coefplot (mi_wealth1, ciopts(lwidth(0.8 2) lcolor("128 19 54*0.8" "128 19 54*0.6")  recast(rcap)) mcolor("128 19 54")) (mi_wealth1_1, keep(1.sccp_id)  ciopts(lwidth(0.8 2) lcolor("238 69 64*0.8" "238 69 64*0.6")  recast(rcap)) mcolor("238 69 64")) (mi_wealth1_1, keep(2.sccp_id)  ciopts(lwidth(0.8 2) lcolor("199 44 65*0.8" "199 44 65*0.6")  recast(rcap)) mcolor("199 44 65")) (mi_wealth1_1, keep(3.sccp_id)  ciopts(lwidth(0.8 2) lcolor("128 19 54*0.8" "128 19 54*0.6")  recast(rcap)) mcolor("128 19 54")), bylabel({bf:A} Wealth index) || (mi_wealth2, ciopts(lwidth(0.8 2) lcolor("128 19 54*0.8" "128 19 54*0.6")  recast(rcap)) mcolor("128 19 54")) (mi_wealth2_1, keep(1.sccp_id)  ciopts(lwidth(0.8 2) lcolor("238 69 64*0.8" "238 69 64*0.6")  recast(rcap)) mcolor("238 69 64")) (mi_wealth2_1, keep(2.sccp_id)  ciopts(lwidth(0.8 2) lcolor("199 44 65*0.8" "199 44 65*0.6")  recast(rcap)) mcolor("199 44 65")) (mi_wealth2_1, keep(3.sccp_id)  ciopts(lwidth(0.8 2) lcolor("128 19 54*0.8" "128 19 54*0.6")  recast(rcap)) mcolor("128 19 54")),bylabel({bf:B} HH income) || (mi_wealth2,ciopts(lwidth(0.8 2) lcolor("128 19 54*0.8" "128 19 54*0.6")  recast(rcap)) mcolor("128 19 54")) (mi_wealth3_1, keep(1.sccp_id)  ciopts(lwidth(0.8 2) lcolor("238 69 64*0.8" "238 69 64*0.6")  recast(rcap)) mcolor("238 69 64")) (mi_wealth3_1, keep(2.sccp_id)  ciopts(lwidth(0.8 2) lcolor("199 44 65*0.8" "199 44 65*0.6")  recast(rcap)) mcolor("199 44 65")) (mi_wealth3_1, keep(3.sccp_id)  ciopts(lwidth(0.8 2) lcolor("128 19 54*0.8" "128 19 54*0.6")  recast(rcap)) mcolor("128 19 54")),  bylabel({bf:C} SES ladder) ||, xla(,labsize(6pt)) byopts(compact xrescale imargin(*1.2) rows(1) legend(off)) keep(1.sccp_area 1.sccp_id 2.sccp_id 3.sccp_id) coeflabels(1.sccp_area= "SCCP (all)" , labsize(6pt)) xline(0, lpattern(dash) lcolor(gs3)) xtitle("Regression estimated differences relative to buffer zone (in SD)", size(6pt)) grid(none) levels(95 90)mlabel(cond(@pval<.005, "***", cond(@pval<.05, "**", cond(@pval<.1, "*", "")))) msize(3pt) msymbol(D) mlabsize(10pt) mlabposition(12) mlabgap(-1.2)  subtitle(, size(9pt) lstyle(none) margin(medium) nobox justification(center) alignment(top) bmargin(top))  xsize(5) ysize(2)  norecycle
gr save "$working_ANALYSIS/results/intermediate/figure9_wealth_impact.gph", replace
gr export "$working_ANALYSIS/results/figures/fig7_wealth_income.png", replace width(3800)



*Likelihood to be employed by the GNP
gen job_sccp = 0
replace job_sccp = 1 if sccp_job==1
replace job_sccp=. if sccp_area==0
lab def jobie 0 "No SCCP job" 1 "Had SCCP job", replace
lab val job_sccp jobie

egen gnp_hh_employed = rowmax(hh_work_np hh_piecework_np)
tab hh_work_np
tab hh_piecework_np
tab gnp_hh_employed
tab hh_work_np hh_piecework_np

prtest hh_work_np, by(job_sccp)

replace hh_work_np=hh_work_np*100
replace hh_piecework_np=hh_piecework_np*100


probit hh_work_np i.job_sccp , cluster(village_id)
margins, dydx(*)
*19%-points increase in likelihood to get a job in GNP for those who had a job in the SCCP


probit hh_piecework_np i.job_sccp , cluster(village_id)
margins, dydx(*)


* visualization
betterbarci hh_piecework_np hh_work_np, over(job_sccp) vertical barlab format(%5.0f)  xla(3.5 "Permanent" 12.5 "Non-permanent")   yla(0(10)40, nogrid) ytitle("Share (in %)", size(6pt))  xsize(2) ysize(2)  legend(ring(1) pos(6) cols(2) size(6pt))
gr_edit plotregion1.plot4.style.editstyle label(textstyle(size(8-pt))) editcopy
gr save  "$working_ANALYSIS/results/intermediate/figure_10a.gph", replace 
gr export "$working_ANALYSIS/results/figures/fig8_gnp_employment.png", replace width(3800)



* NOTE: An instrumental-variable specification using distance to the initial
* project village as an instrument for SCCP employment was estimated during
* development but removed from the paper: the exclusion restriction is not
* defensible, since distance to the project village plausibly affects park
* employment through channels other than SCCP participation. The employment
* pathway is reported descriptively in Figure 8.



*----------------------------------------------------------------
*Hypothesis 2: : Motivations to conserve the environment and conservation agency are higher for participants who participated in the SCCP, especially those who adopted agroforestry, than in the control area.
*----------------------------------------------------------------


global socio female age edu_years same_place people_hh people_hh_below14 

*intrinsic motivations
eststo motivation1_1: reg z_intrinsic i.sccp_area $socio, cluster(village_id)
estadd local controls "Yes"
estadd local imputations "None"
eststo motivation1_2: reg z_intrinsic i.sccp_id $socio, cluster(village_id)
estadd local controls "Yes"
estadd local imputations "None"
eststo motivation1_3: reg z_intrinsic i.sccp_benefit_today $socio, cluster(village_id)
estadd local controls "Yes"
estadd local imputations "None"
eststo motivation1_gender: reg z_intrinsic i.sccp_area##i.female $socio, cluster(village_id)
estadd local controls "Yes"
estadd local imputations "None"


*extrinsic motivations
eststo motivation2_1: reg z_extrinsic i.sccp_area $socio, cluster(village_id)
estadd local controls "Yes"
estadd local imputations "None"
eststo motivation2_2: reg z_extrinsic i.sccp_id $socio, cluster(village_id)
estadd local controls "Yes"
estadd local imputations "None"
eststo motivation2_3: reg z_extrinsic i.sccp_benefit_today $socio, cluster(village_id)
estadd local controls "Yes"
estadd local imputations "None"
eststo motivation2_gender: reg z_extrinsic i.sccp_area##i.female $socio, cluster(village_id)
estadd local controls "Yes"
estadd local imputations "None"

*environmental agency
eststo motivation3_1: reg z_agency i.sccp_area $socio, cluster(village_id)
estadd local controls "Yes"
estadd local imputations "None"
eststo motivation3_2: reg z_agency i.sccp_id $socio, cluster(village_id)
estadd local controls "Yes"
estadd local imputations "None"
eststo motivation3_3: reg z_agency i.sccp_benefit_today $socio, cluster(village_id)
estadd local controls "Yes"
estadd local imputations "None"
eststo motivation3_gender: reg z_agency  i.sccp_area##i.female $socio, cluster(village_id)
estadd local controls "Yes"
estadd local imputations "None"



preserve
** Set dataset in memory as MI dataset
mi set flong // set dataset in memory as "MI" dataset; _mi_miss, _mi_m, and _mi_id generated to track imputed datasets and values

** Inspect missing values
mi misstable summarize age edu_years people_hh_below14 z_hh_income_avg z_intrinsic z_extrinsic z_agency
mi misstable patterns age edu_years people_hh_below14 z_hh_income_avg z_intrinsic z_extrinsic z_agency

/* Imputation model specification
- Include in the imputation model all the variables (also interaction-terms) that will be included in the analysis model
- Include in the imputation model the outcome variable for the analysis model
- Include variables that are related to the missingness and variables that are correlated with variables of interest (recommendation r>.4)
*/

*variables to be imputed
mi register imputed age edu_years people_hh_below14 z_hh_income_avg z_intrinsic z_extrinsic z_agency
mi describe

mi impute chained (pmm, knn(5)) age edu_years people_hh_below14 z_hh_income_avg z_intrinsic z_extrinsic z_agency = i.sccp_id people_hh female same_place z_wealth_index, add(20) rseed(1234)

/*
Imputation diagnostics
After performing an imputation it is also useful to look at means, frequencies and box plots comparing observed and imputed values to assess if the range appears reasonable. You may also want to examine plots of residuals and outliers for each imputed dataset individually. If anomalies are evident in only a small number of imputations then this indicates a problem with the imputation model (White et al, 2010).
*/

mi xeq 0 1 20: summarize age edu_years people_hh_below14 z_hh_income_avg z_econ_ladder1
mi describe
*intrinsic motivation
eststo mi_motivation1: mi estimate, post: reg z_intrinsic i.sccp_area $socio, cluster(village_id)
estadd local controls "Yes"
estadd local imputations "20"
eststo mi_motivation1_1: mi estimate, post: reg z_intrinsic i.sccp_id $socio, cluster(village_id)
estadd local controls "Yes"
estadd local imputations "20"
eststo mi_motivation1_2: mi estimate, post: reg z_intrinsic i.sccp_benefit_today $socio, cluster(village_id)
estadd local controls "Yes"
estadd local imputations "20"
eststo mi_motivation1_gender: mi estimate, post: reg z_intrinsic i.sccp_area##i.female $socio, cluster(village_id)
estadd local controls "Yes"
estadd local imputations "20"

*extrinsic motivation
eststo mi_motivation2: mi estimate, post: reg z_extrinsic i.sccp_area $socio, cluster(village_id)
estadd local controls "Yes"
estadd local imputations "20"
eststo mi_motivation2_1: mi estimate, post: reg z_extrinsic i.sccp_id $socio, cluster(village_id)
estadd local controls "Yes"
estadd local imputations "20"
eststo mi_motivation2_2: mi estimate, post: reg z_extrinsic i.sccp_benefit_today $socio, cluster(village_id)
estadd local controls "Yes"
estadd local imputations "20"
eststo mi_motivation2_gender: mi estimate, post: reg z_extrinsic i.sccp_area##i.female $socio, cluster(village_id)
estadd local controls "Yes"
estadd local imputations "20"

*Environmental agency
eststo mi_motivation3: mi estimate, post: reg z_agency i.sccp_area $socio, cluster(village_id)
estadd local controls "Yes"
estadd local imputations "20"
eststo mi_motivation3_1: mi estimate, post: reg z_agency i.sccp_id $socio, cluster(village_id)
estadd local controls "Yes"
estadd local imputations "20"
eststo mi_motivation3_2: mi estimate, post: reg z_agency i.sccp_benefit_today $socio, cluster(village_id)
estadd local controls "Yes"
estadd local imputations "20"
eststo mi_motivation3_gender: mi estimate, post: reg z_agency i.sccp_area##i.female $socio, cluster(village_id)
estadd local controls "Yes"
estadd local imputations "20"

restore

*Figure 7.	SCCP correlation with intrinsic, extrinsic motivations to plant trees and environmental agency
coefplot (mi_motivation1 mi_motivation1_1), bylabel({bf:A} Intrinsic Motivation) ||  (mi_motivation3 mi_motivation3_1), bylabel({bf:B} Environmental Agency) ||,  byopts(compact xrescale imargin(*1.2) rows(1) legend(off))  coeflabel(1.sccp_area="SCCP ATE", labsize(6pt)) grid(none) xla(, labsize(6pt) nogrid)   keep(1.sccp_area 1.sccp_id 2.sccp_id 3.sccp_id 4.sccp_id) xline(0, lpattern(dash) lcolor(gs3)) xtitle("Regression estimated impact relative to Control (in SD)", size(6pt)) levels(95 90) ciopts(lwidth(0.8 2)  lcolor(*1 *.3) recast(rcap)) mlabel(cond(@pval<.01, "***", cond(@pval<.05, "**", cond(@pval<.1, "*", "")))) mlabgap(0) msize(4pt) msymbol(D) mlabsize(12pt) mlabposition(2) subtitle(, size(10pt) lstyle(none) margin(small) justification(left)  bmargin(top)) xsize(5) ysize(2) 
gr_edit style.editstyle margin(vsmall) editcopy
gr save "$working_ANALYSIS/results/intermediate/figure_agency_impact.gph", replace
gr export "$working_ANALYSIS/results/figures/fig6_motivation_agency.png", replace width(4000)


*hetergeneous gender effects for individual outcomes
coefplot (mi_wealth_gender), bylabel({bf:A} Perceived SES) || (mi_motivation1_gender), bylabel({bf:B} Intrinsic Motivation) ||  (mi_motivation3_gender), bylabel({bf:C} Environmental Agency) ||,  byopts(compact xrescale imargin(*1.2) rows(1) legend(off))  coeflabel(1.sccp_area="SCCP ATE", labsize(6pt)) xla(-0.6(0.2)0.6, nogrid labsize(6pt))   keep(1.sccp_area 1.female 1.sccp_area#1.female) xline(0, lpattern(dash) lcolor(gs3)) xtitle("Regression estimated impact relative to Control (in SD)", size(6pt)) levels(95 90) ciopts(lwidth(0.8 2)  lcolor(*1 *.3) recast(rcap)) mlabel(cond(@pval<.01, "***", cond(@pval<.05, "**", cond(@pval<.1, "*", "")))) mlabgap(0) msize(4pt) msymbol(D) mlabsize(12pt) mlabposition(2) subtitle(, size(10pt) lstyle(none) margin(small) justification(left)  bmargin(top)) xsize(5) ysize(2) 
gr_edit style.editstyle margin(vsmall) editcopy
gr save "$working_ANALYSIS/results/intermediate/figure_gender_effects.gph", replace
gr export "$working_ANALYSIS/results/figures/figS11_gender_effects.png", replace width(4000)



*-----------------------------------
* SUPPLEMENTARY ONLINE MATERIALS 
*-----------------------------------
*Table S2. Area balancing (non-imputed)
global balance female age edu_years same_place people_hh people_hh_below14
sum $balance
iebaltab $balance, grpvar(sccp_area) total rowvarlabels format(%9.2f) ftest tblnonote savexlsx("$working_ANALYSIS/results/tables/tableS17_balancing_stable.xlsx") replace


* Table S3.	SCCP overall and subgroup effects on: Wealth index
esttab wealth1_1 mi_wealth1 wealth1_2 mi_wealth1_1 wealth1_3 mi_wealth1_2  using "$working_ANALYSIS/results/tables/tableS23_wealth_index.rtf", drop(0.sccp_area 0.sccp_id 0.sccp_benefit_today) order(0.sccp_area 1.sccp_area 1.sccp_id 2.sccp_id 3.sccp_id 4.sccp_id 1.sccp_benefit_today 2.sccp_benefit_today) label se(%4.2f) transform(ln*: exp(@) exp(@)) b(%4.2f) mgroups("Average effect" "SCCP intensity" "Perceived benefits today" "Agroforestry still in-place", pattern(1 0 1 0 1 0 1 0)) stats(controls imputations N N_clust r2_a F_mi, labels("Controls" "Imputations" "N" "Village cluster" "Adjusted R-squared" "Model F test") fmt(%4.0f %4.0f %4.0f %4.0f %4.2f)) star(* 0.10 ** 0.05 *** 0.01) varlabels(,elist(weight:_cons "{break}{hline @width}")) nomtitle nonotes addnotes("Notes: The outcome variable in all models is the standardized wealth index. Respondents only exposed to GNP activities are the reference group in all regression models. Uneven models report estimates from complete case analysis while even numbered models offer estimates from multiple imputation by chained equations using the ‘mi’ Stata package.  Standard errors clustered at the village level in parentheses: * p < 0.10, ** p < 0.05, *** p < 0.01.")  replace 

*Table S4.	SCCP overall and subgroup effects on: Average monthly household income
esttab wealth2_1 mi_wealth2 wealth2_2 mi_wealth2_1 wealth2_3 mi_wealth2_2  using "$working_ANALYSIS/results/tables/tableS24_hh_income.rtf", drop(0.sccp_area 0.sccp_id 0.sccp_benefit_today) order(0.sccp_area 1.sccp_area 1.sccp_id 2.sccp_id 3.sccp_id  4.sccp_id 1.sccp_benefit_today 2.sccp_benefit_today) label se(%4.2f) transform(ln*: exp(@) exp(@)) b(%4.2f) mgroups("Average effect" "SCCP intensity" "Perceived benefits today" "Agroforestry still in-place", pattern(1 0 1 0 1 0 1 0))  stats(controls imputations N N_clust r2_a F_mi, labels("Controls" "Imputations" "N" "Village cluster" "Adjusted R-squared" "Model F test") fmt(%4.0f %4.0f %4.0f %4.0f %4.2f)) star(* 0.10 ** 0.05 *** 0.01) varlabels(,elist(weight:_cons "{break}{hline @width}")) nomtitle nonotes addnotes("Notes: The outcome variable in all models is the standardized household income. Respondents only exposed to GNP activities are the reference group in all regression models. Uneven models report estimates from complete case analysis while even numbered models offer estimates from multiple imputation by chained equations using the ‘mi’ Stata package.  Standard errors clustered at the village level in parentheses: * p < 0.10, ** p < 0.05, *** p < 0.01.")  replace 

*Table S5.	SCCP overall and subgroup effects on: Perceived economic situation
esttab wealth3_1 mi_wealth3 wealth3_2 mi_wealth3_1 wealth3_3 mi_wealth3_2  using "$working_ANALYSIS/results/tables/tableS25_economic_ladder.rtf", drop(0.sccp_area 0.sccp_id 0.sccp_benefit_today) order(0.sccp_area 1.sccp_area 1.sccp_id 2.sccp_id 3.sccp_id   4.sccp_id 1.sccp_benefit_today 2.sccp_benefit_today) label se(%4.2f) transform(ln*: exp(@) exp(@)) b(%4.2f) mgroups("Average effect" "SCCP intensity" "Perceived benefits today" "Agroforestry still in-place", pattern(1 0 1 0 1 0 1 0))  stats(controls imputations N N_clust r2_a F_mi, labels("Controls" "Imputations" "N" "Village cluster" "Adjusted R-squared" "Model F test") fmt(%4.0f %4.0f %4.0f %4.0f %4.2f)) star(* 0.10 ** 0.05 *** 0.01) varlabels(,elist(weight:_cons "{break}{hline @width}")) nomtitle nonotes addnotes("Notes: The outcome variable in all models is the standardized perceived economic situation based on the ladder tool. Respondents only exposed to GNP activities are the reference group in all regression models. Uneven models report estimates from complete case analysis while even numbered models offer estimates from multiple imputation by chained equations using the ‘mi’ Stata package.  Standard errors clustered at the village level in parentheses: * p < 0.10, ** p < 0.05, *** p < 0.01.")  replace 

 
*Table S6.	SCCP overall and subgroup effects on: Intrinsic motivations to plant trees
esttab motivation1_1 mi_motivation1 motivation1_2 mi_motivation1_1 motivation1_3 mi_motivation1_2  using "$working_ANALYSIS/results/tables/tableS26_intrinsic.rtf", drop(0.sccp_area 0.sccp_id 0.sccp_benefit_today) order(0.sccp_area 1.sccp_area 1.sccp_id 2.sccp_id 3.sccp_id  4.sccp_id 1.sccp_benefit_today 2.sccp_benefit_today) label se(%4.2f) transform(ln*: exp(@) exp(@)) b(%4.2f) mgroups("Average effect" "SCCP intensity" "Perceived benefits today" "Agroforestry still in-place", pattern(1 0 1 0 1 0 1 0)) stats(controls imputations N N_clust r2_a F_mi, labels("Controls" "Imputations" "N" "Village cluster" "Adjusted R-squared" "Model F test") fmt(%4.0f %4.0f %4.0f %4.0f %4.2f)) star(* 0.10 ** 0.05 *** 0.01) varlabels(,elist(weight:_cons "{break}{hline @width}")) nomtitle nonotes addnotes("Notes: The outcome variable in all models is the standardized intrinsic motivation to plant trees. Respondents only exposed to GNP activities are the reference group in all regression models. Uneven models report estimates from complete case analysis while even numbered models offer estimates from multiple imputation by chained equations using the ‘mi’ Stata package. Standard errors clustered at the village level in parentheses: * p < 0.10, ** p < 0.05, *** p < 0.01.")  replace

*Table S7.	SCCP overall and subgroup effects on: Extrinsic motivations to plant trees
esttab motivation2_1 mi_motivation2 motivation2_2 mi_motivation2_1 motivation2_3 mi_motivation2_2  using "$working_ANALYSIS/results/diagnostics/diag_extrinsic_motivations.rtf", drop(0.sccp_area 0.sccp_id 0.sccp_benefit_today) order(0.sccp_area 1.sccp_area 1.sccp_id 2.sccp_id 3.sccp_id  4.sccp_id 1.sccp_benefit_today 2.sccp_benefit_today) label se(%4.2f) transform(ln*: exp(@) exp(@)) b(%4.2f) mgroups("Average effect" "SCCP intensity" "Perceived benefits today" "Agroforestry still in-place", pattern(1 0 1 0 1 0 1 0)) stats(controls imputations N N_clust r2_a F_mi, labels("Controls" "Imputations" "N" "Village cluster" "Adjusted R-squared" "Model F test") fmt(%4.0f %4.0f %4.0f %4.0f %4.2f)) star(* 0.10 ** 0.05 *** 0.01) varlabels(,elist(weight:_cons "{break}{hline @width}")) nomtitle nonotes addnotes("Notes: The outcome variable in all models is the standardized extrinsic (monetary) motivation to plant trees. Respondents only exposed to GNP activities are the reference group in all regression models. Uneven models report estimates from complete case analysis while even numbered models offer estimates from multiple imputation by chained equations using the ‘mi’ Stata package. Standard errors clustered at the village level in parentheses: * p < 0.10, ** p < 0.05, *** p < 0.01.")  replace 


*Table S8.	SCCP overall and subgroup effects on: Environmental agency index
esttab motivation3_1 mi_motivation3 motivation3_2 mi_motivation3_1 motivation3_3 mi_motivation3_2 using "$working_ANALYSIS/results/tables/tableS27_env_agency.rtf", drop(0.sccp_area 0.sccp_id 0.sccp_benefit_today) order(0.sccp_area 1.sccp_area 1.sccp_id 2.sccp_id 3.sccp_id  4.sccp_id 1.sccp_benefit_today 2.sccp_benefit_today) label se(%4.2f) transform(ln*: exp(@) exp(@)) b(%4.2f) mgroups("Average effect" "SCCP intensity" "Perceived benefits today" "Agroforestry still in-place", pattern(1 0 1 0 1 0 1 0)) stats(controls imputations N N_clust r2_a F_mi, labels("Controls" "Imputations" "N" "Village cluster" "Adjusted R-squared" "Model F test") fmt(%4.0f %4.0f %4.0f %4.0f %4.2f)) star(* 0.10 ** 0.05 *** 0.01) varlabels(,elist(weight:_cons "{break}{hline @width}")) nomtitle nonotes addnotes("Notes: The outcome variable in all models is the standardized environmental agency index from factor analysis. Respondents only exposed to GNP activities are the reference group in all regression models. Uneven models report estimates from complete case analysis while even numbered models offer estimates from multiple imputation by chained equations using the ‘mi’ Stata package. Standard errors clustered at the village level in parentheses: * p < 0.10, ** p < 0.05, *** p < 0.01.")  replace 






** EOF
