set VIEW ECO_XHOLD_022001
set eco_VIEW ECO_XHOLD_022501

set scenarios "\
func_wcl_cworst_t_setup func_wcl_rcworst_t_setup func_wcl_cworst_hold func_wcl_rcworst_hold func_bc_rcworst_hold func_ml_cbest_hold  func_ml_rcworst_hold func_lt_rcbest_hold func_ml_rcbest_hold \
scan_wcl_cworst_t_setup scan_wcl_rcworst_t_setup scan_wcl_cworst_hold scan_wcl_rcworst_hold scan_bc_rcworst_hold scan_ml_cbest_hold scan_ml_cworst_hold scan_ml_rcworst_hold scan_lt_rcbest_hold \
func_wc_cworst_t_setup func_wc_rcworst_t_setup \ 
cdc_wc_cworst_t_setup \
cdc_wcl_cworst_t_setup \
cdc_wcl_rcworst_t_setup \
cdc_wc_rcworst_t_setup \
cdc_wcz_cworst_t_setup \
cdc_wcz_rcworst_t_setup \
"
set scenarios { \
func_lt_cworst_hold \
func_ml_cworst_hold \
func_wcl_cworst_hold \
func_wcl_cworst_t_setup \
scan_lt_cworst_hold \
scan_ml_cworst_hold \
scan_wcl_cworst_hold \
scan_wcl_cworst_t_setup \
cdc_wc_cworst_t_setup \
cdc_wcl_cworst_t_setup \
cdc_wcl_rcworst_t_setup \
cdc_wc_rcworst_t_setup \
cdc_wcz_cworst_t_setup \
cdc_wcz_rcworst_t_setup \
}

#cdc_wcl_cworst_t_setup 
#cdc_wcl_rcworst_t_setup 

set scenarios {  \
func_typ_85_setup \
func_wcl_cworst_t_setup \
func_bc_cworst_hold \
func_lt_rcworst_hold \
func_ml_cbest_hold \
func_ml_rcworst_hold \
func_typ_85_hold \
scan_bc_cworst_hold \
scan_lt_rcworst_hold \
scan_ml_cbest_hold \
scan_ml_rcworst_hold \
scan_typ_85_hold \
}

#set DESIGN_NAME 
source ./user_define_gba.tcl

set FIX_DRC 		"true"
set FIX_SETUP		"false"
set FIX_HOLD		"true"
set FIX_LKG		"false"
set EFFORT 		"ultra_high"


# EFFORT could be  " low medium high ultra_high extreme_high"

#Leon: add time prefix
set prefix [exec date +%m%d%H%M]
puts [exec date]

set_parameter max_thread_number {28}
create_workspace work_${eco_VIEW} -overwrite
source /eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/backend/be8803/last/.lib_setup.tcl
set vars(dont_use_list_file) ""
set vars(dont_touch_list_file) ""
set vars(dont_use_list) "*ZTUL* *ZTL* *ZTUH* *_X0* *_X20* *ECO* *AND*_X11* *AND*_X8* *AO21A1AI2_X8* *AOI21B_X8* *AOI21_X11* *AOI21_X8* *AOI22BB_X8* *AOI22_X11* *AOI22_X8* *AOI2XB1_X8* *AOI31_X8* *ENDCAP FILL* GP* MXGL* OA*_X8* OR*_X11* NOR*_X11* OR*_X8* NOR*_X8*"
if { $block_use_7t} {
    link_reference_library -format lef "$vars(TECH_LEF_7T)  $vars(LEF_7T_LIBS) $vars(LEF_9T_LIBS) $vars(LEF_12T_LIBS) $vars(LEF_RAM_LIBS) $vars(LEF_ROM_LIBS) $vars(LEF_IO_LIBS) $vars(LEF_IP_LIBS) "
}

if { $block_use_9t} {
    link_reference_library -format lef "$vars(TECH_LEF_9T)  $vars(LEF_7T_LIBS) $vars(LEF_9T_LIBS) $vars(LEF_12T_LIBS) $vars(LEF_RAM_LIBS) $vars(LEF_ROM_LIBS) $vars(LEF_IO_LIBS) $vars(LEF_IP_LIBS) "
}

define_designs -verilogs "../dsn/gate/${DESIGN_NAME}.pr.${VIEW}.vg.gz " \
                 -defs "../dsn/def/${DESIGN_NAME}.${VIEW}.def.gz "

#set_site_map {unit  core7T}
#set_site_map {unit  CoreSite}
import_designs

#lowpower
###################################################################
#please source dump_power_domain_from_INNO.tcl file in block invs gui,
#source /eda_tools/empyrean/icexplorer-xtop-2019.06/utilities/data_preparation/dump_power_domain_from_INNO.tcl
#write_pd_for_xtop ../../dsn/eco 
###################################################################
#
#import_power_domain -design ${DESIGN_NAME} -upf_file $UPF_FILE -region_file ../dsn/eco/${DESIGN_NAME}.pd
#import_power_domain -design ${DESIGN_NAME} \
#    -upf_file /eda_files/proj/ict2100/backend/mun/chip_top_tdp/sub_proj/chip_top/dsn/eco/chip_top.upf \
#    -region_file /eda_files/proj/ict2100/backend/mun/chip_top_tdp/sub_proj/chip_top/dsn/eco/chip_top.pd
#import_power_domain -design ${DESIGN_NAME} \
    -region_file /eda_files/proj/ict2100/backend/chenjinyong/chip_top_fdp/sub_proj/chip_top/dsn/chip_top.pd

check_placement_readiness


save_workspace

if {$scenarios=="all" || [lsearch $scenarios *_wcl_cworst_t_setup ] >=0 } { create_corner wcl_cworst_t_setup }
if {$scenarios=="all" || [lsearch $scenarios *_wcl_rcworst_t_setup ] >=0 } { create_corner wcl_rcworst_t_setup }
if {$scenarios=="all" || [lsearch $scenarios *_wc_cworst_t_setup ] >=0 } { create_corner wc_cworst_t_setup }
if {$scenarios=="all" || [lsearch $scenarios *_wc_rcworst_t_setup ] >=0 } { create_corner wc_rcworst_t_setup }
if {$scenarios=="all" || [lsearch $scenarios *_wcz_cworst_t_setup ] >=0 } { create_corner wcz_cworst_t_setup }
if {$scenarios=="all" || [lsearch $scenarios *_wcz_rcworst_t_setup ] >=0 } { create_corner wcz_rcworst_t_setup }
if {$scenarios=="all" || [lsearch $scenarios *_typ_85_setup ] >=0 } { create_corner typ_85_setup }

if {$scenarios=="all" || [lsearch $scenarios *_wcl_cworst_hold ] >=0 } { create_corner wcl_cworst_hold }
if {$scenarios=="all" || [lsearch $scenarios *_wcl_rcworst_hold ] >=0 } { create_corner wcl_rcworst_hold }
if {$scenarios=="all" || [lsearch $scenarios *_wc_cworst_hold ] >=0 } { create_corner wc_cworst_hold }
if {$scenarios=="all" || [lsearch $scenarios *_wc_rcworst_hold ] >=0 } { create_corner wc_rcworst_hold }
if {$scenarios=="all" || [lsearch $scenarios *_wcz_cworst_hold ] >=0 } { create_corner wcz_cworst_hold }
if {$scenarios=="all" || [lsearch $scenarios *_wcz_rcworst_hold ] >=0 } { create_corner wcz_rcworst_hold }
if {$scenarios=="all" || [lsearch $scenarios *_ml_cworst_hold ] >=0 } { create_corner ml_cworst_hold }
if {$scenarios=="all" || [lsearch $scenarios *_ml_rcworst_hold ] >=0 } { create_corner ml_rcworst_hold }
if {$scenarios=="all" || [lsearch $scenarios *_ml_cbest_hold ] >=0 } { create_corner ml_cbest_hold }
if {$scenarios=="all" || [lsearch $scenarios *_ml_rcbest_hold ] >=0 } { create_corner ml_rcbest_hold }
if {$scenarios=="all" || [lsearch $scenarios *_lt_cworst_hold ] >=0 } { create_corner lt_cworst_hold }
if {$scenarios=="all" || [lsearch $scenarios *_lt_rcworst_hold ] >=0 } { create_corner lt_rcworst_hold }
if {$scenarios=="all" || [lsearch $scenarios *_lt_cbest_hold ] >=0 } { create_corner lt_cbest_hold }
if {$scenarios=="all" || [lsearch $scenarios *_lt_rcbest_hold ] >=0 } { create_corner lt_rcbest_hold }
if {$scenarios=="all" || [lsearch $scenarios *_bc_cworst_hold ] >=0 } { create_corner bc_cworst_hold }
if {$scenarios=="all" || [lsearch $scenarios *_bc_rcworst_hold ] >=0 } { create_corner bc_rcworst_hold }
if {$scenarios=="all" || [lsearch $scenarios *_bc_cbest_hold ] >=0 } { create_corner bc_cbest_hold }
if {$scenarios=="all" || [lsearch $scenarios *_bc_rcbest_hold ] >=0 } { create_corner bc_rcbest_hold }
if {$scenarios=="all" || [lsearch $scenarios *_typ_85_hold] >=0 } { create_corner typ_85_hold }



create_mode func
if {$scenarios=="all" || [lsearch -exact $scenarios func_typ_85_setup ] >=0 } {
         create_scenario -corner {typ_85_setup} -mode {func} {func_typ_85_setup}
}

if {$scenarios=="all" || [lsearch -exact $scenarios func_wcl_cworst_t_setup ] >=0 } {
	 create_scenario -corner {wcl_cworst_t_setup} -mode {func} {func_wcl_cworst_t_setup} 
}
if {$scenarios=="all" || [lsearch -exact $scenarios func_wcl_rcworst_t_setup ] >=0 } {
	 create_scenario -corner {wcl_rcworst_t_setup} -mode {func} {func_wcl_rcworst_t_setup} 
}
if {$scenarios=="all" || [lsearch -exact $scenarios func_wc_cworst_t_setup ] >=0 } {
	 create_scenario -corner {wc_cworst_t_setup} -mode {func} {func_wc_cworst_t_setup} 
}
if {$scenarios=="all" || [lsearch -exact $scenarios func_wc_rcworst_t_setup ] >=0 } {
	 create_scenario -corner {wc_rcworst_t_setup} -mode {func} {func_wc_rcworst_t_setup} 
}
if {$scenarios=="all" || [lsearch -exact $scenarios func_wcz_cworst_t_setup ] >=0 } {
	 create_scenario -corner {wcz_cworst_t_setup} -mode {func} {func_wcz_cworst_t_setup} 
}
if {$scenarios=="all" || [lsearch -exact $scenarios func_wcz_rcworst_t_setup ] >=0 } {
	 create_scenario -corner {wcz_rcworst_t_setup} -mode {func} {func_wcz_rcworst_t_setup} 
}
if {$scenarios=="all" || [lsearch -exact $scenarios func_typ_85_hold ] >=0 } {
         create_scenario -corner {typ_85_hold} -mode {func} {func_typ_85_hold}
}

if {$scenarios=="all" || [lsearch -exact $scenarios func_wcl_cworst_hold ] >=0 } {
	 create_scenario -corner {wcl_cworst_hold} -mode {func} {func_wcl_cworst_hold} 
}
if {$scenarios=="all" || [lsearch -exact $scenarios func_wcl_rcworst_hold ] >=0 } {
	 create_scenario -corner {wcl_rcworst_hold} -mode {func} {func_wcl_rcworst_hold} 
}
if {$scenarios=="all" || [lsearch -exact $scenarios func_wc_cworst_hold ] >=0 } {
	 create_scenario -corner {wc_cworst_hold} -mode {func} {func_wc_cworst_hold} 
}
if {$scenarios=="all" || [lsearch -exact $scenarios func_wc_rcworst_hold ] >=0 } {
	 create_scenario -corner {wc_rcworst_hold} -mode {func} {func_wc_rcworst_hold} 
}
if {$scenarios=="all" || [lsearch -exact $scenarios func_wcz_cworst_hold ] >=0 } {
	 create_scenario -corner {wcz_cworst_hold} -mode {func} {func_wcz_cworst_hold} 
}
if {$scenarios=="all" || [lsearch -exact $scenarios func_wcz_rcworst_hold ] >=0 } {
	 create_scenario -corner {wcz_rcworst_hold} -mode {func} {func_wcz_rcworst_hold} 
}
if {$scenarios=="all" || [lsearch -exact $scenarios func_ml_cworst_hold ] >=0 } {
	 create_scenario -corner {ml_cworst_hold} -mode {func} {func_ml_cworst_hold} 
}
if {$scenarios=="all" || [lsearch -exact $scenarios func_ml_rcworst_hold ] >=0 } {
	 create_scenario -corner {ml_rcworst_hold} -mode {func} {func_ml_rcworst_hold} 
}
if {$scenarios=="all" || [lsearch -exact $scenarios func_ml_cbest_hold ] >=0 } {
	 create_scenario -corner {ml_cbest_hold} -mode {func} {func_ml_cbest_hold} 
}
if {$scenarios=="all" || [lsearch -exact $scenarios func_ml_rcbest_hold ] >=0 } {
	 create_scenario -corner {ml_rcbest_hold} -mode {func} {func_ml_rcbest_hold} 
}
if {$scenarios=="all" || [lsearch -exact $scenarios func_lt_cworst_hold ] >=0 } {
	 create_scenario -corner {lt_cworst_hold} -mode {func} {func_lt_cworst_hold} 
}
if {$scenarios=="all" || [lsearch -exact $scenarios func_lt_rcworst_hold ] >=0 } {
	 create_scenario -corner {lt_rcworst_hold} -mode {func} {func_lt_rcworst_hold} 
}
if {$scenarios=="all" || [lsearch -exact $scenarios func_lt_cbest_hold ] >=0 } {
	 create_scenario -corner {lt_cbest_hold} -mode {func} {func_lt_cbest_hold} 
}
if {$scenarios=="all" || [lsearch -exact $scenarios func_lt_rcbest_hold ] >=0 } {
	 create_scenario -corner {lt_rcbest_hold} -mode {func} {func_lt_rcbest_hold} 
}
if {$scenarios=="all" || [lsearch -exact $scenarios func_bc_cworst_hold ] >=0 } {
	 create_scenario -corner {bc_cworst_hold} -mode {func} {func_bc_cworst_hold} 
}
if {$scenarios=="all" || [lsearch -exact $scenarios func_bc_rcworst_hold ] >=0 } {
	 create_scenario -corner {bc_rcworst_hold} -mode {func} {func_bc_rcworst_hold} 
}
if {$scenarios=="all" || [lsearch -exact $scenarios func_bc_cbest_hold ] >=0 } {
	 create_scenario -corner {bc_cbest_hold} -mode {func} {func_bc_cbest_hold} 
}
if {$scenarios=="all" || [lsearch -exact $scenarios func_bc_rcbest_hold ] >=0 } {
	 create_scenario -corner {bc_rcbest_hold} -mode {func} {func_bc_rcbest_hold} 
}

create_mode func1

if {$scenarios=="all" || [lsearch -exact $scenarios func1_wcl_cworst_t_setup ] >=0 } {
	 create_scenario -corner {wcl_cworst_t_setup} -mode {func1} {func1_wcl_cworst_t_setup} 
}
if {$scenarios=="all" || [lsearch -exact $scenarios func1_wcl_rcworst_t_setup ] >=0 } {
	 create_scenario -corner {wcl_rcworst_t_setup} -mode {func1} {func1_wcl_rcworst_t_setup} 
}
if {$scenarios=="all" || [lsearch -exact $scenarios func1_wc_cworst_t_setup ] >=0 } {
	 create_scenario -corner {wc_cworst_t_setup} -mode {func1} {func1_wc_cworst_t_setup} 
}
if {$scenarios=="all" || [lsearch -exact $scenarios func1_wc_rcworst_t_setup ] >=0 } {
	 create_scenario -corner {wc_rcworst_t_setup} -mode {func1} {func1_wc_rcworst_t_setup} 
}
if {$scenarios=="all" || [lsearch -exact $scenarios func1_wcz_cworst_t_setup ] >=0 } {
	 create_scenario -corner {wcz_cworst_t_setup} -mode {func1} {func1_wcz_cworst_t_setup} 
}
if {$scenarios=="all" || [lsearch -exact $scenarios func1_wcz_rcworst_t_setup ] >=0 } {
	 create_scenario -corner {wcz_rcworst_t_setup} -mode {func1} {func1_wcz_rcworst_t_setup} 
}

if {$scenarios=="all" || [lsearch -exact $scenarios func1_wcl_cworst_hold ] >=0 } {
	 create_scenario -corner {wcl_cworst_hold} -mode {func1} {func1_wcl_cworst_hold} 
}
if {$scenarios=="all" || [lsearch -exact $scenarios func1_wcl_rcworst_hold ] >=0 } {
	 create_scenario -corner {wcl_rcworst_hold} -mode {func1} {func1_wcl_rcworst_hold} 
}
if {$scenarios=="all" || [lsearch -exact $scenarios func1_wc_cworst_hold ] >=0 } {
	 create_scenario -corner {wc_cworst_hold} -mode {func1} {func1_wc_cworst_hold} 
}
if {$scenarios=="all" || [lsearch -exact $scenarios func1_wc_rcworst_hold ] >=0 } {
	 create_scenario -corner {wc_rcworst_hold} -mode {func1} {func1_wc_rcworst_hold} 
}
if {$scenarios=="all" || [lsearch -exact $scenarios func1_wcz_cworst_hold ] >=0 } {
	 create_scenario -corner {wcz_cworst_hold} -mode {func1} {func1_wcz_cworst_hold} 
}
if {$scenarios=="all" || [lsearch -exact $scenarios func1_wcz_rcworst_hold ] >=0 } {
	 create_scenario -corner {wcz_rcworst_hold} -mode {func1} {func1_wcz_rcworst_hold} 
}
if {$scenarios=="all" || [lsearch -exact $scenarios func1_ml_cworst_hold ] >=0 } {
	 create_scenario -corner {ml_cworst_hold} -mode {func1} {func1_ml_cworst_hold} 
}
if {$scenarios=="all" || [lsearch -exact $scenarios func1_ml_rcworst_hold ] >=0 } {
	 create_scenario -corner {ml_rcworst_hold} -mode {func1} {func1_ml_rcworst_hold} 
}
if {$scenarios=="all" || [lsearch -exact $scenarios func1_ml_cbest_hold ] >=0 } {
	 create_scenario -corner {ml_cbest_hold} -mode {func1} {func1_ml_cbest_hold} 
}
if {$scenarios=="all" || [lsearch -exact $scenarios func1_ml_rcbest_hold ] >=0 } {
	 create_scenario -corner {ml_rcbest_hold} -mode {func1} {func1_ml_rcbest_hold} 
}
if {$scenarios=="all" || [lsearch -exact $scenarios func1_lt_cworst_hold ] >=0 } {
	 create_scenario -corner {lt_cworst_hold} -mode {func1} {func1_lt_cworst_hold} 
}
if {$scenarios=="all" || [lsearch -exact $scenarios func1_lt_rcworst_hold ] >=0 } {
	 create_scenario -corner {lt_rcworst_hold} -mode {func1} {func1_lt_rcworst_hold} 
}
if {$scenarios=="all" || [lsearch -exact $scenarios func1_lt_cbest_hold ] >=0 } {
	 create_scenario -corner {lt_cbest_hold} -mode {func1} {func1_lt_cbest_hold} 
}
if {$scenarios=="all" || [lsearch -exact $scenarios func1_lt_rcbest_hold ] >=0 } {
	 create_scenario -corner {lt_rcbest_hold} -mode {func1} {func1_lt_rcbest_hold} 
}
if {$scenarios=="all" || [lsearch -exact $scenarios func1_bc_cworst_hold ] >=0 } {
	 create_scenario -corner {bc_cworst_hold} -mode {func1} {func1_bc_cworst_hold} 
}
if {$scenarios=="all" || [lsearch -exact $scenarios func1_bc_rcworst_hold ] >=0 } {
	 create_scenario -corner {bc_rcworst_hold} -mode {func1} {func1_bc_rcworst_hold} 
}
if {$scenarios=="all" || [lsearch -exact $scenarios func1_bc_cbest_hold ] >=0 } {
	 create_scenario -corner {bc_cbest_hold} -mode {func1} {func1_bc_cbest_hold} 
}
if {$scenarios=="all" || [lsearch -exact $scenarios func1_bc_rcbest_hold ] >=0 } {
	 create_scenario -corner {bc_rcbest_hold} -mode {func1} {func1_bc_rcbest_hold} 
}

######create_mode func3p3v
######
######create_scenario -corner {wcl_cworst_t_setup} -mode {func3p3v} {func3p3v_wcl_cworst_t_setup}
######create_scenario -corner {wcl_rcworst_t_setup} -mode {func3p3v} {func3p3v_wcl_rcworst_t_setup}
#######create_scenario -corner {wcl_cbest_setup} -mode {func3p3v} {func3p3v_wcl_cbest_setup}
#######create_scenario -corner {wcl_rcbest_setup} -mode {func3p3v} {func3p3v_wcl_rcbest_setup}
######
######create_scenario -corner {wc_cworst_t_setup} -mode {func3p3v} {func3p3v_wc_cworst_t_setup}
######create_scenario -corner {wc_rcworst_t_setup} -mode {func3p3v} {func3p3v_wc_rcworst_t_setup}
#######create_scenario -corner {wc_cbest_setup} -mode {func3p3v} {func3p3v_wc_cbest_setup}
#######create_scenario -corner {wc_rcbest_setup} -mode {func3p3v} {func3p3v_wc_rcbest_setup}
######
######create_scenario -corner {wcz_cworst_t_setup} -mode {func3p3v} {func3p3v_wcz_cworst_t_setup}
######create_scenario -corner {wcz_rcworst_t_setup} -mode {func3p3v} {func3p3v_wcz_rcworst_t_setup}
#######create_scenario -corner {wcz_cbest_setup} -mode {func3p3v} {func3p3v_wcz_cbest_setup}
#######create_scenario -corner {wcz_rcbest_setup} -mode {func3p3v} {func3p3v_wcz_rcbest_setup}
######
######
######create_scenario -corner {wcl_cworst_hold} -mode {func3p3v} {func3p3v_wcl_cworst_hold}
######create_scenario -corner {wcl_rcworst_hold} -mode {func3p3v} {func3p3v_wcl_rcworst_hold}
#######create_scenario -corner {wcl_cbest_hold} -mode {func3p3v} {func3p3v_wcl_cbest_hold}
#######create_scenario -corner {wcl_rcbest_hold} -mode {func3p3v} {func3p3v_wcl_rcbest_hold}
######
######create_scenario -corner {wc_cworst_hold} -mode {func3p3v} {func3p3v_wc_cworst_hold}
######create_scenario -corner {wc_rcworst_hold} -mode {func3p3v} {func3p3v_wc_rcworst_hold}
#######create_scenario -corner {wc_cbest_hold} -mode {func3p3v} {func3p3v_wc_cbest_hold}
#######create_scenario -corner {wc_rcbest_hold} -mode {func3p3v} {func3p3v_wc_rcbest_hold}
######
######create_scenario -corner {wcz_cworst_hold} -mode {func3p3v} {func3p3v_wcz_cworst_hold}
######create_scenario -corner {wcz_rcworst_hold} -mode {func3p3v} {func3p3v_wcz_rcworst_hold}
#######create_scenario -corner {wcz_cbest_hold} -mode {func3p3v} {func3p3v_wcz_cbest_hold}
#######create_scenario -corner {wcz_rcbest_hold} -mode {func3p3v} {func3p3v_wcz_rcbest_hold}
######
######create_scenario -corner {ml_cworst_hold} -mode {func3p3v} {func3p3v_ml_cworst_hold}
######create_scenario -corner {ml_rcworst_hold} -mode {func3p3v} {func3p3v_ml_rcworst_hold}
######create_scenario -corner {ml_cbest_hold} -mode {func3p3v} {func3p3v_ml_cbest_hold}
######create_scenario -corner {ml_rcbest_hold} -mode {func3p3v} {func3p3v_ml_rcbest_hold}
######
######create_scenario -corner {lt_cworst_hold} -mode {func3p3v} {func3p3v_lt_cworst_hold}
######create_scenario -corner {lt_rcworst_hold} -mode {func3p3v} {func3p3v_lt_rcworst_hold}
######create_scenario -corner {lt_cbest_hold} -mode {func3p3v} {func3p3v_lt_cbest_hold}
######create_scenario -corner {lt_rcbest_hold} -mode {func3p3v} {func3p3v_lt_rcbest_hold}
######
######create_scenario -corner {bc_cworst_hold} -mode {func3p3v} {func3p3v_bc_cworst_hold}
######create_scenario -corner {bc_rcworst_hold} -mode {func3p3v} {func3p3v_bc_rcworst_hold}
#create_scenario -corner {bc_cbest_hold} -mode {func3p3v} {func3p3v_bc_cbest_hold}
######create_scenario -corner {bc_rcbest_hold} -mode {func3p3v} {func3p3v_bc_rcbest_hold}

create_mode scan

if {$scenarios=="all" || [lsearch -exact $scenarios scan_wcl_cworst_t_setup ] >=0 } {
	 create_scenario -corner {wcl_cworst_t_setup} -mode {scan} {scan_wcl_cworst_t_setup} 
}
if {$scenarios=="all" || [lsearch -exact $scenarios scan_wcl_rcworst_t_setup ] >=0 } {
	 create_scenario -corner {wcl_rcworst_t_setup} -mode {scan} {scan_wcl_rcworst_t_setup} 
}
if {$scenarios=="all" || [lsearch -exact $scenarios scan_wc_cworst_t_setup ] >=0 } {
	 create_scenario -corner {wc_cworst_t_setup} -mode {scan} {scan_wc_cworst_t_setup} 
}
if {$scenarios=="all" || [lsearch -exact $scenarios scan_wc_rcworst_t_setup ] >=0 } {
	 create_scenario -corner {wc_rcworst_t_setup} -mode {scan} {scan_wc_rcworst_t_setup} 
}
if {$scenarios=="all" || [lsearch -exact $scenarios scan_wcz_cworst_t_setup ] >=0 } {
	 create_scenario -corner {wcz_cworst_t_setup} -mode {scan} {scan_wcz_cworst_t_setup} 
}
if {$scenarios=="all" || [lsearch -exact $scenarios scan_wcz_rcworst_t_setup ] >=0 } {
	 create_scenario -corner {wcz_rcworst_t_setup} -mode {scan} {scan_wcz_rcworst_t_setup} 
}
if {$scenarios=="all" || [lsearch -exact $scenarios scan_typ_85_setup ] >=0 } {
	 create_scenario -corner {typ_85_setup} -mode {scan} {scan_typ_85_setup} 
}
if {$scenarios=="all" || [lsearch -exact $scenarios scan_typ_85_hold ] >=0 } {
	 create_scenario -corner {typ_85_hold} -mode {scan} {scan_typ_85_hold} 
}

if {$scenarios=="all" || [lsearch -exact $scenarios scan_wcl_cworst_hold ] >=0 } {
	 create_scenario -corner {wcl_cworst_hold} -mode {scan} {scan_wcl_cworst_hold} 
}
if {$scenarios=="all" || [lsearch -exact $scenarios scan_wcl_rcworst_hold ] >=0 } {
	 create_scenario -corner {wcl_rcworst_hold} -mode {scan} {scan_wcl_rcworst_hold} 
}
if {$scenarios=="all" || [lsearch -exact $scenarios scan_wc_cworst_hold ] >=0 } {
	 create_scenario -corner {wc_cworst_hold} -mode {scan} {scan_wc_cworst_hold} 
}
if {$scenarios=="all" || [lsearch -exact $scenarios scan_wc_rcworst_hold ] >=0 } {
	 create_scenario -corner {wc_rcworst_hold} -mode {scan} {scan_wc_rcworst_hold} 
}
if {$scenarios=="all" || [lsearch -exact $scenarios scan_wcz_cworst_hold ] >=0 } {
	 create_scenario -corner {wcz_cworst_hold} -mode {scan} {scan_wcz_cworst_hold} 
}
if {$scenarios=="all" || [lsearch -exact $scenarios scan_wcz_rcworst_hold ] >=0 } {
	 create_scenario -corner {wcz_rcworst_hold} -mode {scan} {scan_wcz_rcworst_hold} 
}
if {$scenarios=="all" || [lsearch -exact $scenarios scan_ml_cworst_hold ] >=0 } {
	 create_scenario -corner {ml_cworst_hold} -mode {scan} {scan_ml_cworst_hold} 
}
if {$scenarios=="all" || [lsearch -exact $scenarios scan_ml_rcworst_hold ] >=0 } {
	 create_scenario -corner {ml_rcworst_hold} -mode {scan} {scan_ml_rcworst_hold} 
}
if {$scenarios=="all" || [lsearch -exact $scenarios scan_ml_cbest_hold ] >=0 } {
	 create_scenario -corner {ml_cbest_hold} -mode {scan} {scan_ml_cbest_hold} 
}
if {$scenarios=="all" || [lsearch -exact $scenarios scan_ml_rcbest_hold ] >=0 } {
	 create_scenario -corner {ml_rcbest_hold} -mode {scan} {scan_ml_rcbest_hold} 
}
if {$scenarios=="all" || [lsearch -exact $scenarios scan_lt_cworst_hold ] >=0 } {
	 create_scenario -corner {lt_cworst_hold} -mode {scan} {scan_lt_cworst_hold} 
}
if {$scenarios=="all" || [lsearch -exact $scenarios scan_lt_rcworst_hold ] >=0 } {
	 create_scenario -corner {lt_rcworst_hold} -mode {scan} {scan_lt_rcworst_hold} 
}
if {$scenarios=="all" || [lsearch -exact $scenarios scan_lt_cbest_hold ] >=0 } {
	 create_scenario -corner {lt_cbest_hold} -mode {scan} {scan_lt_cbest_hold} 
}
if {$scenarios=="all" || [lsearch -exact $scenarios scan_lt_rcbest_hold ] >=0 } {
	 create_scenario -corner {lt_rcbest_hold} -mode {scan} {scan_lt_rcbest_hold} 
}
if {$scenarios=="all" || [lsearch -exact $scenarios scan_bc_cworst_hold ] >=0 } {
	 create_scenario -corner {bc_cworst_hold} -mode {scan} {scan_bc_cworst_hold} 
}
if {$scenarios=="all" || [lsearch -exact $scenarios scan_bc_rcworst_hold ] >=0 } {
	 create_scenario -corner {bc_rcworst_hold} -mode {scan} {scan_bc_rcworst_hold} 
}
if {$scenarios=="all" || [lsearch -exact $scenarios scan_bc_cbest_hold ] >=0 } {
	 create_scenario -corner {bc_cbest_hold} -mode {scan} {scan_bc_cbest_hold} 
}
if {$scenarios=="all" || [lsearch -exact $scenarios scan_bc_rcbest_hold ] >=0 } {
	 create_scenario -corner {bc_rcbest_hold} -mode {scan} {scan_bc_rcbest_hold} 
}

create_mode cdc

if {$scenarios=="all" || [lsearch -exact $scenarios cdc_wcl_cworst_t_setup ] >=0 } {
	 create_scenario -corner {wcl_cworst_t_setup} -mode {cdc} {cdc_wcl_cworst_t_setup} 
}
if {$scenarios=="all" || [lsearch -exact $scenarios cdc_wcl_rcworst_t_setup ] >=0 } {
	 create_scenario -corner {wcl_rcworst_t_setup} -mode {cdc} {cdc_wcl_rcworst_t_setup} 
}
if {$scenarios=="all" || [lsearch -exact $scenarios cdc_wc_cworst_t_setup ] >=0 } {
	 create_scenario -corner {wc_cworst_t_setup} -mode {cdc} {cdc_wc_cworst_t_setup} 
}
if {$scenarios=="all" || [lsearch -exact $scenarios cdc_wc_rcworst_t_setup ] >=0 } {
	 create_scenario -corner {wc_rcworst_t_setup} -mode {cdc} {cdc_wc_rcworst_t_setup} 
}
if {$scenarios=="all" || [lsearch -exact $scenarios cdc_wcz_cworst_t_setup ] >=0 } {
	 create_scenario -corner {wcz_cworst_t_setup} -mode {cdc} {cdc_wcz_cworst_t_setup} 
}
if {$scenarios=="all" || [lsearch -exact $scenarios cdc_wcz_rcworst_t_setup ] >=0 } {
	 create_scenario -corner {wcz_rcworst_t_setup} -mode {cdc} {cdc_wcz_rcworst_t_setup} 
}


#foreach  wcl_corners  [get_corner wcl_*] {link_timing_library -corner $wcl_corners -search_type min_max "$vars(CCS_0P8_WCL_LIBS) $vars(ROM_WCL_LIBS) $vars(RAM_WCL_LIBS) $vars(IO_1P8V0P8V_WCL_LIBS) $vars(IP_WCL_CMAX_FUNC_HOLD_LIBS)"}
#
#foreach  wc_corners  [get_corner wc_*] {link_timing_library -corner $wc_corners -search_type min_max "$vars(CCS_0P8_WC_LIBS)  $vars(ROM_WC_LIBS) $vars(RAM_WC_LIBS) $vars(IO_1P8V0P8V_WC_LIBS) $vars(IP_WC_RCMAX_T_FUNC_SETUP_LIBS)"}
#
#foreach  wcz_corners  [get_corner wcz_*] {link_timing_library -corner $wcz_corners -search_type min_max "$vars(CCS_0P8_WCZ_LIBS)  $vars(ROM_WCZ_LIBS) $vars(RAM_WCZ_LIBS) $vars(IO_1P8V0P8V_WCZ_LIBS) $vars(IP_WCZ_CMAX_FUNC_HOLD_LIBS)"}
#
#foreach  ml_corners  [get_corner ml_*] {link_timing_library -corner $ml_corners -search_type min_max "$vars(CCS_0P8_ML_LIBS)  $vars(ROM_ML_LIBS) $vars(RAM_ML_LIBS) $vars(IO_1P8V0P8V_ML_LIBS) $vars(IP_ML_RCMAX_FUNC_HOLD_LIBS)"}
#
#foreach  lt_corners  [get_corner lt_*] {link_timing_library -corner $lt_corners -search_type min_max "$vars(CCS_0P8_LT_LIBS)  $vars(ROM_LT_LIBS) $vars(RAM_LT_LIBS) $vars(IO_1P8V0P8V_LT_LIBS) $vars(IP_LT_RCMAX_FUNC_HOLD_LIBS)"}
#
#foreach  bc_corners  [get_corner bc_*] {link_timing_library -corner $bc_corners -search_type min_max "$vars(CCS_0P8_BC_LIBS)  $vars(ROM_BC_LIBS) $vars(RAM_BC_LIBS) $vars(IO_1P8V0P8V_BC_LIBS) $vars(IP_BC_RCMIN_FUNC_HOLD_LIBS)"}

foreach scenario [get_scenario  *] {
if { [regexp scan.* $scenario   ] } {
    if {[regexp .*hold $scenario   ]}  {
         foreach  wcl_corners  [get_corner wcl_*] {link_timing_library -corner $wcl_corners -search_type min_max "$vars(CCS_7T_0P9V_WCL_LIBS) $vars(CCS_9T_0P9V_WCL_LIBS) $vars(CCS_12T_0P9V_WCL_LIBS) $vars(LIB_RAM_0P9VP_0P9VC_WCL_LIBS) $vars(LIB_ROM_0P9VP_0P9VC_WCL_LIBS) $vars(LIB_IO_1P8V0P9V_WCL_LIBS) $vars(LIB_IP_SCAN_WCL_RCWORST_HOLD_LIBS)"}
         foreach  wc_corners  [get_corner wc_*] {link_timing_library -corner $wc_corners    -search_type min_max "$vars(CCS_7T_0P9V_WC_LIBS)  $vars(CCS_9T_0P9V_WC_LIBS)  $vars(CCS_12T_0P9V_WC_LIBS) $vars(LIB_RAM_0P9VP_0P9VC_WC_LIBS) $vars(LIB_ROM_0P9VP_0P9VC_WC_LIBS)  $vars(LIB_IO_1P8V0P9V_WC_LIBS) $vars(LIB_IP_SCAN_WC_CWORST_HOLD_LIBS)"}
         foreach  wcz_corners  [get_corner wcz_*] {link_timing_library -corner $wcz_corners -search_type min_max "$vars(CCS_7T_0P9V_WCZ_LIBS) $vars(CCS_9T_0P9V_WCZ_LIBS) $vars(CCS_12T_0P9V_WCZ_LIBS) $vars(LIB_RAM_0P9VP_0P9VC_WCZ_LIBS) $vars(LIB_ROM_0P9VP_0P9VC_WCZ_LIBS) $vars(LIB_IO_1P8V0P9V_WCZ_LIBS)   $vars(LIB_IP_SCAN_WCZ_RCWORST_HOLD_LIBS)"}
         foreach  ml_corners  [get_corner ml_*] {link_timing_library -corner $ml_corners    -search_type min_max "$vars(CCS_7T_0P9V_ML_LIBS)  $vars(CCS_9T_0P9V_ML_LIBS)  $vars(CCS_12T_0P9V_ML_LIBS) $vars(LIB_RAM_0P9VP_0P9VC_ML_LIBS) $vars(LIB_ROM_0P9VP_0P9VC_ML_LIBS) $vars(LIB_IO_1P8V0P9V_ML_LIBS)     $vars(LIB_IP_SCAN_ML_RCWORST_HOLD_LIBS)"}
         foreach  lt_corners  [get_corner lt_*] {link_timing_library -corner $lt_corners    -search_type min_max "$vars(CCS_7T_0P9V_LT_LIBS)  $vars(CCS_9T_0P9V_LT_LIBS)  $vars(CCS_12T_0P9V_LT_LIBS) $vars(LIB_RAM_0P9VP_0P9VC_LT_LIBS) $vars(LIB_ROM_0P9VP_0P9VC_LT_LIBS) $vars(LIB_IO_1P8V0P9V_LT_LIBS)     $vars(LIB_IP_SCAN_LT_RCWORST_HOLD_LIBS)"}
         foreach  bc_corners  [get_corner bc_*] {link_timing_library -corner $bc_corners    -search_type min_max "$vars(CCS_7T_0P9V_BC_LIBS)  $vars(CCS_9T_0P9V_BC_LIBS)  $vars(CCS_12T_0P9V_BC_LIBS) $vars(LIB_RAM_0P9VP_0P9VC_BC_LIBS) $vars(LIB_ROM_0P9VP_0P9VC_BC_LIBS) $vars(LIB_IO_1P8V0P9V_BC_LIBS) $vars(LIB_IP_SCAN_BC_CBEST_HOLD_LIBS)" }
	foreach  typ_corners [get_corner typ_25*]  {link_timing_library -corner $typ_corners  -search_type min_max "$vars(CCS_7T_0P9V_TC_LIBS)    $vars(CCS_9T_0P9V_TC_LIBS)     $vars(LIB_RAM_0P9VP_0P9VC_TC_LIBS)    $vars(LIB_ROM_0P9VP_0P9VC_TC_LIBS) $vars(LIB_IO_1P8V0P9V_TC_LIBS) $vars(LIB_IP_SCAN_TC_TYPICAL_HOLD_LIBS)"}
	foreach  typ_corners [get_corner typ_85*]  {link_timing_library -corner $typ_corners  -search_type min_max "$vars(CCS_7T_0P9V_TC85_LIBS)  $vars(CCS_9T_0P9V_TC85_LIBS)   $vars(LIB_RAM_0P9VP_0P9VC_TC85_LIBS)  $vars(LIB_ROM_0P9VP_0P9VC_TC85_LIBS)  $vars(LIB_IO_1P8V0P9V_TC85_LIBS) $vars(LIB_IP_SCAN_TC85_TYPICAL_HOLD_LIBS)"}
	foreach  typ_corners [get_corner typ_125*] {link_timing_library -corner $typ_corners  -search_type min_max "$vars(CCS_7T_0P9V_TC125_LIBS) $vars(CCS_9T_0P9V_TC125_LIBS)  $vars(LIB_RAM_0P9VP_0P9VC_TC125_LIBS) $vars(LIB_ROM_0P9VP_0P9VC_TC125_LIBS) $vars(LIB_IO_1P8V0P9V_TC125_LIBS) $vars(LIB_IP_SCAN_TC125_TYPICAL_HOLD_LIBS)"}

} else  {

foreach  wcl_corners  [get_corner wcl_*] {link_timing_library -corner $wcl_corners -search_type min_max "$vars(CCS_7T_0P9V_WCL_LIBS) $vars(CCS_9T_0P9V_WCL_LIBS) $vars(CCS_12T_0P9V_WCL_LIBS) $vars(LIB_RAM_0P9VP_0P9VC_WCL_LIBS) $vars(LIB_ROM_0P9VP_0P9VC_WCL_LIBS) $vars(LIB_IO_1P8V0P9V_WCL_LIBS) $vars(LIB_IP_SCAN_WCL_CWORST_T_SETUP_LIBS)"}
foreach  wc_corners  [get_corner wc_*] {link_timing_library -corner $wc_corners    -search_type min_max "$vars(CCS_7T_0P9V_WC_LIBS)  $vars(CCS_9T_0P9V_WC_LIBS)  $vars(CCS_12T_0P9V_WC_LIBS)  $vars(LIB_RAM_0P9VP_0P9VC_WC_LIBS) $vars(LIB_ROM_0P9VP_0P9VC_WC_LIBS)  $vars(LIB_IO_1P8V0P9V_WC_LIBS) $vars(LIB_IP_SCAN_WC_CWORST_T_SETUP_LIBS)"}
foreach  wcz_corners  [get_corner wcz_*] {link_timing_library -corner $wcz_corners -search_type min_max "$vars(CCS_7T_0P9V_WCZ_LIBS) $vars(CCS_9T_0P9V_WCZ_LIBS) $vars(CCS_12T_0P9V_WCZ_LIBS) $vars(LIB_RAM_0P9VP_0P9VC_WCZ_LIBS) $vars(LIB_ROM_0P9VP_0P9VC_WCZ_LIBS) $vars(LIB_IO_1P8V0P9V_WCZ_LIBS)   $vars(LIB_IP_SCAN_WCZ_RCWORST_SETUP_LIBS)"}
	foreach  typ_corners [get_corner typ_25*]  {link_timing_library -corner $typ_corners  -search_type min_max "$vars(CCS_7T_0P9V_TC_LIBS)    $vars(CCS_9T_0P9V_TC_LIBS)     $vars(LIB_RAM_0P9VP_0P9VC_TC_LIBS)    $vars(LIB_ROM_0P9VP_0P9VC_TC_LIBS) $vars(LIB_IO_1P8V0P9V_TC_LIBS) $vars(LIB_IP_SCAN_TC_TYPICAL_SETUP_LIBS)"}
	foreach  typ_corners [get_corner typ_85*]  {link_timing_library -corner $typ_corners  -search_type min_max "$vars(CCS_7T_0P9V_TC85_LIBS)  $vars(CCS_9T_0P9V_TC85_LIBS)   $vars(LIB_RAM_0P9VP_0P9VC_TC85_LIBS)  $vars(LIB_ROM_0P9VP_0P9VC_TC85_LIBS)  $vars(LIB_IO_1P8V0P9V_TC85_LIBS) $vars(LIB_IP_SCAN_TC85_TYPICAL_SETUP_LIBS)"}
	foreach  typ_corners [get_corner typ_125*] {link_timing_library -corner $typ_corners  -search_type min_max "$vars(CCS_7T_0P9V_TC125_LIBS) $vars(CCS_9T_0P9V_TC125_LIBS)  $vars(LIB_RAM_0P9VP_0P9VC_TC125_LIBS) $vars(LIB_ROM_0P9VP_0P9VC_TC125_LIBS) $vars(LIB_IO_1P8V0P9V_TC125_LIBS) $vars(LIB_IP_SCAN_TC125_TYPICAL_SETUP_LIBS)"}




}
} else {
        if {[regexp .*hold $scenario   ]}  {
foreach  wcl_corners  [get_corner wcl_*] {link_timing_library -corner $wcl_corners -search_type min_max "$vars(CCS_7T_0P9V_WCL_LIBS) $vars(CCS_9T_0P9V_WCL_LIBS) $vars(CCS_12T_0P9V_WCL_LIBS) $vars(LIB_RAM_0P9VP_0P9VC_WCL_LIBS) $vars(LIB_ROM_0P9VP_0P9VC_WCL_LIBS) $vars(LIB_IO_1P8V0P9V_WCL_LIBS) $vars(LIB_IP_FUNC_WCL_CWORST_HOLD_LIBS)"}
foreach  wc_corners  [get_corner wc_*] {link_timing_library -corner $wc_corners    -search_type min_max "$vars(CCS_7T_0P9V_WC_LIBS)  $vars(CCS_9T_0P9V_WC_LIBS)  $vars(CCS_12T_0P9V_WC_LIBS) $vars(LIB_RAM_0P9VP_0P9VC_WC_LIBS) $vars(LIB_ROM_0P9VP_0P9VC_WC_LIBS)  $vars(LIB_IO_1P8V0P9V_WC_LIBS) $vars(LIB_IP_FUNC_WC_CWORST_HOLD_LIBS)"}
foreach  wcz_corners  [get_corner wcz_*] {link_timing_library -corner $wcz_corners -search_type min_max "$vars(CCS_7T_0P9V_WCZ_LIBS) $vars(CCS_9T_0P9V_WCZ_LIBS) $vars(CCS_12T_0P9V_WCZ_LIBS) $vars(LIB_RAM_0P9VP_0P9VC_WCZ_LIBS) $vars(LIB_ROM_0P9VP_0P9VC_WCZ_LIBS) $vars(LIB_IO_1P8V0P9V_WCZ_LIBS)   $vars(LIB_IP_FUNC_WCZ_RCWORST_HOLD_LIBS)"}
foreach  ml_corners  [get_corner ml_*] {link_timing_library -corner $ml_corners    -search_type min_max "$vars(CCS_7T_0P9V_ML_LIBS)  $vars(CCS_9T_0P9V_ML_LIBS)  $vars(CCS_12T_0P9V_ML_LIBS) $vars(LIB_RAM_0P9VP_0P9VC_ML_LIBS) $vars(LIB_ROM_0P9VP_0P9VC_ML_LIBS) $vars(LIB_IO_1P8V0P9V_ML_LIBS)     $vars(LIB_IP_FUNC_ML_RCWORST_HOLD_LIBS)"}
foreach  lt_corners  [get_corner lt_*] {link_timing_library -corner $lt_corners    -search_type min_max "$vars(CCS_7T_0P9V_LT_LIBS)  $vars(CCS_9T_0P9V_LT_LIBS)  $vars(CCS_12T_0P9V_LT_LIBS) $vars(LIB_RAM_0P9VP_0P9VC_LT_LIBS) $vars(LIB_ROM_0P9VP_0P9VC_LT_LIBS) $vars(LIB_IO_1P8V0P9V_LT_LIBS)     $vars(LIB_IP_FUNC_LT_RCWORST_HOLD_LIBS)"}
foreach  bc_corners  [get_corner bc_*] {link_timing_library -corner $bc_corners    -search_type min_max "$vars(CCS_7T_0P9V_BC_LIBS)  $vars(CCS_9T_0P9V_BC_LIBS)  $vars(CCS_12T_0P9V_BC_LIBS) $vars(LIB_RAM_0P9VP_0P9VC_BC_LIBS) $vars(LIB_ROM_0P9VP_0P9VC_BC_LIBS) $vars(LIB_IO_1P8V0P9V_BC_LIBS) $vars(LIB_IP_FUNC_BC_CBEST_HOLD_LIBS)"}
	foreach  typ_corners [get_corner typ_25*]  {link_timing_library -corner $typ_corners  -search_type min_max "$vars(CCS_7T_0P9V_TC_LIBS)    $vars(CCS_9T_0P9V_TC_LIBS)     $vars(LIB_RAM_0P9VP_0P9VC_TC_LIBS)    $vars(LIB_ROM_0P9VP_0P9VC_TC_LIBS) $vars(LIB_IO_1P8V0P9V_TC_LIBS) $vars(LIB_IP_FUNC_TC_TYPICAL_HOLD_LIBS)"}
	foreach  typ_corners [get_corner typ_85*]  {link_timing_library -corner $typ_corners  -search_type min_max "$vars(CCS_7T_0P9V_TC85_LIBS)  $vars(CCS_9T_0P9V_TC85_LIBS)   $vars(LIB_RAM_0P9VP_0P9VC_TC85_LIBS)  $vars(LIB_ROM_0P9VP_0P9VC_TC85_LIBS)  $vars(LIB_IO_1P8V0P9V_TC85_LIBS) $vars(LIB_IP_FUNC_TC85_TYPICAL_HOLD_LIBS)"}
	foreach  typ_corners [get_corner typ_125*] {link_timing_library -corner $typ_corners  -search_type min_max "$vars(CCS_7T_0P9V_TC125_LIBS) $vars(CCS_9T_0P9V_TC125_LIBS)  $vars(LIB_RAM_0P9VP_0P9VC_TC125_LIBS) $vars(LIB_ROM_0P9VP_0P9VC_TC125_LIBS) $vars(LIB_IO_1P8V0P9V_TC125_LIBS) $vars(LIB_IP_FUNC_TC125_TYPICAL_HOLD_LIBS)"}


        }  else {
foreach  wcl_corners  [get_corner wcl_*] {link_timing_library -corner $wcl_corners -search_type min_max "$vars(CCS_7T_0P9V_WCL_LIBS) $vars(CCS_9T_0P9V_WCL_LIBS) $vars(CCS_12T_0P9V_WCL_LIBS) $vars(LIB_RAM_0P9VP_0P9VC_WCL_LIBS) $vars(LIB_ROM_0P9VP_0P9VC_WCL_LIBS) $vars(LIB_IO_1P8V0P9V_WCL_LIBS) $vars(LIB_IP_FUNC_WCL_CWORST_T_SETUP_LIBS)"}
foreach  wc_corners  [get_corner wc_*] {link_timing_library -corner $wc_corners    -search_type min_max "$vars(CCS_7T_0P9V_WC_LIBS)  $vars(CCS_9T_0P9V_WC_LIBS)  $vars(CCS_12T_0P9V_WC_LIBS) $vars(LIB_RAM_0P9VP_0P9VC_WC_LIBS) $vars(LIB_ROM_0P9VP_0P9VC_WC_LIBS)  $vars(LIB_IO_1P8V0P9V_WC_LIBS) $vars(LIB_IP_FUNC_WC_CWORST_T_SETUP_LIBS)"}
foreach  wcz_corners  [get_corner wcz_*] {link_timing_library -corner $wcz_corners -search_type min_max "$vars(CCS_7T_0P9V_WCZ_LIBS) $vars(CCS_9T_0P9V_WCZ_LIBS) $vars(CCS_12T_0P9V_WCZ_LIBS) $vars(LIB_RAM_0P9VP_0P9VC_WCZ_LIBS) $vars(LIB_ROM_0P9VP_0P9VC_WCZ_LIBS) $vars(LIB_IO_1P8V0P9V_WCZ_LIBS)   $vars(LIB_IP_FUNC_WCZ_RCWORST_SETUP_LIBS)"}

	foreach  typ_corners [get_corner typ_25*]  {link_timing_library -corner $typ_corners  -search_type min_max "$vars(CCS_7T_0P9V_TC_LIBS)    $vars(CCS_9T_0P9V_TC_LIBS)     $vars(LIB_RAM_0P9VP_0P9VC_TC_LIBS)    $vars(LIB_ROM_0P9VP_0P9VC_TC_LIBS) $vars(LIB_IO_1P8V0P9V_TC_LIBS) $vars(LIB_IP_FUNC_TC_TYPICAL_SETUP_LIBS)"}
	foreach  typ_corners [get_corner typ_85*]  {link_timing_library -corner $typ_corners  -search_type min_max "$vars(CCS_7T_0P9V_TC85_LIBS)  $vars(CCS_9T_0P9V_TC85_LIBS)   $vars(LIB_RAM_0P9VP_0P9VC_TC85_LIBS)  $vars(LIB_ROM_0P9VP_0P9VC_TC85_LIBS)  $vars(LIB_IO_1P8V0P9V_TC85_LIBS) $vars(LIB_IP_FUNC_TC85_TYPICAL_SETUP_LIBS)"}
	foreach  typ_corners [get_corner typ_125*] {link_timing_library -corner $typ_corners  -search_type min_max "$vars(CCS_7T_0P9V_TC125_LIBS) $vars(CCS_9T_0P9V_TC125_LIBS)  $vars(LIB_RAM_0P9VP_0P9VC_TC125_LIBS) $vars(LIB_ROM_0P9VP_0P9VC_TC125_LIBS) $vars(LIB_IO_1P8V0P9V_TC125_LIBS) $vars(LIB_IP_FUNC_TC125_TYPICAL_SETUP_LIBS)"}


        }
}

}


read_timing_data  -data_dir $sta_db/$VIEW/rpt/xtop/${VIEW} 

check_inst_reference_library
check_inst_timing_library


if {[file exists $vars(dont_use_list_file)] && $vars(dont_use_list_file) != ""} {
        set fileId [open $vars(dont_use_list_file) r]
        while {[gets $fileId line] >= 0} {
		set_dont_use [lindex $line 0]
	    }
      	close $fileId
}
#Leon
if {$vars(dont_use_list) != ""} {
	foreach i $vars(dont_use_list) {
		set_dont_use $i
	}
}

if {[file exists $vars(dont_touch_list_file)] && $vars(dont_touch_list_file) != ""} {
        set fileId [open $vars(dont_touch_list_file) r]
        while {[gets $fileId line] >= 0} {
		    set_dont_touch  [get_nets [lindex $line 0]]
	    }
      	close $fileId
}
set_parameter  decimal_point_tokens  P
#set_parameter  tmlib_table_sample_method fon
#set_parameter tmlib_fanout_factor {4}

set_removable_fillers {*FILL*}

#leon
if { $block_use_7t  } {

set hold_buf1 "\
DLY4_X1M_A7PP140ZTH_C40  DLY4_X2M_A7PP140ZTH_C40  DLY4_X4M_A7PP140ZTH_C40 \
DLY2_X1M_A7PP140ZTH_C40  DLY2_X2M_A7PP140ZTH_C40  DLY2_X4M_A7PP140ZTH_C40 \
DLY4_X1M_A7PP140ZTH_C35  DLY4_X2M_A7PP140ZTH_C35  DLY4_X4M_A7PP140ZTH_C35 \
DLY2_X1M_A7PP140ZTH_C35  DLY2_X2M_A7PP140ZTH_C35  DLY2_X4M_A7PP140ZTH_C35 \
DLY4_X1M_A7PP140ZTH_C30  DLY4_X2M_A7PP140ZTH_C30  DLY4_X4M_A7PP140ZTH_C30 \
DLY2_X1M_A7PP140ZTH_C30  DLY2_X2M_A7PP140ZTH_C30  DLY2_X4M_A7PP140ZTH_C30 \
DLY4_X1M_A7PP140ZTS_C40  DLY4_X2M_A7PP140ZTS_C40  DLY4_X4M_A7PP140ZTS_C40 \
DLY2_X1M_A7PP140ZTS_C40  DLY2_X2M_A7PP140ZTS_C40  DLY2_X4M_A7PP140ZTS_C40 \
DLY4_X1M_A7PP140ZTS_C35  DLY4_X2M_A7PP140ZTS_C35  DLY4_X4M_A7PP140ZTS_C35 \
DLY2_X1M_A7PP140ZTS_C35  DLY2_X2M_A7PP140ZTS_C35  DLY2_X4M_A7PP140ZTS_C35 \ 
BUF_X1P7M_A7PP140ZTH_C40 BUF_X1P7B_A7PP140ZTH_C40 BUF_X1P4M_A7PP140ZTH_C40 BUF_X1P4B_A7PP140ZTH_C40 BUF_X1M_A7PP140ZTH_C40 BUF_X1B_A7PP140ZTH_C40 BUF_X2M_A7PP140ZTH_C40 BUF_X2B_A7PP140ZTH_C40 \
BUF_X1P7M_A7PP140ZTH_C35 BUF_X1P7B_A7PP140ZTH_C35 BUF_X1P4M_A7PP140ZTH_C35 BUF_X1P4B_A7PP140ZTH_C35 BUF_X1M_A7PP140ZTH_C35 BUF_X1B_A7PP140ZTH_C35 BUF_X2M_A7PP140ZTH_C35 BUF_X2B_A7PP140ZTH_C35 \
BUF_X1P7M_A7PP140ZTH_C30 BUF_X1P7B_A7PP140ZTH_C30 BUF_X1P4M_A7PP140ZTH_C30 BUF_X1P4B_A7PP140ZTH_C30 BUF_X1M_A7PP140ZTH_C30 BUF_X1B_A7PP140ZTH_C30 BUF_X2M_A7PP140ZTH_C30 BUF_X2B_A7PP140ZTH_C30 \
BUF_X1P7M_A7PP140ZTS_C40 BUF_X1P7B_A7PP140ZTS_C40 BUF_X1P4M_A7PP140ZTS_C40 BUF_X1P4B_A7PP140ZTS_C40 BUF_X1M_A7PP140ZTS_C40 BUF_X1B_A7PP140ZTS_C40 BUF_X2M_A7PP140ZTS_C40 BUF_X2B_A7PP140ZTS_C40 \
BUF_X1P7M_A7PP140ZTS_C35 BUF_X1P7B_A7PP140ZTS_C35 BUF_X1P4M_A7PP140ZTS_C35 BUF_X1P4B_A7PP140ZTS_C35 BUF_X1M_A7PP140ZTS_C35 BUF_X1B_A7PP140ZTS_C35 BUF_X2M_A7PP140ZTS_C35 BUF_X2B_A7PP140ZTS_C35 \
BUF_X1P7M_A7PP140ZTS_C30 BUF_X1P7B_A7PP140ZTS_C30 BUF_X1P4M_A7PP140ZTS_C30 BUF_X1P4B_A7PP140ZTS_C30 BUF_X1M_A7PP140ZTS_C30 BUF_X1B_A7PP140ZTS_C30 BUF_X2M_A7PP140ZTS_C30 BUF_X2B_A7PP140ZTS_C30 \
 "
set hold_buf2 "\
DLY4_X1M_A7PP140ZTS_C40  DLY4_X2M_A7PP140ZTS_C40  DLY4_X4M_A7PP140ZTS_C40 \
DLY2_X1M_A7PP140ZTS_C40  DLY2_X2M_A7PP140ZTS_C40  DLY2_X4M_A7PP140ZTS_C40 \
DLY4_X1M_A7PP140ZTS_C35  DLY4_X2M_A7PP140ZTS_C35  DLY4_X4M_A7PP140ZTS_C35 \
DLY2_X1M_A7PP140ZTS_C35  DLY2_X2M_A7PP140ZTS_C35  DLY2_X4M_A7PP140ZTS_C35 \ 
BUF_X1P7M_A7PP140ZTS_C40 BUF_X1P7B_A7PP140ZTS_C40 BUF_X1P4M_A7PP140ZTS_C40 BUF_X1P4B_A7PP140ZTS_C40 BUF_X1M_A7PP140ZTS_C40 BUF_X1B_A7PP140ZTS_C40 BUF_X2M_A7PP140ZTS_C40 BUF_X2B_A7PP140ZTS_C40 \
BUF_X1P7M_A7PP140ZTS_C35 BUF_X1P7B_A7PP140ZTS_C35 BUF_X1P4M_A7PP140ZTS_C35 BUF_X1P4B_A7PP140ZTS_C35 BUF_X1M_A7PP140ZTS_C35 BUF_X1B_A7PP140ZTS_C35 BUF_X2M_A7PP140ZTS_C35 BUF_X2B_A7PP140ZTS_C35 \
BUF_X1P7M_A7PP140ZTS_C30 BUF_X1P7B_A7PP140ZTS_C30 BUF_X1P4M_A7PP140ZTS_C30 BUF_X1P4B_A7PP140ZTS_C30 BUF_X1M_A7PP140ZTS_C30 BUF_X1B_A7PP140ZTS_C30 BUF_X2M_A7PP140ZTS_C30 BUF_X2B_A7PP140ZTS_C30 \
 "
set hold_buf3 "\
BUF_X1P7M_A7PP140ZTS_C40 BUF_X1P7B_A7PP140ZTS_C40 BUF_X1P4M_A7PP140ZTS_C40 BUF_X1P4B_A7PP140ZTS_C40 BUF_X1P2M_A7PP140ZTS_C40 BUF_X1P2B_A7PP140ZTS_C40 BUF_X1M_A7PP140ZTS_C40 BUF_X1B_A7PP140ZTS_C40 BUF_X2P5M_A7PP140ZTS_C40 BUF_X2P5B_A7PP140ZTS_C40 BUF_X2M_A7PP140ZTS_C40 BUF_X2B_A7PP140ZTS_C40 BUF_X3P5M_A7PP140ZTS_C40 BUF_X3P5B_A7PP140ZTS_C40 BUF_X3M_A7PP140ZTS_C40 BUF_X3B_A7PP140ZTS_C40 \
BUF_X1P7M_A7PP140ZTS_C35 BUF_X1P7B_A7PP140ZTS_C35 BUF_X1P4M_A7PP140ZTS_C35 BUF_X1P4B_A7PP140ZTS_C35 BUF_X1P2M_A7PP140ZTS_C35 BUF_X1P2B_A7PP140ZTS_C35 BUF_X1M_A7PP140ZTS_C35 BUF_X1B_A7PP140ZTS_C35 BUF_X2P5M_A7PP140ZTS_C35 BUF_X2P5B_A7PP140ZTS_C35 BUF_X2M_A7PP140ZTS_C35 BUF_X2B_A7PP140ZTS_C35 BUF_X3P5M_A7PP140ZTS_C35 BUF_X3P5B_A7PP140ZTS_C35 BUF_X3M_A7PP140ZTS_C35 BUF_X3B_A7PP140ZTS_C35 \
BUF_X1P7M_A7PP140ZTS_C30 BUF_X1P7B_A7PP140ZTS_C30 BUF_X1P4M_A7PP140ZTS_C30 BUF_X1P4B_A7PP140ZTS_C30 BUF_X1P2M_A7PP140ZTS_C30 BUF_X1P2B_A7PP140ZTS_C30 BUF_X1M_A7PP140ZTS_C30 BUF_X1B_A7PP140ZTS_C30 BUF_X2P5M_A7PP140ZTS_C30 BUF_X2P5B_A7PP140ZTS_C30 BUF_X2M_A7PP140ZTS_C30 BUF_X2B_A7PP140ZTS_C30 BUF_X3P5M_A7PP140ZTS_C30 BUF_X3P5B_A7PP140ZTS_C30 BUF_X3M_A7PP140ZTS_C30 BUF_X3B_A7PP140ZTS_C30 \
 "
}

if { $block_use_9t  } {
set hold_buf1 "\
DLY4_X1M_A9PP140ZTH_C40  DLY4_X2M_A9PP140ZTH_C40  DLY4_X4M_A9PP140ZTH_C40 \
DLY2_X1M_A9PP140ZTH_C40  DLY2_X2M_A9PP140ZTH_C40  DLY2_X4M_A9PP140ZTH_C40 \
DLY4_X1M_A9PP140ZTH_C35  DLY4_X2M_A9PP140ZTH_C35  DLY4_X4M_A9PP140ZTH_C35 \
DLY2_X1M_A9PP140ZTH_C35  DLY2_X2M_A9PP140ZTH_C35  DLY2_X4M_A9PP140ZTH_C35 \
DLY4_X1M_A9PP140ZTH_C30  DLY4_X2M_A9PP140ZTH_C30  DLY4_X4M_A9PP140ZTH_C30 \
DLY2_X1M_A9PP140ZTH_C30  DLY2_X2M_A9PP140ZTH_C30  DLY2_X4M_A9PP140ZTH_C30 \
DLY4_X1M_A9PP140ZTS_C40  DLY4_X2M_A9PP140ZTS_C40  DLY4_X4M_A9PP140ZTS_C40 \
DLY2_X1M_A9PP140ZTS_C40  DLY2_X2M_A9PP140ZTS_C40  DLY2_X4M_A9PP140ZTS_C40 \
DLY4_X1M_A9PP140ZTS_C35  DLY4_X2M_A9PP140ZTS_C35  DLY4_X4M_A9PP140ZTS_C35 \
DLY2_X1M_A9PP140ZTS_C35  DLY2_X2M_A9PP140ZTS_C35  DLY2_X4M_A9PP140ZTS_C35 \ 
BUF_X1P7M_A9PP140ZTH_C40 BUF_X1P7B_A9PP140ZTH_C40 BUF_X1P4M_A9PP140ZTH_C40 BUF_X1P4B_A9PP140ZTH_C40 BUF_X1M_A9PP140ZTH_C40 BUF_X1B_A9PP140ZTH_C40 BUF_X2M_A9PP140ZTH_C40 BUF_X2B_A9PP140ZTH_C40 \
BUF_X1P7M_A9PP140ZTH_C35 BUF_X1P7B_A9PP140ZTH_C35 BUF_X1P4M_A9PP140ZTH_C35 BUF_X1P4B_A9PP140ZTH_C35 BUF_X1M_A9PP140ZTH_C35 BUF_X1B_A9PP140ZTH_C35 BUF_X2M_A9PP140ZTH_C35 BUF_X2B_A9PP140ZTH_C35 \
BUF_X1P7M_A9PP140ZTH_C30 BUF_X1P7B_A9PP140ZTH_C30 BUF_X1P4M_A9PP140ZTH_C30 BUF_X1P4B_A9PP140ZTH_C30 BUF_X1M_A9PP140ZTH_C30 BUF_X1B_A9PP140ZTH_C30 BUF_X2M_A9PP140ZTH_C30 BUF_X2B_A9PP140ZTH_C30 \
BUF_X1P7M_A9PP140ZTS_C40 BUF_X1P7B_A9PP140ZTS_C40 BUF_X1P4M_A9PP140ZTS_C40 BUF_X1P4B_A9PP140ZTS_C40 BUF_X1M_A9PP140ZTS_C40 BUF_X1B_A9PP140ZTS_C40 BUF_X2M_A9PP140ZTS_C40 BUF_X2B_A9PP140ZTS_C40 \
BUF_X1P7M_A9PP140ZTS_C35 BUF_X1P7B_A9PP140ZTS_C35 BUF_X1P4M_A9PP140ZTS_C35 BUF_X1P4B_A9PP140ZTS_C35 BUF_X1M_A9PP140ZTS_C35 BUF_X1B_A9PP140ZTS_C35 BUF_X2M_A9PP140ZTS_C35 BUF_X2B_A9PP140ZTS_C35 \
BUF_X1P7M_A9PP140ZTS_C30 BUF_X1P7B_A9PP140ZTS_C30 BUF_X1P4M_A9PP140ZTS_C30 BUF_X1P4B_A9PP140ZTS_C30 BUF_X1M_A9PP140ZTS_C30 BUF_X1B_A9PP140ZTS_C30 BUF_X2M_A9PP140ZTS_C30 BUF_X2B_A9PP140ZTS_C30 \
 "
set hold_buf2 "\
DLY4_X1M_A9PP140ZTS_C40  DLY4_X2M_A9PP140ZTS_C40  DLY4_X4M_A9PP140ZTS_C40 \
DLY2_X1M_A9PP140ZTS_C40  DLY2_X2M_A9PP140ZTS_C40  DLY2_X4M_A9PP140ZTS_C40 \
DLY4_X1M_A9PP140ZTS_C35  DLY4_X2M_A9PP140ZTS_C35  DLY4_X4M_A9PP140ZTS_C35 \
DLY2_X1M_A9PP140ZTS_C35  DLY2_X2M_A9PP140ZTS_C35  DLY2_X4M_A9PP140ZTS_C35 \ 
BUF_X1P7M_A9PP140ZTS_C40 BUF_X1P7B_A9PP140ZTS_C40 BUF_X1P4M_A9PP140ZTS_C40 BUF_X1P4B_A9PP140ZTS_C40 BUF_X1M_A9PP140ZTS_C40 BUF_X1B_A9PP140ZTS_C40 BUF_X2M_A9PP140ZTS_C40 BUF_X2B_A9PP140ZTS_C40 \
BUF_X1P7M_A9PP140ZTS_C35 BUF_X1P7B_A9PP140ZTS_C35 BUF_X1P4M_A9PP140ZTS_C35 BUF_X1P4B_A9PP140ZTS_C35 BUF_X1M_A9PP140ZTS_C35 BUF_X1B_A9PP140ZTS_C35 BUF_X2M_A9PP140ZTS_C35 BUF_X2B_A9PP140ZTS_C35 \
BUF_X1P7M_A9PP140ZTS_C30 BUF_X1P7B_A9PP140ZTS_C30 BUF_X1P4M_A9PP140ZTS_C30 BUF_X1P4B_A9PP140ZTS_C30 BUF_X1M_A9PP140ZTS_C30 BUF_X1B_A9PP140ZTS_C30 BUF_X2M_A9PP140ZTS_C30 BUF_X2B_A9PP140ZTS_C30 \
 "
set hold_buf3 "\
BUF_X1P7M_A9PP140ZTS_C40 BUF_X1P7B_A9PP140ZTS_C40 BUF_X1P4M_A9PP140ZTS_C40 BUF_X1P4B_A9PP140ZTS_C40 BUF_X1P2M_A9PP140ZTS_C40 BUF_X1P2B_A9PP140ZTS_C40 BUF_X1M_A9PP140ZTS_C40 BUF_X1B_A9PP140ZTS_C40 BUF_X2P5M_A9PP140ZTS_C40 BUF_X2P5B_A9PP140ZTS_C40 BUF_X2M_A9PP140ZTS_C40 BUF_X2B_A9PP140ZTS_C40 BUF_X3P5M_A9PP140ZTS_C40 BUF_X3P5B_A9PP140ZTS_C40 BUF_X3M_A9PP140ZTS_C40 BUF_X3B_A9PP140ZTS_C40 \
BUF_X1P7M_A9PP140ZTS_C35 BUF_X1P7B_A9PP140ZTS_C35 BUF_X1P4M_A9PP140ZTS_C35 BUF_X1P4B_A9PP140ZTS_C35 BUF_X1P2M_A9PP140ZTS_C35 BUF_X1P2B_A9PP140ZTS_C35 BUF_X1M_A9PP140ZTS_C35 BUF_X1B_A9PP140ZTS_C35 BUF_X2P5M_A9PP140ZTS_C35 BUF_X2P5B_A9PP140ZTS_C35 BUF_X2M_A9PP140ZTS_C35 BUF_X2B_A9PP140ZTS_C35 BUF_X3P5M_A9PP140ZTS_C35 BUF_X3P5B_A9PP140ZTS_C35 BUF_X3M_A9PP140ZTS_C35 BUF_X3B_A9PP140ZTS_C35 \
BUF_X1P7M_A9PP140ZTS_C30 BUF_X1P7B_A9PP140ZTS_C30 BUF_X1P4M_A9PP140ZTS_C30 BUF_X1P4B_A9PP140ZTS_C30 BUF_X1P2M_A9PP140ZTS_C30 BUF_X1P2B_A9PP140ZTS_C30 BUF_X1M_A9PP140ZTS_C30 BUF_X1B_A9PP140ZTS_C30 BUF_X2P5M_A9PP140ZTS_C30 BUF_X2P5B_A9PP140ZTS_C30 BUF_X2M_A9PP140ZTS_C30 BUF_X2B_A9PP140ZTS_C30 BUF_X3P5M_A9PP140ZTS_C30 BUF_X3P5B_A9PP140ZTS_C30 BUF_X3M_A9PP140ZTS_C30 BUF_X3B_A9PP140ZTS_C30 \
 "

}
if { $block_use_12t  } {
set hold_buf1 "\
 DLY10_X1M_A12PP140ZTH_C40  DLY10_X2M_A12PP140ZTH_C40  DLY10_X4M_A12PP140ZTH_C40 \
 DLY8_X1M_A12PP140ZTH_C40  DLY8_X2M_A12PP140ZTH_C40  DLY8_X4M_A12PP140ZTH_C40 \
 DLY6_X1M_A12PP140ZTH_C40  DLY6_X2M_A12PP140ZTH_C40  DLY6_X4M_A12PP140ZTH_C40 \
 DLY4_X1M_A12PP140ZTH_C40  DLY4_X2M_A12PP140ZTH_C40  DLY4_X4M_A12PP140ZTH_C40 \
 DLY2_X1M_A12PP140ZTH_C40  DLY2_X2M_A12PP140ZTH_C40  DLY2_X4M_A12PP140ZTH_C40 \
    "
set hold_buf2 "\
 DLY10_X1M_A12PP140ZTH_C40  DLY10_X2M_A12PP140ZTH_C40  DLY10_X4M_A12PP140ZTH_C40 \
 DLY8_X1M_A12PP140ZTH_C40  DLY8_X2M_A12PP140ZTH_C40  DLY8_X4M_A12PP140ZTH_C40 \
 DLY6_X1M_A12PP140ZTH_C40  DLY6_X2M_A12PP140ZTH_C40  DLY6_X4M_A12PP140ZTH_C40 \
 DLY4_X1M_A12PP140ZTH_C40  DLY4_X2M_A12PP140ZTH_C40  DLY4_X4M_A12PP140ZTH_C40 \
 DLY2_X1M_A12PP140ZTH_C40  DLY2_X2M_A12PP140ZTH_C40  DLY2_X4M_A12PP140ZTH_C40 \
 DLY10_X1M_A12PP140ZTS_C40  DLY10_X2M_A12PP140ZTS_C40  DLY10_X4M_A12PP140ZTS_C40 \
 DLY8_X1M_A12PP140ZTS_C40  DLY8_X2M_A12PP140ZTS_C40  DLY8_X4M_A12PP140ZTS_C40 \
 DLY6_X1M_A12PP140ZTS_C40  DLY6_X2M_A12PP140ZTS_C40  DLY6_X4M_A12PP140ZTS_C40 \
 DLY4_X1M_A12PP140ZTS_C40  DLY4_X2M_A12PP140ZTS_C40  DLY4_X4M_A12PP140ZTS_C40 \
 DLY2_X1M_A12PP140ZTS_C40  DLY2_X2M_A12PP140ZTS_C40  DLY2_X4M_A12PP140ZTS_C40 \ 
 DLY10_X1M_A12PP140ZTH_C35  DLY10_X2M_A12PP140ZTH_C35  DLY10_X4M_A12PP140ZTH_C35 \
 DLY8_X1M_A12PP140ZTH_C35  DLY8_X2M_A12PP140ZTH_C35  DLY8_X4M_A12PP140ZTH_C35 \
 DLY6_X1M_A12PP140ZTH_C35  DLY6_X2M_A12PP140ZTH_C35  DLY6_X4M_A12PP140ZTH_C35 \
 DLY4_X1M_A12PP140ZTH_C35  DLY4_X2M_A12PP140ZTH_C35  DLY4_X4M_A12PP140ZTH_C35 \
 DLY2_X1M_A12PP140ZTH_C35  DLY2_X2M_A12PP140ZTH_C35  DLY2_X4M_A12PP140ZTH_C35 \
 DLY10_X1M_A12PP140ZTS_C35  DLY10_X2M_A12PP140ZTS_C35  DLY10_X4M_A12PP140ZTS_C35 \
 DLY8_X1M_A12PP140ZTS_C35  DLY8_X2M_A12PP140ZTS_C35  DLY8_X4M_A12PP140ZTS_C35 \
 DLY6_X1M_A12PP140ZTS_C35  DLY6_X2M_A12PP140ZTS_C35  DLY6_X4M_A12PP140ZTS_C35 \
 DLY4_X1M_A12PP140ZTS_C35  DLY4_X2M_A12PP140ZTS_C35  DLY4_X4M_A12PP140ZTS_C35 \
 DLY2_X1M_A12PP140ZTS_C35  DLY2_X2M_A12PP140ZTS_C35  DLY2_X4M_A12PP140ZTS_C35 \ 
 DLY10_X1M_A12PP140ZTL_C35  DLY10_X2M_A12PP140ZTL_C35  DLY10_X4M_A12PP140ZTL_C35 \
 DLY8_X1M_A12PP140ZTL_C35  DLY8_X2M_A12PP140ZTL_C35  DLY8_X4M_A12PP140ZTL_C35 \
 DLY6_X1M_A12PP140ZTL_C35  DLY6_X2M_A12PP140ZTL_C35  DLY6_X4M_A12PP140ZTL_C35 \
 DLY4_X1M_A12PP140ZTL_C35  DLY4_X2M_A12PP140ZTL_C35  DLY4_X4M_A12PP140ZTL_C35 \
 DLY2_X1M_A12PP140ZTL_C35  DLY2_X2M_A12PP140ZTL_C35  DLY2_X4M_A12PP140ZTL_C35 \ 
    "
set hold_buf3 "BUFH_X11M_A12PP140ZTS_C30 BUFH_X13M_A12PP140ZTS_C30 BUFH_X16M_A12PP140ZTS_C30 BUFH_X2M_A12PP140ZTS_C30 BUFH_X3M_A12PP140ZTS_C30 BUFH_X4M_A12PP140ZTS_C30 BUFH_X5M_A12PP140ZTS_C30 BUFH_X6M_A12PP140ZTS_C30 BUFH_X9M_A12PP140ZTS_C30 BUF_X11B_A12PP140ZTS_C30 BUF_X11M_A12PP140ZTS_C30 BUF_X13B_A12PP140ZTS_C30 BUF_X13M_A12PP140ZTS_C30 BUF_X16B_A12PP140ZTS_C30 BUF_X16M_A12PP140ZTS_C30 BUF_X2B_A12PP140ZTS_C30 BUF_X2M_A12PP140ZTS_C30 BUF_X3B_A12PP140ZTS_C30 BUF_X3M_A12PP140ZTS_C30 BUF_X4B_A12PP140ZTS_C30 BUF_X4M_A12PP140ZTS_C30 BUF_X5B_A12PP140ZTS_C30 BUF_X5M_A12PP140ZTS_C30 BUF_X6B_A12PP140ZTS_C30 BUF_X6M_A12PP140ZTS_C30 BUF_X9B_A12PP140ZTS_C30 BUF_X9M_A12PP140ZTS_C30 \
BUFH_X11M_A12PP140ZTS_C35 BUFH_X13M_A12PP140ZTS_C35 BUFH_X16M_A12PP140ZTS_C35 BUFH_X2M_A12PP140ZTS_C35 BUFH_X3M_A12PP140ZTS_C35 BUFH_X4M_A12PP140ZTS_C35 BUFH_X5M_A12PP140ZTS_C35 BUFH_X6M_A12PP140ZTS_C35 BUFH_X9M_A12PP140ZTS_C35 BUF_X11B_A12PP140ZTS_C35 BUF_X11M_A12PP140ZTS_C35 BUF_X13B_A12PP140ZTS_C35 BUF_X13M_A12PP140ZTS_C35 BUF_X16B_A12PP140ZTS_C35 BUF_X16M_A12PP140ZTS_C35 BUF_X2B_A12PP140ZTS_C35 BUF_X2M_A12PP140ZTS_C35 BUF_X3B_A12PP140ZTS_C35 BUF_X3M_A12PP140ZTS_C35 BUF_X4B_A12PP140ZTS_C35 BUF_X4M_A12PP140ZTS_C35 BUF_X5B_A12PP140ZTS_C35 BUF_X5M_A12PP140ZTS_C35 BUF_X6B_A12PP140ZTS_C35 BUF_X6M_A12PP140ZTS_C35 BUF_X9B_A12PP140ZTS_C35 BUF_X9M_A12PP140ZTS_C35 \
 "


}



#set_parameter eco_buffer_list_for_setup {BUFFD4BWP7T35P140 BUFFD4BWP7T30P140 BUFFD6BWP7T35P140 BUFFD6BWP7T30P140 BUFFD8BWP7T35P140 BUFFD8BWP7T30P140 BUFFD12BWP7T35P140 BUFFD12BWP7T30P140 }
#set_parameter eco_buffer_group {BUF* DLY*} ;
set_parameter eco_cell_classify_rule {cell_attribute}  ;
set_parameter eco_cell_match_attribute {footprint} ;

#set_parameter eco_cell_nominal_swap_keywords {"LVT" "" "HVT"}  ;
#Leon
#set_parameter eco_cell_nominal_swap_keywords {"LVT@30P" "LVT@35P" "LVT@40P" "@30P" "@35P" "@40P" "HVT@30P" "HVT@35P" "HVT@40P"}  ;
#set_parameter eco_cell_nominal_swap_keywords {"ZTUL@C30" "ZTUL@C35" "ZTUL@C40" "ZTL@C30"  "ZTL@C35" "ZTL@C40" "ZTS@C30"  "ZTS@C35" "ZTS@C40" "ZTH@C30" "ZTH@C35" "ZTH@C40"}  ;
set_parameter eco_cell_nominal_swap_keywords {"ZTL_C30"  "ZTL_C35" "ZTL_C40" "ZTS_C30"  "ZTS_C35" "ZTS_C40" "ZTH_C30" "ZTH_C35" "ZTH_C40"}
#set_parameter eco_cell_nominal_sizing_pattern {D([0-9])+BWP}  ;
set_parameter eco_cell_nominal_sizing_pattern {X([0-9])+};

#set_parameter placement_legalization_mode true
set_placement_constraint  -max_displacement {10 1} -min_filler_width 0
report_placement_constraint

set_skip_scenarios [get_scenario *setup]  -min true 

#set_skip_scenarios [get_scenario *hold]  -max true


summarize_transition_violations -as_reference
summarize_capacitance_violations  -as_reference
summarize_gba_violations  -r2r_only  -as_reference -setup
summarize_gba_violations  -r2r_only  -as_reference -hold

#summarize_gba_violations    -as_reference -setup
#summarize_gba_violations    -as_reference -hold


#### block dont touch setting
#set_module_dont_touch { sby_top  lb_dsp lb_lte_modem_top}
#set_module_dont_touch {lb_lte_modem_top}
#set_specific_lib_cells -design lb_cpu [get_lib_cells *LVT] -recursive 

set_parameter eco_new_object_prefix "xtop_tran_${prefix}"

#Leon: ignore io path
set_dont_touch [get_io_path_pins]  true

if {$FIX_DRC == "true"} {
fix_transition_violations -methods "size_cell" -size_rule nominal_keywords
fix_transition_violations -methods "size_cell" -size_rule nominal_regex
#fix_transition_violations -methods "split_net"
#fix_transition_violations -methods "insert_buffer"
summarize_transition_violations -with_reference
set_parameter eco_new_object_prefix "xtop_cap_${prefix}"
fix_capacitance_violations -methods "size_cell"
#fix_capacitance_violations -methods "split_net"
#fix_capacitance_violations -methods "insert_buffer"

summarize_capacitance_violations -with_reference
write_design_changes -format INNOVUS -eco_file_prefix xtop_opt_innovus_maxTran_${eco_VIEW} -output_dir ../dsn/eco/
write_design_changes -format INNOVUS -eco_file_prefix xtop_opt_innovus_maxTran_atomic_${eco_VIEW} -output_dir ../dsn/eco/  -write_atomic_cmd
}





if {$FIX_SETUP == "true"} {
set_parameter eco_new_object_prefix "xtop_setup_${prefix}"
fix_setup_gba_violations -methods "size_cell" -size_rule nominal_keywords -setup_target 0.005 -hold_margin 0
fix_setup_gba_violations -methods "size_cell" -size_rule nominal_keywords -setup_target 0.005 -hold_margin 0 -dff_only
fix_setup_gba_violations -methods "size_cell" -size_rule nominal_regex -effort $EFFORT -setup_target 0.005 -hold_margin 0

##Leon
#set_parameter eco_buffer_group {BUFF* DEL*}
set_parameter eco_buffer_group {BUF* DLY*}
fix_setup_gba_violations -methods "size_cell" -size_rule cell_attribute -effort $EFFORT -setup_target 0.005 -hold_margin 0

summarize_gba_violations  -r2r_only  -with_reference  -setup
summarize_gba_violations  -setup -with_top_n  1000  -r2r_only  -with_fail_reason > rpt/fix_setup_failed.${eco_VIEW}
#summarize_gba_violations  -setup -with_top_n  1000    -with_fail_reason > rpt/fix_setup_failed.${eco_VIEW}

write_design_changes -format INNOVUS -eco_file_prefix xtop_opt_innovus_setup_${eco_VIEW} -output_dir ../dsn/eco/
#write_design_changes -format INNOVUS -eco_file_prefix xtop_opt_innovus_setup_atomic_${eco_VIEW} -output_dir ../dsn/eco/  -write_atomic_cmd
}


if {$FIX_HOLD == "true"} {
#Leon 
set_parameter eco_new_object_prefix "xtop_hold_${prefix}"
set_placement_constraint  -max_displacement {1 1} -min_filler_width 0
report_placement_constraint
fix_hold_gba_violations -size_cell_only -size_rule nominal_keywords -hold_target 0.005 -setup_margin 0.005
fix_hold_gba_violations -size_cell_only -size_rule nominal_keywords -hold_target 0.005 -setup_margin 0.1 -dff_only
fix_hold_gba_violations -size_cell_only -size_rule nominal_regex -hold_target 0.005 -setup_margin 0.005

set_parameter eco_buffer_group {BUF* DLY*}
fix_hold_gba_violations -size_cell_only -size_rule cell_attribute -hold_target 0.005 -setup_margin 0.05
#1st insert_buf
set_parameter eco_buffer_list_for_hold $hold_buf1
fix_hold_gba_violations -effort $EFFORT  -hold_target 0.005 -setup_margin 0.005
#2nd insert_buf
set_placement_constraint  -max_displacement {10 1} -min_filler_width 0
report_placement_constraint
set_parameter eco_buffer_list_for_hold $hold_buf2
fix_hold_gba_violations -effort $EFFORT  -hold_target 0.005 -setup_margin 0.005
#3rd insert_buf
set_placement_constraint  -max_displacement {30 1} -min_filler_width 0
report_placement_constraint
set_parameter eco_buffer_list_for_hold $hold_buf3
fix_hold_gba_violations -effort $EFFORT  -hold_target 0.005 -setup_margin 0.005
#set_parameter placement_legalization_mode false
#set_parameter eco_driver_setup_slack_deterioration 0.05

summarize_gba_violations  -r2r_only  -with_reference  -hold
summarize_gba_violations  -with_reference  -hold



summarize_gba_violations  -hold -with_top_n  1000  -r2r_only  -with_fail_reason > rpt/fix_hold_failed.${eco_VIEW}
#summarize_gba_violations  -hold -with_top_n  1000  -with_fail_reason > rpt/fix_hold_failed.${eco_VIEW}
}

if {$FIX_LKG == "true"} {
optimize_leakage_power  -setup_margin 0.1 -transition_margin 0.03 -dff_only
optimize_leakage_power  -setup_margin 0.03 -transition_margin 0.02 -effort $EFFORT
}
#fix_si_violations   -max_si  0.01  -methods size_cell   [get_setup_gba_violated_pins]
#fix_si_violations   -max_si  0.01  -methods split_net -buffer BUF_X4M_A7PP140ZTS_C35  [get_setup_gba_violated_pins]
#fix_si_violations   -max_si  0.01  -methods split_net -buffer   [get_setup_gba_violated_pins]

write_design_changes -format INNOVUS -eco_file_prefix xtop_opt_innovus_${eco_VIEW} -output_dir ../dsn/eco/
write_design_changes -format INNOVUS -eco_file_prefix xtop_opt_innovus_atomic_${eco_VIEW} -output_dir ../dsn/eco/  -write_atomic_cmd

exec  touch ../dsn/eco/${DESIGN_NAME}_eco.${eco_VIEW}.done

puts [exec date]
exit
 #echo "$eco_VIEW END [exec date]" >> runtime
