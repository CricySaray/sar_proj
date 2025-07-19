source /eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/backend/be8803/last/lib_setup/12t_lib.tcl  
source /eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/backend/be8803/last/lib_setup/9t_lib.tcl
source /eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/backend/be8803/last/lib_setup/7t_lib.tcl   
source /eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/backend/be8803/last/lib_setup/ALL_RAM_LIBS
source /eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/backend/be8803/last/lib_setup/ALL_ROM_LIBS
source /eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/backend/be8803/last/lib_setup/io_lib.tcl
source /eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/backend/be8803/last/lib_setup/ALL_IP_LIBS.tcl

set vars(GDS_LIBS) " \
$vars(GDS_12T_LIBS) \
$vars(GDS_9T_LIBS) \
$vars(GDS_7T_LIBS) \
$vars(GDS_ROM_LIBS) \
$vars(GDS_RAM_LIBS) \
$vars(GDS_IO_LIBS) \
$vars(GDS_IP_LIBS) \
" 

set vars(CDL_LIBS) " \
$vars(CDL_12T_LIBS) \
$vars(CDL_9T_LIBS) \
$vars(CDL_7T_LIBS) \
$vars(CDL_ROM_LIBS) \
$vars(CDL_RAM_LIBS) \
$vars(CDL_IO_LIBS) \
$vars(CDL_IP_LIBS) \
"


set vars(TECH_LEF_7T) "/eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/archive_fullmask/chip_top_idp/lib/tech/sc7mcpp140z_tech.lef"
set vars(TECH_LEF_9T) "/eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/archive_fullmask/chip_top_idp/lib/tech/sc9mcpp140z_tech.lef"
set vars(TECH_LEF_12T) "/eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/archive_fullmask/chip_top_idp/lib/tech/sc12mcpp140z_tech.lef"
set vars(TECH_NDR_LEF) "/eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/archive_fullmask/common_script/pr_common_script/ndr_rule.tlef"

set vars(TECH_TYPICAL_QRC) "/eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/archive_fullmask/chip_top_idp/lib/tech/TYPICAL"
set vars(TECH_CMAX_QRC)    "/eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/archive_fullmask/chip_top_idp/lib/tech/CMAX"
set vars(TECH_CMAX_T_QRC)  "/eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/archive_fullmask/chip_top_idp/lib/tech/CMAX_T"
set vars(TECH_RCMAX_QRC)   "/eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/archive_fullmask/chip_top_idp/lib/tech/RCMAX"
set vars(TECH_RCMAX_T_QRC) "/eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/archive_fullmask/chip_top_idp/lib/tech/RCMAX_T"
set vars(TECH_CMIN_QRC)    "/eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/archive_fullmask/chip_top_idp/lib/tech/CMIN"
set vars(TECH_CMIN_T_QRC)  "/eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/archive_fullmask/chip_top_idp/lib/tech/CMIN_T"
set vars(TECH_RCMIN_QRC)   "/eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/archive_fullmask/chip_top_idp/lib/tech/RCMIN"
set vars(TECH_RCMIN_T_QRC) "/eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/archive_fullmask/chip_top_idp/lib/tech/RCMIN_T"

set vars(TECH_MAP_STAR)     "/eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/archive_fullmask/chip_top_idp/lib/tech/tluplus.map"
set vars(TECH_CORNER_STAR)  "/eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/archive_fullmask/chip_top_idp/lib/tech/corners.smc"
set vars(TECH_MAP_DEF2GDS)  "/eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/archive_fullmask/chip_top_idp/lib/tech/starrc_gds.map"
set vars(TECH_WIRE_POCV) ""
set vars(TECH_MAP_EDI) "/eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/archive_fullmask/chip_top_idp/lib/tech/tech.map"

set vars(DMSA_CORNERS) " wcl_cworst_t wcl_rcworst_t \
      wc_cworst_t wc_rcworst_t \
      wcz_cworst_t wcz_rcworst_t \
      ml_cbest ml_rcbest \
      lt_cbest lt_rcbest   \
      bc_cbest bc_rcbest   \
      ml_cworst ml_rcworst \
      lt_cworst lt_rcworst \
      bc_cworst bc_rcworst \
      wcl_cworst wcl_rcworst \
      wc_cworst wc_rcworst \
      wcz_cworst wcz_rcworst \
      "
source /eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/backend/be8803/chip_top_idp/lib/tech/common_pv_setup.tcl

