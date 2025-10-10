puts "RM-Info: Running script [info script]\n"
##################################################################
#    Preparation Before ECO Fixing                               #
##################################################################
remote_execute {
set search_path $search_path
echo $search_path
echo $link_path
}

remote_execute {
#set_false_path -from SCK -to spi0/spi_pi/synch/sync2/sync_STDINSFIX/D -hold
## size cell only when pin names and logic function are both match
set eco_strict_pin_name_equivalence true
set eco_alternative_area_ratio_threshold 1.5
## specify dont_touch elements
#set_dont_touch [get_cells -hier -filter "is_pad_cell==true && is_hierarchical==false"]
set_dont_touch [get_nets -of [get_ports *] -segments]

# deng add #

set_dont_use [get_lib_cells */*LVT */*D0BWP* */*D1BWP* */*D20BWP*  */ISOSR* */PT*  */HDRSI*] true

## specify dont_use elements
#source -echo pt_dont_use.tcl
#set power_enable_analysis true
#source -echo fixecopower.tcl
#define_user_attribute -type string -class lib_cell vt_swap_priority
#foreach_in_collection lcell [get_lib_cells */SVN_*] {
#  regsub -all {SVN_} [get_attribute   $lcell base_name] "" ftprt
#  set_user_attribute $lcell vt_swap_priority $ftprt
# }
#foreach_in_collection lcell [get_lib_cells */SVL_*] {
#  regsub -all {SVL_} [get_attribute   $lcell base_name] "" ftprt
#  set_user_attribute $lcell vt_swap_priority $ftprt
# }
#
#set eco_alternative_cell_attribute_restrictions vt_swap_priority
#
#
 }


set eco_strict_pin_name_equivalence true
set eco_alternative_area_ratio_threshold 1.5
#################################################################
remote_execute {
		set_dont_use "*/*D0BWP* */*D20BWP*"
		}
remote_execute {
define_user_attribute vt_group -type string -classes lib_cell
set_user_attribute [get_lib_cell */*LVT] vt_group lvt
set_user_attribute [get_lib_cell */*HVT] vt_group hvt
set_user_attribute [get_lib_cell */*35P140] vt_group svt
set eco_alternative_cell_attribute_restrictions "vt_group"
}
fix_eco_power -setup_margin 0.05 -verbose

set time_clock [clock format [clock seconds] -format "%Y%m%d_%H%M%S"]
set eco_instance_name_prefix eco_pt_setup_${time_clock}
set eco_net_name_prefix eco_pt_setup_net_${time_clock}
fix_eco_timing -type setup -method {size_cell} -cell_type combinational -slack_lesser_than 0 -hold_margin 0.05 
set eco_instance_name_prefix eco_pt_hold_${time_clock}
set eco_net_name_prefix eco_pt_hold_net_${time_clock}
fix_eco_timing -type hold -method {insert_buffer_at_load_pins size_cell} -verbose -buffer_list {BUFFD1BWP7T40P140HVT BUFFD2BWP7T40P140HVT} -slack_lesser_than 0 -setup_margin 0.05
write_changes -format text -output ./eco_changes.txti

##################################################################
#    Fix ECO DRC Section                                         #
##################################################################

set link_path "*"

## echo "DRC ECO Fixing Starting"
## comment it if there is no max_tran violation
#fix_eco_drc -type max_transition -method {size_cell insert_buffer} -verbose -buffer_list $eco_drc_buf_list
#fix_eco_drc -type max_transition -method size_cell -verbose

## comment it if there is no max_cap violation
#fix_eco_drc -type max_capacitance -method {size_cell insert_buffer} -verbose -buffer_list $eco_drc_buf_list

## echo "DRC ECO Fixing Stop"

##################################################################
#    Fix ECO Timing Section                                      #
##################################################################
## echo "Timing ECO Fixing Starting"
## comment it if there is no setup violation
#set time_clock [clock format [clock seconds] -format "%Y%m%d_%H%M%S"]
#set eco_instance_name_prefix eco_pt_hold_${time_clock}
#set eco_net_name_prefix eco_pt_hold_net_${time_clock}
#fix_eco_timing -type hold -method {insert_buffer_at_load_pins size_cell} -verbose -buffer_list {BUFFD1BWP7T40P140HVT BUFFD2BWP7T40P140HVT} -slack_lesser_than 0 -setup_margin 0.05
############
#fix_eco_timing -type setup -method {size_cell} -verbose -slack_lesser_than 0
#fix_eco_timing -type setup -method {size_cell} -cell_type combinational -slack_lesser_than 0 -hold_margin 0 -setup_margin 0 
#fix_eco_leakage -pattern_priority {HVT RVT}  -attribute vtvt -setup_margin 0.2
#fix_eco_timing -type hold -verbose -buffer_list $eco_hold_buf_list -slack_lesser_than 0 -hold_margin 0.05 -setup_margin 0.06
#fix_eco_timing -type hold -method {insert_buffer_at_load_pins} -verbose -buffer_list $eco_hold_buf_list -slack_lesser_than 0 -setup_margin 0.05
#fix_eco_timing -type hold -method {insert_buffer} -verbose -buffer_list $eco_hold_buf_list -slack_lesser_than 0

## echo "Timing ECO Fixing Stop"
##################################################################
#    Fix ECO Output Section                                      #
##################################################################
#remote_execute {
#write_changes -format icc2tcl -output $RESULTS_DIR/eco_changes.icc
#write_changes -format text -output $RESULTS_DIR/eco_changes.txt
#}


#puts "RM-Info: Completed script [info script]\n"

