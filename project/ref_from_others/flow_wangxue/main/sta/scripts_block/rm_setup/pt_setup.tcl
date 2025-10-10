#B
## User specify
# Used to control the PT behavior, set it to true if you want to do ECO fixing,
# before which you must have already completed timing analysis and all sessions
# are avaiable
#set ECO_FIX [getenv ECO_FIX]
set postfix [clock format [clock seconds] -format "%m%d_%H%M"]
set eco_instance_name_prefix pteco_${postfix}_
set eco_net_name_prefix      pteco_net_${postfix}_
set ECO_FIX false

### pt_setup.tcl file              ###


set pt_tmp_dir .

puts "RM-Info: Running script [info script]\n"
### Start of PrimeTime Runtime Variables ###

##########################################################################################
# PrimeTime Variables PrimeTime RM script
# Script: pt_setup.tcl
# Version: F-2011.06 (June 27, 2011)
# Copyright (C) 2008-2011 Synopsys All rights reserved.
##########################################################################################


######################################
# Report and Results directories
######################################


set REPORTS_DIR "reports"
set RESULTS_DIR "results"

######################################
# Library & Design Setup
######################################


### Mode : DMSA

set search_path ". $search_path \
"
source /home/user3/project/CX200UR1/lib_conf/all_db.tcl 

# Provide list of  Verilog netlist file. It can be compressed ---example "A.v B.v C.v"
set NETLIST_FILES               "/home/user3/project/CX200UR1/CX200UR1_SOC_TOP/dataout/$env(DATAOUT_VERSION)/netlist/$env(DESIGN).pr.v.gz"

set DESIGN_NAME                 "CX200UR1_SOC_TOP"  ;#  The name of the top-level design

######################################
#
#DMSA File Section
######################################

set sh_source_uses_search_path true

# Provide a list of DMSA Corners : best_case, nom, worst_case
#
# The syntax will be:
#		1.  set dmsa_corners "corner1 corner2 ..."

#set dmsa_corners      " \
#                       ffgm40c_cworst_dc   ssgm40c_rcworst_dc   ffg125c_rcbest_dc    ssgm40c_cworst_dc \
#                       ssgm40c_cworst_D_dc ffgm40c_rcworst_dc   ffgm40c_rcbest_dc    ffgm40c_cbest_dc \
#                       ffg125c_rcworst_dc  ssgm40c_rcworst_D_dc ssg125c_rcworst_D_dc ssg125c_cworst_D_dc \
#                       ffg125c_cworst_dc   ssg125c_rcworst_dc   ffg125c_cbest_dc     ssg125c_cworst_dc \
#                       tt25c_typ \
#                       "

#set dmsa_corners           " \
#tt_typical \
#ssm40_cbest ssm40_rcbest ssm40_rcworst ssm40_cworst \
#ss125_cbest ss125_rcbest ss125_rcworst ss125_cworst \
#ffm40_cbest ffm40_rcbest ffm40_rcworst ffm40_cworst \
#ff125_cbest ff125_rcbest ff125_rcworst ff125_cworst \
#"

set dmsa_corners           " \
tt_85 \
ssm40_cworst_T \
ssm40_rcworst_T \
ss125_cworst_T \
ss125_rcworst_T \
ssm40_cworst \
ssm40_rcworst \
ss125_cworst \
ss125_rcworst \
ffm40_cworst \
"
#set dmsa_corners           " \
#ssm40_cworst_T \
#ffm40_cbest \
#ssm40_cworst \
#"


set  dmsa_corner_library_files(tt_85)            "$vars(tt_85,timing)"
set  dmsa_corner_library_files(ssm40_cworst_T)   "$vars(ssm40,timing)"
set  dmsa_corner_library_files(ssm40_rcworst_T)  "$vars(ssm40,timing)"
set  dmsa_corner_library_files(ssm40_cworst)     "$vars(ssm40,timing)"
set  dmsa_corner_library_files(ssm40_rcworst)    "$vars(ssm40,timing)"
set  dmsa_corner_library_files(ssm40_rcbest)     "$vars(ssm40,timing)"
set  dmsa_corner_library_files(ffm40_cworst)     "$vars(ffm40,timing)"
set  dmsa_corner_library_files(ffm40_rcworst)    "$vars(ffm40,timing)"
set  dmsa_corner_library_files(ffm40_rcbest)     "$vars(ffm40,timing)"
set  dmsa_corner_library_files(ffm40_cbest)      "$vars(ffm40,timing)"
set  dmsa_corner_library_files(ss125_cworst_T)   "$vars(ss125,timing)"
set  dmsa_corner_library_files(ss125_rcworst_T)  "$vars(ss125,timing)"
set  dmsa_corner_library_files(ss125_cworst)     "$vars(ss125,timing)"
set  dmsa_corner_library_files(ss125_rcworst)    "$vars(ss125,timing)"
set  dmsa_corner_library_files(ss125_rcbest)     "$vars(ss125,timing)"
set  dmsa_corner_library_files(ff125_cbest)      "$vars(ff125,timing)"
set  dmsa_corner_library_files(ff125_rcbest)     "$vars(ff125,timing)"
set  dmsa_corner_library_files(ff125_cworst)     "$vars(ff125,timing)"
set  dmsa_corner_library_files(ff125_rcworst)    "$vars(ff125,timing)"
set  dmsa_corner_library_files(ff0_cbest)        "$vars(ff0,timing)"
set  dmsa_corner_library_files(ff0_rcbest)       "$vars(ff0,timing)"
set  dmsa_corner_library_files(ff0_cworst)       "$vars(ff0,timing)"
set  dmsa_corner_library_files(ff0_rcworst)      "$vars(ff0,timing)"


set dmsa_modes      "func"



set dmsa_mode_constraint_files(func) "/process/TSMC28/projects/CX200UR1/backend/user3/backend/input/syn/1.0/CX200UR1_SOC_TOP_func_ptwrite.sdc"
set dmsa_mode_constraint_files(scan) "/process/TSMC28/projects/CX200UR1/backend/user3/backend/input/syn/1.0/CX200UR1_SOC_TOP_scan_ptwrite.sdc"
#set dmsa_mode_constraint_files(mbist) "/home/jz/projects/EP/pnr/run_0605/design_data/incoming/Chip_mbist_pt.sdc";

#
# Corner Based Back Annotation Section
#
# The syntax will be:
#		1. PARASITIC_FILES(corner1)
#		2. PARASITIC_PATHS(corner1)
#

#The path (instance name) and name of the parasitic file --- example "top.spef A.spef"
#Each PARASITIC_PATH entry corresponds to the related PARASITIC_FILE for the specific block"
#For a single toplevel PARASITIC file please use the toplevel design name in PARASITIC_PATHS variable."
set PARASITIC_PATHS "/home/user3/project/CX200UR1/CX200UR1_SOC_TOP/dataout/$env(DATAOUT_VERSION)/spef/"
set PARASITIC_FILES(tt_25)  	"$PARASITIC_PATHS/CX200UR1_SOC_TOP.spef.tt_25.gz"
set PARASITIC_FILES(tt_85)  	"$PARASITIC_PATHS/CX200UR1_SOC_TOP.spef.tt_85.gz"
set PARASITIC_FILES(ssm40_cworst_T)   	"$PARASITIC_PATHS/CX200UR1_SOC_TOP.spef.m40_cworst_T.gz"
set PARASITIC_FILES(ssm40_rcworst_T)   	"$PARASITIC_PATHS/CX200UR1_SOC_TOP.spef.m40_rcworst_T.gz"
set PARASITIC_FILES(ss125_cworst_T)   	"$PARASITIC_PATHS/CX200UR1_SOC_TOP.spef.125_cworst_T.gz"
set PARASITIC_FILES(ss125_rcworst_T)   	"$PARASITIC_PATHS/CX200UR1_SOC_TOP.spef.125_rcworst_T.gz"
set PARASITIC_FILES(ssm40_cworst)   	"$PARASITIC_PATHS/CX200UR1_SOC_TOP.spef.m40_cworst.gz"
set PARASITIC_FILES(ssm40_rcworst)   	"$PARASITIC_PATHS/CX200UR1_SOC_TOP.spef.m40_rcworst.gz"
set PARASITIC_FILES(ss125_cworst)   	"$PARASITIC_PATHS/CX200UR1_SOC_TOP.spef.125_cworst.gz"
set PARASITIC_FILES(ss125_rcworst)   	"$PARASITIC_PATHS/CX200UR1_SOC_TOP.spef.125_rcworst.gz"
set PARASITIC_FILES(ffm40_cworst)   	"$PARASITIC_PATHS/CX200UR1_SOC_TOP.spef.m40_cworst.gz"
set PARASITIC_FILES(ffm40_rcworst)   	"$PARASITIC_PATHS/CX200UR1_SOC_TOP.spef.m40_rcworst.gz"
set PARASITIC_FILES(ffm40_rcbest)   	"$PARASITIC_PATHS/CX200UR1_SOC_TOP.spef.m40_rcbest.gz"
set PARASITIC_FILES(ssm40_rcbest)       "$PARASITIC_PATHS/CX200UR1_SOC_TOP.spef.m40_rcbest.gz"
set PARASITIC_FILES(ffm40_cbest)   	"$PARASITIC_PATHS/CX200UR1_SOC_TOP.spef.m40_cbest.gz"
set PARASITIC_FILES(ff125_cworst)   	"$PARASITIC_PATHS/CX200UR1_SOC_TOP.spef.125_cworst.gz"
set PARASITIC_FILES(ff125_rcworst)   	"$PARASITIC_PATHS/CX200UR1_SOC_TOP.spef.125_rcworst.gz"
set PARASITIC_FILES(ff125_rcbest)   	"$PARASITIC_PATHS/CX200UR1_SOC_TOP.spef.125_rcbest.gz"
set PARASITIC_FILES(ss125_rcbest)       "$PARASITIC_PATHS/CX200UR1_SOC_TOP.spef.125_rcbest.gz"
set PARASITIC_FILES(ff125_cbest)   	"$PARASITIC_PATHS/CX200UR1_SOC_TOP.spef.125_cbest.gz"
set PARASITIC_FILES(ff0_cworst)   	"$PARASITIC_PATHS/CX200UR1_SOC_TOP.spef.0_cworst.gz"
set PARASITIC_FILES(ff0_rcworst)   	"$PARASITIC_PATHS/CX200UR1_SOC_TOP.spef.0_rcworst.gz"
set PARASITIC_FILES(ff0_rcbest)   	"$PARASITIC_PATHS/CX200UR1_SOC_TOP.spef.0_rcbest.gz"
set PARASITIC_FILES(ff0_cbest)   	"$PARASITIC_PATHS/CX200UR1_SOC_TOP.spef.0_cbest.gz"


## switching activity (VCD/SAIF) file
#set ACTIVITY_FILE ""
#
## strip_path setting for the activity file
#set STRIP_PATH ""

## name map file
#set NAME_MAP_FILE ""



#
# Provide Mode/Corner Specific Derates
#
# The syntax is
#		1. set dmsa_derate_clock_early_value(mode_corner) "_1.09"
#		2. set dmsa_derate_clock_late_value(mode_corner) "_1.09"
#		3. set dmsa_derate_data_early_value(mode_corner) "_1.09"
#		4. set dmsa_derate_data_late_value(mode_corner) "_1.09"
#
#
set dmsa_derate_clock_early_value(tt_25) "1"
set dmsa_derate_clock_late_value(tt_25) "1"
set dmsa_derate_data_early_value(tt_25) "1"
set dmsa_derate_data_late_value(tt_25) "1"
set dmsa_derate_data_net_early_value(tt_25) "1"
set dmsa_derate_data_net_late_value(tt_25) "1"
set dmsa_derate_clk_net_early_value(tt_25) "1"
set dmsa_derate_clk_net_late_value(tt_25) "1"

set dmsa_derate_clock_early_value(tt_85) "1"
set dmsa_derate_clock_late_value(tt_85) "1"
set dmsa_derate_data_early_value(tt_85) "1"
set dmsa_derate_data_late_value(tt_85) "1"
set dmsa_derate_data_net_early_value(tt_85) "1"
set dmsa_derate_data_net_late_value(tt_85) "1"
set dmsa_derate_clk_net_early_value(tt_85) "1"
set dmsa_derate_clk_net_late_value(tt_85) "1"


set dmsa_derate_clock_early_value(ssm40_cworst_T) "0.937"
set dmsa_derate_clock_late_value(ssm40_cworst_T) "1.02"
set dmsa_derate_data_early_value(ssm40_cworst_T) "1"
set dmsa_derate_data_late_value(ssm40_cworst_T) "1.069"
set dmsa_derate_data_net_early_value(ssm40_cworst_T) "1"
set dmsa_derate_data_net_late_value(ssm40_cworst_T) "1.06"
set dmsa_derate_clk_net_early_value(ssm40_cworst_T) "0.94"
set dmsa_derate_clk_net_late_value(ssm40_cworst_T) "1.06"

set dmsa_derate_clock_early_value(ssm40_rcworst_T) "0.937"
set dmsa_derate_clock_late_value(ssm40_rcworst_T) "1.02"
set dmsa_derate_data_early_value(ssm40_rcworst_T) "1"
set dmsa_derate_data_late_value(ssm40_rcworst_T) "1.069"
set dmsa_derate_data_net_early_value(ssm40_rcworst_T) "1"
set dmsa_derate_data_net_late_value(ssm40_rcworst_T) "1.06"
set dmsa_derate_clk_net_early_value(ssm40_rcworst_T) "0.94"
set dmsa_derate_clk_net_late_value(ssm40_rcworst_T) "1.06"

set dmsa_derate_clock_early_value(ss125_cworst_T) "0.937"
set dmsa_derate_clock_late_value(ss125_cworst_T) "1.02"
set dmsa_derate_data_early_value(ss125_cworst_T) "1"
set dmsa_derate_data_late_value(ss125_cworst_T) "1.069"
set dmsa_derate_data_net_early_value(ss125_cworst_T) "1"
set dmsa_derate_data_net_late_value(ss125_cworst_T) "1.06"
set dmsa_derate_clk_net_early_value(ss125_cworst_T) "0.94"
set dmsa_derate_clk_net_late_value(ss125_cworst_T) "1.06"

set dmsa_derate_clock_early_value(ss125_rcworst_T) "0.937"
set dmsa_derate_clock_late_value(ss125_rcworst_T) "1.02"
set dmsa_derate_data_early_value(ss125_rcworst_T) "1"
set dmsa_derate_data_late_value(ss125_rcworst_T) "1.069"
set dmsa_derate_data_net_early_value(ss125_rcworst_T) "1"
set dmsa_derate_data_net_late_value(ss125_rcworst_T) "1.06"
set dmsa_derate_clk_net_early_value(ss125_rcworst_T) "0.94"
set dmsa_derate_clk_net_late_value(ss125_rcworst_T) "1.06"

set dmsa_derate_clock_early_value(ssm40_cworst) "0.892"
set dmsa_derate_clock_late_value(ssm40_cworst) "1.032"
set dmsa_derate_data_early_value(ssm40_cworst) "0.827"
set dmsa_derate_data_late_value(ssm40_cworst) "1"
set dmsa_derate_data_net_early_value(ssm40_cworst) "0.915"
set dmsa_derate_data_net_late_value(ssm40_cworst) "1"
set dmsa_derate_clk_net_early_value(ssm40_cworst) "0.915"
set dmsa_derate_clk_net_late_value(ssm40_cworst) "1"

set dmsa_derate_clock_early_value(ssm40_rcworst) "0.892"
set dmsa_derate_clock_late_value(ssm40_rcworst) "1.032"
set dmsa_derate_data_early_value(ssm40_rcworst) "0.827"
set dmsa_derate_data_late_value(ssm40_rcworst) "1"
set dmsa_derate_data_net_early_value(ssm40_rcworst) "0.915"
set dmsa_derate_data_net_late_value(ssm40_rcworst) "1"
set dmsa_derate_clk_net_early_value(ssm40_rcworst) "0.915"
set dmsa_derate_clk_net_late_value(ssm40_rcworst) "1"

set dmsa_derate_clock_early_value(ssm40_rcbest) "0.892"
set dmsa_derate_clock_late_value(ssm40_rcbest) "1.032"
set dmsa_derate_data_early_value(ssm40_rcbest) "0.827"
set dmsa_derate_data_late_value(ssm40_rcbest) "1"
set dmsa_derate_data_net_early_value(ssm40_rcbest) "0.915"
set dmsa_derate_data_net_late_value(ssm40_rcbest) "1"
set dmsa_derate_clk_net_early_value(ssm40_rcbest) "0.915"
set dmsa_derate_clk_net_late_value(ssm40_rcbest) "1"

set dmsa_derate_clock_early_value(ss125_cworst) "0.892"
set dmsa_derate_clock_late_value(ss125_cworst) "1.032"
set dmsa_derate_data_early_value(ss125_cworst) "0.827"
set dmsa_derate_data_late_value(ss125_cworst) "1"
set dmsa_derate_data_net_early_value(ss125_cworst) "0.915"
set dmsa_derate_data_net_late_value(ss125_cworst) "1"
set dmsa_derate_clk_net_early_value(ss125_cworst) "0.915"
set dmsa_derate_clk_net_late_value(ss125_cworst) "1"

set dmsa_derate_clock_early_value(ss125_rcworst) "0.892"
set dmsa_derate_clock_late_value(ss125_rcworst) "1.032"
set dmsa_derate_data_early_value(ss125_rcworst) "0.827"
set dmsa_derate_data_late_value(ss125_rcworst) "1"
set dmsa_derate_data_net_early_value(ss125_rcworst) "0.915"
set dmsa_derate_data_net_late_value(ss125_rcworst) "1"
set dmsa_derate_clk_net_early_value(ss125_rcworst) "0.915"
set dmsa_derate_clk_net_late_value(ss125_rcworst) "1"

set dmsa_derate_clock_early_value(ss125_rcbest) "0.892"
set dmsa_derate_clock_late_value(ss125_rcbest) "1.032"
set dmsa_derate_data_early_value(ss125_rcbest) "0.827"
set dmsa_derate_data_late_value(ss125_rcbest) "1"
set dmsa_derate_data_net_early_value(ss125_rcbest) "0.915"
set dmsa_derate_data_net_late_value(ss125_rcbest) "1"
set dmsa_derate_clk_net_early_value(ss125_rcbest) "0.915"
set dmsa_derate_clk_net_late_value(ss125_rcbest) "1"

set dmsa_derate_clock_early_value(ffm40_cworst) "0.963"
set dmsa_derate_clock_late_value(ffm40_cworst) "1.093"
set dmsa_derate_data_early_value(ffm40_cworst) "0.879"
set dmsa_derate_data_late_value(ffm40_cworst) "1"
set dmsa_derate_data_net_early_value(ffm40_cworst) "0.915"
set dmsa_derate_data_net_late_value(ffm40_cworst) "1"
set dmsa_derate_clk_net_early_value(ffm40_cworst) "0.915"
set dmsa_derate_clk_net_late_value(ffm40_cworst) "1.085"

set dmsa_derate_clock_early_value(ffm40_rcworst) "0.963"
set dmsa_derate_clock_late_value(ffm40_rcworst) "1.093"
set dmsa_derate_data_early_value(ffm40_rcworst) "0.879"
set dmsa_derate_data_late_value(ffm40_rcworst) "1"
set dmsa_derate_data_net_early_value(ffm40_rcworst) "0.915"
set dmsa_derate_data_net_late_value(ffm40_rcworst) "1"
set dmsa_derate_clk_net_early_value(ffm40_rcworst) "0.915"
set dmsa_derate_clk_net_late_value(ffm40_rcworst) "1.085"

set dmsa_derate_clock_early_value(ffm40_rcbest) "0.963"
set dmsa_derate_clock_late_value(ffm40_rcbest) "1.093"
set dmsa_derate_data_early_value(ffm40_rcbest) "0.879"
set dmsa_derate_data_late_value(ffm40_rcbest) "1"
set dmsa_derate_data_net_early_value(ffm40_rcbest) "0.915"
set dmsa_derate_data_net_late_value(ffm40_rcbest) "1"
set dmsa_derate_clk_net_early_value(ffm40_rcbest) "0.915"
set dmsa_derate_clk_net_late_value(ffm40_rcbest) "1.085"

set dmsa_derate_clock_early_value(ffm40_cbest) "0.963"
set dmsa_derate_clock_late_value(ffm40_cbest) "1.093"
set dmsa_derate_data_early_value(ffm40_cbest) "0.879"
set dmsa_derate_data_late_value(ffm40_cbest) "1"
set dmsa_derate_data_net_early_value(ffm40_cbest) "0.915"
set dmsa_derate_data_net_late_value(ffm40_cbest) "1"
set dmsa_derate_clk_net_early_value(ffm40_cbest) "0.915"
set dmsa_derate_clk_net_late_value(ffm40_cbest) "1.085"

set dmsa_derate_clock_early_value(ff125_cworst) "0.963"
set dmsa_derate_clock_late_value(ff125_cworst) "1.093"
set dmsa_derate_data_early_value(ff125_cworst) "0.879"
set dmsa_derate_data_late_value(ff125_cworst) "1"
set dmsa_derate_data_net_early_value(ff125_cworst) "0.915"
set dmsa_derate_data_net_late_value(ff125_cworst) "1"
set dmsa_derate_clk_net_early_value(ff125_cworst) "0.915"
set dmsa_derate_clk_net_late_value(ff125_cworst) "1.085"

set dmsa_derate_clock_early_value(ff125_rcworst) "0.963"
set dmsa_derate_clock_late_value(ff125_rcworst) "1.093"
set dmsa_derate_data_early_value(ff125_rcworst) "0.879"
set dmsa_derate_data_late_value(ff125_rcworst) "1"
set dmsa_derate_data_net_early_value(ff125_rcworst) "0.915"
set dmsa_derate_data_net_late_value(ff125_rcworst) "1"
set dmsa_derate_clk_net_early_value(ff125_rcworst) "0.915"
set dmsa_derate_clk_net_late_value(ff125_rcworst) "1.085"

set dmsa_derate_clock_early_value(ff125_cbest) "0.963"
set dmsa_derate_clock_late_value(ff125_cbest) "1.093"
set dmsa_derate_data_early_value(ff125_cbest) "0.879"
set dmsa_derate_data_late_value(ff125_cbest) "1"
set dmsa_derate_data_net_early_value(ff125_cbest) "0.915"
set dmsa_derate_data_net_late_value(ff125_cbest) "1"
set dmsa_derate_clk_net_early_value(ff125_cbest) "0.915"
set dmsa_derate_clk_net_late_value(ff125_cbest) "1.085"

set dmsa_derate_clock_early_value(ff125_rcbest) "0.963"
set dmsa_derate_clock_late_value(ff125_rcbest) "1.093"
set dmsa_derate_data_early_value(ff125_rcbest) "0.879"
set dmsa_derate_data_late_value(ff125_rcbest) "1"
set dmsa_derate_data_net_early_value(ff125_rcbest) "0.915"
set dmsa_derate_data_net_late_value(ff125_rcbest) "1"
set dmsa_derate_clk_net_early_value(ff125_rcbest) "0.915"
set dmsa_derate_clk_net_late_value(ff125_rcbest) "1.085"

set dmsa_derate_clock_early_value(ff0_cworst) "0.963"
set dmsa_derate_clock_late_value(ff0_cworst) "1.093"
set dmsa_derate_data_early_value(ff0_cworst) "0.879"
set dmsa_derate_data_late_value(ff0_cworst) "1"
set dmsa_derate_data_net_early_value(ff0_cworst) "0.915"
set dmsa_derate_data_net_late_value(ff0_cworst) "1"
set dmsa_derate_clk_net_early_value(ff0_cworst) "0.915"
set dmsa_derate_clk_net_late_value(ff0_cworst) "1.085"

set dmsa_derate_clock_early_value(ff0_rcworst) "0.963"
set dmsa_derate_clock_late_value(ff0_rcworst) "1.093"
set dmsa_derate_data_early_value(ff0_rcworst) "0.879"
set dmsa_derate_data_late_value(ff0_rcworst) "1"
set dmsa_derate_data_net_early_value(ff0_rcworst) "0.915"
set dmsa_derate_data_net_late_value(ff0_rcworst) "1"
set dmsa_derate_clk_net_early_value(ff0_rcworst) "0.915"
set dmsa_derate_clk_net_late_value(ff0_rcworst) "1.085"

set dmsa_derate_clock_early_value(ff0_cbest) "0.963"
set dmsa_derate_clock_late_value(ff0_cbest) "1.093"
set dmsa_derate_data_early_value(ff0_cbest) "0.879"
set dmsa_derate_data_late_value(ff0_cbest) "1"
set dmsa_derate_data_net_early_value(ff0_cbest) "0.915"
set dmsa_derate_data_net_late_value(ff0_cbest) "1"
set dmsa_derate_clk_net_early_value(ff0_cbest) "0.915"
set dmsa_derate_clk_net_late_value(ff0_cbest) "1.085"

set dmsa_derate_clock_early_value(ff0_rcbest) "0.963"
set dmsa_derate_clock_late_value(ff0_rcbest) "1.093"
set dmsa_derate_data_early_value(ff0_rcbest) "0.879"
set dmsa_derate_data_late_value(ff0_rcbest) "1"
set dmsa_derate_data_net_early_value(ff0_rcbest) "0.915"
set dmsa_derate_data_net_late_value(ff0_rcbest) "1"
set dmsa_derate_clk_net_early_value(ff0_rcbest) "0.915"
set dmsa_derate_clk_net_late_value(ff0_rcbest) "1.085"


# Set the number of hosts and licenses to number of dmsa_corners * number of dmsa_modes
set dmsa_num_of_hosts [expr [llength $dmsa_corners] * [llength $dmsa_modes]]
set dmsa_num_of_licenses [expr [llength $dmsa_corners] * [llength $dmsa_modes]]


######################################
# Fix ECO DRC Setup
######################################
# specify a list of allowable buffers to use for fixing drc
# eg set eco_drc_buf_list "BUF4 BUF8 BUF12"
set eco_drc_buf_list ""

######################################
# Fix ECO Timing Setup
######################################
# specify a list of allowable buffers to use for fixing hold
# eg set eco_hold_buf_list "DEL1 DEL2 DEL4"
set eco_hold_buf_list "BUFFD4BWP7T35P140 BUFFD6BWP7T35P140 BUFFD8BWP7T35P140"

######################################
# End
######################################

### End of PrimeTime Runtime Variables ###
puts "RM-Info: Completed script [info script]\n"

