# ------------------------
# pt alias 

alias sa "source ~/.pt_alias.tcl"
alias rs "restore_session"
alias sc "set_host_options -max_cores" ; # you need input number of max cores
alias rt "report_timing -nos -input -nets -delay_type max -transition_time -capacitance -crosstalk_delta -derate -significant_digits 3 -nworst 3"
alias rth "report_timing -nos -input -nets -delay_type min -transition_time -capacitance -crosstalk_delta -derate -significant_digits 3 -nworst 3"

alias rts "report_timing -nos -input -nets -delay_type max -transition_time -capacitance -crosstalk_delta -derate -significant_digits 3 -nworst 3 -path_type summary"
alias rtsh "report_timing -nos -input -nets -delay_type min -transition_time -capacitance -crosstalk_delta -derate -significant_digits 3 -nworst 3 -path_type summary"
