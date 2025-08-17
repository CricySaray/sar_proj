source ./proc_mux_of_strategies.invs.tcl; # mux_of_strategies
source ../../../packages/generate_randomNumber_withNormalDistribution.package.tcl; # generate_randomNumber_withNormalDistribution
source ../../../packages/print_formattedTable.package.tcl; # print_formattedTable
source ../../../eco_fix/timing_fix/trans_fix/proc_get_net_lenth.invs.tcl; # 
proc test_all_output_pin {{sumFile "testPinOutput.list"}} {
  set allOutputPin [dbget [dbget top.insts.instTerms {.isOutput == 1}].name]
  set allOutputPin [lrange $allOutputPin 0 9999]
  set fo [open $sumFile w]
  set i 0
  foreach testpin $allOutputPin {
    set netname [dbget [dbget top.insts.instTerms.name $testpin -p].net.name -e]
    if {$netname == ""} {continue}
    set netLen [get_net_length $netname]
    if {$netLen == 0} {continue}
    set randomViolValue [generate_randomNumber_withNormalDistribution]
    puts "point [incr i]: viol: $randomViolValue | pin: $testpin"
    set dict_of_sum [mux_of_strategies -violValue $randomViolValue -violPin $testpin]
    set temp "randomViolValue: $randomViolValue | [dict get $dict_of_sum]"
    puts $fo $temp
    incr i
    flush $fo
  }
  puts "total process $i"
  close $fo
}
