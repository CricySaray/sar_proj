#set active_corners [all_delay_corners]
set views " [all_setup_analysis_views] [all_hold_analysis_views]"
set active_corner ""
foreach view $views {
	set list [split $view _]
	set corner [join [lrange $list 1 end] _]
	lappend active_corner $corner
	}
set active_corners  [lsort -u $active_corner]
echo $active_corners
if {[lsearch $active_corners tt25] != -1} {
   set_timing_derate -data -cell_delay -early -delay_corner tt_25 1
   set_timing_derate -clock -cell_delay -early -delay_corner tt_25 1
   set_timing_derate -data -cell_delay -late -delay_corner tt_25 1
   set_timing_derate -clock -cell_delay -late -delay_corner tt_25 1
   set_timing_derate -data -net_delay -early -delay_corner tt_25 1
   set_timing_derate -clock -net_delay -early -delay_corner tt_25 1
   set_timing_derate -data -net_delay -late -delay_corner tt_25 1
   set_timing_derate -clock -net_delay -late -delay_corner tt_25 1
}
if {[lsearch $active_corners tt85] != -1} {
   set_timing_derate -data -cell_delay -early -delay_corner tt_85 1
   set_timing_derate -clock -cell_delay -early -delay_corner tt_85 1
   set_timing_derate -data -cell_delay -late -delay_corner tt_85 1
   set_timing_derate -clock -cell_delay -late -delay_corner tt_85 1
   set_timing_derate -data -net_delay -early -delay_corner tt_85 1
   set_timing_derate -clock -net_delay -early -delay_corner tt_85 1
   set_timing_derate -data -net_delay -late -delay_corner tt_85 1
   set_timing_derate -clock -net_delay -late -delay_corner tt_85 1
}
if {[lsearch $active_corners ssm40_cworst_T] != -1} {
   set_timing_derate -data -cell_delay -early -delay_corner ssm40_cworst_T 1
   set_timing_derate -clock -cell_delay -early -delay_corner ssm40_cworst_T 0.937
   set_timing_derate -data -cell_delay -late -delay_corner ssm40_cworst_T 1.069
   set_timing_derate -clock -cell_delay -late -delay_corner ssm40_cworst_T 1.02
   set_timing_derate -data -net_delay -early -delay_corner ssm40_cworst_T 1
   set_timing_derate -clock -net_delay -early -delay_corner ssm40_cworst_T 0.94
   set_timing_derate -data -net_delay -late -delay_corner ssm40_cworst_T 1.06
   set_timing_derate -clock -net_delay -late -delay_corner ssm40_cworst_T 1.06
}
if {[lsearch $active_corners ssm40_cworst_T_2p5io] != -1} {
   set_timing_derate -data -cell_delay -early -delay_corner ssm40_cworst_T_2p5io 1
   set_timing_derate -clock -cell_delay -early -delay_corner ssm40_cworst_T_2p5io 0.937
   set_timing_derate -data -cell_delay -late -delay_corner ssm40_cworst_T_2p5io 1.069
   set_timing_derate -clock -cell_delay -late -delay_corner ssm40_cworst_T_2p5io 1.02
   set_timing_derate -data -net_delay -early -delay_corner ssm40_cworst_T_2p5io 1
   set_timing_derate -clock -net_delay -early -delay_corner ssm40_cworst_T_2p5io 0.94
   set_timing_derate -data -net_delay -late -delay_corner ssm40_cworst_T_2p5io 1.06
   set_timing_derate -clock -net_delay -late -delay_corner ssm40_cworst_T_2p5io 1.06
}
if {[lsearch $active_corners ssm40_cworst_T_1p8io] != -1} {
   set_timing_derate -data -cell_delay -early -delay_corner ssm40_cworst_T_1p8io 1
   set_timing_derate -clock -cell_delay -early -delay_corner ssm40_cworst_T_1p8io 0.937
   set_timing_derate -data -cell_delay -late -delay_corner ssm40_cworst_T_1p8io 1.069
   set_timing_derate -clock -cell_delay -late -delay_corner ssm40_cworst_T_1p8io 1.02
   set_timing_derate -data -net_delay -early -delay_corner ssm40_cworst_T_1p8io 1
   set_timing_derate -clock -net_delay -early -delay_corner ssm40_cworst_T_1p8io 0.94
   set_timing_derate -data -net_delay -late -delay_corner ssm40_cworst_T_1p8io 1.06
   set_timing_derate -clock -net_delay -late -delay_corner ssm40_cworst_T_1p8io 1.06
}
if {[lsearch $active_corners ssm40_rcworst_T] != -1} {
   set_timing_derate -data -cell_delay -early -delay_corner ssm40_rcworst_T 1
   set_timing_derate -clock -cell_delay -early -delay_corner ssm40_rcworst_T 0.937
   set_timing_derate -data -cell_delay -late -delay_corner ssm40_rcworst_T 1.069
   set_timing_derate -clock -cell_delay -late -delay_corner ssm40_rcworst_T 1.02
   set_timing_derate -data -net_delay -early -delay_corner ssm40_rcworst_T 1
   set_timing_derate -clock -net_delay -early -delay_corner ssm40_rcworst_T 0.94
   set_timing_derate -data -net_delay -late -delay_corner ssm40_rcworst_T 1.06
   set_timing_derate -clock -net_delay -late -delay_corner ssm40_rcworst_T 1.06
}
if {[lsearch $active_corners ss125_cworst_T] != -1} {
   set_timing_derate -data -cell_delay -early -delay_corner ss125_cworst_T 1
   set_timing_derate -clock -cell_delay -early -delay_corner ss125_cworst_T 0.937
   set_timing_derate -data -cell_delay -late -delay_corner ss125_cworst_T 1.069
   set_timing_derate -clock -cell_delay -late -delay_corner ss125_cworst_T 1.02
   set_timing_derate -data -net_delay -early -delay_corner ss125_cworst_T 1
   set_timing_derate -clock -net_delay -early -delay_corner ss125_cworst_T 0.94
   set_timing_derate -data -net_delay -late -delay_corner ss125_cworst_T 1.06
   set_timing_derate -clock -net_delay -late -delay_corner ss125_cworst_T 1.06
}
if {[lsearch $active_corners ss125_cworst_T_2p5io] != -1} {
   set_timing_derate -data -cell_delay -early -delay_corner ss125_cworst_T_2p5io 1
   set_timing_derate -clock -cell_delay -early -delay_corner ss125_cworst_T_2p5io 0.937
   set_timing_derate -data -cell_delay -late -delay_corner ss125_cworst_T_2p5io 1.069
   set_timing_derate -clock -cell_delay -late -delay_corner ss125_cworst_T_2p5io 1.02
   set_timing_derate -data -net_delay -early -delay_corner ss125_cworst_T_2p5io 1
   set_timing_derate -clock -net_delay -early -delay_corner ss125_cworst_T_2p5io 0.94
   set_timing_derate -data -net_delay -late -delay_corner ss125_cworst_T_2p5io 1.06
   set_timing_derate -clock -net_delay -late -delay_corner ss125_cworst_T_2p5io 1.06
}
if {[lsearch $active_corners ss125_cworst_T_1p8io] != -1} {
   set_timing_derate -data -cell_delay -early -delay_corner ss125_cworst_T_1p8io 1
   set_timing_derate -clock -cell_delay -early -delay_corner ss125_cworst_T_1p8io 0.937
   set_timing_derate -data -cell_delay -late -delay_corner ss125_cworst_T_1p8io 1.069
   set_timing_derate -clock -cell_delay -late -delay_corner ss125_cworst_T_1p8io 1.02
   set_timing_derate -data -net_delay -early -delay_corner ss125_cworst_T_1p8io 1
   set_timing_derate -clock -net_delay -early -delay_corner ss125_cworst_T_1p8io 0.94
   set_timing_derate -data -net_delay -late -delay_corner ss125_cworst_T_1p8io 1.06
   set_timing_derate -clock -net_delay -late -delay_corner ss125_cworst_T_1p8io 1.06
}
if {[lsearch $active_corners ss125_rcworst_T] != -1} {
   set_timing_derate -data -cell_delay -early -delay_corner ss125_rcworst_T 1
   set_timing_derate -clock -cell_delay -early -delay_corner ss125_rcworst_T 0.937
   set_timing_derate -data -cell_delay -late -delay_corner ss125_rcworst_T 1.069
   set_timing_derate -clock -cell_delay -late -delay_corner ss125_rcworst_T 1.02
   set_timing_derate -data -net_delay -early -delay_corner ss125_rcworst_T 1
   set_timing_derate -clock -net_delay -early -delay_corner ss125_rcworst_T 0.94
   set_timing_derate -data -net_delay -late -delay_corner ss125_rcworst_T 1.06
   set_timing_derate -clock -net_delay -late -delay_corner ss125_rcworst_T 1.06
}
if {[lsearch $active_corners ssm40_cworst] != -1} {
   set_timing_derate -data -cell_delay -early -delay_corner ssm40_cworst 0.827
   set_timing_derate -clock -cell_delay -early -delay_corner ssm40_cworst 0.892
   set_timing_derate -data -cell_delay -late -delay_corner ssm40_cworst 1
   set_timing_derate -clock -cell_delay -late -delay_corner ssm40_cworst 1.032
   set_timing_derate -data -net_delay -early -delay_corner ssm40_cworst 0.915
   set_timing_derate -clock -net_delay -early -delay_corner ssm40_cworst 0.915
   set_timing_derate -data -net_delay -late -delay_corner ssm40_cworst 1
   set_timing_derate -clock -net_delay -late -delay_corner ssm40_cworst 1
}
if {[lsearch $active_corners ssm40_cworst_1p8io] != -1} {
   set_timing_derate -data -cell_delay -early -delay_corner ssm40_cworst_1p8io 0.827
   set_timing_derate -clock -cell_delay -early -delay_corner ssm40_cworst_1p8io 0.892
   set_timing_derate -data -cell_delay -late -delay_corner ssm40_cworst_1p8io 1
   set_timing_derate -clock -cell_delay -late -delay_corner ssm40_cworst_1p8io 1.032
   set_timing_derate -data -net_delay -early -delay_corner ssm40_cworst_1p8io 0.915
   set_timing_derate -clock -net_delay -early -delay_corner ssm40_cworst_1p8io 0.915
   set_timing_derate -data -net_delay -late -delay_corner ssm40_cworst_1p8io 1
   set_timing_derate -clock -net_delay -late -delay_corner ssm40_cworst_1p8io 1
}
if {[lsearch $active_corners ssm40_cworst_2p5io] != -1} {
   set_timing_derate -data -cell_delay -early -delay_corner ssm40_cworst_2p5io 0.827
   set_timing_derate -clock -cell_delay -early -delay_corner ssm40_cworst_2p5io 0.892
   set_timing_derate -data -cell_delay -late -delay_corner ssm40_cworst_2p5io 1
   set_timing_derate -clock -cell_delay -late -delay_corner ssm40_cworst_2p5io 1.032
   set_timing_derate -data -net_delay -early -delay_corner ssm40_cworst_2p5io 0.915
   set_timing_derate -clock -net_delay -early -delay_corner ssm40_cworst_2p5io 0.915
   set_timing_derate -data -net_delay -late -delay_corner ssm40_cworst_2p5io 1
   set_timing_derate -clock -net_delay -late -delay_corner ssm40_cworst_2p5io 1
}
if {[lsearch $active_corners ssm40_rcworst] != -1} {
   set_timing_derate -data -cell_delay -early -delay_corner ssm40_rcworst 0.827
   set_timing_derate -clock -cell_delay -early -delay_corner ssm40_rcworst 0.892
   set_timing_derate -data -cell_delay -late -delay_corner ssm40_rcworst 1
   set_timing_derate -clock -cell_delay -late -delay_corner ssm40_rcworst 1.032
   set_timing_derate -data -net_delay -early -delay_corner ssm40_rcworst 0.915
   set_timing_derate -clock -net_delay -early -delay_corner ssm40_rcworst 0.915
   set_timing_derate -data -net_delay -late -delay_corner ssm40_rcworst 1
   set_timing_derate -clock -net_delay -late -delay_corner ssm40_rcworst 1
}
if {[lsearch $active_corners ss125_cworst] != -1} {
   set_timing_derate -data -cell_delay -early -delay_corner ss125_cworst 0.827
   set_timing_derate -clock -cell_delay -early -delay_corner ss125_cworst 0.892
   set_timing_derate -data -cell_delay -late -delay_corner ss125_cworst 1
   set_timing_derate -clock -cell_delay -late -delay_corner ss125_cworst 1.032
   set_timing_derate -data -net_delay -early -delay_corner ss125_cworst 0.915
   set_timing_derate -clock -net_delay -early -delay_corner ss125_cworst 0.915
   set_timing_derate -data -net_delay -late -delay_corner ss125_cworst 1
   set_timing_derate -clock -net_delay -late -delay_corner ss125_cworst 1
}
if {[lsearch $active_corners ss125_cworst_2p5io] != -1} {
   set_timing_derate -data -cell_delay -early -delay_corner ss125_cworst_2p5io 0.827
   set_timing_derate -clock -cell_delay -early -delay_corner ss125_cworst_2p5io 0.892
   set_timing_derate -data -cell_delay -late -delay_corner ss125_cworst_2p5io 1
   set_timing_derate -clock -cell_delay -late -delay_corner ss125_cworst_2p5io 1.032
   set_timing_derate -data -net_delay -early -delay_corner ss125_cworst_2p5io 0.915
   set_timing_derate -clock -net_delay -early -delay_corner ss125_cworst_2p5io 0.915
   set_timing_derate -data -net_delay -late -delay_corner ss125_cworst_2p5io 1
   set_timing_derate -clock -net_delay -late -delay_corner ss125_cworst_2p5io 1
}
if {[lsearch $active_corners ss125_cworst_1p8io] != -1} {
   set_timing_derate -data -cell_delay -early -delay_corner ss125_cworst_1p8io 0.827
   set_timing_derate -clock -cell_delay -early -delay_corner ss125_cworst_1p8io 0.892
   set_timing_derate -data -cell_delay -late -delay_corner ss125_cworst_1p8io 1
   set_timing_derate -clock -cell_delay -late -delay_corner ss125_cworst_1p8io 1.032
   set_timing_derate -data -net_delay -early -delay_corner ss125_cworst_1p8io 0.915
   set_timing_derate -clock -net_delay -early -delay_corner ss125_cworst_1p8io 0.915
   set_timing_derate -data -net_delay -late -delay_corner ss125_cworst_1p8io 1
   set_timing_derate -clock -net_delay -late -delay_corner ss125_cworst_1p8io 1
}
if {[lsearch $active_corners ss125_rcworst] != -1} {
   set_timing_derate -data -cell_delay -early -delay_corner ss125_rcworst 0.827
   set_timing_derate -clock -cell_delay -early -delay_corner ss125_rcworst 0.892
   set_timing_derate -data -cell_delay -late -delay_corner ss125_rcworst 1
   set_timing_derate -clock -cell_delay -late -delay_corner ss125_rcworst 1.032
   set_timing_derate -data -net_delay -early -delay_corner ss125_rcworst 0.915
   set_timing_derate -clock -net_delay -early -delay_corner ss125_rcworst 0.915
   set_timing_derate -data -net_delay -late -delay_corner ss125_rcworst 1
   set_timing_derate -clock -net_delay -late -delay_corner ss125_rcworst 1
}
if {[lsearch $active_corners ffm40_cworst] != -1} {
   set_timing_derate -data -cell_delay -early -delay_corner ffm40_cworst 0.879
   set_timing_derate -clock -cell_delay -early -delay_corner ffm40_cworst 0.963
   set_timing_derate -data -cell_delay -late -delay_corner ffm40_cworst 1
   set_timing_derate -clock -cell_delay -late -delay_corner ffm40_cworst 1.093
   set_timing_derate -data -net_delay -early -delay_corner ffm40_cworst 0.915
   set_timing_derate -clock -net_delay -early -delay_corner ffm40_cworst 0.915
   set_timing_derate -data -net_delay -late -delay_corner ffm40_cworst 1
   set_timing_derate -clock -net_delay -late -delay_corner ffm40_cworst 1.085
}
if {[lsearch $active_corners ffm40_rcworst] != -1} {
   set_timing_derate -data -cell_delay -early -delay_corner ffm40_rcworst 0.879
   set_timing_derate -clock -cell_delay -early -delay_corner ffm40_rcworst 0.963
   set_timing_derate -data -cell_delay -late -delay_corner ffm40_rcworst 1
   set_timing_derate -clock -cell_delay -late -delay_corner ffm40_rcworst 1.093
   set_timing_derate -data -net_delay -early -delay_corner ffm40_rcworst 0.915
   set_timing_derate -clock -net_delay -early -delay_corner ffm40_rcworst 0.915
   set_timing_derate -data -net_delay -late -delay_corner ffm40_rcworst 1
   set_timing_derate -clock -net_delay -late -delay_corner ffm40_rcworst 1.085
}
if {[lsearch $active_corners ffm40_cbest] != -1} {
   set_timing_derate -data -cell_delay -early -delay_corner ffm40_cbest 0.879
   set_timing_derate -clock -cell_delay -early -delay_corner ffm40_cbest 0.963
   set_timing_derate -data -cell_delay -late -delay_corner ffm40_cbest 1
   set_timing_derate -clock -cell_delay -late -delay_corner ffm40_cbest 1.093
   set_timing_derate -data -net_delay -early -delay_corner ffm40_cbest 0.915
   set_timing_derate -clock -net_delay -early -delay_corner ffm40_cbest 0.915
   set_timing_derate -data -net_delay -late -delay_corner ffm40_cbest 1
   set_timing_derate -clock -net_delay -late -delay_corner ffm40_cbest 1.085
}
if {[lsearch $active_corners ffm40_rcbest] != -1} {
   set_timing_derate -data -cell_delay -early -delay_corner ffm40_rcbest 0.879
   set_timing_derate -clock -cell_delay -early -delay_corner ffm40_rcbest 0.963
   set_timing_derate -data -cell_delay -late -delay_corner ffm40_rcbest 1
   set_timing_derate -clock -cell_delay -late -delay_corner ffm40_rcbest 1.093
   set_timing_derate -data -net_delay -early -delay_corner ffm40_rcbest 0.915
   set_timing_derate -clock -net_delay -early -delay_corner ffm40_rcbest 0.915
   set_timing_derate -data -net_delay -late -delay_corner ffm40_rcbest 1
   set_timing_derate -clock -net_delay -late -delay_corner ffm40_rcbest 1.085
}
if {[lsearch $active_corners ff125_cworst] != -1} {
   set_timing_derate -data -cell_delay -early -delay_corner ff125_cworst 0.879
   set_timing_derate -clock -cell_delay -early -delay_corner ff125_cworst 0.963
   set_timing_derate -data -cell_delay -late -delay_corner ff125_cworst 1
   set_timing_derate -clock -cell_delay -late -delay_corner ff125_cworst 1.093
   set_timing_derate -data -net_delay -early -delay_corner ff125_cworst 0.915
   set_timing_derate -clock -net_delay -early -delay_corner ff125_cworst 0.915
   set_timing_derate -data -net_delay -late -delay_corner ff125_cworst 1
   set_timing_derate -clock -net_delay -late -delay_corner ff125_cworst 1.085
}
if {[lsearch $active_corners ff125_rcworst] != -1} {
   set_timing_derate -data -cell_delay -early -delay_corner ff125_rcworst 0.879
   set_timing_derate -clock -cell_delay -early -delay_corner ff125_rcworst 0.963
   set_timing_derate -data -cell_delay -late -delay_corner ff125_rcworst 1
   set_timing_derate -clock -cell_delay -late -delay_corner ff125_rcworst 1.093
   set_timing_derate -data -net_delay -early -delay_corner ff125_rcworst 0.915
   set_timing_derate -clock -net_delay -early -delay_corner ff125_rcworst 0.915
   set_timing_derate -data -net_delay -late -delay_corner ff125_rcworst 1
   set_timing_derate -clock -net_delay -late -delay_corner ff125_rcworst 1.085
}
if {[lsearch $active_corners ff125_cbest] != -1} {
   set_timing_derate -data -cell_delay -early -delay_corner ff125_cbest 0.879
   set_timing_derate -clock -cell_delay -early -delay_corner ff125_cbest 0.963
   set_timing_derate -data -cell_delay -late -delay_corner ff125_cbest 1
   set_timing_derate -clock -cell_delay -late -delay_corner ff125_cbest 1.093
   set_timing_derate -data -net_delay -early -delay_corner ff125_cbest 0.915
   set_timing_derate -clock -net_delay -early -delay_corner ff125_cbest 0.915
   set_timing_derate -data -net_delay -late -delay_corner ff125_cbest 1
   set_timing_derate -clock -net_delay -late -delay_corner ff125_cbest 1.085
}
if {[lsearch $active_corners ff125_rcbest] != -1} {
   set_timing_derate -data -cell_delay -early -delay_corner ff125_rcbest 0.879
   set_timing_derate -clock -cell_delay -early -delay_corner ff125_rcbest 0.963
   set_timing_derate -data -cell_delay -late -delay_corner ff125_rcbest 1
   set_timing_derate -clock -cell_delay -late -delay_corner ff125_rcbest 1.093
   set_timing_derate -data -net_delay -early -delay_corner ff125_rcbest 0.915
   set_timing_derate -clock -net_delay -early -delay_corner ff125_rcbest 0.915
   set_timing_derate -data -net_delay -late -delay_corner ff125_rcbest 1
   set_timing_derate -clock -net_delay -late -delay_corner ff125_rcbest 1.085
}
if {[lsearch $active_corners ff0_cworst] != -1} {
   set_timing_derate -data -cell_delay -early -delay_corner ff0_cworst 0.879
   set_timing_derate -clock -cell_delay -early -delay_corner ff0_cworst 0.963
   set_timing_derate -data -cell_delay -late -delay_corner ff0_cworst 1
   set_timing_derate -clock -cell_delay -late -delay_corner ff0_cworst 1.093
   set_timing_derate -data -net_delay -early -delay_corner ff0_cworst 0.915
   set_timing_derate -clock -net_delay -early -delay_corner ff0_cworst 0.915
   set_timing_derate -data -net_delay -late -delay_corner ff0_cworst 1
   set_timing_derate -clock -net_delay -late -delay_corner ff0_cworst 1.085
}
if {[lsearch $active_corners ff0_rcworst] != -1} {
   set_timing_derate -data -cell_delay -early -delay_corner ff0_rcworst 0.879
   set_timing_derate -clock -cell_delay -early -delay_corner ff0_rcworst 0.963
   set_timing_derate -data -cell_delay -late -delay_corner ff0_rcworst 1
   set_timing_derate -clock -cell_delay -late -delay_corner ff0_rcworst 1.093
   set_timing_derate -data -net_delay -early -delay_corner ff0_rcworst 0.915
   set_timing_derate -clock -net_delay -early -delay_corner ff0_rcworst 0.915
   set_timing_derate -data -net_delay -late -delay_corner ff0_rcworst 1
   set_timing_derate -clock -net_delay -late -delay_corner ff0_rcworst 1.085
}
if {[lsearch $active_corners ff0_cbest] != -1} {
   set_timing_derate -data -cell_delay -early -delay_corner ff0_cbest 0.879
   set_timing_derate -clock -cell_delay -early -delay_corner ff0_cbest 0.963
   set_timing_derate -data -cell_delay -late -delay_corner ff0_cbest 1
   set_timing_derate -clock -cell_delay -late -delay_corner ff0_cbest 1.093
   set_timing_derate -data -net_delay -early -delay_corner ff0_cbest 0.915
   set_timing_derate -clock -net_delay -early -delay_corner ff0_cbest 0.915
   set_timing_derate -data -net_delay -late -delay_corner ff0_cbest 1
   set_timing_derate -clock -net_delay -late -delay_corner ff0_cbest 1.085
}
if {[lsearch $active_corners ff0_rcbest] != -1} {
   set_timing_derate -data -cell_delay -early -delay_corner ff0_rcbest 0.879
   set_timing_derate -clock -cell_delay -early -delay_corner ff0_rcbest 0.963
   set_timing_derate -data -cell_delay -late -delay_corner ff0_rcbest 1
   set_timing_derate -clock -cell_delay -late -delay_corner ff0_rcbest 1.093
   set_timing_derate -data -net_delay -early -delay_corner ff0_rcbest 0.915
   set_timing_derate -clock -net_delay -early -delay_corner ff0_rcbest 0.915
   set_timing_derate -data -net_delay -late -delay_corner ff0_rcbest 1
   set_timing_derate -clock -net_delay -late -delay_corner ff0_rcbest 1.085
}


