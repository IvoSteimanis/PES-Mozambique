*--------------------------------------------------------------------
* SCRIPT:  00_install_packages.do
* PURPOSE: Installs the Stata add-on packages used by this replication
*          package into scripts/libraries/stata.
*
* YOU DO NOT NEED TO RUN THIS. The package ships with every add-on already
* vendored in scripts/libraries/stata, and run.do points Stata's adopath at
* that folder. The versions vendored there are the ones used to produce the
* published results; re-installing pulls whatever is current on SSC and
* GitHub today, which may differ.
*
* Run this only to rebuild the library from scratch, after deleting
* scripts/libraries/stata. See docs/software_versions.md for the versions
* that were actually used.
*
* RUN VIA: manually, and only if rebuilding (requires $working_ANALYSIS)
*--------------------------------------------------------------------

* Create and define a local installation directory for the packages
cap mkdir "$working_ANALYSIS/scripts/libraries"
cap mkdir "$working_ANALYSIS/scripts/libraries/stata"
net set ado "$working_ANALYSIS/scripts/libraries/stata"

* grc1leg / grc1leg2: combine graphs under a single shared legend
net install grc1leg, from("http://www.stata.com/users/vwiggins") replace
net install grc1leg2, from("http://digital.cgdev.org/doc/stata/MO/Misc") replace

* Packages installed directly from GitHub
* ietoolkit supplies iebaltab, used for the balance tables
net install ietoolkit, from("https://raw.githubusercontent.com/worldbank/ietoolkit/master/src") replace
* palettes and colrspace are dependencies of grstyle
net install palettes, from("https://raw.githubusercontent.com/benjann/palettes/master/") replace
net install colrspace, from("https://raw.githubusercontent.com/benjann/colrspace/master/") replace

* Packages from SSC. Each entry is used by at least one script; see the
* DEPENDS line in the header of each do-file.
*   betterbar  betterbarci, Figure 8
*   coefplot   all coefficient plots
*   estout     esttab / eststo, all regression tables
*   grstyle    graph styling set in run.do
*   kobo2stata import of the KoboToolbox survey (01_clean_data.do only)
*   missings   missings dropvars (01_clean_data.do only)
*   psmatch2   propensity score matching, psgraph, pstest
*   rbounds    Rosenbaum bounds, Table S11
*   schemepack supplies the tab2 graph scheme set in run.do
*   shp2dta    shapefile import (01_clean_data.do only)
*   spmap      matched-cell maps, Figure S2
*   winsor2    winsorising of survey outcome variables
foreach p in betterbar coefplot estout grstyle kobo2stata missings ///
             psmatch2 rbounds schemepack shp2dta spmap winsor2 {
	local ltr = substr(`"`p'"',1,1)
	qui net from "http://fmwww.bc.edu/repec/bocode/`ltr'"
	net install `p', replace
}

** EOF
