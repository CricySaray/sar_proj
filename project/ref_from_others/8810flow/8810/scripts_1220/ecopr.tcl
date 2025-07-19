set view_name     V0303_S0303_FP0222_030301init
set out_view_name V0303_S0303_FP0222_030301init
#source ../scr/user_var.csh
source ../scr/setup.invs
#source ../scr/DI.tcl
source ../scr/util/proc
#setNanoRouteMode -routeWithViaInPin 1:1
#setNanoRouteMode -droutePostRouteSwapVia false
#setNanoRouteMode -routeWithEco true

#setEcoMode -honorDontTouch false -honorFixedStatus true -updateTiming false -honorDontUse false -honorPowerIntent true -prefixName ECOTIMING_${view_name}_ -refinePlace false 
#setNanoRouteMode -routeBottomRoutingLayer 2 
#setNanoRouteMode -routeTopRoutingLayer $vars(max_route_layer)
#setNanoRouteMode -routeWithTimingDriven false
#setNanoRouteMode -dbViaWeight $vars(via_weight)
#setNanoRouteMode -routeConcurrentMinimizeViaCountEffort high
#setNanoRouteMode -drouteVerboseViolationSummary 1
#setNanoRouteMode -routeWithViaInPin true
#setNanoRouteMode -routeWithViaInPin 1:1
#setNanoRouteMode -droutePostRouteSwapVia false
#setNanoRouteMode -routeWithEco true

#loadECO /eda_files/proj/ict7900/mun/chip_top_fdp/sub_proj/lb_rf_serdes_top/dsn/eco/xtop_opt_innovus_V0602_1_netlist_lb_rf_serdes_top.txt
#loadECO /eda_files/proj/ict5100/backend/mun/chip_top_fdp/sub_proj/lb_cpu_top/dsn/eco/xtop_opt_innovus_atomic_${view_name}_netlist_lb_cpu_top.txt
#source /eda_files/proj/ict2210/backend/mun/chip_top_sdp/sub_proj/n300_ps_cpu_top/dsn/eco/xtop_opt_innovus_atomic_${view_name}_netlist_n300_ps_cpu_top.txt
#source /eda_files/proj/ict2210/backend/mun/chip_top_sdp/sub_proj/n300_ps_cpu_top/dsn/eco/xtop_opt_innovus_atomic_${view_name}_physical_n300_ps_cpu_top.txt
#source /eda_files/proj/ict2210/backend/wenjiezhang/chip_top_tdp/sub_proj/chip_top/sta_pt/Version_${view_name}/PT_ECO/eco_${view_name}/innovus_ecooutput/n300_ps_cpu_top_innovus_v1_eco_${view_name}.tcl
deleteEmptyModule
deleteAllCellPad
deleteInstPad -all
#setPlaceMode -place_hard_fence false
#deleteFiller -prefix CHIPCORE_SPARE
#deleteFiller -prefix CHIPCORE_DECAP
#deleteFiller -prefix FILL
#refinePlace
##checkPlace refinePlace
#ecoRoute

#source ../scr/add_decap_core.tcl

#userSaveDesign  -view $out_view_name -type all -pwr_net "vdd_pd_08" -gnd_net "vss"
source /eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/backend/be8803/share/leon_share/genDummyBlk.tcl 
#source /eda_files/proj/ict8810/backend/be8805/chip_top_fdp/sub_proj/lb_ddr4_top/pr_invs/scr_9T/add_filler.tcl
#userSaveDesign -addFiller

#deleteCellPad *
#deleteInstPad -all
#deleteFiller -prefix DCAP_FILL
#deleteFiller -prefix FILL
#refinePlace
#checkPlace
#selectInst [dbget [dbget top.insts.pStatus placed -p].name]
#dbSet selected.pStatus fixed
#deselectAll

#ecoRoute
#saveDesign ../db/$vars(design).$view_name.enc




userSaveDesign  -view $out_view_name -type pv -pwr_net "vdd09" -gnd_net "vss" -addfiller
#userSaveDesign  -view $out_view_name -type pv -pwr_net "vdd09" -gnd_net "vss" -addfiller
#saveDesign ../db/$vars(design).addfiller_$view_name.enc

##
