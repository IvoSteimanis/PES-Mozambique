# Data provenance

Where every input to this replication package comes from, and what is and is not
distributed with it.

## What ships

The Zenodo archive contains the analysis-ready datasets in `processed/` plus one
geometry file in `data/`. Everything from `scripts/02_matching_hansen20.do` onward runs
from these files alone.

| File | Level | Obs | Built by | Contents |
|---|---|---|---|---|
| `processed/hansen20pct_rdy.dta` | 9-ha grid cell | 91,195 | `01_clean_data.do` | Unmatched panel, forest cover 2000-2019 at the 20% canopy threshold, plus matching covariates |
| `processed/hansen20pct_matched.dta` | 9-ha grid cell | 91,195 | `02_matching_hansen20.do` | The above with matching weights, propensity scores and matched-pair identifiers for each of the five treatment definitions |
| `processed/hansen30pct_rdy.dta` | 9-ha grid cell | 91,195 | `01_clean_data.do` | As above at the 30% canopy threshold |
| `processed/hansen30pct_matched.dta` | 9-ha grid cell | 91,195 | `03_matching_hansen30.do` | As above, matched |
| `processed/remote_sensing_rdy.dta` | 9-ha grid cell | 91,195 | `01_clean_data.do` | Own miombo-specific classification, 1996/2002/2014/2019 |
| `processed/remote_sensing_matched.dta` | 9-ha grid cell | 91,195 | `04_matching_miombo.do` | As above, matched |
| `processed/rs_village_data.dta` | village | 30 | `01_clean_data.do` | Buffer-zone remote-sensing statistics around each surveyed village |
| `processed/survey_rdy.dta` | household | 738 | `01_clean_data.do` | De-identified household survey, cleaned and with derived indices |
| `data/remote_sensing/sccp_coord.dta` | polygon vertex | 547,170 | `01_clean_data.do` | Grid-cell boundaries, used by `spmap` for Figure S2 |

## What does not ship, and why

### Household survey (confidentiality)

The raw survey export and every intermediate built from it are withheld. They contain
respondent names, phone numbers, household GPS coordinates, enumerator identifiers,
interview timestamps and open-ended free-text responses. In a sample of 738 households
across a small number of villages, these fields are re-identifying.

`scripts/01_clean_data.do` is shipped so that every construction step is inspectable, but
it cannot be executed from the public package. The de-identification it applies is
explicit and marked `CONFIDENTIALITY` in the source. The following are dropped before any
file is written:

- direct identifiers: name, surname, phone number, GPS coordinates and precision,
  device ID, submission UUID, submitter account;
- indirect identifiers: enumerator, village name, respondent ID, interview date,
  start and end timestamps, distance to the initial project village;
- village name and centroid coordinates carried in from the village-level file;
- all open-ended free-text fields (`*_other`, `*_oth`, `comment`, `origin_village`,
  the agroforestry organisation name).

Villages are identified in the shipped data by an anonymous numeric `village_id` only.
Short `select_multiple` code strings are retained; they contain response codes, not text.

Written informed consent was obtained from every respondent, recorded on tablets at the point
of interview. The consent indicator and the URL of the stored consent record are themselves
identifying and are dropped during cleaning, so neither appears in the distributed data.

Researchers who need the raw survey data can request them from the corresponding author.
Access requires a confidentiality agreement.

### Hansen Global Forest Change rasters (size and public availability)

The forest-cover measures derive from Hansen et al. (2013), Global Forest Change v1.7
(2000-2019). The two source rasters covering the study area are each several hundred
megabytes and are publicly downloadable, so they are not mirrored here:

- `Hansen_GFC-2019-v1.7_treecover2000_10S_030E.tif`
- `Hansen_GFC-2019-v1.7_lossyear_10S_030E.tif`

Download from `https://storage.googleapis.com/earthenginepartners-hansen/GFC-2019-v1.7/`
(tile `10S_030E`), or via the Global Forest Change portal at the University of Maryland.

Zonal statistics were extracted per 9-ha grid cell with Python (`rasterio`,
`rasterstats`, `geopandas`), producing the annual cell-level panels
`hansen_panel_2000_2019_20pct.csv` and `..._30pct.csv` that `01_clean_data.do` reads.
These intermediates are roughly 700 MB each and are likewise not distributed; the
`processed/*_rdy.dta` files derived from them are.

### Own miombo classification

The 1996/2002/2014/2019 miombo-specific classification was produced for the project by
Remote Sensing Solutions GmbH from Landsat imagery. The classified rasters are not ours
to redistribute. The cell-level aggregates enter the package through
`processed/remote_sensing_rdy.dta`.

### Grid-cell shapefile

`gridcells_9ha.shp` defines the 9-ha analysis grid. Its geometry is shipped in the
Stata-native form required by `spmap` (`data/remote_sensing/sccp_coord.dta`); the
original shapefile and its 53 MB attribute table are not.

## Constants used in the emission benchmark

`05_event_study.do` converts the estimated avoided deforestation into tCO2e and compares
it with the project's own figures. The constants are:

| Constant | Value | Source |
|---|---|---|
| Project area | 21,725 ha | Project design document |
| Carbon stock | 83.7 tCO2e per ha | Mature-miombo value used in the project's own carbon accounting |
| Claimed sequestration | 571,690 tCO2e | Net of the buffer pool, as reported by the project |
| Credits sold | 159,817 tCO2e | Registry records |

## Figures not produced by code

Figure 1 (conceptual framework) and Figure S1 (theory of change) were drawn in
PowerPoint. Figures 2 and 3 (study site, forest canopy density) were composed in QGIS
3.3 from the Hansen rasters and the grid shapefile. Figure S9 reproduces a survey
instrument item. None of these depend on the analysis output.
