#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/03 17:13:23 Sunday
# label     : task_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|misc_proc)
# descrip   : selector of strategies for fix_trans.invs.tcl
# return    : 
# TODO      : U001: consider Loop case, judge it before use mux_of_strategies. you must reRoute if severe case!!!
#             U002: build a function relationship between netLen and violValue(one2one), need other more complex relationship when one2more
#             U003: judge if the driver cell can change VT and drive capacity, if not, using inserting buffer or add to NOTICEList(need to fix by yourself)
# ref       : link url
# --------------------------
source ./proc_32_solve_quadratic_equation.common.tcl; # solve_quadratic_equation
source ./proc_cond_meet_any.invs.tcl; # cond_met_any
source ./proc_getAllInfo_fromPin.invs.tcl; # get_allInfo_fromPin
# allInfo: dict keys: driverPin/sinksPin/driverCellClass/sinksCellClass/netName/netLen/driverInstname/sinksInstname/
#                 driverCellType/sinksCellType/driverCapacity/sinksCapacity/driverVTtype/sinksVTtype/driverPinPT/
#                 sinksPinPT/numSinks/shortenedSinksCellClassRaw/simplizedSinksCellClass/shortenedSinksCellClassSimplized/
#                 uniqueSinksCellClass/mostFrequentInSinksCellClass/numOfMostFrequentInSinksCellClass/centerPtOfSinksPinPT/
#                 distanceOfDriver2CenterOfSinksPinPt/ifLoop
proc mux_of_strategies {{violValue 0} {violPin ""}} {
  if {![string is double $violValue] || [expr $violValue > 0] || $violPin == "" || $violPin == "0x0" || [dbget top.insts.instTerms.name $violPin -e] == ""} {
    error "proc mux_of_strategies: check your input, violValue($violValue) is not double number or greater than 0 or violPin($violPin) is not found!!!"
  } else {
    set allInfo [get_allInfo_fromPin $violPin]
    dict for {infovar infovalue} $allInfo { set $infovar $infovalue }

    set validViolValue [expr abs($violValue) * 1000]

    ## bl - buffer to logic
    set crosspoint {15 15} ; # for bl situ
    set farThresholdPoint {30 130} ; # x: validViolValue , y: netLen
    set coefficientsABC [solve_quadratic_equation {0 0} $crosspoint $farThresholdPoint]
    # x : $validViolValue   y : netLen
    set netLenLine [expr {[dict get $coefficientsABC a]*($validViolValue**2) + [dict get $coefficientsABC b]*$validViolValue + [dict get $coefficientsABC c]}] ; # U002: function bewteen netLen and violValue when one2one 
    # puts "netLen: $netLen   |  netLenLine: $netLenLine"
    if {$netLen <= [lindex $crosspoint 1] || $netLen >= $netLenLine} { ; # if netLen < fixedValue, you can't insert buffer
      puts "you can fix viol by changing VT and drive capacity!!!" 
    } else {
      puts "you need insert buffer to fix!!!" 
    }



    if {0} {
      array set mapCond {
        v violValue
        n netLen
      }
      # specify conds that can change VT and driveCapacity, the others need to insert buffer to fix
      # $v: violValue
      # $n: netLen
      set conds {
        {bl {
          {$v > -0.010 && $n < 15}
          {$v > -0.030 && $n < 30}
        }} {bb {
          {$v > -0.020 && $n < 20}
        }} {lb {
          {$v > -0.020 && $n < 20}
        }} {ll {
          {$v > -0.020 && $n < 20}
        }}
      }
     
    }

  }
}
