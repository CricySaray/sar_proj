#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/03 17:13:23 Sunday
# label     : task_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|misc_proc)
# descrip   : selector of strategies for fix_trans.invs.tcl
# return    : 
# TODO      : 
#             U001: consider Loop case, judge it before use mux_of_strategies. you must reRoute if severe case!!!
#             U003: judge if the driver cell can change VT and drive capacity, if not, using inserting buffer or add to NOTICEList(need to fix by yourself)
# FIXED     :
#             U001(partial): only pick out this situation, need to improve return value
#             U002: build a function relationship between netLen and violValue(one2one), need other more complex relationship when one2more
# ref       : link url
# --------------------------
source ../../../packages/logic_AND_OR.package.tcl; # er
source ../../../packages/every_any.package.tcl; # every any
source ./proc_32_solve_quadratic_equation.common.tcl; # solve_quadratic_equation
source ./proc_cond_meet_any.invs.tcl; # cond_met_any
source ./proc_getAllInfo_fromPin.invs.tcl; # get_allInfo_fromPin
# allInfo: dict keys: driverPin/sinksPin/driverCellClass/sinksCellClass/netName/netLen/driverInstname/sinksInstname/
#                 driverCellType/sinksCellType/driverCapacity/sinksCapacity/driverVTtype/sinksVTtype/driverPinPT/
#                 sinksPinPT/numSinks/shortenedSinksCellClassRaw/simplizedSinksCellClass/shortenedSinksCellClassSimplized/
#                 uniqueSinksCellClass/mostFrequentInSinksCellClass/numOfMostFrequentInSinksCellClass/centerPtOfSinksPinPT/
#                 distanceOfDriver2CenterOfSinksPinPt/ifLoop/ifOne2One/ifSimpleOne2More/driverSinksSymbol/ifHaveBeenFastVTinRange/
#                 ifHaveBeenLargestCapacityInRange
alias mux_of_strategies "sliding_rheostat_of_strategies"
proc sliding_rheostat_of_strategies {{violValue 0} {violPin ""} {debug 0}} {
  if {![string is double $violValue] || [expr $violValue > 0] || $violPin == "" || $violPin == "0x0" || [dbget top.insts.instTerms.name $violPin -e] == ""} {
    error "proc mux_of_strategies: check your input, violValue($violValue) is not double number or greater than 0 or violPin($violPin) is not found!!!"
  } else {
    set allInfo [get_allInfo_fromPin $violPin]
    dict for {infovar infovalue} $allInfo { set $infovar $infovalue }
    set validViolValue [expr abs($violValue) * 1000]

    er $debug { puts "ifLoop : $ifLoop  | numSinks : $numSinks" }
    # you can add other conditions(scripts) to precheck situation in list of $preCheckConds
    # it will return 1 if any of scripts return true or 1
    set preCheckConds { 
      {expr {$ifOne2One && $ifLoop in {moderate severe}}}
      {expr !$ifSimpleOne2More}
      {any x [list $driverCellClass {*}$sinksCellClass] { expr {$x in {memory IP IOpad}} }}
    }
    set ifFailedPreCheck [cond_met_any {*}$preCheckConds]
    if {$ifFailedPreCheck} {
      return "notPassPreCheck"; # loop and complex one 2 more
    } else {
      puts "Congratulations!!! pass precheck"
    }
  # ---------------------------------------------- 
  # begin process valid situations!!!
    switch $driverSinksSymbol {
      "bl" - "bs" {set crosspoint {15 15}}
      "bb"        {set crosspoint {25 25}}
      "lb" - "sb" {set crosspoint {20 20}}
      "ll" - "ss" {set crosspoint {10 10}}
    }
    set farThresholdPoint {30 130} ; # x: validViolValue , y: netLen
    set coefficientsABC [solve_quadratic_equation {0 0} $crosspoint $farThresholdPoint]
    # x : $validViolValue   y : netLen
    er $debug { puts "driverSinksSymbol: $driverSinksSymbol | crosspoint: $crosspoint" }
    er $debug { puts "validViolValue: $validViolValue | a: [dict get $coefficientsABC a] | b: [dict get $coefficientsABC b] | c: [dict get $coefficientsABC c]" }
    set netLenLine [expr {[dict get $coefficientsABC a]*($validViolValue**2) + [dict get $coefficientsABC b]*$validViolValue + [dict get $coefficientsABC c]}] ; # U002: function bewteen netLen and violValue when one2one 
    er $debug { puts "netLen: $netLen   |  netLenLine: $netLenLine" }
    set ifOutOfFunctionRelationshipThreshold [expr $netLen <= [lindex $crosspoint 1] || $netLen >= $netLenLine]; # if netLen < fixedValue, you can't insert buffer
    puts "if Out of functions: $ifOutOfFunctionRelationshipThreshold"
    
  }
}
