###pr -m -t -s'' ramlib_format postfix | awk '{print $1,$NF}' 
set dir "/eda_files/proj/ict8810/swap/to_vct/04_lib/241214_8810_ram_pick"
set rams [exec ls $dir]
proc ramlib_format {file0 dir rams type protfix} {
	puts $file0 "set vars($type) \" \\"
	foreach r $rams {
		if {[regexp AU28 $r]} {
			puts $file0 "${dir}/${r}/${r}${protfix} \\"
		}
	}
	puts $file0 "\""
}
set file0 [open ./lib_ram_1223.tcl w]

ramlib_format $file0 $dir $rams LEF_RAM_LIBS .lef
ramlib_format $file0 $dir $rams GDS_RAM_LIBS .gds2
ramlib_format $file0 $dir $rams CDL_RAM_LIBS .cdl
ramlib_format $file0 $dir $rams MDT_RAM_LIBS .mdt
ramlib_format $file0 $dir $rams MBIST_RAM_LIBS .memlib
ramlib_format $file0 $dir $rams VLG_RAM_LIBS .v
ramlib_format $file0 $dir $rams LIB_RAM_0P9VP_0P9VC_WCL_LIBS _ssg_cworstt_0p81v_0p81v_m40c.lib_ccs_tn_sh5p1cm
ramlib_format $file0 $dir $rams LIB_RAM_1P0VP_1P0VC_WCL_LIBS _ssg_cworstt_0p90v_0p90v_m40c.lib_ccs_tn_sh5p1cm
ramlib_format $file0 $dir $rams AOCV_RAM_0P9VP_0P9VC_WCL_LIBS _ssg_cworstt_0p81v_0p81v_m40c.aocv3
ramlib_format $file0 $dir $rams AOCV_RAM_1P0VP_1P0VC_WCL_LIBS _ssg_cworstt_0p90v_0p90v_m40c.aocv3
ramlib_format $file0 $dir $rams DB_RAM_0P9VP_0P9VC_WCL_LIBS _ssg_cworstt_0p81v_0p81v_m40c.db
ramlib_format $file0 $dir $rams DB_RAM_1P0VP_1P0VC_WCL_LIBS _ssg_cworstt_0p90v_0p90v_m40c.db
ramlib_format $file0 $dir $rams LIB_RAM_0P9VP_0P9VC_WC_LIBS _ssg_cworstt_0p81v_0p81v_125c.lib_ccs_tn_sh5p1cm
ramlib_format $file0 $dir $rams LIB_RAM_1P0VP_1P0VC_WC_LIBS _ssg_cworstt_0p90v_0p90v_125c.lib_ccs_tn_sh5p1cm
ramlib_format $file0 $dir $rams AOCV_RAM_0P9VP_0P9VC_WC_LIBS _ssg_cworstt_0p81v_0p81v_125c.aocv3
ramlib_format $file0 $dir $rams AOCV_RAM_1P0VP_1P0VC_WC_LIBS _ssg_cworstt_0p90v_0p90v_125c.aocv3
ramlib_format $file0 $dir $rams DB_RAM_0P9VP_0P9VC_WC_LIBS _ssg_cworstt_0p81v_0p81v_125c.db
ramlib_format $file0 $dir $rams DB_RAM_1P0VP_1P0VC_WC_LIBS _ssg_cworstt_0p90v_0p90v_125c.db
ramlib_format $file0 $dir $rams LIB_RAM_0P9VP_0P9VC_WCZ_LIBS _ssg_cworstt_0p81v_0p81v_0c.lib_ccs_tn_sh5p1cm
ramlib_format $file0 $dir $rams LIB_RAM_1P0VP_1P0VC_WCZ_LIBS _ssg_cworstt_0p90v_0p90v_0c.lib_ccs_tn_sh5p1cm
ramlib_format $file0 $dir $rams AOCV_RAM_0P9VP_0P9VC_WCZ_LIBS _ssg_cworstt_0p81v_0p81v_0c.aocv3
ramlib_format $file0 $dir $rams AOCV_RAM_1P0VP_1P0VC_WCZ_LIBS _ssg_cworstt_0p90v_0p90v_0c.aocv3
ramlib_format $file0 $dir $rams DB_RAM_0P9VP_0P9VC_WCZ_LIBS _ssg_cworstt_0p81v_0p81v_0c.db
ramlib_format $file0 $dir $rams DB_RAM_1P0VP_1P0VC_WCZ_LIBS _ssg_cworstt_0p90v_0p90v_0c.db
ramlib_format $file0 $dir $rams LIB_RAM_0P9VP_0P9VC_ML_LIBS _ffg_cbestt_0p99v_0p99v_125c.lib_ccs_tn_sh5p1cm
ramlib_format $file0 $dir $rams LIB_RAM_1P0VP_1P0VC_ML_LIBS _ffg_cbestt_1p05v_1p05v_125c.lib_ccs_tn_sh5p1cm
ramlib_format $file0 $dir $rams AOCV_RAM_0P9VP_0P9VC_ML_LIBS _ffg_cbestt_0p99v_0p99v_125c.aocv3
ramlib_format $file0 $dir $rams AOCV_RAM_1P0VP_1P0VC_ML_LIBS _ffg_cbestt_1p05v_1p05v_125c.aocv3
ramlib_format $file0 $dir $rams DB_RAM_0P9VP_0P9VC_ML_LIBS _ffg_cbestt_0p99v_0p99v_125c.db
ramlib_format $file0 $dir $rams DB_RAM_1P0VP_1P0VC_ML_LIBS _ffg_cbestt_1p05v_1p05v_125c.db
ramlib_format $file0 $dir $rams LIB_RAM_0P9VP_0P9VC_LT_LIBS _ffg_cbestt_0p99v_0p99v_m40c.lib_ccs_tn_sh5p1cm
ramlib_format $file0 $dir $rams LIB_RAM_1P0VP_1P0VC_LT_LIBS _ffg_cbestt_1p05v_1p05v_m40c.lib_ccs_tn_sh5p1cm
ramlib_format $file0 $dir $rams AOCV_RAM_0P9VP_0P9VC_LT_LIBS _ffg_cbestt_0p99v_0p99v_m40c.aocv3
ramlib_format $file0 $dir $rams AOCV_RAM_1P0VP_1P0VC_LT_LIBS _ffg_cbestt_1p05v_1p05v_m40c.aocv3
ramlib_format $file0 $dir $rams DB_RAM_0P9VP_0P9VC_LT_LIBS _ffg_cbestt_0p99v_0p99v_m40c.db
ramlib_format $file0 $dir $rams DB_RAM_1P0VP_1P0VC_LT_LIBS _ffg_cbestt_1p05v_1p05v_m40c.db
ramlib_format $file0 $dir $rams LIB_RAM_0P9VP_0P9VC_BC_LIBS _ffg_cbestt_0p99v_0p99v_0c.lib_ccs_tn_sh5p1cm
ramlib_format $file0 $dir $rams LIB_RAM_1P0VP_1P0VC_BC_LIBS _ffg_cbestt_1p05v_1p05v_0c.lib_ccs_tn_sh5p1cm
ramlib_format $file0 $dir $rams AOCV_RAM_0P9VP_0P9VC_BC_LIBS _ffg_cbestt_0p99v_0p99v_0c.aocv3
ramlib_format $file0 $dir $rams AOCV_RAM_1P0VP_1P0VC_BC_LIBS _ffg_cbestt_1p05v_1p05v_0c.aocv3
ramlib_format $file0 $dir $rams DB_RAM_0P9VP_0P9VC_BC_LIBS _ffg_cbestt_0p99v_0p99v_0c.db
ramlib_format $file0 $dir $rams DB_RAM_1P0VP_1P0VC_BC_LIBS _ffg_cbestt_1p05v_1p05v_0c.db
ramlib_format $file0 $dir $rams LIB_RAM_0P9VP_0P9VC_TC_LIBS _tt_ctypical_0p90v_0p90v_25c.lib_ccs_tn_sh0cm
ramlib_format $file0 $dir $rams LIB_RAM_1P0VP_1P0VC_TC_LIBS _tt_ctypical_1p00v_1p00v_25c.lib_ccs_tn_sh0cm
ramlib_format $file0 $dir $rams AOCV_RAM_0P9VP_0P9VC_TC_LIBS _tt_ctypical_0p90v_0p90v_25c.aocv3
ramlib_format $file0 $dir $rams AOCV_RAM_1P0VP_1P0VC_TC_LIBS _tt_ctypical_1p00v_1p00v_25c.aocv3
ramlib_format $file0 $dir $rams DB_RAM_0P9VP_0P9VC_TC_LIBS _tt_ctypical_0p90v_0p90v_25c.db
ramlib_format $file0 $dir $rams DB_RAM_1P0VP_1P0VC_TC_LIBS _tt_ctypical_1p00v_1p00v_25c.db
ramlib_format $file0 $dir $rams LIB_RAM_0P9VP_0P9VC_TC85_LIBS _tt_ctypical_0p90v_0p90v_85c.lib_ccs_tn_sh0cm
ramlib_format $file0 $dir $rams AOCV_RAM_0P9VP_0P9VC_TC85_LIBS _tt_ctypical_0p90v_0p90v_85c.aocv3
ramlib_format $file0 $dir $rams DB_RAM_0P9VP_0P9VC_TC85_LIBS _tt_ctypical_0p90v_0p90v_85c.db
ramlib_format $file0 $dir $rams LIB_RAM_1P0VP_1P0VC_TC85_LIBS _tt_ctypical_1p00v_1p00v_85c.lib_ccs_tn_sh0cm
ramlib_format $file0 $dir $rams AOCV_RAM_1P0VP_1P0VC_TC85_LIBS _tt_ctypical_1p00v_1p00v_85c.aocv3
ramlib_format $file0 $dir $rams DB_RAM_1P0VP_1P0VC_TC85_LIBS _tt_ctypical_1p00v_1p00v_85c.db
close $file0
