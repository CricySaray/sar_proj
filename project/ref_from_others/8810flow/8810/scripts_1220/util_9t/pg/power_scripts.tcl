##used for pgr of multi-domain or single domain
##begin time
set t1 [exec date]
#
#################################
###proc
#################################
source ../scr/util/pg/invsAddM1.tcl
source ../scr/util/pg/invsAddM5.tcl
#source ../scr/util/pg/invsFixDrc.tcl
source ../scr/util/pg/invsAddM6.tcl
source ../scr/util/pg/invsAddM7.tcl
source ../scr/util/pg/invsAddM8.tcl
source ../scr/util/pg/invsAddRG.tcl
source ../scr/util/pg/invsAddEnd.tcl
#source ../scr/util/pg/invsAddWell.tcl
source ../scr/util/pg/invsAddMemM5.tcl
source ../scr/util/pg/invsAddMemM6.tcl
source ../scr/util/pg/invsAddCorePSWM5.tcl
source ../scr/util/pg/invsAddPowerSwitch.tcl
source ../scr/util/pg/invsAddChannelM5.tcl
source ../scr/util/userCreateM1FollowPin.tcl
source ../scr/util/proc
#
#################################
###vars
#################################
##core/die info
set core_area [dbGet top.fplan.coreBox]
set die_area [dbGet Top.fplan.box]
set vars(core_x1) [lindex [lindex $core_area 0] 0]
set vars(core_y1) [lindex [lindex $core_area 0] 1]
set vars(core_x2) [lindex [lindex $core_area 0] 2]
set vars(core_y2) [lindex [lindex $core_area 0] 3]
set vars(die_x1) [lindex [lindex $die_area 0] 0]
set vars(die_y1) [lindex [lindex $die_area 0] 1]
set vars(die_x2) [lindex [lindex $die_area 0] 2]
set vars(die_y2) [lindex [lindex $die_area 0] 3]
#
####direction
set vars(m5_direction) Vertical
set vars(m6_direction) Horizontal
set vars(m7_direction) Vertical
set vars(m8_direction) Horizontal
#
#### Power pattern info
set vars(m5_width) 0.68
set vars(m5_pitch) 10
set vars(m5_step) 20
set vars(addm5_width) 0.68
set vars(addm5_pitch) 3
set vars(addm5_step) 6
set vars(m6_width) 8
set vars(m6_pitch) 10
set vars(m6_step) 20
set vars(m7_width) 10
set vars(m7_pitch) 20
set vars(m7_step) 40
set vars(m5psw_width) 1.3
set vars(m5psw_pitch) 1.6
set vars(m5psw_step) 58
set vars(m7psw_width) 1
set vars(m7psw_pitch) 1.3
#
####offset setting
set vars(m5_offset) 0.26
set vars(m6_offset) 4.11
set vars(m7_offset) 0
set vars(m8_offset) 0
set vars(m5mem_offset) $vars(m5_offset)
set vars(m5psw_offset) $vars(m5_offset)
#set vars(m5channel_offset) [expr 2.98 - 0.13 - 0.5/2]
set vars(m5channel_offset) 0.95
#
####start/stop points setting
set vars(m5_start) [expr $vars(core_y1)  + $vars(m5_offset)]
set vars(m5_stop) $vars(core_y2)
set vars(m6_start) [expr $vars(core_y1)  + $vars(m6_offset)]
set vars(m6_stop) $vars(core_y2)
set vars(m7_start) [expr $vars(core_x1)  + $vars(m7_offset)]
set vars(m7_stop) $vars(core_x2)
set vars(m8_start) [expr $vars(core_y1)  + $vars(m8_offset)]
set vars(m8_stop) $vars(core_y2)
set vars(sw_offset) 20
set vars(halo) 2.8
#
#### psw setting
set pgvars(domain) pd_aa
set pgvars(pso_cell) HEADBUFHDV32
set pgvars(channel_pso_cell) HEADBUFHDV32
#the vars below is related with power switch type
set pgvars(channel_placementAdjustX) -1.28
set pgvars(leftOffset) [expr $vars(m5psw_offset) + [dbGet top.fplan.coreBox_llx] +$vars(sw_offset) -$vars(m5psw_step) ]
set pgvars(horizontalPitch) $vars(m5psw_step)
set pgvars(skipRows) 1
set pgvars(enablePortIn) [list  PD_AA_IN] ;
set pgvars(enablePortOut) [list  PD_AA_OUT] ;
set pgvars(channel_skipRows) 1
set pgvars(AON_POWER) VDD ;
set pgvars(AON_POWER_layer) M7 ;
set pgvars(add_pwrsh_option) "-checkerBoard -honorNonRegularPitchStripe -ignoreSoftBlockage -noFixedStdCellOverlap"
set pgvars(channel_add_pwrsh_option) "-honorNonRegularPitchStripe -ignoreSoftBlockage -noFixedStdCellOverlap"
#
###power domain info
set vars(power_domains) [userGetPowerDomains]
#
###addstripeMode setting
setAddStripeMode -stripe_min_length 0
setAddStripeMode -ignore_nondefault_domains 1
setAddStripeMode -use_exact_spacing true
setAddStripeMode -use_point2point_router false
