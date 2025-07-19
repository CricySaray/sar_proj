if {$vars(ocv) == "aocv"} {
		if { $vars(library) == "UMC_ARM28HPCPLUS" } {
      foreach max_cn $vars(max_corner1) {
			set_timing_derate [get_lib_cells -quiet *ssg_*max_0p81v_m40c*/*ZTUL*] -delay_corner $max_cn -cell_delay -early -clock $vars(max_cell_early_clock1_ulvt)
	    	set_timing_derate [get_lib_cells -quiet *ssg_*max_0p81v_m40c*/*ZTUL*] -delay_corner $max_cn -cell_delay -late -clock $vars(max_cell_late_clock1_ulvt)

	    	set_timing_derate [get_lib_cells -quiet *ssg_*max_0p81v_m40c*/*ZTL*] -delay_corner $max_cn -cell_delay -early -clock $vars(max_cell_early_clock1_lvt)
	    	set_timing_derate [get_lib_cells -quiet *ssg_*max_0p81v_m40c*/*ZTL*] -delay_corner $max_cn -cell_delay -late -clock $vars(max_cell_late_clock1_lvt)
	    	
	    	set_timing_derate [get_lib_cells -quiet *ssg_*max_0p81v_m40c*/*ZTS*] -delay_corner $max_cn -cell_delay -early -clock $vars(max_cell_early_clock1_svt)
	    	set_timing_derate [get_lib_cells -quiet *ssg_*max_0p81v_m40c*/*ZTS*] -delay_corner $max_cn -cell_delay -late -clock $vars(max_cell_late_clock1_svt)

	    	set_timing_derate [get_lib_cells -quiet *ssg_*max_0p81v_m40c*/*ZTH*] -delay_corner $max_cn -cell_delay -early -clock $vars(max_cell_early_clock1_hvt)
	    	set_timing_derate [get_lib_cells -quiet *ssg_*max_0p81v_m40c*/*ZTH*] -delay_corner $max_cn -cell_delay -late -clock $vars(max_cell_late_clock1_hvt)
	    }

	    foreach max_cn $vars(max_corner2) {
			set_timing_derate [get_lib_cells -quiet *ssg_*max_0p81v_125c*/*ZTUL*] -delay_corner $max_cn -cell_delay -early -clock $vars(max_cell_early_clock2_ulvt)
	    	set_timing_derate [get_lib_cells -quiet *ssg_*max_0p81v_125c*/*ZTUL*] -delay_corner $max_cn -cell_delay -late -clock $vars(max_cell_late_clock2_ulvt)

	    	set_timing_derate [get_lib_cells -quiet *ssg_*max_0p81v_125c*/*ZTL*] -delay_corner $max_cn -cell_delay -early -clock $vars(max_cell_early_clock2_lvt)
	    	set_timing_derate [get_lib_cells -quiet *ssg_*max_0p81v_125c*/*ZTL*] -delay_corner $max_cn -cell_delay -late -clock $vars(max_cell_late_clock2_lvt)
	    	
	    	set_timing_derate [get_lib_cells -quiet *ssg_*max_0p81v_125c*/*ZTS*] -delay_corner $max_cn -cell_delay -early -clock $vars(max_cell_early_clock2_svt)
	    	set_timing_derate [get_lib_cells -quiet *ssg_*max_0p81v_125c*/*ZTS*] -delay_corner $max_cn -cell_delay -late -clock $vars(max_cell_late_clock2_svt)

	    	set_timing_derate [get_lib_cells -quiet *ssg_*max_0p81v_125c*/*ZTH*] -delay_corner $max_cn -cell_delay -early -clock $vars(max_cell_early_clock2_hvt)
	    	set_timing_derate [get_lib_cells -quiet *ssg_*max_0p81v_125c*/*ZTH*] -delay_corner $max_cn -cell_delay -late -clock $vars(max_cell_late_clock2_hvt)
	    }


      foreach min_cn $vars(min_corner1) {
			set_timing_derate [get_lib_cells -quiet *ffg_*min_0p99v_125c*/*ZTUL*] -delay_corner $min_cn -cell_delay -early -clock $vars(min_cell_early_clock1_ulvt)
	    	set_timing_derate [get_lib_cells -quiet *ffg_*min_0p99v_125c*/*ZTUL*] -delay_corner $min_cn -cell_delay -late -clock $vars(min_cell_late_clock1_ulvt)

	    	set_timing_derate [get_lib_cells -quiet *ffg_*min_0p99v_125c*/*ZTL*] -delay_corner $min_cn -cell_delay -early -clock $vars(min_cell_early_clock1_lvt)
	    	set_timing_derate [get_lib_cells -quiet *ffg_*min_0p99v_125c*/*ZTL*] -delay_corner $min_cn -cell_delay -late -clock $vars(min_cell_late_clock1_lvt)
	    	
	    	set_timing_derate [get_lib_cells -quiet *ffg_*min_0p99v_125c*/*ZTS*] -delay_corner $min_cn -cell_delay -early -clock $vars(min_cell_early_clock1_svt)
	    	set_timing_derate [get_lib_cells -quiet *ffg_*min_0p99v_125c*/*ZTS*] -delay_corner $min_cn -cell_delay -late -clock $vars(min_cell_late_clock1_svt)
	    
	    	set_timing_derate [get_lib_cells -quiet *ffg_*min_0p99v_125c*/*ZTH*] -delay_corner $min_cn -cell_delay -early -clock $vars(min_cell_early_clock1_hvt)
	    	set_timing_derate [get_lib_cells -quiet *ffg_*min_0p99v_125c*/*ZTH*] -delay_corner $min_cn -cell_delay -late -clock $vars(min_cell_late_clock1_hvt)
	    }

	    foreach min_cn $vars(min_corner2) {
			set_timing_derate [get_lib_cells -quiet *ffg_*min_0p99v_m40c*/*ZTUL*] -delay_corner $min_cn -cell_delay -early -clock $vars(min_cell_early_clock2_ulvt)
	    	set_timing_derate [get_lib_cells -quiet *ffg_*min_0p99v_m40c*/*ZTUL*] -delay_corner $min_cn -cell_delay -late -clock $vars(min_cell_late_clock2_ulvt)

	    	set_timing_derate [get_lib_cells -quiet *ffg_*min_0p99v_m40c*/*ZTL*] -delay_corner $min_cn -cell_delay -early -clock $vars(min_cell_early_clock2_lvt)
	    	set_timing_derate [get_lib_cells -quiet *ffg_*min_0p99v_m40c*/*ZTL*] -delay_corner $min_cn -cell_delay -late -clock $vars(min_cell_late_clock2_lvt)
	    	
	    	set_timing_derate [get_lib_cells -quiet *ffg_*min_0p99v_m40c*/*ZTS*] -delay_corner $min_cn -cell_delay -early -clock $vars(min_cell_early_clock2_svt)
	    	set_timing_derate [get_lib_cells -quiet *ffg_*min_0p99v_m40c*/*ZTS*] -delay_corner $min_cn -cell_delay -late -clock $vars(min_cell_late_clock2_svt)
	    
	    	set_timing_derate [get_lib_cells -quiet *ffg_*min_0p99v_m40c*/*ZTH*] -delay_corner $min_cn -cell_delay -early -clock $vars(min_cell_early_clock2_hvt)
	    	set_timing_derate [get_lib_cells -quiet *ffg_*min_0p99v_m40c*/*ZTH*] -delay_corner $min_cn -cell_delay -late -clock $vars(min_cell_late_clock2_hvt)
	    }

			foreach min_cn $vars(min_corner3) {
			set_timing_derate [get_lib_cells -quiet *ssg_*max_0p81v_m40c*/*ZTUL*] -delay_corner $min_cn -cell_delay -early -clock $vars(min_cell_early_clock3_ulvt)
	    	set_timing_derate [get_lib_cells -quiet *ssg_*max_0p81v_m40c*/*ZTUL*] -delay_corner $min_cn -cell_delay -late -clock $vars(min_cell_late_clock3_ulvt)
		    set_timing_derate [get_lib_cells -quiet *ssg_*max_0p81v_m40c*/*ZTUL*] -delay_corner $min_cn -cell_delay -early -data $vars(min_cell_early_data3_ulvt)

	    	set_timing_derate [get_lib_cells -quiet *ssg_*max_0p81v_m40c*/*ZTL*] -delay_corner $min_cn -cell_delay -early -clock $vars(min_cell_early_clock3_lvt)
	    	set_timing_derate [get_lib_cells -quiet *ssg_*max_0p81v_m40c*/*ZTL*] -delay_corner $min_cn -cell_delay -late -clock $vars(min_cell_late_clock3_lvt)
            set_timing_derate [get_lib_cells -quiet *ssg_*max_0p81v_m40c*/*ZTL*] -delay_corner $min_cn -cell_delay -early -data $vars(min_cell_early_data3_lvt)

	    	set_timing_derate [get_lib_cells -quiet *ssg_*max_0p81v_m40c*/*ZTS*] -delay_corner $min_cn -cell_delay -early -clock $vars(min_cell_early_clock3_svt)
	    	set_timing_derate [get_lib_cells -quiet *ssg_*max_0p81v_m40c*/*ZTS*] -delay_corner $min_cn -cell_delay -late -clock $vars(min_cell_late_clock3_svt)
            set_timing_derate [get_lib_cells -quiet *ssg_*max_0p81v_m40c*/*ZTS*] -delay_corner $min_cn -cell_delay -early -data $vars(min_cell_early_data3_svt)

	    	set_timing_derate [get_lib_cells -quiet *ssg_*max_0p81v_m40c*/*ZTH*] -delay_corner $min_cn -cell_delay -early -clock $vars(min_cell_early_clock3_hvt)
	    	set_timing_derate [get_lib_cells -quiet *ssg_*max_0p81v_m40c*/*ZTH*] -delay_corner $min_cn -cell_delay -late -clock $vars(min_cell_late_clock3_hvt)
            set_timing_derate [get_lib_cells -quiet *ssg_*max_0p81v_m40c*/*ZTH*] -delay_corner $min_cn -cell_delay -early -data $vars(min_cell_early_data3_hvt)
      }	
	}
} elseif { $vars(ocv) == "socv" } {
	reset_timing_derate

	set timing_socv_rc_variation_mode true

	set_socv_rc_variation_factor -early 0.06 -view {func_wcl_cworst_t func_wcl_rcworst_t func_wc_cworst_t func_wc_rcworst_t func_ml_rcworst func_ml_cworst func_ml_rcbest func_ml_cbest func_lt_rcworst func_lt_cworst func_lt_rcbest func_lt_cbest}
	set_socv_rc_variation_factor -late 0.06 -view {func_wcl_cworst_t func_wcl_rcworst_t func_wc_cworst_t func_wc_rcworst_t func_ml_rcworst func_ml_cworst func_ml_rcbest func_ml_cbest func_lt_rcworst func_lt_cworst func_lt_rcbest func_lt_cbest}

    if { $vars(library) == "TSMC22ULL" } {
        foreach max_cn $vars(max_corner1) {
	    	set_timing_derate [get_lib_cells -quiet *ssg0p72vm40c*/*P140LVT] -delay_corner $max_cn -cell_delay -early -clock $vars(max_cell_early_clock1_lvt)
	    	set_timing_derate [get_lib_cells -quiet *ssg0p72vm40c*/*P140LVT] -delay_corner $max_cn -cell_delay -late -clock $vars(max_cell_late_clock1_lvt)
	    	
	    	set_timing_derate [get_lib_cells -quiet *ssg0p72vm40c*/*P140] -delay_corner $max_cn -cell_delay -early -clock $vars(max_cell_early_clock1_svt)
	    	set_timing_derate [get_lib_cells -quiet *ssg0p72vm40c*/*P140] -delay_corner $max_cn -cell_delay -late -clock $vars(max_cell_late_clock1_svt)

	    	set_timing_derate [get_lib_cells -quiet *ssg0p72vm40c*/*P140HVT] -delay_corner $max_cn -cell_delay -early -clock $vars(max_cell_early_clock1_hvt)
	    	set_timing_derate [get_lib_cells -quiet *ssg0p72vm40c*/*P140HVT] -delay_corner $max_cn -cell_delay -late -clock $vars(max_cell_late_clock1_hvt)

	    	set_timing_derate [get_lib_cells -quiet *ssg0p72v0p81vm40c*/LVL*P140HVT] -delay_corner $max_cn -cell_delay -early -clock $vars(max_cell_early_clock1_hvt)
	    	set_timing_derate [get_lib_cells -quiet *ssg0p72v0p81vm40c*/LVL*P140HVT] -delay_corner $max_cn -cell_delay -late -clock $vars(max_cell_late_clock1_hvt)

	    	set_timing_derate [get_lib_cells -quiet *ssg0p81v0p72vm40c*/LVL*P140HVT] -delay_corner $max_cn -cell_delay -early -clock $vars(max_cell_early_clock1_hvt)
	    	set_timing_derate [get_lib_cells -quiet *ssg0p81v0p72vm40c*/LVL*P140HVT] -delay_corner $max_cn -cell_delay -late -clock $vars(max_cell_late_clock1_hvt)

	    	set_timing_derate [get_lib_cells -quiet *ssg0p81vm40c*/*P140EHVT] -delay_corner $max_cn -cell_delay -early -clock $vars(max_cell_early_clock1_ehvt)
	    	set_timing_derate [get_lib_cells -quiet *ssg0p81vm40c*/*P140EHVT] -delay_corner $max_cn -cell_delay -late -clock $vars(max_cell_late_clock1_ehvt)
	    }

	    foreach max_cn $vars(max_corner2) {
	    	set_timing_derate [get_lib_cells -quiet *ssg0p72v125c*/*P140LVT] -delay_corner $max_cn -cell_delay -early -clock $vars(max_cell_early_clock2_lvt)
	    	set_timing_derate [get_lib_cells -quiet *ssg0p72v125c*/*P140LVT] -delay_corner $max_cn -cell_delay -late -clock $vars(max_cell_late_clock2_lvt)
	    	
	    	set_timing_derate [get_lib_cells -quiet *ssg0p72v125c*/*P140] -delay_corner $max_cn -cell_delay -early -clock $vars(max_cell_early_clock2_svt)
	    	set_timing_derate [get_lib_cells -quiet *ssg0p72v125c*/*P140] -delay_corner $max_cn -cell_delay -late -clock $vars(max_cell_late_clock2_svt)

	    	set_timing_derate [get_lib_cells -quiet *ssg0p72v125c*/*P140HVT] -delay_corner $max_cn -cell_delay -early -clock $vars(max_cell_early_clock2_hvt)
	    	set_timing_derate [get_lib_cells -quiet *ssg0p72v125c*/*P140HVT] -delay_corner $max_cn -cell_delay -late -clock $vars(max_cell_late_clock2_hvt)

	    	set_timing_derate [get_lib_cells -quiet *ssg0p72v0p81v125c*/LVL*P140HVT] -delay_corner $max_cn -cell_delay -early -clock $vars(max_cell_early_clock2_hvt)
	    	set_timing_derate [get_lib_cells -quiet *ssg0p72v0p81v125c*/LVL*P140HVT] -delay_corner $max_cn -cell_delay -late -clock $vars(max_cell_late_clock2_hvt)

	    	set_timing_derate [get_lib_cells -quiet *ssg0p81v0p72v125c*/LVL*P140HVT] -delay_corner $max_cn -cell_delay -early -clock $vars(max_cell_early_clock2_hvt)
	    	set_timing_derate [get_lib_cells -quiet *ssg0p81v0p72v125c*/LVL*P140HVT] -delay_corner $max_cn -cell_delay -late -clock $vars(max_cell_late_clock2_hvt)

	    	set_timing_derate [get_lib_cells -quiet *ssg0p81v125c*/*P140EHVT] -delay_corner $max_cn -cell_delay -early -clock $vars(max_cell_early_clock2_ehvt)
	    	set_timing_derate [get_lib_cells -quiet *ssg0p81v125c*/*P140EHVT] -delay_corner $max_cn -cell_delay -late -clock $vars(max_cell_late_clock2_ehvt)
	    }

	    foreach min_cn $vars(min_corner1) {
	    	set_timing_derate [get_lib_cells -quiet *ffg0p88v125c*/*P140LVT] -delay_corner $min_cn -cell_delay -early -clock $vars(min_cell_early_clock1_lvt)
	    	set_timing_derate [get_lib_cells -quiet *ffg0p88v125c*/*P140LVT] -delay_corner $min_cn -cell_delay -late -clock $vars(min_cell_late_clock1_lvt)
	    	
	    	set_timing_derate [get_lib_cells -quiet *ffg0p88v125c*/*P140] -delay_corner $min_cn -cell_delay -early -clock $vars(min_cell_early_clock1_svt)
	    	set_timing_derate [get_lib_cells -quiet *ffg0p88v125c*/*P140] -delay_corner $min_cn -cell_delay -late -clock $vars(min_cell_late_clock1_svt)
	    
	    	set_timing_derate [get_lib_cells -quiet *ffg0p88v125c*/*P140HVT] -delay_corner $min_cn -cell_delay -early -clock $vars(min_cell_early_clock1_hvt)
	    	set_timing_derate [get_lib_cells -quiet *ffg0p88v125c*/*P140HVT] -delay_corner $min_cn -cell_delay -late -clock $vars(min_cell_late_clock1_hvt)

	    	set_timing_derate [get_lib_cells -quiet *ffg0p88v0p99v125c*/LVL*P140HVT] -delay_corner $min_cn -cell_delay -early -clock $vars(min_cell_early_clock1_hvt)
	    	set_timing_derate [get_lib_cells -quiet *ffg0p88v0p99v125c*/LVL*P140HVT] -delay_corner $min_cn -cell_delay -late -clock $vars(min_cell_late_clock1_hvt)

	    	set_timing_derate [get_lib_cells -quiet *ffg0p99v0p88v125c*/LVL*P140HVT] -delay_corner $min_cn -cell_delay -early -clock $vars(min_cell_early_clock1_hvt)
	    	set_timing_derate [get_lib_cells -quiet *ffg0p99v0p88v125c*/LVL*P140HVT] -delay_corner $min_cn -cell_delay -late -clock $vars(min_cell_late_clock1_hvt)

	    	set_timing_derate [get_lib_cells -quiet *ffg0p99v125c*/*P140EHVT] -delay_corner $min_cn -cell_delay -early -clock $vars(min_cell_early_clock1_ehvt)
	    	set_timing_derate [get_lib_cells -quiet *ffg0p99v125c*/*P140EHVT] -delay_corner $min_cn -cell_delay -late -clock $vars(min_cell_late_clock1_ehvt)
	    }

	    foreach min_cn $vars(min_corner2) {
	    	set_timing_derate [get_lib_cells -quiet *ffg0p88vm40c*/*P140LVT] -delay_corner $min_cn -cell_delay -early -clock $vars(min_cell_early_clock2_lvt)
	    	set_timing_derate [get_lib_cells -quiet *ffg0p88vm40c*/*P140LVT] -delay_corner $min_cn -cell_delay -late -clock $vars(min_cell_late_clock2_lvt)
	    	
	    	set_timing_derate [get_lib_cells -quiet *ffg0p88vm40c*/*P140] -delay_corner $min_cn -cell_delay -early -clock $vars(min_cell_early_clock2_svt)
	    	set_timing_derate [get_lib_cells -quiet *ffg0p88vm40c*/*P140] -delay_corner $min_cn -cell_delay -late -clock $vars(min_cell_late_clock2_svt)
	    
	    	set_timing_derate [get_lib_cells -quiet *ffg0p88vm40c*/*P140HVT] -delay_corner $min_cn -cell_delay -early -clock $vars(min_cell_early_clock2_hvt)
	    	set_timing_derate [get_lib_cells -quiet *ffg0p88vm40c*/*P140HVT] -delay_corner $min_cn -cell_delay -late -clock $vars(min_cell_late_clock2_hvt)

	    	set_timing_derate [get_lib_cells -quiet *ffg0p99v0p88vm40c*/LVL*P140HVT] -delay_corner $min_cn -cell_delay -early -clock $vars(min_cell_early_clock2_hvt)
	    	set_timing_derate [get_lib_cells -quiet *ffg0p99v0p88vm40c*/LVL*P140HVT] -delay_corner $min_cn -cell_delay -late -clock $vars(min_cell_late_clock2_hvt)
	    	
	    	set_timing_derate [get_lib_cells -quiet *ffg0p88v0p99vm40c*/LVL*P140HVT] -delay_corner $min_cn -cell_delay -early -clock $vars(min_cell_early_clock2_hvt)
	    	set_timing_derate [get_lib_cells -quiet *ffg0p88v0p99vm40c*/LVL*P140HVT] -delay_corner $min_cn -cell_delay -late -clock $vars(min_cell_late_clock2_hvt)

	    	set_timing_derate [get_lib_cells -quiet *ffg0p99vm40c*/*P140EHVT] -delay_corner $min_cn -cell_delay -early -clock $vars(min_cell_early_clock2_ehvt)
	    	set_timing_derate [get_lib_cells -quiet *ffg0p99vm40c*/*P140EHVT] -delay_corner $min_cn -cell_delay -late -clock $vars(min_cell_late_clock2_ehvt)
	    }

        foreach min_cn $vars(min_corner3) {
	    	set_timing_derate [get_lib_cells -quiet *ssg0p72vm40c*/*P140LVT] -delay_corner $min_cn -cell_delay -early -clock $vars(min_cell_early_clock3_lvt)
	    	set_timing_derate [get_lib_cells -quiet *ssg0p72vm40c*/*P140LVT] -delay_corner $min_cn -cell_delay -late -clock $vars(min_cell_late_clock3_lvt)
        set_timing_derate [get_lib_cells -quiet *ssg0p72vm40c*/*P140LVT] -delay_corner $min_cn -cell_delay -early -data $vars(min_cell_early_data3_lvt)

	    	set_timing_derate [get_lib_cells -quiet *ssg0p72vm40c*/*P140] -delay_corner $min_cn -cell_delay -early -clock $vars(min_cell_early_clock3_svt)
	    	set_timing_derate [get_lib_cells -quiet *ssg0p72vm40c*/*P140] -delay_corner $min_cn -cell_delay -late -clock $vars(min_cell_late_clock3_svt)
        set_timing_derate [get_lib_cells -quiet *ssg0p72vm40c*/*P140] -delay_corner $min_cn -cell_delay -early -data $vars(min_cell_early_data3_svt)

	    	set_timing_derate [get_lib_cells -quiet *ssg0p72vm40c*/*P140HVT] -delay_corner $min_cn -cell_delay -early -clock $vars(min_cell_early_clock3_hvt)
	    	set_timing_derate [get_lib_cells -quiet *ssg0p72vm40c*/*P140HVT] -delay_corner $min_cn -cell_delay -late -clock $vars(min_cell_late_clock3_hvt)
        set_timing_derate [get_lib_cells -quiet *ssg0p72vm40c*/*P140HVT] -delay_corner $min_cn -cell_delay -early -data $vars(min_cell_early_data3_hvt)

	    	set_timing_derate [get_lib_cells -quiet *ssg0p72v0p81vm40c*/LVL*P140HVT] -delay_corner $min_cn -cell_delay -early -clock $vars(min_cell_early_clock3_hvt)
	    	set_timing_derate [get_lib_cells -quiet *ssg0p72v0p81vm40c*/LVL*P140HVT] -delay_corner $min_cn -cell_delay -late -clock $vars(min_cell_late_clock3_hvt)
        set_timing_derate [get_lib_cells -quiet *ssg0p72v0p81vm40c*/LVL*P140HVT] -delay_corner $min_cn -cell_delay -early -data $vars(min_cell_early_data3_hvt)

	    	set_timing_derate [get_lib_cells -quiet *ssg0p81v0p72vm40c*/LVL*P140HVT] -delay_corner $min_cn -cell_delay -early -clock $vars(min_cell_early_clock3_hvt)
	    	set_timing_derate [get_lib_cells -quiet *ssg0p81v0p72vm40c*/LVL*P140HVT] -delay_corner $min_cn -cell_delay -late -clock $vars(min_cell_late_clock3_hvt)
        set_timing_derate [get_lib_cells -quiet *ssg0p81v0p72vm40c*/LVL*P140HVT] -delay_corner $min_cn -cell_delay -early -data $vars(min_cell_early_data3_hvt)

	    	set_timing_derate [get_lib_cells -quiet *ssg0p81vm40c*/*P140EHVT] -delay_corner $min_cn -cell_delay -early -clock $vars(min_cell_early_clock3_ehvt)
	    	set_timing_derate [get_lib_cells -quiet *ssg0p81vm40c*/*P140EHVT] -delay_corner $min_cn -cell_delay -late -clock $vars(min_cell_late_clock3_ehvt)
        set_timing_derate [get_lib_cells -quiet *ssg0p81vm40c*/*P140EHVT] -delay_corner $min_cn -cell_delay -early -data $vars(min_cell_early_data3_ehvt)
	    }
    } elseif { $vars(library) == "ARM22ULL" } {
        foreach max_cn $vars(max_corner1) {
	    	set_timing_derate [get_lib_cells -quiet *ssg_*max_0p72v_m40c*/*ZTL*] -delay_corner $max_cn -cell_delay -early -clock $vars(max_cell_early_clock1_lvt)
	    	set_timing_derate [get_lib_cells -quiet *ssg_*max_0p72v_m40c*/*ZTL*] -delay_corner $max_cn -cell_delay -late -clock $vars(max_cell_late_clock1_lvt)
	    	
	    	set_timing_derate [get_lib_cells -quiet *ssg_*max_0p72v_m40c*/*ZTS*] -delay_corner $max_cn -cell_delay -early -clock $vars(max_cell_early_clock1_svt)
	    	set_timing_derate [get_lib_cells -quiet *ssg_*max_0p72v_m40c*/*ZTS*] -delay_corner $max_cn -cell_delay -late -clock $vars(max_cell_late_clock1_svt)

	    	set_timing_derate [get_lib_cells -quiet *ssg_*max_0p72v_m40c*/*ZTH*] -delay_corner $max_cn -cell_delay -early -clock $vars(max_cell_early_clock1_hvt)
	    	set_timing_derate [get_lib_cells -quiet *ssg_*max_0p72v_m40c*/*ZTH*] -delay_corner $max_cn -cell_delay -late -clock $vars(max_cell_late_clock1_hvt)
	    }

	    foreach max_cn $vars(max_corner2) {
	    	set_timing_derate [get_lib_cells -quiet *ssg_*max_0p72v_125c*/*ZTL*] -delay_corner $max_cn -cell_delay -early -clock $vars(max_cell_early_clock2_lvt)
	    	set_timing_derate [get_lib_cells -quiet *ssg_*max_0p72v_125c*/*ZTL*] -delay_corner $max_cn -cell_delay -late -clock $vars(max_cell_late_clock2_lvt)
	    	
	    	set_timing_derate [get_lib_cells -quiet *ssg_*max_0p72v_125c*/*ZTS*] -delay_corner $max_cn -cell_delay -early -clock $vars(max_cell_early_clock2_svt)
	    	set_timing_derate [get_lib_cells -quiet *ssg_*max_0p72v_125c*/*ZTS*] -delay_corner $max_cn -cell_delay -late -clock $vars(max_cell_late_clock2_svt)

	    	set_timing_derate [get_lib_cells -quiet *ssg_*max_0p72v_125c*/*ZTH*] -delay_corner $max_cn -cell_delay -early -clock $vars(max_cell_early_clock2_hvt)
	    	set_timing_derate [get_lib_cells -quiet *ssg_*max_0p72v_125c*/*ZTH*] -delay_corner $max_cn -cell_delay -late -clock $vars(max_cell_late_clock2_hvt)
	    }


        foreach min_cn $vars(min_corner1) {
	    	set_timing_derate [get_lib_cells -quiet *ffg_*min_0p88v_125c*/*ZTL*] -delay_corner $min_cn -cell_delay -early -clock $vars(min_cell_early_clock1_lvt)
	    	set_timing_derate [get_lib_cells -quiet *ffg_*min_0p88v_125c*/*ZTL*] -delay_corner $min_cn -cell_delay -late -clock $vars(min_cell_late_clock1_lvt)
	    	
	    	set_timing_derate [get_lib_cells -quiet *ffg_*min_0p88v_125c*/*ZTS*] -delay_corner $min_cn -cell_delay -early -clock $vars(min_cell_early_clock1_svt)
	    	set_timing_derate [get_lib_cells -quiet *ffg_*min_0p88v_125c*/*ZTS*] -delay_corner $min_cn -cell_delay -late -clock $vars(min_cell_late_clock1_svt)
	    
	    	set_timing_derate [get_lib_cells -quiet *ffg_*min_0p88v_125c*/*ZTH*] -delay_corner $min_cn -cell_delay -early -clock $vars(min_cell_early_clock1_hvt)
	    	set_timing_derate [get_lib_cells -quiet *ffg_*min_0p88v_125c*/*ZTH*] -delay_corner $min_cn -cell_delay -late -clock $vars(min_cell_late_clock1_hvt)
	    }

	    foreach min_cn $vars(min_corner2) {
	    	set_timing_derate [get_lib_cells -quiet *ffg_*min_0p88v_m40c*/*ZTL*] -delay_corner $min_cn -cell_delay -early -clock $vars(min_cell_early_clock2_lvt)
	    	set_timing_derate [get_lib_cells -quiet *ffg_*min_0p88v_m40c*/*ZTL*] -delay_corner $min_cn -cell_delay -late -clock $vars(min_cell_late_clock2_lvt)
	    	
	    	set_timing_derate [get_lib_cells -quiet *ffg_*min_0p88v_m40c*/*ZTS*] -delay_corner $min_cn -cell_delay -early -clock $vars(min_cell_early_clock2_svt)
	    	set_timing_derate [get_lib_cells -quiet *ffg_*min_0p88v_m40c*/*ZTS*] -delay_corner $min_cn -cell_delay -late -clock $vars(min_cell_late_clock2_svt)
	    
	    	set_timing_derate [get_lib_cells -quiet *ffg_*min_0p88v_m40c*/*ZTH*] -delay_corner $min_cn -cell_delay -early -clock $vars(min_cell_early_clock2_hvt)
	    	set_timing_derate [get_lib_cells -quiet *ffg_*min_0p88v_m40c*/*ZTH*] -delay_corner $min_cn -cell_delay -late -clock $vars(min_cell_late_clock2_hvt)
	    }

        foreach min_cn $vars(min_corner3) {
	    	set_timing_derate [get_lib_cells -quiet *ssg_*max_0p72v_m40c*/*ZTL*] -delay_corner $min_cn -cell_delay -early -clock $vars(min_cell_early_clock3_lvt)
	    	set_timing_derate [get_lib_cells -quiet *ssg_*max_0p72v_m40c*/*ZTL*] -delay_corner $min_cn -cell_delay -late -clock $vars(min_cell_late_clock3_lvt)
        set_timing_derate [get_lib_cells -quiet *ssg_*max_0p72v_m40c*/*ZTL*] -delay_corner $min_cn -cell_delay -early -data $vars(min_cell_early_data3_lvt)

	    	set_timing_derate [get_lib_cells -quiet *ssg_*max_0p72v_m40c*/*ZTS*] -delay_corner $min_cn -cell_delay -early -clock $vars(min_cell_early_clock3_svt)
	    	set_timing_derate [get_lib_cells -quiet *ssg_*max_0p72v_m40c*/*ZTS*] -delay_corner $min_cn -cell_delay -late -clock $vars(min_cell_late_clock3_svt)
        set_timing_derate [get_lib_cells -quiet *ssg_*max_0p72v_m40c*/*ZTS*] -delay_corner $min_cn -cell_delay -early -data $vars(min_cell_early_data3_svt)

	    	set_timing_derate [get_lib_cells -quiet *ssg_*max_0p72v_m40c*/*ZTH*] -delay_corner $min_cn -cell_delay -early -clock $vars(min_cell_early_clock3_hvt)
	    	set_timing_derate [get_lib_cells -quiet *ssg_*max_0p72v_m40c*/*ZTH*] -delay_corner $min_cn -cell_delay -late -clock $vars(min_cell_late_clock3_hvt)
        set_timing_derate [get_lib_cells -quiet *ssg_*max_0p72v_m40c*/*ZTH*] -delay_corner $min_cn -cell_delay -early -data $vars(min_cell_early_data3_hvt)
        }
    } else {
        puts "process definition error!"
    }
}
