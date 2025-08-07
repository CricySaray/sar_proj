source ./proc_mux_of_strategies.invs.tcl; # mux_of_strategies
source ../../../packages/generate_randomNumber_withNormalDistribution.package.tcl; # generate_randomNumber_withNormalDistribution
source ../../../packages/print_formattedTable.package.tcl; # print_formattedTable
source ../../../eco_fix/timing_fix/trans_fix/proc_get_net_lenth.invs.tcl; # 
proc test_all_output_pin {{sumFile "testPinOutput.list"}} {
  set allOutputPin [dbget [dbget top.insts.instTerms {.isOutput == 1}].name]
  set fo [open $sumFile w]
  foreach testpin $allOutputPin {
    set netname [dbget [dbget top.insts.instTerms.name $testpin .p2].net.name ]
    set netLen [get_net_length $netname]
    if {!$netLen} {continue}
    set randomViolValue [generate_randomNumber_withNormalDistribution]
    puts "point [incr i]: viol: $randomViolValue | pin: $testpin"
    set dict_of_sum [mux_of_strategies $randomViolValue $testpin]
    set temp "randomViolValue: $randomViolValue | [dict get $dict_of_sum]"
    puts $fo $temp
    flush $fo
  }
  puts "total process [llength $allOutputPin]"
  close $fo
}
