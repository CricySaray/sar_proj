set_table_style -no_frame_fix_width
set_global timing_report_unconstrained_paths                true
set_global timing_enable_genclk_edge_based_source_latency   false
set_global timing_disable_recovery_removal_checks           false
set_global timing_library_enable_mt_flow                    true
set_default_switching_activity -global_activity 0.2 -period 10ns -seq_activity 0.2 -clock_gates_output 1.2

setAnalysisMode -aocv true
set_global timing_aocv_analysis_mode                        separate_data_clock
set_global timing_aocv_analysis_mode                        combine_launch_capture
set_global timing_aocv_derate_mode                          aocv_additive
set_global timing_enable_aocv_slack_based                   true
set_global report_timing_format {instance arc cell fanout slew load incr_delay delay_mean delay_sensitivity delay_sigma delay arrival_mean arrival_sensitivity arrival_sigma arrival user_derate total_derate}

setOptMode -timeDesignNumPaths 9999
setOptMode -fixHoldAllowOverlap false
