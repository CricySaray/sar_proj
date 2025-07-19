#!/bin/csh

unset view_from
unset view_rpt

setenv view_from V1127_S1127_FP1127_xxx
setenv view_rpt  V1127_S1127_FP1127_xxx

####==========================================================####
#### input file 
####==========================================================####
setenv top                "lb_se_tm_top"
setenv pt_mode            "func scan funcasyn" ;# mode list
setenv corner             "wcz_cworst_t_setup"
setenv liblist            "/eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/backend/be8803/scripts/.lib_setup.tcl"
setenv netlist_list       "/eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/archive_fullmask/chip_top_idp/dsn/fe_release/ICT8810fullmaskNV1.0.0_SYN/netlist/lb_se_tm_top/lb_se_tm_top.scan.default.vg.gz"
setenv func_sdc           "/eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/backend/be8801/chip_top_idp/sub_proj/pp_top/pr_invs/work/pp_top.func.pt_write.sdc"
setenv scan_sdc           "/eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/archive_fullmask/chip_top_idp/dsn/fe_release/ICT8810fullmaskNV1.0.0_SYN/netlist/lb_se_tm_top/sdc/lb_se_tm_top.scan.pt_write.sdc"
setenv funcasyn_sdc       "/eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/archive_fullmask/chip_top_idp/dsn/fe_release/ICT8810fullmaskNV1.0.0_SYN/netlist/pp_top/sdc/pp_top.async.func.sdc"
setenv dont_touch_and_size_only_file    "/eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/archive_fullmask/chip_top_idp/dsn/fe_release/ICT8810fullmaskNV1.0.0_SYN/netlist/lb_se_tm_top/lb_se_tm_top.dont_touch.list"
setenv dont_use_cells    "INV*SGCAP* BUF*SGCAP* FRICG* DFF*QL_* DFF*QNL_* SDFF*QL_* SDFF*QNL_* SDFFQH* SDFFQNH* SDFFRPQH* SDFFRPQNH* SDFFSQH* SDFFSQNH* SDFFSRPQH* SDFFY* *DRFF* HEAD* FOOT* *X0* *DLY* SDFFX* XOR3* XNOR3* *ECO* *ZTL* *ZTEH* *ZTUH* *ZTUL* *ISO* *LVL* *G33* A    NTENNA* *AND*_X11* *AND*_X8* *AO21A1AI2_X8* *AOI21B_X8* *AOI21_X11* *AOI21_X8* *AOI22BB_X8* *AOI22_X11* *AOI22_X8* *AOI2XB1_X8* *AOI31_X8* *ENDCAP FILL* GP* MXGL* OA*_X8* OR*_X11* NOR*_X11* OR*_X8* NOR*_X8* *_X20* *QN* ICT_CDMSTD"
setenv extra_db           ""
setenv netlist_version    "A7P" ;# 7T : A7P  9T : A9P
setenv black_boxes        false
setenv cell_vt_group      "HVT *ZTH_* SVT *ZTS_* LVT *ZTL_* uLVT *ZTUL_*"
setenv buffer_cell        "BUF_*"
setenv inv_cell           "INV_*"


mkdir -p ../log/initchk/$view_rpt
foreach mode ($pt_mode)
    setenv session      ${top}.${mode}_${corner}
    setenv MODE         $mode
    xterm -T "${top}:initchk:${session}" -e '/eda_tools/synopsys/prime/Q-2019.12-SP5/bin/pt_shell -file ../scr/initchk_pt.tcl | tee  ../log/initchk/${view_rpt}/${session}/run.log' &
end
