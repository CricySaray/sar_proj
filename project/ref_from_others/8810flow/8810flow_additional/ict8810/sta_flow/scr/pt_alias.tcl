alias rt report_timing -crosstalk_delta -nets -capacitance -transition_time -to
alias rf report_timing -crosstalk_delta -nets -capacitance -transition_time -from 
alias rtf report_timing -crosstalk_delta -nets -capacitance -transition_time -path_type full_clock_expanded  -to  
alias rff report_timing -crosstalk_delta -nets -capacitance -transition_time -path_type full_clock_expanded  -from 
alias rts report_timing -path_type short -to 
alias rfs report_timing -path_type short -from
alias rtm report_timing -delay_type min -crosstalk_delta -nets -capacitance -transition_time -to
alias rfm report_timing -delay_type min -crosstalk_delta -nets -capacitance -transition_time -from
alias rtmf report_timing -delay_type min -crosstalk_delta -nets -capacitance -transition_time -path_type full_clock_expanded  -to
alias rfmf report_timing -delay_type min -crosstalk_delta -nets -capacitance -transition_time -path_type full_clock_expanded  -from 
alias rtms report_timing -delay_type min -path_type short -to
alias rfms report_timing -delay_type min -path_type short -from
