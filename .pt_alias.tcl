# ------------------------
# pt alias 

alias sa "source ~/.pt_alias.tcl"
alias rs "restore_session"
alias sc "set_host_options -max_cores" ; # you need input number of max cores
set common_options "-nos -input -nets -transition_time -variation -capacitance -crosstalk_delta -derate -significant_digits 3 -delay_type"
alias rt "report_timing $common_options max -nworst 3"
alias rth "report_timing $common_options min -nworst 3"
