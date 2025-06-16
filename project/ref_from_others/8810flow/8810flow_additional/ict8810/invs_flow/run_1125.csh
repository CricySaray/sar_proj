#!/bin/csh

unset view_from
unset view_rpt

setenv view_from tmp1125
setenv view_rpt  tmp1125

setenv design              lb_dp_ocb_top
setenv top_or_block        block
setenv timing_cri_mode     false
setenv cong_cri_mode       true
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
 
setenv netlist             "/eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/archive_fullmask/chip_top_idp/dsn/fe_release/ICT8810fullmaskNV1.0.0_SYN/netlist/lb_dp_ocb_top/lb_dp_ocb_top.scan.default.vg.gz"
setenv sdc_func            "/eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/archive_fullmask/chip_top_idp/dsn/fe_release/ICT8810fullmaskNV1.0.0_SYN/netlist/lb_dp_ocb_top/sdc/lb_dp_ocb_top.func.pt_write.sdc"
setenv sdc_funcasyn        "/eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/archive_fullmask/chip_top_idp/dsn/fe_release/ICT8810fullmaskNV1.0.0_SYN/netlist/lb_dp_ocb_top/sdc/lb_dp_ocb_top.async.func.sdc"
setenv sdc_scan            "/eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/archive_fullmask/chip_top_idp/dsn/fe_release/ICT8810fullmaskNV1.0.0_SYN/netlist/lb_dp_ocb_top/sdc/lb_dp_ocb_top.scan.pt_write.sdc"
setenv func_dontch_list    "/eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/archive_fullmask/chip_top_idp/dsn/fe_release/ICT8810fullmaskNV1.0.0_SYN/netlist/lb_dp_ocb_top/lb_dp_ocb_top.dont_touch.list"
setenv scan_def            "/eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/archive_fullmask/chip_top_idp/dsn/fe_release/ICT8810fullmaskNV1.0.0_SYN/netlist/lb_dp_ocb_top/lb_dp_ocb_top.scan.default.def.gz"
setenv fp_def              "/eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/backend/be8803/chip_top_idp/sub_proj/lb_dp_ocb_top/dsn/def/lb_dp_ocb_top.floorplan.fp.tmp1125.def"

/eda_tools/cadence/INNOVUS_1917/bin/innovus -files ../scr/floorplan.invs.tcl -log ../log/floorplan_${view_rpt}.log -execute "stty columns 279; stty rows 25"

/eda_tools/cadence/INNOVUS_1917/bin/innovus -files ../scr/init.invs.tcl -log ../log/init_${view_rpt}.log -execute "stty columns 279; stty rows 25"
/eda_tools/cadence/INNOVUS_1917/bin/innovus -files ../scr/place.invs.tcl -log ../log/place_${view_rpt}.log -execute "stty columns 279; stty rows 25"
/eda_tools/cadence/INNOVUS_1917/bin/innovus -files ../scr/cts.invs.tcl -log ../log/cts_${view_rpt}.log -execute "stty columns 279; stty rows 25"
/eda_tools/cadence/INNOVUS_1917/bin/innovus -files ../scr/route.invs.tcl -log ../log/route_${view_rpt}.log -execute "stty columns 279; stty rows 25"
/eda_tools/cadence/INNOVUS_1917/bin/innovus -files ../scr/postroute.invs.tcl -log ../log/postroute_${view_rpt}.log -execute "stty columns 279; stty rows 25"
