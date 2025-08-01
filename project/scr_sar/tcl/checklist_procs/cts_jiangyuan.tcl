proc proc_yj_check_cts_cell {} {
	set cts_cell [filter_collection [get_clock_network_objects -type cell -include_clock_gating_network] "ref_name !~ ANT* && is_black_box==false && is_pad_cell == false"]
	set txt ""
	set violnum 0

	# 1) all clock cells driver must >= D1
	set driver_viols_cells [filter_collection $cts_cell "ref_name =~ *D0BWP* || ref_name =~ *D1BWP*"]
	append txt [pc_text $driver_viols_cells "ERROR: cts cell driver must > 1 ; " inst]
	incr violnum [sizeof_coll $driver_viols_cells]

	# 2) all buf/inv must be DCCK*, LH/LN must be CK*, logicsX2 must be CK*
	set type_viols_cells_bufinv  [filter_collection $cts_cell "ref_name =~ *BUF* || ref_name =~ *INV* || ref_name =~ CKB* || ref_name =~ CKN*"]
	set type_viols_cells_latch   [filter_collection $cts_cell "( ref_name =~ LH* || ref_name =~ LN* ) && ref_name !~ CK* "]
	set type_viols_cells_logics  [filter_collection $cts_cell "( ref_name =~ MUX2* || ref_name =~ AN2* || ref_name =~ OR2* ) && ref_name !~ CK*"]
	append txt [pc_text $type_viols_cells_bufinv "ERROR: buffer/inverter must be DCCK* ; " inst]
	append txt [pc_text $type_viols_cells_latch "ERROR: latch must be CKL* ; " inst]
	append txt [pc_text $type_viols_cells_logics "ERROR: MUX2/AN2/OR2 must be CK* ; " inst]
	incr violnum [sizeof_coll $type_viols_cells_bufinv]
	incr violnum [sizeof_coll $type_viols_cells_latch]
	incr violnum [sizeof_coll $type_viols_cells_logics]

	# 3) all logics must be all ULVT or all LVT
	if { [get_attr [current_design] full_name -q] != "chip_top" } {
		set vt_cells_ulvt  [filter_collection $cts_cell "ref_name =~ *CPDULVT"]
		set vt_cells_lvt   [filter_collection $cts_cell "ref_name =~ *CPDLVT"]
		if { [sizeof_coll $vt_cells_ulvt] > [sizeof_coll $vt_cells_lvt] } {
			set vt_cells_noulvt [filter_collection $cts_cell "ref_name !~ *CPDULVT"]
			append txt [pc_text $vt_cells_noulvt "ERROR: cts cell must all be *ULVT ; " inst]
			incr violnum [sizeof_coll $vt_cells_noulvt]
		} else {
			set vt_cells_nolvt [filter_collection $cts_cell "ref_name !~ *CPDLVT"]
			append txt [pc_text $vt_cells_nolvt "ERROR: cts cell must all be *LVT ; " inst]
			incr violnum [sizeof_coll $vt_cells_nolvt]
		}
	}

	return [list $txt $violnum]
}
