###############################
#        pt proc              #                    
###############################
set_app_var report_default_significant_digits 4

alias qor_sum "report_global_timing -include {scenario_details} -format wide"
alias check_annotated "remote_execute -v {report_annotated_parasitics}"

alias rp "report_timing -nosplit -transition_time -capacitance -derate -crosstalk_delta -nets -input_pins"
alias rpf "report_timing -nosplit -transition_time -capacitance -derate -crosstalk_delta -nets -input_pins -from"
alias rpff "report_timing -nosplit -transition_time -capacitance -derate -crosstalk_delta -nets -input_pins -path_type full_clock_ex -from"
alias rpt "report_timing -nosplit -transition_time -capacitance -derate -crosstalk_delta -nets -input_pins -to"
alias rptf "report_timing -nosplit -transition_time -capacitance -derate -crosstalk_delta -nets -input_pins -path_type full_clock_ex -to"

alias hrp "report_timing -nosplit -transition_time -capacitance -derate -crosstalk_delta -nets -input_pins -delay_type min"
alias hrpf "report_timing -nosplit -transition_time -capacitance -derate -crosstalk_delta -nets -input_pins -delay_type min -from"
alias hrpff "report_timing -nosplit -transition_time -capacitance -derate -crosstalk_delta -nets -input_pins -delay_type min -path_type full_clock_ex -from"
alias hrpt "report_timing -nosplit -transition_time -capacitance -derate -crosstalk_delta -nets -input_pins -delay_type min -to"
alias hrptf "report_timing -nosplit -transition_time -capacitance -derate -crosstalk_delta -nets -input_pins -delay_type min -path_type full_clock_ex -to"

alias h "history"

alias rpt_sum100 "report_timing -path_type summary -max_paths 100 -delay_type max -nosplit"
alias hrpt_sum100 "report_timing -path_type summary -max_paths 100 -delay_type min -nosplit"

alias rpt_sum10000 "report_timing -path_type summary -max_paths 10000 -delay_type max -nosplit"
alias hrpt_sum10000 "report_timing -path_type summary -max_paths 10000 -delay_type min -nosplit"

