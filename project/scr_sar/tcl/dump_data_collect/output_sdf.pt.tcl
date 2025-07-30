set dir ""
set scenario  ""
set design_name ""

set blk_data_dir /simulation/arsong/SC5018/PT/run/r0769_s0769_FP0714_dft_071414_eco5
set session func_hold typical typical_25c
set rc_corner hold_1p1v_1plv25c
set blk_name SC5018_TOP

### remove clock uncertainty
set clocks [get_clocks *]
foreach_in_collection cptr $clocks {
	set clock [get_attribute $cptr full_name]
	puts "remove clock uncertainty $clock"
	remove_clock_uncertainty $clock
  foreach_in_collection cptr_iner $clocks {
    set clock_iner [get_attribute $cptr_iner full_name]
    puts "remove clock uncertainty between $clock and $clock_iner"
    remove_clock_uncertainty -from $clock -to $clock_iner
  }
}


set all_regs [all_registers]
set mem_cells [filter_collection $all_regs "is_memory_cell ==true"]
set mem_macros_ck_pins [get_pins -of_objects $mem_cells -filter "is_clock_pin ==true" -quiet]
remove_clock_uncertainty -hold $mem_macros_ck_pins

### reset derate and pocv
set timing_aocvm_enable_analysis false
set timing_pocvm_enable_analysis false
reset_timing_derate

# to fix the small violations in verify sdf flow
set_path_margin -setup 0.010 -to [get_clocks]
set_path_margin -hold 0.010 -to [get_clocks]

proc annotated {} {
	global blk_data_dir session
	set hold_timing "-delay_type min -max_path 9999999 -nworst 1 -slack_lesser_than 0"
	set hold_paths [eval [concat "get_timing_paths" $hold_timing]]
	set hold_num [sizeof_collection $hold_paths]

	if {$hold_num} {
		foreach_in_collection hold_path $hold_paths {
			set slack [get_attribute $hold_path slack]
			set endpt [get_attribute $hold_path endpoint]
			if {[regexp {\d+} $slack]} {
				set slack [expr $slack - 0.015]
        set_annotated_delay [expr 0 - $slack] -increment -net -to [get_attribute $endpt full_name]
        echo "set_annotated_delay [expr 0 - $slack] -increment -net -to [get_attribute $endpt full_name]" >> ${blk_data_dir}/${session}.annotated.tcl
			}
		}
	}

	set setup_timing "-delay_type max -max_path 9999999 -nworst 1 -slack_lesser_than 0"
	set setup_paths [eval [concat "get_timing_paths" $setup_timing]]
	set setup_num [sizeof_collection $setup_paths]

	if {$setup_num} {
		foreach_in_collection setup_path $setup_paths {
			set slack [get_attribute $setup_path slack]
			set endpt [get_attribute $setup_path endpoint]
			if {[regexp {\d+} $slack]} {
				set slack [expr $slack - 0.015]
        set_annotated_delay [expr 0 + $slack] -increment -net -to [get_attribute $endpt full_name]
        echo "set_annotated_delay [expr 0 + $slack] -increment -net -to [get_attribute $endpt full_name]" >> ${blk_data_dir}/${session}.annotated.tcl
			}
		}
	}
}

update_timing -full
annotated
update_timing -full

report_global_timing > ${blk_data_dir}/${session}.pre_annotated.global_timing.rpt

write_sdf \
-version 3.0 \
-significant_digits 5 \
-input_port_nets \
-output_port_nets \
-include { SETUPHOLD RECREM } \
-exclude { no_condelse checkpins } \
-context verilog \
-no_internal_pins \
-compress gzip \
-no_negative_values { cell_delays net_delays } \
${blk_data_dir}/${blk_name}.${session}.sdf.gz

