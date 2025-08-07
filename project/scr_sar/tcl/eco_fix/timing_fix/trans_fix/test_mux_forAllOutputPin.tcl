source ./proc_mux_of_strategies.invs.tcl; # mux_of_strategies
proc test_all_output_pin {} {
  set allOutputPin [dbget [dbget top.insts.instTerms {.isOutput == 1}].name]
  set 
}
