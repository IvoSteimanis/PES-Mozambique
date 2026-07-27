# Verification report

Record of the reproduction check run while assembling this package, on 27 July 2026,
StataNow 19.5, Windows 11.

Method: the pipeline was run from the de-identified analysis-ready data shipped with the
package, and every number in each generated table was compared against the corresponding
table in the accepted Supplementary Information
(`sccp_SI_anon_R2_clean.docx`). Comparison was value-by-value, not eyeballed.

## Result

**Sixteen of the seventeen code-generated tables reproduce exactly**, coefficients and
standard errors alike, including every table underpinning the paper's main claims.

| Table | Content | Result |
|---|---|---|
| S4 | Pre-trends 2000-2004 | exact |
| **S5** | **Forest cover changes, 20% threshold (primary result)** | **exact** |
| S6 | Year-by-year DiD, event study | exact |
| S7 | Forest cover changes, 30% threshold | **partial, see below** |
| S8 | Alternative matching specifications | exact |
| S9 | Closeness to GNP | exact |
| S10 | Leakage into GNP | exact |
| S12-S16 | Miombo-specific impact, five areas | exact |
| S23-S27 | Survey subgroup effects, five outcomes | exact |

Tables S1, S2, S3, S11, S17-S22 are produced as `.csv`, `.xlsx` or `.txt` and were checked
by inspection rather than by automated parsing.

## The matching is deterministic

The published code set no random seed, and `psmatch2 ... noreplacement` breaks ties by the
current sort order, so there was a real risk that the matched samples, and therefore every
forest-cover estimate, were not reproducible. `set seed 20260727` and an explicit `sort id`
were added before every matching call.

This was verified rather than assumed. The re-run matched samples were compared cell by cell
against the archived matched datasets:

| Sample | Treated + control cells | Identical to archive |
|---|---|---|
| Hansen 20%, SCCP area | 4,502 | yes |
| Hansen 20%, 2-km spillover | 2,472 | yes |
| Hansen 20%, 5-km spillover | 6,378 | yes |
| Hansen 20%, 10-km spillover | 12,918 | yes |
| Hansen 20%, combined | 10,620 | yes |
| Hansen 30%, all five | 4,502 / 2,438 / 6,352 / 12,772 / 10,426 | yes |

Not one cell differs. Adding the seed and the sort pinned the existing behaviour; it did not
change any published estimate.

## Table S7 and Figure S5: the published version used a different matching specification

Table S7 reports the 30% canopy threshold as a robustness check. The SCCP-area column, which
is what the main text cites, reproduces exactly:

| | Published S7 | This package |
|---|---|---|
| SCCP area, Treated × During SCCP | 3.10\*\*\* (0.24) | 3.10\*\*\* (0.24) |
| SCCP area, Treated × Post-SCCP | 4.01\*\*\* (0.40) | 4.01\*\*\* (0.40) |

The four spillover columns do not:

| | Published S7 | This package |
|---|---|---|
| 10-km, Treated × During SCCP | 0.95\*\*\* (0.12) | 0.28\*\* (0.14) |
| 10-km, Treated × Post-SCCP | 1.64\*\*\* (0.21) | 0.22 (0.23) |
| 10-km, N | 306,640 | 255,440 |
| 10-km, clusters | 7,666 | 6,386 |
| 5-km, Treated × Post-SCCP | 0.91\*\*\* (0.26) | 0.85\*\*\* (0.27) |
| Combined, Treated × Post-SCCP | 2.16\*\*\* (0.22) | 2.04\*\*\* (0.23) |
| 2-km, Treated × Post-SCCP | 1.45\*\*\* (0.33) | 1.45\*\*\* (0.34) |

### Cause, confirmed

The published Table S7 was produced by a 30% matching run **without the 0.05 caliper**.
Re-running the 30% matching with `psmatch2 ... n(1) noreplacement common` and no caliper
reproduces the published table exactly:

| Matched pairs | Published S7 | No caliper | Caliper 0.05 (this package) |
|---|---|---|---|
| SCCP area | 2,251 | 2,251 | 2,251 |
| 2-km spillover | 1,250 | 1,250 | 1,219 |
| 5-km spillover | 3,273 | 3,273 | 3,176 |
| 10-km spillover | 7,666 | 7,666 | 6,386 |
| Combined | 5,526 | 5,526 | 5,213 |

and the 10-km DiD without a caliper returns 0.951 (0.125) and 1.643 (0.206) on N = 306,640,
which is the published 0.95\*\*\* (0.12), 1.64\*\*\* (0.21), N = 306,640.

The caliper does not bind in the SCCP area, where every treated cell matches either way. That
is why the SCCP column is identical in both versions and the discrepancy is confined to the
spillover buffers.

`caliper(0.05)` is present in the archived `02_matching_hansen30pct.do` and was not introduced
by this cleanup; the only additions here were `set seed` and `sort id`. So the caliper was
added to the 30% branch at some point, the table was regenerated to
`results/tables/tableS2_TWFE_30pct.rtf` on 26 June 2025, and the SI was never updated from it.
No archived run log covers the 30% branch, so it was last executed interactively.

The calipered version is the correct one. A 0.05 caliper with one-to-one matching and no
replacement is the paper's main matching specification, stated as such in the note to Table S8
and used throughout the 20% analysis that produces Table S5. A robustness check on the
canopy threshold should hold the matching specification fixed; the published Table S7 varied
both at once.

Figure S5 draws on the same 30% estimates and therefore also changes, though only slightly:
it plots the SCCP, 5-km and combined areas, not the 10-km buffer, so the visible movement is
0.63 to 0.61 and 0.91 to 0.85 for the 5-km area and 1.66 to 1.64 and 2.16 to 2.04 for the
combined area. Every estimate in the figure remains significant at the 1% level. The corrected
figure is `results/figures/figS5_forest_cover_impact_30pct.png`.

The 20% branch does not have this problem: it has always been calipered, and the published
Table S5 matches the current data exactly.

Effect on the paper's claims: the Results sentence reads "using the common 30% canopy cover
threshold instead of 20%, we find larger treatment effects of 3.1 percentage points during
the SCCP period which increase to 4.0 pp in the post-program for core SCCP areas, with
positive spillover effects across all buffer zones." The two headline figures, 3.1 and 4.0,
are exact. All spillover point estimates remain positive, so the sentence stays literally
true, but the 10-km post-period estimate is 0.22 and no longer statistically significant
where the published table reports 1.64\*\*\*.

The authors reviewed this finding on 27 July 2026 and are correcting Table S7 and Figure S5
before publication. The package therefore ships the calipered results, which are the correct
ones under the paper's stated matching specification.

## Two corrected SI figures

Both were rendered and visually inspected.

- **Figure S6.** Panels A and B now read "≤2km" and ">2km", matching the variable actually
  plotted. The published version read "≤5km" and ">5km".
- **Figure S3.** Panel E now shows the Hansen 20% bias-reduction plot, listing the
  `forest20pct2001`-`forest20pct2004` covariates consistently with panels A to D. The
  published version showed the miombo-classification plot because `gr combine` referenced a
  stale filename.

A minor cosmetic point remains in the corrected Figure S3: the legend under panel E overlaps
slightly. This comes from the graph-editor positioning recorded for the original panel and
was not adjusted, since changing it further would move the figure away from the published
layout in ways unrelated to the correction.

## Defects fixed that would have blocked a replicator

Three problems in the archived code would have stopped the pipeline outright:

1. `07_gnp_leakage.do` called `lincom 1.post#1.close_to_sccp` against models estimated on
   `i.period##i.close_to_sccp`. There is no `post` term in those models, so both calls failed
   and the summary block printed nothing. Corrected to `1.period` and `2.period`.
2. `03_analysis_RS_DID.do` (now `08_did_miombo.do`) ran
   `bys year: sum ... if treated==2`, referencing a variable that does not exist in the
   matched dataset. This halted the script before any of Tables S12 to S16 were written. The
   block was scratch output that fed nothing, and has been removed.
3. `03_analysis_hansen10pct_DID.do` contained a truncated line, `lover10k_pair)`, left by a
   broken paste. That whole branch is dropped from the package: the 10% threshold appears
   nowhere in the paper.

## A note on batch execution

Building Figure S2 renders roughly 91,000 polygons five times and then combines them.
On Windows, running the whole pipeline in a single headless Stata session could exhaust the
graph engine partway through, terminating Stata without an error message. Two changes make
the run stable: `set graphics off` in `run.do`, and `graph drop _all` between scripts and
before the map is assembled. Graphs are written to disk in every case, so nothing is lost.

If Stata does terminate during a batch run, re-running the affected script on its own
completes normally; each script is self-contained and reads its inputs from `processed/`.
