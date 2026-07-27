# Software versions

## Stata

The published results were produced with **StataNow 19.5** on Windows 11 (64-bit).
`run.do` sets `version 19`.

Stata 16 and later should reproduce the results; earlier versions are untested. If you use
a version older than 19, remove or lower the `version 19` line in `run.do`.

## Stata add-on packages

Every add-on used is vendored in `scripts/libraries/stata`. `run.do` strips the default
`adopath` down to `BASE` and prepends that folder, so the run uses these copies and not
whatever is installed on your machine. **You do not need to install anything.**

The table below lists the packages present in the vendored library and the install date
recorded in `scripts/libraries/stata/stata.trk`. The date is the package's own release
date as declared by its distributor, which is the closest thing to a version number that
SSC packages carry.

| Package | Release date | Used for |
|---|---|---|
| `betterbar` | 4 Jun 2024 | `betterbarci`, Figures 5 and 8 |
| `coefplot` | 2 Mar 2023 | all coefficient plots |
| `colrspace` | 4 Jun 2024 | dependency of `grstyle` |
| `estout` | 2 Mar 2023 | `eststo` / `esttab`, all regression tables |
| `grc1leg` | 6 Jan 2022 | combining maps under a shared legend, Figure S2 |
| `grc1leg2` | 4 Jun 2024 | combining panels under a shared legend |
| `grstyle` | 2 Mar 2022 | graph styling set in `run.do` |
| `ietoolkit` | 4 Jun 2024 | `iebaltab`, balance tables S2, S3, S17 |
| `kobo2stata` | 22 Aug 2022 | survey import (`01_clean_data.do` only) |
| `missings` | 2 Mar 2023 | `missings dropvars` (`01_clean_data.do` only) |
| `palettes` | 4 Jun 2024 | dependency of `grstyle` |
| `psmatch2` | 2 Mar 2023 | matching, `psgraph`, `pstest` |
| `rbounds` | 22 Aug 2024 | Rosenbaum bounds, Table S11 |
| `schemepack` | 2 Mar 2023 | the `tab2` graph scheme |
| `shp2dta` | 2 Mar 2022 | shapefile import (`01_clean_data.do` only) |
| `spmap` | 2 Mar 2022 | matched-cell maps, Figure S2 |
| `winsor2` | 24 Aug 2022 | winsorising of survey outcomes |

The vendored library also contains packages left over from specifications that were cut
before publication (`ivreg2`, `rbiprobit`, `cmp`, `ghk2`, `sspecialreg`, `sdid`, `asdoc`,
`catplot`, `cibar`, `distplot`, `geo2xy`, `kdens`, `mif2dta`, `moss`, `mylabels`,
`outreg2`, `estimate_supt_critical_value`). No script in this package calls them. They are
retained rather than deleted so that the library matches the environment in which the
published results were produced.

`scripts/00_install_packages.do` rebuilds the library from SSC and GitHub. It is not part
of a normal run and should not be used to reproduce the paper: it installs whatever is
current today, which may differ from the versions above.

## Other software

Not needed to run this package, but used to build inputs documented in
`docs/data_provenance.md`:

- **Python 3** with `rasterio`, `rasterstats`, `geopandas`, `numpy`, `pandas`, for the
  zonal extraction of Hansen forest cover per 9-ha grid cell.
- **QGIS 3.3**, for Figures 2 and 3.
- **Microsoft PowerPoint**, for Figure 1 and Figure S1.

## Runtime

Roughly 25 to 40 minutes end to end on a current desktop. The propensity score matching in
scripts 02 to 04 and the multiple imputation in script 11 dominate. Building the matched-cell
map in script 02 is the single most demanding step: it renders about 91,000 polygons five
times over.
