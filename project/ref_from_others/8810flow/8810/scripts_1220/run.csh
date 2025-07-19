#!/bin/csh

unset view_from
unset view_rpt

setenv view_from V0126_S0128_FP021901_021901
setenv view_rpt  V0126_S0128_FP021901_021901

setenv design              lb_cpu_top
setenv top_or_block        block
setenv timing_cri_mode     true
setenv cong_cri_mode       false
setenv scan_reoder_mode    true
setenv cellPad_mode        true
setenv simplify_mode       true
setenv userfulSkew_mode    true
setenv cts_swap_ff_mode    false
setenv leakage_opt_mode    true
setenv cts_hold_fix_mode   false
setenv merge_ffs           false
setenv ccopt_shiled_mode   true
setenv feed_through        false
setenv use_lvt             false
 
setenv netlist             "/eda_files/proj/ict8810/swap/to_vct/syn_develop/lb_cpu_top_arm_syn/lb_cpu_top.synthesis.v.gz"
setenv sdc_func            ""
setenv sdc_funcasyn        ""
setenv sdc_scan            ""
setenv func_dontch_list    "/eda_files/proj/ict8810/swap/to_vct/syn_develop/lb_cpu_top_arm_syn/lb_cpu_top.dont_touch.list"
setenv scan_def            ""
setenv fp_def              "/eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/backend/be8803/chip_top_sdp/sub_proj/lb_cpu_top/dsn/def/lb_cpu_top.floorplan.fp.V0126_S0128_FP020701_020701.def"

bsub -Ip -q  I8810_PR /eda_tools/cadence/INNOVUS_1917/bin/innovus -files ../scr/floorplan.invs.tcl -log ../log/floorplan_${view_rpt}.log -execute "stty columns 279; stty rows 25"
bsub -Ip -q  I8810_PR /eda_tools/cadence/INNOVUS_1917/bin/innovus -files ../scr/init.invs.tcl -log ../log/init_${view_rpt}.log -execute "stty columns 279; stty rows 25"
bsub -Ip -q  I8810_PR /eda_tools/cadence/INNOVUS_1917/bin/innovus -files ../scr/place.invs.tcl -log ../log/place_${view_rpt}.log -execute "stty columns 279; stty rows 25"
bsub -Ip -q  I8810_PR /eda_tools/cadence/INNOVUS_1917/bin/innovus -files ../scr/cts.invs.tcl -log ../log/cts_${view_rpt}.log -execute "stty columns 279; stty rows 25"
bsub -Ip -q  I8810_PR /eda_tools/cadence/INNOVUS_1917/bin/innovus -files ../scr/route.invs.tcl -log ../log/route_${view_rpt}.log -execute "stty columns 279; stty rows 25"
bsub -Ip -q  I8810_PR /eda_tools/cadence/INNOVUS_1917/bin/innovus -files ../scr/postroute.invs.tcl -log ../log/postroute_${view_rpt}.log -execute "stty columns 279; stty rows 25"
#bsub -Ip -q  I8810_PR /eda_tools/cadence/INNOVUS_1917/bin/innovus -files ../scr/ecopr.invs.tcl -log ../log/ecopr_${view_rpt}.log -execute "stty columns 279; stty rows 25"
