puts "RM-Info: Running script [info script]\n"

##########################################################################################
# Variables common to all reference methodology scripts
# Script: common_setup.tcl
# Version: Q-2019.12-SP4 (July 20, 2020)
# Copyright (C) 2007-2020 Synopsys, Inc. All rights reserved.
##########################################################################################
#######################add for FE
set POST_STA 1 

####### hyper flow option 
  set char_context 0
  set create_block_context 0
  set block_context  0 
  set HS_BLK    {  lb_cpu lb_dsp lb_lte_modem_top aon_top  sby_top }

############
set DESIGN_REF_DATA_PATH          ""  ;#  Absolute path prefix variable for library/design data.
                                       #  Use this variable to prefix the common absolute path  
                                       #  to the common variables defined below.
                                       #  Absolute paths are mandatory for hierarchical 
                                       #  reference methodology flow.

##########################################################################################
# Hierarchical Flow Design Variables
##########################################################################################

set HIERARCHICAL_DESIGNS           "" ;# List of hierarchical block design names "DesignA DesignB" ...
set HIERARCHICAL_CELLS             "" ;# List of hierarchical block cell instance names "u_DesignA u_DesignB" ...

##########################################################################################
# Library Setup Variables
##########################################################################################

# For the following variables, use a blank space to separate multiple entries.
# Example: set TARGET_LIBRARY_FILES "lib1.db lib2.db lib3.db"

set ADDITIONAL_SEARCH_PATH        ""  ;#  Additional search path to be added to the default search path

set TARGET_LIBRARY_FILES          ""  ;#  Target technology logical libraries
set ADDITIONAL_LINK_LIB_FILES     ""  ;#  Extra link logical libraries not included in TARGET_LIBRARY_FILES

set MIN_LIBRARY_FILES             ""  ;#  List of max min library pairs "max1 min1 max2 min2 max3 min3"...

set MW_REFERENCE_LIB_DIRS         ""  ;#  Milkyway reference libraries (include IC Compiler ILMs here)

set MW_REFERENCE_CONTROL_FILE     ""  ;#  Reference Control file to define the Milkyway reference libs

set TECH_FILE                     ""  ;#  Milkyway technology file
set MAP_FILE                      ""  ;#  Mapping file for TLUplus
set TLUPLUS_MAX_FILE              ""  ;#  Max TLUplus file
set TLUPLUS_MIN_FILE              ""  ;#  Min TLUplus file

set MIN_ROUTING_LAYER            ""   ;# Min routing layer
set MAX_ROUTING_LAYER            ""   ;# Max routing layer

set LIBRARY_DONT_USE_FILE        ""   ;# Tcl file with library modifications for dont_use

##########################################################################################
# Multivoltage Common Variables
#
# Define the following multivoltage common variables for the reference methodology scripts 
# for multivoltage flows. 
# Use as few or as many of the following definitions as needed by your design.
##########################################################################################

set PD1                          ""           ;# Name of power domain/voltage area  1
set VA1_COORDINATES              {}           ;# Coordinates for voltage area 1
set MW_POWER_NET1                "VDD1"       ;# Power net for voltage area 1

set PD2                          ""           ;# Name of power domain/voltage area  2
set VA2_COORDINATES              {}           ;# Coordinates for voltage area 2
set MW_POWER_NET2                "VDD2"       ;# Power net for voltage area 2

set PD3                          ""           ;# Name of power domain/voltage area  3
set VA3_COORDINATES              {}           ;# Coordinates for voltage area 3
set MW_POWER_NET3                "VDD3"       ;# Power net for voltage area 3

set PD4                          ""           ;# Name of power domain/voltage area  4
set VA4_COORDINATES              {}           ;# Coordinates for voltage area 4
set MW_POWER_NET4                "VDD4"       ;# Power net for voltage area 4

############################################################################################






set  DESIGN_NAME lb_cpu_top
set sdc_func "/eda_files/proj/ict8810/archive/chip_top_sdp/dsn/fe_release/SDP_240414/netlist/lb_cpu_top/sdc/lb_cpu_top.func.pt_write.sdc" 
set sdc_func1 ""

set sdc_scan "" 
set sdc_cdc "" 
set sdc_func2 ""  
set sdc_func3 ""  

set full_chip 0 
set all_blocks "" 
set sdc_func "/eda_files/proj/ict8810/archive/chip_top_sdp/dsn/fe_release/SDP_240414/netlist/lb_cpu_top/sdc/lb_cpu_top.func.pt_write.sdc" 
set sdc_scan "" 
set sdc_cdc "" 
set sdc_func1 "/eda_files/proj/ict8810/archive/chip_top_sdp/dsn/fe_release/SDP_240414/netlist/lb_cpu_top/sdc/lb_cpu_top.scan.pt_write.sdc"
set sdc_func2 ""  
set sdc_func3 ""  
set full_chip 0 
set all_blocks "" 
set  DESIGN_NAME lb_cpu_top
set  Quen I8100_STA
