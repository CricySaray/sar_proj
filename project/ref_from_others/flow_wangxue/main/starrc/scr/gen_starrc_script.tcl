#!/usr/bin/tclsh

#source ../common_setup.tcl
set vars(version) $env(DATAOUT_VERSION) ;# defined in Makefile
set vars(design) $env(DESIGN)
source ../../lib_conf/lib_setup.tcl

set vars(dataoutDir) "../../../dataout/$vars(version)"
set vars(def) "$vars(dataoutDir)/def/$vars(design).pr.def.gz"

set vars(metal_fill_exists)	$env(STARRC_WITH_DUMMY)
set vars(metal_fill_gds_block)	 "$vars(design)_DM"
set vars(metal_fill_gds_file) "$vars(dataoutDir)/gds/$vars(design).DM.gds"
set vars(extract_corners)       "m40_cworst_T m40_rcworst_T 125_cworst_T 125_rcworst_T m40_cworst m40_rcworst 125_cworst 125_rcworst m40_rcbest m40_cbest 125_rcbest 125_cbest 0_cworst 0_rcworst 0_rcbest 0_cbest tt_85"

set vars(LEF_LIBS)	$vars(lef_files)
set vars(STAR_MAP)	"../../QRC_layermap.tcl"
#"/home/wangxue/work/project/yuki/STARRC/StarRC_55LLULPRF_1P8M_6Ic_1TMc_1MTTc_ALPA2_cell.map"
set vars(DEF2GDS_MAP)	"../../starrc_gds.map"
set vars(CORNER_FILE)	"../../scr/corner.smc"

set vars(LEF_LIBS_SUB) "" ;# sub lef files for hier design

#####not modify the following

set file1 [open run_starrc.$vars(version).csh w]
exec mkdir -p ../dataout/$vars(version)/spef
#foreach vars(corners) $vars(extract_corners) 
set vars(corners) "all"
    set file [open ./scr/$vars(design).$vars(version).star w]
    puts $file "**STARRC CMD FILE"
    puts $file "NETLIST_FILE: $vars(dataoutDir)/spef/$vars(design).spef.gz"
    puts $file "TOP_DEF_FILE: $vars(def)"
    puts $file "BLOCK: $vars(design)"

    puts $file "************   SETUP  *****************"
    puts $file ""
    puts $file ""
    puts $file "* Provide technology let file followed by standard cell and macro let files. This command can be specified multiple times to provide multiple lef files."
    #puts $file "LEF_FILE: $vars(LEF_LIBS)"
	foreach i $vars(LEF_LIBS) {
    puts $file "LEF_FILE: $i"
	}
	foreach i $vars(LEF_LIBS_SUB) {
    puts $file "LEF_FILE: $i"
	}
    puts $file "* Provide def files for macros referenced in TOP_DEF_FILE separated by a space. This command can be specified multiple times to provide multiple def files. If there is only TOP_DEF_FILE, avoid this command"

    puts $file "*MACRO_DEF_FILE:<list_of_macro_def_files>"
    puts $file "* Provide top macro def file"
    puts $file ""
    puts $file ""

    puts $file "* Specify nxtgrd file which consists of capacitance models."
    puts $file "*TCAD_GRD_FILE:"
    puts $file "* Provide the mapping file in which design Layers mapped to process layers."
    puts $file "MAPPING_FILE: $vars(STAR_MAP)"
    puts $file ""

    puts $file "* Reduction setting for STA Analysis."
    puts $file "REDUCTION: NO_EXTRA_LOOPS"
    puts $file ""

    puts $file "* Use '*' to extract all signal nets in the design. Otherwise, provide the net names to be extracted separated by a space. Wildcards '?' and '!' are accepted for net names" 
    puts $file "NETS: *"
    puts $file ""

    puts $file "* Use 'RC' to perform resistance and capacitance extraction on the nets"
    puts $file "EXTRACTION: RC"
    puts $file ""

    puts $file "* Provide operating temperature in degree celsius at which extraction is performed."
    puts $file "*OPERATING_TEMPERATURE: 125C"
    #puts $file "MAGNIFICATION_FACTOR: 0.9"
    puts $file "MAGNIFY_DEVICE_PARAMS: NO"

    puts $file "NETLIST_UNSCALED_RES_PROP:YES"
    puts $file "NETLIST_UNSCALED_COORDINATES:YES"
    puts $file ""


    puts $file "***********   FLOW SELECTION  ****************"
    puts $file "ENABLE_IPV6: NO"
    puts $file "* Choose maximum of 2 cores for designs less than 100k nets, 4 to 6 cores for designs around 1Million nets and 8 to 16 cores for designs around 10Million nets"
    puts $file "NUM_CORES: 8"
    puts $file "* Provide settings to distribute StarRC job on Gridwire or LSF. Use Command Reference manual for reference"
    puts $file "STARRC_DP_STRING: list localhost:8"
    puts $file "* Simultaneous Multicorner Extraction is supported with Distributed Processing and Rapid3D extractions"
    puts $file "* Temperature sensitivity extraction is now integrated into SMC"
    puts $file "* Define all corners at the project level in the following syntax in corners.smc file:"
    puts $file "*	CORNER_NAME: CWorst_TWC"
    puts $file "*	TCAD_GRD_FILE: CWorst.nxtgrd"
    puts $file "*   OPERATING_TEMPERATURE: TWC"
    puts $file "*   CORNER NAME: CTypical_TTP"
    puts $file "*	TCAD_GRD_FILE: CTypical.nxtgrd"
    puts $file "*	OPERATING_TEMPERATURE: TBC"
    puts $file "* Provide the defined corners.smc file"
    puts $file "CORNERS_FILE: $vars(CORNER_FILE)"
    puts $file "* List all corners to be extracted separated by a space"
    puts $file "SELECTED_CORNERS: $vars(extract_corners)"
    puts $file "* Enable the SMC feature"
    puts $file "SIMULTANEOUS_MULTI_CORNER: YES"
    puts $file ""
    puts $file "******** SKIPPING ALL CELLS ******"

    puts $file "SKIP_CELLS: *"
    puts $file ""





    puts $file "* Metal fill database type will be aligned to skip cells additiOnat layout file type if skip cell addtional Layout contents is selected"

    puts $file "******** FILL HANDLING ***********"
    puts $file "* Provide the metal fill gds file's cell name."
    puts $file "* Provide the metal fill gds file for fill extraction"
    if {$vars(metal_fill_exists)} {
    	puts $file "METAL_FILL_GDS_BLOCK: $vars(metal_fill_gds_block)"
    	puts $file "METAL_FILL_GDS_FILE: $vars(metal_fill_gds_file)"
    } else {
    	puts $file "*METAL_FILL_GDS_BLOCK:"
    	puts $file "*METAL_FILL_GDS_FILE:"
    }

    puts $file "* Provide the setting how the metal fill needs to be treated, FLOATING or GROUNDED"
    puts $file "METAL_FILL_POLYGON_HANDLING: FLOATING"
    puts $file ""
    puts $file "REPORT_METAL_FILL_STATISTICS:YES"



    puts $file "* Provide the fill GDS layer map file that consists of fill gds layers mapped to design database layers"
    puts $file "GDS_LAYER_MAP_FILE: $vars(DEF2GDS_MAP)"
    puts $file ""
    puts $file "************** PARASITIC OUTPUT *************"

    puts $file ""
    puts $file "COUPLE_TO_GROUND: NO"
    puts $file ""

    puts $file ""
    puts $file "COUPLING_ABS_THRESHOLD: 3E-16"
    puts $file "COUPLING_REL_THRESHOLD: 0.02"
    puts $file "COUPLING_REPORT_NUMBER: 10000000"
    puts $file "DENSITY_BASED_THICKNESS: YES"
    puts $file ""

    puts $file ""
    puts $file "REDUCTION_MAX_DELAY_ERROR: 1e-14"
    puts $file ""

    puts $file ""
    puts $file "BUS_BIT: \[\]"
    puts $file "CASE_SENSITIVE:	YES"
    puts $file "HIERARCHICAL_SEPARATOR: /"
    puts $file "EXTRACT_VIA_CAPS: YES"
    puts $file "REMOVE_DANGLING_NETS: YES"
    puts $file "SHORT_PINS: MIXED"
    #puts $file "INTRANET_CAPS: NO" ;  Valid only in transistor-level flows
    puts $file ""


    puts $file ""
    puts $file "NETLIST_FORMAT: SPEF"
    puts $file ""



    puts $file ""
    puts $file "NETLIST_COMPRESS_COMMAND: /usr/bin/gzip"
    puts $file ""

    puts $file "* Provide the name of a summary file to which runtime and memory usage is written"
    puts $file "SUMMARY_FILE: ./star_sum"
    puts $file ""

    puts $file "* Provide the working directory name to which StarRC internal information is written in binary"
    puts $file "STAR_DIRECTORY: ./rpt"
    puts $file ""
    puts $file1 "#!/bin/tcsh"
    puts $file1 "mkdir -p ./work/$vars(version)"
    puts $file1 "cd ./work/$vars(version)"
    puts $file1 "StarXtract -clean ../../scr/$vars(design).$vars(version).star "
    #puts $file1 "StarXtract -clean ../../scr/$vars(design).$vars(version).star &"
    #puts $file1 "sleep 32"
    #puts $file1 "cd -"
    puts $file1 ""
    close $file
#}
close $file1

exec ln -sf run_starrc.$vars(version).csh run_starrc.csh

