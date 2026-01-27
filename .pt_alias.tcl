# ------------------------
# pt alias 

alias s "source"
alias sa "source ~/.pt_alias.tcl"
alias rs "restore_session"
alias sc "set_host_options -max_cores" ; # you need input number of max cores
set_host_options -max_cores 8
alias sa "source ~/.pt_alias.tcl"

set pba_mode "ex"
set common_options "-nos -input -nets -transition_time -variation -capacitance -crosstalk_delta -derate -significant_digits 3 -pba_mode $pba_mode -delay_type"
set common_options_split "-input -nets -transition_time -variation -capacitance -crosstalk_delta -derate -significant_digits 3 -pba_mode $pba_mode -delay_type"
alias rt "report_timing $common_options max -nworst 1"
alias rtf "report_timing $common_options max -nworst 1 -path_type full_clock_expanded"
alias rth "report_timing $common_options min -nworst 1"
alias rthf "report_timing $common_options min -nworst 1 -path_type full_clock_expanded"

alias rts "report_timing $common_options_split max -nworst 1"
alias rtfs "report_timing $common_options_split max -nworst 1 -path_type full_clock_expanded"
alias rths "report_timing $common_options_split min -nworst 1"
alias rthfs "report_timing $common_options_split min -nworst 1 -path_type full_clock_expanded"
