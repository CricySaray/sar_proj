# library set
create_library_set -name tt1p1v25c \
  -timing { \
  /process/M31/M31GPSC900NL040PH_40N_00.01.000/ccs/M31GPSC900NL040PH_40N_25CTT1P1_typical_css.lib.gz \ 
  /process/M31/M31GPSC900NL040PR_40N_00.01.000/ccs/M31GPSC900NL040PR_40N_25CTT1P1_typical_css.lib.gz \ 
  /process/M31/M31GPSC900NL040PL_40N_00.01.000/ccs/M31GPSC900NL040PL_40N_25CTT1P1_typical_css.lib.gz \ 
  /simulation/exchange/library/lib2db/fft_dp_1024x20_tt1p1v25c.lib \
  /simulation/exchange/library/lib2db/fft_dp_128x20_tt1p1v25c.lib \
  /simulation/exchange/library/lib2db/fft_dp_256x20_tt1p1v25c.lib \
  /simulation/exchange/library/lib2db/fft_dp_512x20_tt1p1v25c.lib \
  /simulation/exchange/library/lib2db/PLL/UPPLLCG500MCI_typ.lib \
  /simulation/yli/sc5018/trunk/analog/lib/SC5018_ANARF_TOP.lib \
  /simulation/yli/sc5018/trunk/analog/lib/SC5018_PMU_TOP.lib \
  }
create_library_set -name ss0p99vm40c \
  -timing { \
  /process/M31/M31GPSC900NL040PH_40N_00.01.000/ccs/M31GPSC900NL040PH_40N_N40CSS0P99_cworst_css.lib.gz \ 
  /process/M31/M31GPSC900NL040PR_40N_00.01.000/ccs/M31GPSC900NL040PR_40N_N40CSS0P99_cworst_css.lib.gz \ 
  /process/M31/M31GPSC900NL040PL_40N_00.01.000/ccs/M31GPSC900NL040PL_40N_N40CSS0P99_cworst_css.lib.gz \ 
  /simulation/exchange/library/lib2db/fft_dp_1024x20_ss0p99vn40c.lib \
  /simulation/exchange/library/lib2db/fft_dp_128x20_ss0p99vn40c.lib \
  /simulation/exchange/library/lib2db/fft_dp_256x20_ss0p99vn40c.lib \
  /simulation/exchange/library/lib2db/fft_dp_512x20_ss0p99vn40c.lib \
  /simulation/exchange/library/lib2db/PLL/UPPLLCG500MCI_max.lib \
  /simulation/yli/sc5018/trunk/analog/lib/SC5018_ANARF_TOP.lib \
  /simulation/yli/sc5018/trunk/analog/lib/SC5018_PMU_TOP.lib \
  }
create_library_set -name ff1p21v125c \
  -timing { \
  /process/M31/M31GPSC900NL040PH_40N_00.01.000/ccs/M31GPSC900NL040PH_40N_125CFF1P21_cbest_css.lib.gz \ 
  /process/M31/M31GPSC900NL040PR_40N_00.01.000/ccs/M31GPSC900NL040PR_40N_125CFF1P21_cbest_css.lib.gz \ 
  /process/M31/M31GPSC900NL040PL_40N_00.01.000/ccs/M31GPSC900NL040PL_40N_125CFF1P21_cbest_css.lib.gz \ 
  /simulation/exchange/library/lib2db/fft_dp_1024x20_ff1p21v125c.lib \
  /simulation/exchange/library/lib2db/fft_dp_128x20_ff1p21v125c.lib \
  /simulation/exchange/library/lib2db/fft_dp_256x20_ff1p21v125c.lib \
  /simulation/exchange/library/lib2db/fft_dp_512x20_ff1p21v125c.lib \
  /simulation/exchange/library/lib2db/PLL/UPPLLCG500MCI_min.lib \
  /simulation/yli/sc5018/trunk/analog/lib/SC5018_ANARF_TOP.lib \
  /simulation/yli/sc5018/trunk/analog/lib/SC5018_PMU_TOP.lib \
  }
create_library_set -name ff1p21vm40c ...
create_library_set -name ss0p99v125c ...

# rc corner set:
create_rc_corner -name cworst_m40c   -qx_tech_file /simulation/arsong/SC5018/PR/ict2qrc_3/cworst/qrcTechFile -T -40
create_rc_corner -name cworst_125c   -qx_tech_file /simulation/arsong/SC5018/PR/ict2qrc_3/cworst/qrcTechFile -T 125
create_rc_corner -name cbest_m40c    -qx_tech_file /simulation/arsong/SC5018/PR/ict2qrc_3/cbest/qrcTechFile -T -40
create_rc_corner -name cbest_125c    -qx_tech_file /simulation/arsong/SC5018/PR/ict2qrc_3/cbest/qrcTechFile -T 125
create_rc_corner -name typical_25c   -qx_tech_file /simulation/arsong/SC5018/PR/ict2qrc_3/typical/qrcTechFile -T 25

# delay corner set: library + rc corners
create_delay_corner -name setup_ss0p99vm40c_cworst      -library_set  ss0p99vm40c   -rc_corner  cworst_m40c
create_delay_corner -name setup_ss0p99v125c_cworst      -library_set  ss0p99v125c   -rc_corner  cworst_125c
create_delay_corner -name hold_ss0p99vm40c_cworst       -library_set  ss0p99vm40c   -rc_corner  cworst_m40c
create_delay_corner -name hold_ss0p99v125c_cworst       -library_set  ss0p99v125c   -rc_corner  cworst_125c
create_delay_corner -name hold_ff1p21vm40c_cbest        -library_set  ff1p21vm40c   -rc_corner  cworst_m40c
create_delay_corner -name hold_ff1p21v125c_cbest        -library_set  ff1p21v125c   -rc_corner  cworst_125c

create_delay_corner -name setup_tt1p1v25c_typical       -library_set  tt1p1v25c     -rc_corner  typical_25c
create_delay_corner -name hold_tt1p1v25c_typical        -library_set  tt1p1v25c     -rc_corner  typical_25c

# constraint modes set:
# func 
create_constraint_mode -name func -sdc_files $sdc_func
# scan
create_constraint_mode -name scan -sdc_files $sdc_scan

# scenarios set:
set delay_corners {setup_ss0p99vm40c_cworst setup_ss0p99v125c_cworst hold_ss0p99vm40c_cworst hold_ss0p99v125c_cworst hold_ff1p21vm40c_cbest hold_ff1p21v125c_cbest setup_tt1p1v25c_typical hold_tt1p1v25c_typical}
set modes {func scan}
set setup_analysis ""
set hold_analysis  ""
# analysis views as :
foreach mode $modes {
  foreach corner $delay_corners {
    create_analysis_view -name ${mode}_${corner} -constraint_mode $mode -delay_corner $corner
    if {[lindex [split $corner "_"] 0] == "setup"} {lappend setup_analysis "${mode}_${corner}"}
    if {[lindex [split $corner "_"] 0] == "hold"} {lappend hold_analysis "${mode}_${corner}"}
  }
}
# contral views :
set_analysis_view -setup $set_analysis -hold $hold_analysis
set_interactive_constraint_modes [all_constraint_modes]
