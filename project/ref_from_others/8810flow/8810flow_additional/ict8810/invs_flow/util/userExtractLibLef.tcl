proc userExtractLibLef {} {
        global vars
        global dsn_constr_dir
        set dsn_constr_dir ../../dsn/constrains
        set lib_dir ../../dsn/lib
	if { ![file exists $lib_dir]} {
		exec mkdir -p $lib_dir
	}
	set lef_dir ../../dsn/lef
	if { ![file exists $lef_dir]} {
		exec mkdir -p $lef_dir
	}

	##abstract lef 
	#lefOut -stripePin -specifyTopLayer 8 -PGpinLayers 7 8 $lef_dir/[dbgDesignName].$vars(step).$vars(view_rpt).lef
    write_lef_abstract -5.8 -PGPinLayers {ME7 ME8 AL_RDL} -extractBlockObs -specifyTopLayer ME7 -stripePin $lef_dir/[dbgDesignName].$vars(step).$vars(view_rpt).lef
	##abstract lib 
	set_analysis_view -setup {func_wcl_cworst_t scan_wcl_cworst_t } -hold {func_ml_rcworst scan_ml_rcworst }
	#set_analysis_view -setup {func_wcl_cworst_t  } -hold {func_ml_rcworst  func_wcl_rcworst  }
	set_interactive_constraint_modes [all_constraint_modes -active]
    set timing_extract_model_case_analysis_in_library false
	set setup_list [all_setup_analysis_views]
	set hold_list [all_hold_analysis_views]
	foreach ss $setup_list {
		set_analysis_view -setup $ss -hold $ss
		set md [all_constraint_modes -active]
        set_interactive_constraint_modes [all_constraint_modes -active]
		regsub -all " " $md "" md
#		update_constraint_mode -name $md -sdc $dsn_constr_dir/[dbgDesignName].${md}.genlib.$vars(view_rpt).sdc
		if {$vars(step) == "place"} {
		} else  {
			set_propagated_clock [all_clocks]
		}
		setAnalysisMode -checkType setup
		do_extract_model $dsn_constr_dir/[dbgDesignName].${ss}.$vars(step).$vars(view_rpt).lib -view $ss
	}
	foreach ff $hold_list {
		set_analysis_view -setup $ff -hold $ff
		set md [all_constraint_modes -active]
        set_interactive_constraint_modes [all_constraint_modes -active]
		regsub -all " " $md "" md
#		update_constraint_mode -name $md -sdc $dsn_constr_dir/[dbgDesignName].${md}.genlib.$vars(view_rpt).sdc
		if {$vars(step) == "place"} {
		} else  {
			set_propagated_clock [all_clocks]
		}
		setAnalysisMode -checkType hold
		do_extract_model $dsn_constr_dir/[dbgDesignName].${ff}.$vars(step).$vars(view_rpt).lib -view $ff
	}
}
