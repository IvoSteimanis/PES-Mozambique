# Codebook

Variables in the datasets shipped with this package. Grid-cell files follow strict naming
conventions, so the conventions are documented rather than all 87 to 176 variable names.
Survey variables carry their questionnaire item number in the Stata variable label; open
`processed/survey_rdy.dta` and run `describe` or `codebook` to see them in full.

---

## Grid-cell datasets

Unit of observation: a 9-hectare grid cell covering the study region. All six grid-cell
files hold the same 91,195 cells.

| File | Forest measure | Years | Built by |
|---|---|---|---|
| `hansen20pct_rdy.dta` | Hansen GFC, 20% canopy | 2000-2019, annual | `01_clean_data.do` |
| `hansen20pct_matched.dta` | as above, plus matching output | 2000-2019, annual | `02_matching_hansen20.do` |
| `hansen30pct_rdy.dta` | Hansen GFC, 30% canopy | 2000-2019, annual | `01_clean_data.do` |
| `hansen30pct_matched.dta` | as above, plus matching output | 2000-2019, annual | `03_matching_hansen30.do` |
| `remote_sensing_rdy.dta` | own miombo classification | 1996, 2002, 2014, 2019 | `01_clean_data.do` |
| `remote_sensing_matched.dta` | as above, plus matching output | 1996-2019 | `04_matching_miombo.do` |

### Identifiers and geography

| Variable | Meaning |
|---|---|
| `id` | Grid-cell identifier. Links to `data/remote_sensing/sccp_coord.dta` for the polygon geometry. |
| `cell_groups` | Group assignment: 0 control, 1 spillover (within 5 km), 2 SCCP EU area, 3 SCCP Envirotrade area, 4 Gorongosa National Park. |
| `share_area_sccp` | Share of the cell inside the nominal SCCP project area. |
| `share_area_north_sccp` | Share inside the northern (analysed) section around Nhambita. |
| `share_area_np` | Share inside Gorongosa National Park. |
| `mean_distancetoprojectareain` | Distance from the cell to the analysed SCCP boundary, metres. |
| `mean_distance_np` | Distance to the National Park boundary, metres. |
| `mean_distanceurban`, `mean_distance_roads`, `mean_distanceagriculture50` | Distance to the nearest town, road, and agricultural land, metres. |
| `mean_slope`, `sq_slope` | Mean slope and its square. |
| `mean_elevation`, `sq_elevation` | Mean elevation and its square. |

### Outcome variables

- `forest20pct<year>`, `forest30pct<year>` — share of the cell classified as forest in that
  year, at the stated canopy threshold. Stored as a proportion in the `_rdy` files and
  rescaled to percentage points inside the analysis scripts.
- `forest<year>`, `denseforest<year>`, `sparseforest<year>` — miombo-specific classification
  (1996, 2002, 2014, 2019), in hectares in the raw file and converted to percentages in the
  matching scripts.
- `burned_forest<year>`, `burned_crop<year>` — burned area, forest and cropland.
- `fc_change00_04` — change in forest cover between 2000 and 2004, the pre-treatment trend
  used as a matching covariate.
- `fcc_02_96`, `dense_02_96`, `sparse_02_96` — miombo forest-cover change 1996 to 2002.

### Treatment definitions

| Variable | Meaning |
|---|---|
| `sccp` | 1 for cells in the analysed SCCP area, 0 for control cells, missing for spillover and park cells. |
| `spillover_2km`, `spillover_5km`, `spillover_10km` | 1 for cells within the stated distance of the SCCP boundary, 0 for controls, missing for park cells. |
| `combined` | 1 for SCCP cells or cells within 5 km, 0 for controls. |
| `treated_north` | Cell lies in the northern project section. |

### Matching output (`*_matched.dta` only)

`psmatch2` output is renamed with a prefix identifying the treatment definition it belongs
to: `sccp`, `spillover2k`, `spillover5k`, `spillover10k`, `combined`. For prefix `X`:

| Variable | Meaning |
|---|---|
| `X_treated` | Treatment indicator used in that matching run. |
| `X_weight` | Matching weight. Non-missing marks a cell as being in the matched sample; every analysis restricts on `X_weight!=.`. |
| `X_pscore` | Estimated propensity score. |
| `X_support` | On common support. |
| `X_pair` | Matched-pair identifier. Standard errors are clustered on this. |
| `X_paircount` | Number of cells sharing the pair identifier. |
| `iptw_X` | Inverse propensity weight. Computed but not used in any published specification. |

### Time structure

The `_rdy` and `_matched` files are wide, one column per year. The analysis scripts
`reshape long` to a cell-year panel and construct:

- `post` = 0 before 2005, 1 during the project (2005-2014), 2 after it ended (2015-2019).
- `period` in `10_gnp_leakage.do` uses the same three-way split.

---

## `rs_village_data.dta`

Unit: surveyed village (30 rows). Buffer-zone remote-sensing statistics used for the
village-level balance diagnostics in `08_did_miombo.do`.

| Variable | Meaning |
|---|---|
| `village_id` | Anonymous numeric village code. Merges to `survey_rdy.dta`. |
| `area` | 1 SCCP and buffer zone, 2 buffer zone only. |
| `buff5km_*`, `buff10km_*` | Statistics within a 5 km or 10 km buffer around the village. |
| `buff5km_wonp_*`, `buff10km_wonp_*` | The same, excluding land inside the National Park. |
| `*_forest<year>` | Forest cover in the buffer in that year. |
| `*_fcc9602`, `*_fcc0214`, `*_fcc1419` | Forest cover change across the three periods. |
| `*_slope`, `*_elevation` | Mean slope and elevation in the buffer. |
| `*_dist_roadn1n6`, `*_dist_np`, `*_dist_agri50` | Mean distance to the main roads, the park, and agricultural land. |

Village names and centroid coordinates have been removed; see `docs/data_provenance.md`.

---

## `sccp_coord.dta`

Grid-cell polygon geometry in the format `spmap` expects: `_ID` (matches `id` in the
grid-cell files), `_X`, `_Y`. Used only to draw Figure S2.

---

## `survey_rdy.dta`

Unit: household (738 rows), surveyed in 2022. Variable labels carry the questionnaire item
number, for example `E.11 Does anyone in your household work in the National Park`. Run
`describe` on the file for the full list.

### Treatment and location

| Variable | Meaning |
|---|---|
| `village_id` | Anonymous numeric village code. Standard errors are clustered on this throughout. |
| `sccp_area` | Respondent lives in a village that was part of the SCCP. |
| `sccp_id` | Respondent is individually identified in project records as a participant. |
| `sccp_benefit_today` | Respondent reports still benefiting from the project. |
| `bufferzone` | Constructed in `11_survey_analysis.do`: reference group of villages outside the project. |

The three treatment definitions are used side by side; the paper reports `sccp_area` as the
main specification and the other two as alternative definitions.

### Outcomes

| Variable | Meaning | Reported in |
|---|---|---|
| `wealth_index` | First principal component of assets, farmland and livestock | Figure 7, Table S23 |
| `hh_income_avg`, `hh_income_good`, `hh_income_bad` | Self-reported monthly household income in an average, good and bad month | Figure 7, Table S24 |
| `econ_ladder1`, `econ_ladder_expect5y`, `econ_ladder_aspiration` | Position on a ten-rung economic ladder now, expected in five years, and aspired to | Figure 7, Table S25, Figure S9 |
| `intrinsic_motivations_trees` | First principal component of four intrinsic-motivation items | Figure 6, Tables S18, S19, S26 |
| `extrinsic_motivations_trees` | First principal component of three extrinsic-motivation items | Tables S18, S19; diagnostics |
| `env_agency` | First factor from a ten-item factor analysis of environmental agency | Figure 6, Tables S20, S21, S27 |
| `job_sccp` | Respondent held a job in the SCCP | Figure 8 |
| `hh_work_np` | Household member in permanent National Park employment | Figure 8 |
| `hh_piecework_np` | Household member hired by the park for piecework | Figure 8 |
| `machamba_*` | Farm plot characteristics, size and practices | Figure S10 |
| `sccp_agroforestry_*`, `sccp_reason_keep*`, `sccp_reason_not_keep*` | Agroforestry contracts, whether trees are still in place, and stated reasons | Figure 5, Table S22 |

### Controls

`female`, `age`, `edu_years` (years of schooling), `same_place` (born in the village),
`people_hh` (household size), `people_hh_below14`.

### Conventions

- Continuous outcome variables are winsorised at the 1st and 99th percentile with `winsor2`
  before analysis; the winsorised versions carry a `_w` suffix.
- Variables prefixed `z_` are standardised to mean zero and unit variance.
- Variables prefixed `mi_` are estimates from the multiply imputed data
  (`mi impute chained`, 20 imputations, `rseed(1234)`).
- Items ending `_r` are reverse-coded.
- Short string variables such as `hh_assets` or `sccp_reason_keep` hold concatenated
  `select_multiple` response codes, not free text. They are expanded into dummies during
  the analysis. All genuine free-text fields have been removed.
