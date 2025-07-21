## user define inputs ##
set BLOCK_OWNER "be2101"
set DESIGN_TOP	"chip_top"
set VIEW "0419_v1"

set dmsa_mode_constraint_files(func) "/eda_files/proj/ict2100/archive/chip_top_fdp/dsn/fe_release/top/flatten_sdc/chip_top.func.default.sdc"
set dmsa_mode_constraint_files(scan) "/eda_files/proj/ict2100/archive/chip_top_fdp/dsn/fe_release/top/flatten_sdc/chip_top.scan.flatten.sdc"
#set MODE "func"; set CORNER "wcl_cworst_t"; set check "setup"
#set MODE "scan"; set CORNER "wcl_cworst_t"; set check "setup"
set MODE "func"; set CORNER "ml_rcworst"  ; set check "hold" 
#set MODE "scan"; set CORNER "ml_rcworst"  ; set check "hold" 
set NETLIST 	"[glob /eda_files/proj/ict2100/backend/zhangwenjie/chip_top_fdp/sub_proj/chip_top/sta_pt/sdf_dsn/gate/*.vg.gz]"
#set SDF     	"/eda_files/proj/ict2100/backend/zhangwenjie/chip_top_fdp/sub_proj/chip_top/dsn/sdf/${DESIGN_TOP}.${MODE}_${CORNER}_${check}.${VIEW}.sdf_v1.gz"
set SDF   "/eda_files/proj/ict2100/backend/zhangwenjie/chip_top_fdp/sub_proj/chip_top/sta_pt/0419_v1_sdf/db/aa.sdf.gz"
#set SDF     	"/eda_files/proj/ict2100/backend/be2101/chip_top_fdp/dsn/sdf/chip_top.func_ml_rcworst_hold.20220302.sdf.gz"
set SDC $dmsa_mode_constraint_files($MODE)
################################



puts "Running  pt constrains analysis at [date] :start"
set sh_source_uses_search_path true
set report_default_significant_digits 3
source /eda_files/proj/ict2100/archive/chip_top_fdp/.lib_setup.tcl.backend
if { $MODE == "scan" } {
	set dmsa_corner_library_files(wcl_cworst)  "$vars(CCSDB_0P8_WCL_LIBS) $vars(CCSDB_0P9_WCL_LIBS) $vars(ROMDB_WCL_LIBS) $vars(RAMDB_WCL_LIBS) $vars(IODB_1P8V0P8V_WCL_LIBS) $vars(IPDB_WCL_CMAX_SCAN_HOLD_LIBS)"
	set dmsa_corner_library_files(wcl_cworst_t)  "$vars(CCSDB_0P8_WCL_LIBS)  $vars(CCSDB_0P9_WCL_LIBS) $vars(ROMDB_WCL_LIBS) $vars(RAMDB_WCL_LIBS) $vars(IODB_1P8V0P8V_WCL_LIBS) $vars(IPDB_WCL_CMAX_T_SCAN_SETUP_LIBS)"
	set dmsa_corner_library_files(wcl_rcworst)  "$vars(CCSDB_0P8_WCL_LIBS)  $vars(CCSDB_0P9_WCL_LIBS) $vars(ROMDB_WCL_LIBS) $vars(RAMDB_WCL_LIBS) $vars(IODB_1P8V0P8V_WCL_LIBS) $vars(IPDB_WCL_RCMAX_SCAN_HOLD_LIBS)"
	set dmsa_corner_library_files(wcl_rcworst_t)  "$vars(CCSDB_0P8_WCL_LIBS)  $vars(CCSDB_0P9_WCL_LIBS) $vars(ROMDB_WCL_LIBS) $vars(RAMDB_WCL_LIBS) $vars(IODB_1P8V0P8V_WCL_LIBS) $vars(IPDB_WCL_RCMAX_T_SCAN_SETUP_LIBS)"

	set dmsa_corner_library_files(wc_cworst)  "$vars(CCSDB_0P8_WC_LIBS)  $vars(CCSDB_0P9_WC_LIBS) $vars(ROMDB_WC_LIBS) $vars(RAMDB_WC_LIBS) $vars(IODB_1P8V0P8V_WC_LIBS) $vars(IPDB_WC_CMAX_SCAN_HOLD_LIBS)"
	set dmsa_corner_library_files(wc_cworst_t)  "$vars(CCSDB_0P8_WC_LIBS)  $vars(CCSDB_0P9_WC_LIBS) $vars(ROMDB_WC_LIBS) $vars(RAMDB_WC_LIBS) $vars(IODB_1P8V0P8V_WC_LIBS) $vars(IPDB_WC_CMAX_T_SCAN_SETUP_LIBS)"
	set dmsa_corner_library_files(wc_rcworst)  "$vars(CCSDB_0P8_WC_LIBS)  $vars(CCSDB_0P9_WC_LIBS) $vars(ROMDB_WC_LIBS) $vars(RAMDB_WC_LIBS) $vars(IODB_1P8V0P8V_WC_LIBS) $vars(IPDB_WC_RCMAX_SCAN_HOLD_LIBS)"
	set dmsa_corner_library_files(wc_rcworst_t)  "$vars(CCSDB_0P8_WC_LIBS)  $vars(CCSDB_0P9_WC_LIBS) $vars(ROMDB_WC_LIBS) $vars(RAMDB_WC_LIBS) $vars(IODB_1P8V0P8V_WC_LIBS) $vars(IPDB_WC_RCMAX_T_SCAN_SETUP_LIBS)"

	set dmsa_corner_library_files(wcz_cworst)  "$vars(CCSDB_0P8_WCZ_LIBS)  $vars(CCSDB_0P9_WCZ_LIBS) $vars(ROMDB_WCZ_LIBS) $vars(RAMDB_WCZ_LIBS) $vars(IODB_1P8V0P8V_WCZ_LIBS) $vars(IPDB_WCZ_CMAX_SCAN_HOLD_LIBS)"
	set dmsa_corner_library_files(wcz_cworst_t)  "$vars(CCSDB_0P8_WCZ_LIBS)  $vars(CCSDB_0P9_WCZ_LIBS) $vars(ROMDB_WCZ_LIBS) $vars(RAMDB_WCZ_LIBS) $vars(IODB_1P8V0P8V_WCZ_LIBS) vars(IPDB_WCZ_CMAX_T_SCAN_SETUP_LIBS)"
	set dmsa_corner_library_files(wcz_rcworst)  "$vars(CCSDB_0P8_WCZ_LIBS)  $vars(CCSDB_0P9_WCZ_LIBS) $vars(ROMDB_WCZ_LIBS) $vars(RAMDB_WCZ_LIBS) $vars(IODB_1P8V0P8V_WCZ_LIBS) vars(IPDB_WCZ_RCMAX_SCAN_HOLD_LIBS)"
	set dmsa_corner_library_files(wcz_rcworst_t)  "$vars(CCSDB_0P8_WCZ_LIBS)  $vars(CCSDB_0P9_WCZ_LIBS) $vars(ROMDB_WCZ_LIBS) $vars(RAMDB_WCZ_LIBS) $vars(IODB_1P8V0P8V_WCZ_LIBS) vars(IPDB_WCZ_RCMAX_T_SCAN_SETUP_LIBS)"

	set dmsa_corner_library_files(ml_cworst)  "$vars(CCSDB_0P8_ML_LIBS)  $vars(CCSDB_0P9_ML_LIBS) $vars(ROMDB_ML_LIBS) $vars(RAMDB_ML_LIBS) $vars(IODB_1P8V0P8V_ML_LIBS) $vars(IPDB_ML_CMAX_SCAN_HOLD_LIBS) "
	set dmsa_corner_library_files(ml_rcworst)  "$vars(CCSDB_0P8_ML_LIBS)  $vars(CCSDB_0P9_ML_LIBS) $vars(ROMDB_ML_LIBS) $vars(RAMDB_ML_LIBS) $vars(IODB_1P8V0P8V_ML_LIBS) vars(IPDB_ML_RCMAX_SCAN_HOLD_LIBS)"
	set dmsa_corner_library_files(ml_cbest)  "$vars(CCSDB_0P8_ML_LIBS)  $vars(CCSDB_0P9_ML_LIBS) $vars(ROMDB_ML_LIBS) $vars(RAMDB_ML_LIBS) $vars(IODB_1P8V0P8V_ML_LIBS) vars(IPDB_ML_CMIN_SCAN_HOLD_LIBS)"
	set dmsa_corner_library_files(ml_rcbest)  "$vars(CCSDB_0P8_ML_LIBS)  $vars(CCSDB_0P9_ML_LIBS) $vars(ROMDB_ML_LIBS) $vars(RAMDB_ML_LIBS) $vars(IODB_1P8V0P8V_ML_LIBS) $vars(IPDB_ML_RCMIN_SCAN_HOLD_LIBS)"

	set dmsa_corner_library_files(lt_cworst)  "$vars(CCSDB_0P8_LT_LIBS)  $vars(CCSDB_0P9_LT_LIBS) $vars(ROMDB_LT_LIBS) $vars(RAMDB_LT_LIBS) $vars(IODB_1P8V0P8V_LT_LIBS) $vars(IPDB_LT_CMAX_SCAN_HOLD_LIBS)"
	set dmsa_corner_library_files(lt_rcworst)  "$vars(CCSDB_0P8_LT_LIBS)  $vars(CCSDB_0P9_LT_LIBS) $vars(ROMDB_LT_LIBS) $vars(RAMDB_LT_LIBS) $vars(IODB_1P8V0P8V_LT_LIBS) $vars(IPDB_LT_RCMAX_SCAN_HOLD_LIBS)"
	set dmsa_corner_library_files(lt_cbest)  "$vars(CCSDB_0P8_LT_LIBS)  $vars(CCSDB_0P9_LT_LIBS) $vars(ROMDB_LT_LIBS) $vars(RAMDB_LT_LIBS) $vars(IODB_1P8V0P8V_LT_LIBS) $vars(IPDB_LT_CMIN_SCAN_HOLD_LIBS)"
	set dmsa_corner_library_files(lt_rcbest)  "$vars(CCSDB_0P8_LT_LIBS)  $vars(CCSDB_0P9_LT_LIBS) $vars(ROMDB_LT_LIBS) $vars(RAMDB_LT_LIBS) $vars(IODB_1P8V0P8V_LT_LIBS) $vars(IPDB_LT_RCMIN_SCAN_HOLD_LIBS)"

	set dmsa_corner_library_files(bc_cworst)  "$vars(CCSDB_0P8_BC_LIBS)  $vars(CCSDB_0P9_BC_LIBS) $vars(ROMDB_BC_LIBS) $vars(RAMDB_BC_LIBS) $vars(IODB_1P8V0P8V_BC_LIBS) $vars(IPDB_BC_CMAX_SCAN_HOLD_LIBS)"
	set dmsa_corner_library_files(bc_rcworst)  "$vars(CCSDB_0P8_BC_LIBS)  $vars(CCSDB_0P9_BC_LIBS) $vars(ROMDB_BC_LIBS) $vars(RAMDB_BC_LIBS) $vars(IODB_1P8V0P8V_BC_LIBS) $vars(IPDB_BC_RCMAX_SCAN_HOLD_LIBS)"
	set dmsa_corner_library_files(bc_cbest)  "$vars(CCSDB_0P8_BC_LIBS)  $vars(CCSDB_0P9_BC_LIBS) $vars(ROMDB_BC_LIBS) $vars(RAMDB_BC_LIBS) $vars(IODB_1P8V0P8V_BC_LIBS) $vars(IPDB_BC_CMIN_SCAN_HOLD_LIBS)"
	set dmsa_corner_library_files(bc_rcbest)  "$vars(CCSDB_0P8_BC_LIBS)  $vars(CCSDB_0P9_BC_LIBS) $vars(ROMDB_BC_LIBS) $vars(RAMDB_BC_LIBS) $vars(IODB_1P8V0P8V_BC_LIBS) $vars(IPDB_BC_RCMIN_SCAN_HOLD_LIBS)"

	set dmsa_corner_library_files(tc_typ25)  "$vars(CCSDB_0P8_TC_LIBS)  $vars(CCSDB_0P9_TC_LIBS) $vars(ROMDB_TC_LIBS) $vars(RAMDB_TC_LIBS) $vars(IODB_1P8V0P8V_TC_LIBS) $vars(IPDB_TC_LIBS)"
} else {

	set dmsa_corner_library_files(wcl_cworst)  "$vars(CCSDB_0P8_WCL_LIBS) $vars(CCSDB_0P9_WCL_LIBS) $vars(ROMDB_WCL_LIBS) $vars(RAMDB_WCL_LIBS) $vars(IODB_1P8V0P8V_WCL_LIBS) $vars(IPDB_WCL_CMAX_FUNC_HOLD_LIBS)"
	set dmsa_corner_library_files(wcl_cworst_t)  "$vars(CCSDB_0P8_WCL_LIBS)  $vars(CCSDB_0P9_WCL_LIBS) $vars(ROMDB_WCL_LIBS) $vars(RAMDB_WCL_LIBS) $vars(IODB_1P8V0P8V_WCL_LIBS) $vars(IPDB_WCL_CMAX_T_FUNC_SETUP_LIBS)"
	set dmsa_corner_library_files(wcl_rcworst)  "$vars(CCSDB_0P8_WCL_LIBS)  $vars(CCSDB_0P9_WCL_LIBS) $vars(ROMDB_WCL_LIBS) $vars(RAMDB_WCL_LIBS) $vars(IODB_1P8V0P8V_WCL_LIBS) $vars(IPDB_WCL_RCMAX_FUNC_HOLD_LIBS)"
	set dmsa_corner_library_files(wcl_rcworst_t)  "$vars(CCSDB_0P8_WCL_LIBS)  $vars(CCSDB_0P9_WCL_LIBS) $vars(ROMDB_WCL_LIBS) $vars(RAMDB_WCL_LIBS) $vars(IODB_1P8V0P8V_WCL_LIBS) $vars(IPDB_WCL_RCMAX_T_FUNC_SETUP_LIBS)"

	set dmsa_corner_library_files(wc_cworst)  "$vars(CCSDB_0P8_WC_LIBS)  $vars(CCSDB_0P9_WC_LIBS) $vars(ROMDB_WC_LIBS) $vars(RAMDB_WC_LIBS) $vars(IODB_1P8V0P8V_WC_LIBS) $vars(IPDB_WC_CMAX_FUNC_HOLD_LIBS)"
	set dmsa_corner_library_files(wc_cworst_t)  "$vars(CCSDB_0P8_WC_LIBS)  $vars(CCSDB_0P9_WC_LIBS) $vars(ROMDB_WC_LIBS) $vars(RAMDB_WC_LIBS) $vars(IODB_1P8V0P8V_WC_LIBS) $vars(IPDB_WC_CMAX_T_FUNC_SETUP_LIBS)"
	set dmsa_corner_library_files(wc_rcworst)  "$vars(CCSDB_0P8_WC_LIBS)  $vars(CCSDB_0P9_WC_LIBS) $vars(ROMDB_WC_LIBS) $vars(RAMDB_WC_LIBS) $vars(IODB_1P8V0P8V_WC_LIBS) $vars(IPDB_WC_RCMAX_FUNC_HOLD_LIBS)"
	set dmsa_corner_library_files(wc_rcworst_t)  "$vars(CCSDB_0P8_WC_LIBS)  $vars(CCSDB_0P9_WC_LIBS) $vars(ROMDB_WC_LIBS) $vars(RAMDB_WC_LIBS) $vars(IODB_1P8V0P8V_WC_LIBS) $vars(IPDB_WC_RCMAX_T_FUNC_SETUP_LIBS)"

	set dmsa_corner_library_files(wcz_cworst)  "$vars(CCSDB_0P8_WCZ_LIBS)  $vars(CCSDB_0P9_WCZ_LIBS) $vars(ROMDB_WCZ_LIBS) $vars(RAMDB_WCZ_LIBS) $vars(IODB_1P8V0P8V_WCZ_LIBS) $vars(IPDB_WCZ_CMAX_FUNC_HOLD_LIBS)"
	set dmsa_corner_library_files(wcz_cworst_t)  "$vars(CCSDB_0P8_WCZ_LIBS)  $vars(CCSDB_0P9_WCZ_LIBS) $vars(ROMDB_WCZ_LIBS) $vars(RAMDB_WCZ_LIBS) $vars(IODB_1P8V0P8V_WCZ_LIBS) $vars(IPDB_WCZ_CMAX_T_FUNC_SETUP_LIBS)"
	set dmsa_corner_library_files(wcz_rcworst)  "$vars(CCSDB_0P8_WCZ_LIBS)  $vars(CCSDB_0P9_WCZ_LIBS) $vars(ROMDB_WCZ_LIBS) $vars(RAMDB_WCZ_LIBS) $vars(IODB_1P8V0P8V_WCZ_LIBS) $vars(IPDB_WCZ_RCMAX_FUNC_HOLD_LIBS)"
	set dmsa_corner_library_files(wcz_rcworst_t)  "$vars(CCSDB_0P8_WCZ_LIBS)  $vars(CCSDB_0P9_WCZ_LIBS) $vars(ROMDB_WCZ_LIBS) $vars(RAMDB_WCZ_LIBS) $vars(IODB_1P8V0P8V_WCZ_LIBS) $vars(IPDB_WCZ_RCMAX_T_FUNC_SETUP_LIBS)"

	set dmsa_corner_library_files(ml_cworst)  "$vars(CCSDB_0P8_ML_LIBS)  $vars(CCSDB_0P9_ML_LIBS) $vars(ROMDB_ML_LIBS) $vars(RAMDB_ML_LIBS) $vars(IODB_1P8V0P8V_ML_LIBS) $vars(IPDB_ML_CMAX_FUNC_HOLD_LIBS) "
	set dmsa_corner_library_files(ml_rcworst)  "$vars(CCSDB_0P8_ML_LIBS)  $vars(CCSDB_0P9_ML_LIBS) $vars(ROMDB_ML_LIBS) $vars(RAMDB_ML_LIBS) $vars(IODB_1P8V0P8V_ML_LIBS) $vars(IPDB_ML_RCMAX_FUNC_HOLD_LIBS)"
	set dmsa_corner_library_files(ml_cbest)  "$vars(CCSDB_0P8_ML_LIBS)  $vars(CCSDB_0P9_ML_LIBS) $vars(ROMDB_ML_LIBS) $vars(RAMDB_ML_LIBS) $vars(IODB_1P8V0P8V_ML_LIBS) $vars(IPDB_ML_CMIN_FUNC_HOLD_LIBS)"
	set dmsa_corner_library_files(ml_rcbest)  "$vars(CCSDB_0P8_ML_LIBS)  $vars(CCSDB_0P9_ML_LIBS) $vars(ROMDB_ML_LIBS) $vars(RAMDB_ML_LIBS) $vars(IODB_1P8V0P8V_ML_LIBS) $vars(IPDB_ML_RCMIN_FUNC_HOLD_LIBS)"

	set dmsa_corner_library_files(lt_cworst)  "$vars(CCSDB_0P8_LT_LIBS)  $vars(CCSDB_0P9_LT_LIBS) $vars(ROMDB_LT_LIBS) $vars(RAMDB_LT_LIBS) $vars(IODB_1P8V0P8V_LT_LIBS) $vars(IPDB_LT_CMAX_FUNC_HOLD_LIBS)"
	set dmsa_corner_library_files(lt_rcworst)  "$vars(CCSDB_0P8_LT_LIBS)  $vars(CCSDB_0P9_LT_LIBS) $vars(ROMDB_LT_LIBS) $vars(RAMDB_LT_LIBS) $vars(IODB_1P8V0P8V_LT_LIBS) $vars(IPDB_LT_RCMAX_FUNC_HOLD_LIBS)"
	set dmsa_corner_library_files(lt_cbest)  "$vars(CCSDB_0P8_LT_LIBS)  $vars(CCSDB_0P9_LT_LIBS) $vars(ROMDB_LT_LIBS) $vars(RAMDB_LT_LIBS) $vars(IODB_1P8V0P8V_LT_LIBS) $vars(IPDB_LT_CMIN_FUNC_HOLD_LIBS)"
	set dmsa_corner_library_files(lt_rcbest)  "$vars(CCSDB_0P8_LT_LIBS)  $vars(CCSDB_0P9_LT_LIBS) $vars(ROMDB_LT_LIBS) $vars(RAMDB_LT_LIBS) $vars(IODB_1P8V0P8V_LT_LIBS) $vars(IPDB_LT_RCMIN_FUNC_HOLD_LIBS)"

	set dmsa_corner_library_files(bc_cworst)  "$vars(CCSDB_0P8_BC_LIBS)  $vars(CCSDB_0P9_BC_LIBS) $vars(ROMDB_BC_LIBS) $vars(RAMDB_BC_LIBS) $vars(IODB_1P8V0P8V_BC_LIBS) $vars(IPDB_BC_CMAX_FUNC_HOLD_LIBS)"
	set dmsa_corner_library_files(bc_rcworst)  "$vars(CCSDB_0P8_BC_LIBS)  $vars(CCSDB_0P9_BC_LIBS) $vars(ROMDB_BC_LIBS) $vars(RAMDB_BC_LIBS) $vars(IODB_1P8V0P8V_BC_LIBS) $vars(IPDB_BC_RCMAX_FUNC_HOLD_LIBS)"
	set dmsa_corner_library_files(bc_cbest)  "$vars(CCSDB_0P8_BC_LIBS)  $vars(CCSDB_0P9_BC_LIBS) $vars(ROMDB_BC_LIBS) $vars(RAMDB_BC_LIBS) $vars(IODB_1P8V0P8V_BC_LIBS) $vars(IPDB_BC_CMIN_FUNC_HOLD_LIBS)"
	set dmsa_corner_library_files(bc_rcbest)  "$vars(CCSDB_0P8_BC_LIBS)  $vars(CCSDB_0P9_BC_LIBS) $vars(ROMDB_BC_LIBS) $vars(RAMDB_BC_LIBS) $vars(IODB_1P8V0P8V_BC_LIBS) $vars(IPDB_BC_RCMIN_FUNC_HOLD_LIBS)"

	set dmsa_corner_library_files(tc_typ25)  "$vars(CCSDB_0P8_TC_LIBS)  $vars(CCSDB_0P9_TC_LIBS) $vars(ROMDB_TC_LIBS) $vars(RAMDB_TC_LIBS) $vars(IODB_1P8V0P8V_TC_LIBS) $vars(IPDB_TC_LIBS)"
}

	set io_3p3v0p8v_dmsa_corner_library_files(wcl_cworst)  "$vars(IODB_3P3V0P8V_WCL_LIBS)"
	set io_3p3v0p8v_dmsa_corner_library_files(wcl_cworst_t)  "$vars(IODB_3P3V0P8V_WCL_LIBS)"
	set io_3p3v0p8v_dmsa_corner_library_files(wcl_rcworst)  "$vars(IODB_3P3V0P8V_WCL_LIBS)"
	set io_3p3v0p8v_dmsa_corner_library_files(wcl_rcworst_t)  "$vars(IODB_3P3V0P8V_WCL_LIBS)"

	set io_3p3v0p8v_dmsa_corner_library_files(wc_cworst)  "$vars(IODB_3P3V0P8V_WC_LIBS)"
	set io_3p3v0p8v_dmsa_corner_library_files(wc_cworst_t)  "$vars(IODB_3P3V0P8V_WC_LIBS)"
	set io_3p3v0p8v_dmsa_corner_library_files(wc_rcworst)  "$vars(IODB_3P3V0P8V_WC_LIBS)"
	set io_3p3v0p8v_dmsa_corner_library_files(wc_rcworst_t)  "$vars(IODB_3P3V0P8V_WC_LIBS)"

	set io_3p3v0p8v_dmsa_corner_library_files(wcz_cworst)  "$vars(IODB_3P3V0P8V_WCZ_LIBS)"
	set io_3p3v0p8v_dmsa_corner_library_files(wcz_cworst_t)  "$vars(IODB_3P3V0P8V_WCZ_LIBS)"
	set io_3p3v0p8v_dmsa_corner_library_files(wcz_rcworst)  "$vars(IODB_3P3V0P8V_WCZ_LIBS)"
	set io_3p3v0p8v_dmsa_corner_library_files(wcz_rcworst_t)  "$vars(IODB_3P3V0P8V_WCZ_LIBS)"

	set io_3p3v0p8v_dmsa_corner_library_files(ml_cworst)  "$vars(IODB_3P3V0P8V_ML_LIBS)"
	set io_3p3v0p8v_dmsa_corner_library_files(ml_rcworst)  "$vars(IODB_3P3V0P8V_ML_LIBS)"
	set io_3p3v0p8v_dmsa_corner_library_files(ml_cbest)  "$vars(IODB_3P3V0P8V_ML_LIBS)"
	set io_3p3v0p8v_dmsa_corner_library_files(ml_rcbest)  "$vars(IODB_3P3V0P8V_ML_LIBS)"

	set io_3p3v0p8v_dmsa_corner_library_files(lt_cworst)  "$vars(IODB_3P3V0P8V_LT_LIBS)"
	set io_3p3v0p8v_dmsa_corner_library_files(lt_rcworst)  "$vars(IODB_3P3V0P8V_LT_LIBS)"
	set io_3p3v0p8v_dmsa_corner_library_files(lt_cbest)  "$vars(IODB_3P3V0P8V_LT_LIBS)"
	set io_3p3v0p8v_dmsa_corner_library_files(lt_rcbest)  "$vars(IODB_3P3V0P8V_LT_LIBS)"

	set io_3p3v0p8v_dmsa_corner_library_files(bc_cworst)  "$vars(IODB_3P3V0P8V_BC_LIBS)"
	set io_3p3v0p8v_dmsa_corner_library_files(bc_rcworst)  "$vars(IODB_3P3V0P8V_BC_LIBS)"
	set io_3p3v0p8v_dmsa_corner_library_files(bc_cbest)  "$vars(IODB_3P3V0P8V_BC_LIBS)"
	set io_3p3v0p8v_dmsa_corner_library_files(bc_rcbest)  "$vars(IODB_3P3V0P8V_BC_LIBS)"

	set io_3p3v0p8v_dmsa_corner_library_files(tc_typ25)  "vars(IODB_3P3V0P8V_TC_LIBS)"

	set io_1p8v0p9v_dmsa_corner_library_files(wcl_cworst)  "$vars(IODB_1P8V0P9V_WCL_LIBS)"
	set io_1p8v0p9v_dmsa_corner_library_files(wcl_cworst_t)  "$vars(IODB_1P8V0P9V_WCL_LIBS)"
	set io_1p8v0p9v_dmsa_corner_library_files(wcl_rcworst)  "$vars(IODB_1P8V0P9V_WCL_LIBS)"
	set io_1p8v0p9v_dmsa_corner_library_files(wcl_rcworst_t)  "$vars(IODB_1P8V0P9V_WCL_LIBS)"

	set io_1p8v0p9v_dmsa_corner_library_files(wc_cworst)  "$vars(IODB_1P8V0P9V_WC_LIBS)"
	set io_1p8v0p9v_dmsa_corner_library_files(wc_cworst_t)  "$vars(IODB_1P8V0P9V_WC_LIBS)"
	set io_1p8v0p9v_dmsa_corner_library_files(wc_rcworst)  "$vars(IODB_1P8V0P9V_WC_LIBS)"
	set io_1p8v0p9v_dmsa_corner_library_files(wc_rcworst_t)  "$vars(IODB_1P8V0P9V_WC_LIBS)"

	set io_1p8v0p9v_dmsa_corner_library_files(wcz_cworst)  "$vars(IODB_1P8V0P9V_WCZ_LIBS)"
	set io_1p8v0p9v_dmsa_corner_library_files(wcz_cworst_t)  "$vars(IODB_1P8V0P9V_WCZ_LIBS)"
	set io_1p8v0p9v_dmsa_corner_library_files(wcz_rcworst)  "$vars(IODB_1P8V0P9V_WCZ_LIBS)"
	set io_1p8v0p9v_dmsa_corner_library_files(wcz_rcworst_t)  "$vars(IODB_1P8V0P9V_WCZ_LIBS)"

	set io_1p8v0p9v_dmsa_corner_library_files(ml_cworst)  "$vars(IODB_1P8V0P9V_ML_LIBS)"
	set io_1p8v0p9v_dmsa_corner_library_files(ml_rcworst)  "$vars(IODB_1P8V0P9V_ML_LIBS)"
	set io_1p8v0p9v_dmsa_corner_library_files(ml_cbest)  "$vars(IODB_1P8V0P9V_ML_LIBS)"
	set io_1p8v0p9v_dmsa_corner_library_files(ml_rcbest)  "$vars(IODB_1P8V0P9V_ML_LIBS)"

	set io_1p8v0p9v_dmsa_corner_library_files(lt_cworst)  "$vars(IODB_1P8V0P9V_LT_LIBS)"
	set io_1p8v0p9v_dmsa_corner_library_files(lt_rcworst)  "$vars(IODB_1P8V0P9V_LT_LIBS)"
	set io_1p8v0p9v_dmsa_corner_library_files(lt_cbest)  "$vars(IODB_1P8V0P9V_LT_LIBS)"
	set io_1p8v0p9v_dmsa_corner_library_files(lt_rcbest)  "$vars(IODB_1P8V0P9V_LT_LIBS)"

	set io_1p8v0p9v_dmsa_corner_library_files(bc_cworst)  "$vars(IODB_1P8V0P9V_BC_LIBS)"
	set io_1p8v0p9v_dmsa_corner_library_files(bc_rcworst)  "$vars(IODB_1P8V0P9V_BC_LIBS)"
	set io_1p8v0p9v_dmsa_corner_library_files(bc_cbest)  "$vars(IODB_1P8V0P9V_BC_LIBS)"
	set io_1p8v0p9v_dmsa_corner_library_files(bc_rcbest)  "$vars(IODB_1P8V0P9V_BC_LIBS)"

	set io_1p8v0p9v_dmsa_corner_library_files(tc_typ25)  "vars(IODB_1P8V0P9V_TC_LIBS)"


set OPRATING_COND(wcl_cworst)  "ssg0p72vm40c"
set OPRATING_COND(wcl_cworst_t)  "ssg0p72vm40c"
set OPRATING_COND(wcl_rcworst)  "ssg0p72vm40c"
set OPRATING_COND(wcl_rcworst_t)  "ssg0p72vm40c"

set OPRATING_COND(wc_cworst)  "ssg0p72v125c"
set OPRATING_COND(wc_cworst_t)  "ssg0p72v125c"
set OPRATING_COND(wc_rcworst)  "ssg0p72v125c"
set OPRATING_COND(wc_rcworst_t)  "ssg0p72v125c"

set OPRATING_COND(wcz_cworst)  "ssg0p72v0c"
set OPRATING_COND(wcz_cworst_t)  "ssg0p72v0c"
set OPRATING_COND(wcz_rcworst)  "ssg0p72v0c"
set OPRATING_COND(wcz_rcworst_t)  "ssg0p72v0c"

set OPRATING_COND(ml_cworst)  "ffg0p88v125c"
set OPRATING_COND(ml_rcworst)  "ffg0p88v125c"
set OPRATING_COND(ml_cbest)  "ffg0p88v125c"
set OPRATING_COND(ml_rcbest)  "ffg0p88v125c"

set OPRATING_COND(bc_cworst)  "ffg0p88v0c"
set OPRATING_COND(bc_rcworst)  "ffg0p88v0c"
set OPRATING_COND(bc_cbest)  "ffg0p88v0c"
set OPRATING_COND(bc_rcbest)  "ffg0p88v0c"

set OPRATING_COND(lt_cworst)  "ffg0p88vm40c"
set OPRATING_COND(lt_rcworst)  "ffg0p88vm40c"
set OPRATING_COND(lt_cbest)  "ffg0p88vm40c"
set OPRATING_COND(lt_rcbest)  "ffg0p88vm40c"

set OPRATING_COND(tc_typ25)  "tt0p8v25c"

set link_path "* $dmsa_corner_library_files($CORNER)"
read_verilog $NETLIST
current_design $DESIGN_TOP
link_design

set_operating_conditions  $OPRATING_COND($CORNER)
read_sdf $SDF
source $SDC
remove_clock_uncertainty [all_clocks]
remove_clock_uncertainty -from [all_clocks ] -to [all_clocks ]
#
group_path -name in2reg -from [all_inputs] -to [all_registers]
group_path -name reg2out -from [all_registers] -to [all_outputs]
group_path -name reg2reg -from [all_registers] -to [all_registers]

set_propagated_clock [all_clocks ]
report_constraint -all_violators -recovery -removal -max_delay > sdf.all_violations.${MODE}_${CORNER}_${check}.max.rpt
report_constraint -all_violators -recovery -removal -min_delay > sdf.all_violations.${MODE}_${CORNER}_${check}.min.rpt

puts "Running  pt sdf check analysis at [date] :end"

