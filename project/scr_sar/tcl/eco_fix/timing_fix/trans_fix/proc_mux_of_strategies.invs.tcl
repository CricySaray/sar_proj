#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/03 17:13:23 Sunday
# label     : task_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|misc_proc)
# descrip   : selector of strategies for fix_trans.invs.tcl
# return    : dict data: $resultDict: cmdList/fixedList/cantChangeList/skippedList/nonConsideredList
# TODO      : 
#             U001: consider Loop case, judge it before use mux_of_strategies. you must reRoute if severe case!!!
#             U003: judge if the driver cell can change VT and drive capacity, if not, using inserting buffer or add to NOTICEList(need to fix by yourself)
#             U004: add judgement for non-consider driver-sinks symbol
#             U005: need shorten too long string of pinname using stringstore::*
# FIXED     :
#             U001(partial): only pick out this situation, need to improve return value
#             U002: build a function relationship between netLen and violValue(one2one), need other more complex relationship when one2more
# ref       : link url
# --------------------------
source ../../../packages/stringstore.package.tcl; # stringstore::*
source ../../../packages/logic_AND_OR.package.tcl; # er
source ../../../packages/every_any.package.tcl; # every any
source ./proc_32_solve_quadratic_equation.common.tcl; # solve_quadratic_equation
source ./proc_print_ecoCommands.invs.tcl; # print_ecoCommand
source ./proc_cond_meet_any.invs.tcl; # cond_met_any
source ./proc_getAllInfo_fromPin.invs.tcl; # get_allInfo_fromPin
# allInfo: dict keys: driverPin/sinksPin/driverCellClass/sinksCellClass/netName/netLen/wiresPts/driverInstname/sinksInstname/
#                 driverCellType/sinksCellType/driverCapacity/sinksCapacity/driverVTtype/sinksVTtype/driverPinPT/
#                 sinksPinPT/numSinks/shortenedSinksCellClass/simplizedSinksCellClass/shortenedSimplizedSinksCellClass/
#                 uniqueSinksCellClass/uniqueShortenedSinksCellClass/uniqueSimplizedSinksCellClass/uniqueShortenedSimplizedSinksCellClass
#                 mostFrequentInSinksCellClass/numOfMostFrequentInSinksCellClass/centerPtOfSinksPinPT/
#                 distanceOfDriver2CenterOfSinksPinPt/ifLoop/ifOne2One/ifSimpleOne2More/driverSinksSymbol/ifHaveBeenFastestVTinRange/
#                 ifHaveBeenLargestCapacityInRange/ifNetConnected/ruleLen/sink_pt_D2List/sinkPinFarthestToDriverPin/sinksCellClassForShow/farthestSinkCellType
#                 infoToShow
alias mux_of_strategies "sliding_rheostat_of_strategies"
proc sliding_rheostat_of_strategies {{violValue 0} {violPin ""} {debug 0} {promptPrefix "# song"}} {
  if {![string is double $violValue] || [expr $violValue > 0] || $violPin == "" || $violPin == "0x0" || [dbget top.insts.instTerms.name $violPin -e] == ""} {
    error "proc mux_of_strategies: check your input, violValue($violValue) is not double number or greater than 0 or violPin($violPin) is not found!!!"
  } else {
    set promptInfo [string cat $promptPrefix "INFO"] ; set promptWarning [string cat $promptPrefix "WARN"] ; set promptError [string cat $promptPrefix "ERROR"]
    proc onlyReadTrace {var_name index operation} { error "proc onlyReadTrace: variable($var_name) is read-only, you can't write it!!!" }
    set allInfo [get_allInfo_fromPin $violPin]
    trace add variable allInfo write onlyReadTrace
    dict for {infovar infovalue} $allInfo { set $infovar $infovalue ; trace add variable $infovar write onlyReadTrace}
    set addedInfoToShow [concat $violValue $infoToShow]
    er $debug { puts [join [dict get $allInfo] \n] }
    set validViolValue [expr abs($violValue) * 1000]
    # U004 $ifNeedConsiderThisDriverSinksSymbol : this flag tell that you need add this mix of type from driverSymbol to sinksSymbol
    set resultDict [dict create ifPassPreCheck 0 ifComplexOne2More 0 ifNeedReRouteNet 0 ifFixedSuccessfully 0 ifSkipped 0 ifNotSupportCellClass 0 ifCantChange 0 ifDirtyCase 0 ifNeedConsiderThisDriverSinksSymbol 0]
    set resultDict_lists [list fixed_one_list cmd_one_list fixed_more_list cmd_more_list fixed_reRoute_list cmd_reRoute_list skipped_list nonConsidered_list cantChange_list dirtyCase_list ]
    foreach lists_item $resultDict_lists { dict set resultDict $lists_item [list ] }

    er $debug { puts "ifLoop : $ifLoop  | numSinks : $numSinks" }
    dict with resultDict {
      # ---------------------------------------------- 
      # pre check
      # you can add other conditions(scripts) to precheck situation in list of $preCheckConds
      # it will return 1 if any of scripts return true or 1
      set ifDirtyCase [expr !$numSinks || !$netLen || !$ifNetConnected] ; # if 1: have problem
      set ifNeedReRouteNet [expr {$ifLoop in {moderate severe}}] ; # if 1: the net has looped (adapted to one2one and one2more)
      set ifNotSupportCellClass [any x [list $driverCellClass {*}$sinksCellClass] { expr {$x in {memory IP IOpad}} }] ; # now not support these cell class
      set ifComplexOne2More [expr !$ifSimpleOne2More] ; # if 1, now can't fix. it need fix by yourself
      set preCheckConds { 
        {expr $ifDirtyCase}
        {expr $ifNeedReRouteNet}
        {expr $ifNotSupportCellClass}
        {expr $ifComplexOne2More}
      }
      set ifPassPreCheck [expr ![cond_met_any {*}$preCheckConds]]
      if {!$ifPassPreCheck} { ; # NOTICE: include nonConsider and dirtyCase list
        if {$ifDirtyCase} {
          lappend dirtyCase_list [concat "dirty" $addedInfoToShow]
        }
        if {$ifNeedReRouteNet} {
          set ifFixedSuccessfully 1
          lappend fixed_reRoute_list [concat "reRoute" $addedInfoToShow]
          lappend cmd_reRoute_list [print_ecoCommand -type delNet -terms $driverPin]
        }
        if {$ifNotSupportCellClass} {
          lappend nonConsidered_list [concat "classNotSupport" $addedInfoToShow]
        }
        if {$ifComplexOne2More} {
          lappend nonConsideredList [concat "complexMore" $addedInfoToShow]
        }
      } elseif {$ifPassPreCheck} {
        er $debug { puts "Congratulations!!! pass precheck" }
        # ---------------------------------------------- 
        # begin process valid situations!!!
        switch -regexp $driverSinksSymbol {
          "^m?b\[ls\]$"       {set crosspointOfChangeCapacityAndInsertBuffer {15 15} ; set crosspointOfChangeVTandCapacity {4 4}}
          "^m?bb$"            {set crosspointOfChangeCapacityAndInsertBuffer {25 25} ; set crosspointOfChangeVTandCapacity {6 6}}
          "^m?\[ls\]b$"       {set crosspointOfChangeCapacityAndInsertBuffer {20 20} ; set crosspointOfChangeVTandCapacity {5 5}}
          "^m?\[ls\]\[ls\]$"  {set crosspointOfChangeCapacityAndInsertBuffer {10 10} ; set crosspointOfChangeVTandCapacity {3 3}}
          default             {set crosspointOfChangeCapacityAndInsertBuffer {15 15} ; set crosspointOfChangeVTandCapacity {4 4} ; set ifNeedConsiderThisDriverSinksSymbol 1}
        }
        if {$ifNeedConsiderThisDriverSinksSymbol} { puts "\n$promptWarning : this driverSinksSymbol($driverSinksSymbol) is not considered, you need add it!!!\n" }
        set farThresholdPointOfChangeCapacityAndInsertBuffer {30 130} ; # x: validViolValue , y: netLen
        set farThresholdPointOfChangeVTandCapacity {8 130} ; # x: validViolValue , y: netLen
        set coefficientsABCOfChangeCapacityAndInsertBuffer [solve_quadratic_equation {0 0} $crosspointOfChangeCapacityAndInsertBuffer $farThresholdPointOfChangeCapacityAndInsertBuffer]
        set coefficientsABCOfChangeVTandCapacity [solve_quadratic_equation {0 0} $crosspointOfChangeVTandCapacity $farThresholdPointOfChangeVTandCapacity]
        # x : $validViolValue   y : netLen
        er $debug { puts "driverSinksSymbol: $driverSinksSymbol | crosspointOfChangeCapacityAndInsertBuffer: $crosspointOfChangeCapacityAndInsertBuffer" }
        er $debug { puts "validViolValue: $validViolValue | a: [dict get $coefficientsABCOfChangeCapacityAndInsertBuffer a] | b: [dict get $coefficientsABCOfChangeCapacityAndInsertBuffer b] | c: [dict get $coefficientsABCOfChangeCapacityAndInsertBuffer c]" }
        set netLenLineOfchangeCapacityAndInsertBuffer [expr {[dict get $coefficientsABCOfChangeCapacityAndInsertBuffer a]*($validViolValue**2) + [dict get $coefficientsABCOfChangeCapacityAndInsertBuffer b]*$validViolValue + [dict get $coefficientsABCOfChangeCapacityAndInsertBuffer c]}] ; # U002: function bewteen netLen and violValue when one2one 
        set netLenLineOfchangeVTandCapacity [expr {[dict get $coefficientsABCOfChangeVTandCapacity a]*($validViolValue**2) + [dict get $coefficientsABCOfChangeVTandCapacity b]*$validViolValue + [dict get $coefficientsABCOfChangeVTandCapacity c]}] ; # U002: function bewteen netLen and violValue when one2one 
        er $debug { puts "netLen: $netLen   |  netLenLineOfchangeCapacityAndInsertBuffer: $netLenLineOfchangeCapacityAndInsertBuffer" }
        set ifInsideFunctionRelationshipThresholdOfChangeCapacityAndInsertBuffer [expr $netLen <= [lindex $crosspointOfChangeCapacityAndInsertBuffer 1] || $netLen >= $netLenLineOfchangeCapacityAndInsertBuffer]; # if netLen < fixedValue, you can't insert buffer
        set ifInsideFunctionRelationshipThresholdOfChangeVTandCapacity [expr $netLen <= [lindex $crosspointOfChangeVTandCapacity 1] || $netLen >= $netLenLineOfchangeVTandCapacity]; # if netLen < fixedValue, you can't insert buffer
        er $debug { puts "if inside functions: $ifInsideFunctionRelationshipThresholdOfChangeCapacityAndInsertBuffer" }
        if {$ifInsideFunctionRelationshipThresholdOfChangeVTandCapacity} {
          puts "\n$promptInfo : Congratulations!!! you can fix viol by changing VT\n" 
         
        } elseif {$ifInsideFunctionRelationshipThresholdOfChangeCapacityAndInsertBuffer} { ; # NOTICE
          puts "\n$promptInfo : Congratulations!!! you can fix viol by changing Capacity\n" 
          
        } else { ; # NOTICE
          puts "\n$promptInfo : needInsertBufferToFix\n" 
        }
       
      }
    }
    dict for {infovar infovalue} $allInfo { trace remove variable $infovar write onlyReadTrace }
    trace remove variable allInfo write onlyReadTrace
    return [join [list $resultDict $allInfo] \n]; # dict data
  }
}
