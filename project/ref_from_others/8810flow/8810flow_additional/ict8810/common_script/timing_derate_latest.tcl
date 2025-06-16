if {$vars(ocv) == "aocv"} {
    if { $vars(library) == "UMC_ARM28HPCPLUS" } {
        # VT derate
        foreach max_cn $vars(max_corner1) {
            ##### wcl setup
            ## cell
            set_timing_derate [get_lib_cells -quiet *ssg_*max_0p81v_m40c*/*ZTUL*] -delay_corner $max_cn -cell_delay -early -clock 0.962
            set_timing_derate [get_lib_cells -quiet *ssg_*max_0p81v_m40c*/*ZTUL*] -delay_corner $max_cn -cell_delay -late  -clock 1.000
            set_timing_derate [get_lib_cells -quiet *ssg_*max_0p81v_m40c*/*ZTL*]  -delay_corner $max_cn -cell_delay -early -clock 0.957
            set_timing_derate [get_lib_cells -quiet *ssg_*max_0p81v_m40c*/*ZTL*]  -delay_corner $max_cn -cell_delay -late  -clock 1.000
            set_timing_derate [get_lib_cells -quiet *ssg_*max_0p81v_m40c*/*ZTS*]  -delay_corner $max_cn -cell_delay -early -clock 0.950
            set_timing_derate [get_lib_cells -quiet *ssg_*max_0p81v_m40c*/*ZTS*]  -delay_corner $max_cn -cell_delay -late  -clock 1.000
            set_timing_derate [get_lib_cells -quiet *ssg_*max_0p81v_m40c*/*ZTH*]  -delay_corner $max_cn -cell_delay -early -clock 0.916
            set_timing_derate [get_lib_cells -quiet *ssg_*max_0p81v_m40c*/*ZTH*]  -delay_corner $max_cn -cell_delay -late  -clock 1.000
            ## Net 
            set_timing_derate -data  -net_delay -early -delay_corner $max_cn 1.000
            set_timing_derate -data  -net_delay -late  -delay_corner $max_cn 1.085
            set_timing_derate -clock -net_delay -early -delay_corner $max_cn 0.915
            set_timing_derate -clock -net_delay -late  -delay_corner $max_cn 1.085
        }
        foreach max_cn $vars(max_corner2) {
            #### wc setup
            ## cell
            set_timing_derate [get_lib_cells -quiet *ssg_*max_0p81v_125c*/*ZTUL*] -delay_corner $max_cn -cell_delay -early -clock 0.969
            set_timing_derate [get_lib_cells -quiet *ssg_*max_0p81v_125c*/*ZTUL*] -delay_corner $max_cn -cell_delay -late  -clock 1.000
            set_timing_derate [get_lib_cells -quiet *ssg_*max_0p81v_125c*/*ZTL*]  -delay_corner $max_cn -cell_delay -early -clock 0.969
            set_timing_derate [get_lib_cells -quiet *ssg_*max_0p81v_125c*/*ZTL*]  -delay_corner $max_cn -cell_delay -late  -clock 1.000
            set_timing_derate [get_lib_cells -quiet *ssg_*max_0p81v_125c*/*ZTS*]  -delay_corner $max_cn -cell_delay -early -clock 0.962
            set_timing_derate [get_lib_cells -quiet *ssg_*max_0p81v_125c*/*ZTS*]  -delay_corner $max_cn -cell_delay -late  -clock 1.000
            set_timing_derate [get_lib_cells -quiet *ssg_*max_0p81v_125c*/*ZTH*]  -delay_corner $max_cn -cell_delay -early -clock 0.946
            set_timing_derate [get_lib_cells -quiet *ssg_*max_0p81v_125c*/*ZTH*]  -delay_corner $max_cn -cell_delay -late  -clock 1.000
            ## Net 
            set_timing_derate -data  -net_delay -early -delay_corner $max_cn 0.915
            set_timing_derate -data  -net_delay -late  -delay_corner $max_cn 1.000
            set_timing_derate -clock -net_delay -early -delay_corner $max_cn 0.915
            set_timing_derate -clock -net_delay -late  -delay_corner $max_cn 1.085
        }
        foreach min_cn $vars(min_corner1) {
            #### ml hold
            ## cell
            set_timing_derate [get_lib_cells -quiet *ffg_*min_0p99v_125c*/*ZTUL*] -delay_corner $min_cn -cell_delay -early -clock 1.000
            set_timing_derate [get_lib_cells -quiet *ffg_*min_0p99v_125c*/*ZTUL*] -delay_corner $min_cn -cell_delay -late  -clock 1.101
            set_timing_derate [get_lib_cells -quiet *ffg_*min_0p99v_125c*/*ZTL*]  -delay_corner $min_cn -cell_delay -early -clock 1.000
            set_timing_derate [get_lib_cells -quiet *ffg_*min_0p99v_125c*/*ZTL*]  -delay_corner $min_cn -cell_delay -late  -clock 1.120
            set_timing_derate [get_lib_cells -quiet *ffg_*min_0p99v_125c*/*ZTS*]  -delay_corner $min_cn -cell_delay -early -clock 1.000
            set_timing_derate [get_lib_cells -quiet *ffg_*min_0p99v_125c*/*ZTS*]  -delay_corner $min_cn -cell_delay -late  -clock 1.122
            set_timing_derate [get_lib_cells -quiet *ffg_*min_0p99v_125c*/*ZTH*]  -delay_corner $min_cn -cell_delay -early -clock 1.000
            set_timing_derate [get_lib_cells -quiet *ffg_*min_0p99v_125c*/*ZTH*]  -delay_corner $min_cn -cell_delay -late  -clock 1.146
            ## Net 
            set_timing_derate -data  -net_delay -early -delay_corner $max_cn 0.915
            set_timing_derate -data  -net_delay -late  -delay_corner $max_cn 1.000
            set_timing_derate -clock -net_delay -early -delay_corner $max_cn 0.915
            set_timing_derate -clock -net_delay -late  -delay_corner $max_cn 1.085
        }
        foreach min_cn $vars(min_corner2) {
            #### lt hold
            ## cell
            set_timing_derate [get_lib_cells -quiet *ffg_*min_0p99v_m40c*/*ZTUL*] -delay_corner $min_cn -cell_delay -early -clock 1.000
            set_timing_derate [get_lib_cells -quiet *ffg_*min_0p99v_m40c*/*ZTUL*] -delay_corner $min_cn -cell_delay -late  -clock 1.120
            set_timing_derate [get_lib_cells -quiet *ffg_*min_0p99v_m40c*/*ZTL*]  -delay_corner $min_cn -cell_delay -early -clock 1.000
            set_timing_derate [get_lib_cells -quiet *ffg_*min_0p99v_m40c*/*ZTL*]  -delay_corner $min_cn -cell_delay -late  -clock 1.128
            set_timing_derate [get_lib_cells -quiet *ffg_*min_0p99v_m40c*/*ZTS*]  -delay_corner $min_cn -cell_delay -early -clock 1.000
            set_timing_derate [get_lib_cells -quiet *ffg_*min_0p99v_m40c*/*ZTS*]  -delay_corner $min_cn -cell_delay -late  -clock 1.144
            set_timing_derate [get_lib_cells -quiet *ffg_*min_0p99v_m40c*/*ZTH*]  -delay_corner $min_cn -cell_delay -early -clock 1.000
            set_timing_derate [get_lib_cells -quiet *ffg_*min_0p99v_m40c*/*ZTH*]  -delay_corner $min_cn -cell_delay -late  -clock 1.190
            ## Net 
            set_timing_derate -data  -net_delay -early -delay_corner $max_cn 0.915
            set_timing_derate -data  -net_delay -late  -delay_corner $max_cn 1.000
            set_timing_derate -clock -net_delay -early -delay_corner $max_cn 0.915
            set_timing_derate -clock -net_delay -late  -delay_corner $max_cn 1.085
        }
        foreach min_cn $vars(min_corner3) {
            #### wcl hold
            ## cell
            set_timing_derate [get_lib_cells -quiet *ssg_*max_0p81v_m40c*/*ZTUL*] -delay_corner $min_cn -cell_delay -early -clock 0.935
            set_timing_derate [get_lib_cells -quiet *ssg_*max_0p81v_m40c*/*ZTUL*] -delay_corner $min_cn -cell_delay -late  -clock 1.000
            set_timing_derate [get_lib_cells -quiet *ssg_*max_0p81v_m40c*/*ZTUL*] -delay_corner $min_cn -cell_delay -early -data  0.935
            set_timing_derate [get_lib_cells -quiet *ssg_*max_0p81v_m40c*/*ZTL*]  -delay_corner $min_cn -cell_delay -early -clock 0.927
            set_timing_derate [get_lib_cells -quiet *ssg_*max_0p81v_m40c*/*ZTL*]  -delay_corner $min_cn -cell_delay -late  -clock 1.000
            set_timing_derate [get_lib_cells -quiet *ssg_*max_0p81v_m40c*/*ZTL*]  -delay_corner $min_cn -cell_delay -early -data  0.927
            set_timing_derate [get_lib_cells -quiet *ssg_*max_0p81v_m40c*/*ZTS*]  -delay_corner $min_cn -cell_delay -early -clock 0.916
            set_timing_derate [get_lib_cells -quiet *ssg_*max_0p81v_m40c*/*ZTS*]  -delay_corner $min_cn -cell_delay -late  -clock 1.000
            set_timing_derate [get_lib_cells -quiet *ssg_*max_0p81v_m40c*/*ZTS*]  -delay_corner $min_cn -cell_delay -early -data  0.916
            set_timing_derate [get_lib_cells -quiet *ssg_*max_0p81v_m40c*/*ZTH*]  -delay_corner $min_cn -cell_delay -early -clock 0.859
            set_timing_derate [get_lib_cells -quiet *ssg_*max_0p81v_m40c*/*ZTH*]  -delay_corner $min_cn -cell_delay -late  -clock 1.000
            set_timing_derate [get_lib_cells -quiet *ssg_*max_0p81v_m40c*/*ZTH*]  -delay_corner $min_cn -cell_delay -early -data  0.859
            ## Net 
            set_timing_derate -data  -net_delay -early -delay_corner $max_cn 0.915
            set_timing_derate -data  -net_delay -late  -delay_corner $max_cn 1.000
            set_timing_derate -clock -net_delay -early -delay_corner $max_cn 0.915
            set_timing_derate -clock -net_delay -late  -delay_corner $max_cn 1.085
        }
    }
}
