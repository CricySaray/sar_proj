source ./proc_mux_of_strategies.invs.tcl; # mux_of_strategies
source ../../../packages/generate_randomNumber_withNormalDistribution.package.tcl; # generate_randomNumber_withNormalDistribution
proc test_all_output_pin {} {
  set allOutputPin [dbget [dbget top.insts.instTerms {.isOutput == 1}].name]
  set randomViolValue [generate_randomNumber_withNormalDistribution]
  set result_test [lmap testpin $allOutputPin {
    set dict_of_sum [mux_of_strategies $randomViolValue $testpin]
    set temp "randomViolValue: $randomViolValue | [dict get $dict_of_sum]"
  }]
}
