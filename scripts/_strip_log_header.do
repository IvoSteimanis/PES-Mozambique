*--------------------------------------------------------------------
* SCRIPT:  _strip_log_header.do
* PURPOSE: Removes the header and footer that Stata writes around a text
*          log. Both record the absolute path of the machine that produced
*          the file, which should not travel with a distributed package.
*          The table itself is left byte-for-byte unchanged.
*
* USAGE:   set two globals, then run it:
*              global STRIP_FILE   "<full path to the .txt log>"
*              global STRIP_MARKER "<text on the first line to keep>"
*              do "$working_ANALYSIS/scripts/_strip_log_header.do"
*
*          Everything before the first line containing STRIP_MARKER is
*          dropped, as is everything from the closing "log close" onwards.
*
* CALLED BY: 01_clean_data.do, 02_matching_hansen20.do
*--------------------------------------------------------------------

capture noisily {
	tempname fin fout
	tempfile cleaned

	file open `fin'  using "$STRIP_FILE", read text
	file open `fout' using "`cleaned'", write text replace

	local keeping = 0
	file read `fin' line
	while r(eof) == 0 {
		if strpos(`"`macval(line)'"', "$STRIP_MARKER") local keeping = 1
		if strpos(`"`macval(line)'"', "log close")     local keeping = 0
		if `keeping' file write `fout' `"`macval(line)'"' _n
		file read `fin' line
	}

	file close `fin'
	file close `fout'
	copy "`cleaned'" "$STRIP_FILE", replace
}
if _rc {
	di as error "Could not strip the log header from $STRIP_FILE (rc = `_rc')."
	di as error "The file is still valid but retains an absolute path in its header."
}

global STRIP_FILE
global STRIP_MARKER

** EOF
