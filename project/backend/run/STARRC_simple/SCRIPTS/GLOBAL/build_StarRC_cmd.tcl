source ./last/lef list.set.tcl; # set lef list

set in	[open "../../SCRIPTS/GLOBAL/StarRC_template.cmd" r]
set out [open "./$env(view_rpt)/StarRC.cmd" w]
while {[gets $in line] > -1} {
	switch -regexp $line {
		"^LEF_FILE.*"  { foreach lef $lef_list { puts $out "LEF_FILE : $lef" }}
		"^NETLIST_FILE.*" { puts $out "NETLIST_FILE : $env(run_dir)/output/$env(design).spef.gz" }
		"^TOP_DEF_FILE.*" {puts $out "TOP_DEF_FILE : $env(def_file)" }
		"^NETLIST_FORMAT.*" { puts $out "NETLIST_FORMAT : SPEF" }
		"^NETLIST_COMPRESS_COMMAND.*" { puts $out "NETLIST_COMPRESS_COMMAND : gzip" }
		"^CORNERS_FILE.*" { puts $out "CORNERS_FILE: $env(corners_file)" }
		"^SIMULTANEOUS_MULTI_CORNER.*" { puts $out "SIMULTANEOUS_MULTI_CORNER : YES"}
		"^SELECTED_CORNERS.*" {puts $out "SELECTED_CORNERS : $env(selected_corners)" }
#		"^TCAD_GRD_FILE.*" {
#			switch -regexp $env(corner) {
#				"cbest.*" {puts $out "TCAD_GRD_FILE : /simulation/exchange/library/starrc/HHW_LO40NLPV4_7M_MTT3eK_RDL28K_CBEST.nxtgrd" }
#				"cworst.*" {puts $out "TCAD_GRD_FILE : /simulation/exchange/Library/starrc/HHW_LO40NLPV4_7M_MTT30K_RDL28K_CWORST.nxtgrd" }
#			}
#		}
#		"^OPERATING_TEMPERATURE.*" {
#			switch -regexp $env(corner) {
#				".*125c" { puts $out "OPERATING_TEMPERATURE : 125"}
#				".*m40c" { puts $out "OPERATING_TEMPERATURE : -40"}
#			}
#		}
		"MAPPING_FILE.*" {puts $out "MAPPING_FILE : $env(mapping_file)" }
		"^NETLIST_UNSCALED_RES_PROP.*" { puts $out "NETLIST_UNSCALED_RES_PROP : YES"}
		"^NETLIST_UNSCALED_COORDINATES.*" { puts $out "NETLIST_UNSCALED_COORDINATES : YES"}
		"^COUPLE_TO_GROUND.*" { puts $out "COUPLE_TO_GROUND : NO"}
		"^POWER_NETS.*" { puts $out "POWER_NETS : DVDD_AON DVDD_ONO DVSS"}
		"^NUM_CORES.*" { puts $out "NUM_CORES : $env(num_cores)"}
		"^COUPLING_ABS_THRESHOLD.*" { puts $out "COUPLING_ABS_THRESHOLD : 1e-15" }
		"^COUPLING_REL_THRESHOLD.*" { puts $out "COUPLING_REL_THRESHOLD : 0.01" }
		"^REDUCTION_MAX_DELAY_ERROR.*" {puts $out "REDUCTION_MAX_DELAY_ERROR : 5.Oe-15"}
		"^EXTRACT_VIA_CAPS.*" { puts $out "EXTRACT_VIA_CAPS : YES"}
		"^NETLIST_INPUT_DRIVERS.*" { puts $out "NETLIST_INPUT_DRIVERS : YES"}
		"^ENHANCED_SHORT_REPORTING.*" { puts $out "ENHANCED_SHORT_REPORTING : YES"}
		"REPORT_METAL_FILL_STATISTICS.*" { puts $out "REPORT_METAL_FILL_STATISTICS : YES"}
		"^METAL_FILL_GDS_FILE.*" { puts $out "METAL_FILL_GDS_FILE : $env(gds_file)" }
		"^SHORTS_LIMIT.*" { puts $out "SHORTS_LIMIT : 100000"}
		"^METAL_FILL_BLOCK_NAME.*" { puts $out "METAL_FILL_BLOCK_NAME : SC5O18_TOP_DM"}
		"^METAL_FILL_POLYGON_HANDLING.*" { puts $out "METAL_FILL_POLYGON_HANDLING : FLOATING"}
		"^GDS_LAYER_MAP_FILE.*" { puts $out "GDS_LAYER_MAP_FILE : $env(gds_layer_map_file)"}
	}
}

