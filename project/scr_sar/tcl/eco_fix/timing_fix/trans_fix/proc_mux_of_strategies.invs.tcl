#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/03 17:13:23 Sunday
# label     : task_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|misc_proc)
# descrip   : selector of strategies for fix_trans.invs.tcl
# return    : dict data: $resultDict: cmd_one|more_list/fixed_one|more_list/cantChange_list/skipped_list/nonConsidered_list
# TODO      : 
#             U006: change strategy according to the sinks capacity (advanced function)
#             U008: need move inst when the size changes too
#             U009 for change VT or/and capacity of driver celltype when adding repeater
#             U010: add try command for critical stage such as addRepeater/changeVT/changeCapacity
#             U011: In the case of one2more, by calculating the geometric area formed by the driver end and all sink ends, 
#                   the coordinate area where repeaters can be placed is determined. This provides more sufficient spatial positions 
#                   to choose from, reducing overlap issues caused by being unable to find positions for repeaters due to overly 
#                   strict position constraints.
#                   This method requires using algorithms to calculate the area where repeaters can be placed.
# FIXED     :
#             U001: consider Loop case, judge it before use mux_of_strategies. you must reRoute if severe case!!!
#             U002: build a function relationship between netLen and violValue(one2one), need other more complex relationship when one2more
#             U003: judge if the driver cell can change VT and drive capacity, if not, using inserting buffer or add to NOTICEList(need to fix by yourself)
#             U004: add judgement for non-consider driver-sinks symbol
#             U005: need shorten too long string of pinname using stringstore::* -> add this function at fix_trans.invs.tcl
#             U007: you need split one2one and one2more situation.
# NOTICE    : AT002: When setting the condition for determining whether it is the maximum allowable driver(proc judge_ifHaveBeenLargestCapacityInRange at 
#                   ./proc_getAllInfo_fromPin.invs.tcl), it needs to correspond to the maximum driver in mapList; if it does not correspond, it will most 
#                   likely report an error inside the proc.
# ref       : link url
# --------------------------
source ../../../packages/stringstore.package.tcl; # stringstore::*
source ../../../packages/logic_AND_OR.package.tcl; # er
source ../../../packages/incr_integer_inSelf.package.tcl; # ci / counter
source ../../../packages/every_any.package.tcl; # every any
source ./proc_32_solve_quadratic_equation.common.tcl; # solve_quadratic_equation
source ./proc_print_ecoCommands.invs.tcl; # print_ecoCommand
source ./proc_cond_meet_any.invs.tcl; # cond_met_any
source ./proc_strategy_changeVT.invs.tcl; # strategy_changeVT_withLUT
source ./proc_strategy_changeDriveCapacity_of_driveCell.invs.tcl; # strategy_changeDriveCapacity_withLUT
source ./proc_strategy_addRepeaterCelltype.invs.tcl; # strategy_addRepeaterCelltype_withLUT
source ./proc_formatDecimal.invs.tcl; # fm/formatDecimal
source ./proc_fit_path.invsGUI.tcl; # fit_path
source ../../../packages/calculate_relative_point_at_path.package.tcl; # calculate_relative_point_at_path
source ../physical_aware_algorithm/findSpaceToInsertRepeater_using_lutDict.invsGUI.tcl; # findSpaceToInsertRepeater_using_lutDict
source ./proc_calculateRelativePoint.invs.tcl; # calculateRelativePoint
source ./proc_calculateResistantCenter_advanced.invs.tcl; # calculateResistantCenter_fromPoints
source ./proc_gen_info_of_one2more_case.invs.tcl; # gen_info_of_one2more_case
source ../lut_build/operateLUT.tcl; # operateLUT
source ./proc_getAllInfo_fromPin.invs.tcl; # get_allInfo_fromPin
# mini descrip: driverPin/sinksPin/netName/netLen/wiresPts/driverInstname/sinksInstname/driverCellType/sinksCellType/
#               driverCellClass/sinksCellClass/driverCapacity/sinksCapacity/driverVTtype/sinksVTtype/driverPinPT/
#               sinksPinPT/numSinks/shortenedSinksCellClass/simplizedSinksCellClass/simplizedDriverCellClass/shortenedSimplizedSinksCellClass/
#               uniqueSinksCellClass/uniqueShortenedSinksCellClass/uniqueSimplizedSinksCellClass/uniqueShortenedSimplizedSinksCellClass
#               mostFrequentInSinksCellClass/numOfMostFrequentInSinksCellClass/centerPtOfSinksPinPT/
#               distanceOfDriver2CenterOfSinksPinPt/ifLoop/ifOne2One/ifSimpleOne2More/driverSinksSymbol/ifHaveBeenFastestVTinRange/
#               ifHaveBeenLargestCapacityInRange/ifNetConnected/ruleLen/sink_pt_D2List/sinkPinFarthestToDriverPin/sinksCellClassForShow/farthestSinkCellType/
#               [one2more: numFartherGroupSinks/fartherGroupSinksPinPt/fartherGroupSinksPin/mostFrequentInSinksCellType]/infoToShow/
alias mux_of_strategies "sliding_rheostat_of_strategies"
proc sliding_rheostat_of_strategies {args} {
  set violValue                                0
  set violPin                                  ""
  set VTweight                                 {{AR9 3} {AL9 1} {AH9 0}}
  set forbiddenVT                              HVT
  set driveCapacityRange                       {1 12}
  set ifInFixLongNetMode                       0
  set ifCanChangeVTandCapacityInFixLongNetMode 0
  set ifCanChangeVTWhenChangeCapacity          1
  set ifCanChangeVTcapacityWhenAddRepeater     1
  set newInstNamePrefix                        "sar_fix_trans_081420"
  set promptPrefix                             "# song"
  set debug                                    0
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  if {![string is double $violValue] || [expr $violValue > 0] || $violPin == "" || $violPin == "0x0" || [dbget top.insts.instTerms.name $violPin -e] == ""} {
    error "proc mux_of_strategies: check your input, violValue($violValue) is not double number or greater than 0 or violPin($violPin) is not found!!!"
  } else {
    set promptInfo [string cat $promptPrefix "INFO"] ; set promptWarning [string cat $promptPrefix "WARN"] ; set promptError [string cat $promptPrefix "ERROR"]
    proc onlyReadTrace {var_name index operation} { error "proc onlyReadTrace: variable($var_name) is read-only, you can't write it!!!" }
    set allInfo [get_allInfo_fromPin $violPin $forbiddenVT $driveCapacityRange]
    trace add variable allInfo write onlyReadTrace
    dict for {infovar infovalue} $allInfo { set $infovar $infovalue ; trace add variable $infovar write onlyReadTrace}
    set addedInfoToShow [concat $violValue $infoToShow]
    er $debug { puts [join [dict get $allInfo] \n] }
    set validViolValue [expr abs($violValue) * 1000]
    # U004 $ifNeedConsiderThisDriverSinksSymbol : this flag tell that you need add this mix of type from driverSymbol to sinksSymbol
    set resultDict [dict create ifPassPreCheck 0 ifComplexOne2More 0 ifNeedReRouteNet 0 ifFixedSuccessfully 0 ifFixButFailed 0 ifSkipped 0 ifNotSupportCellClass 0 ifCantChange 0 ifDirtyCase 0 \
                        ifHaveMovements 0 ifNeedNoticeCase 0 \
                        ifNeedConsiderThisDriverSinksSymbol 0 ifInsideFunctionRelationshipThresholdOfChangeVTandCapacity 0 ifInsideFunctionRelationshipThresholdOfChangeCapacityAndInsertBuffer 0]
    set resultDict_lists [list fixed_one_list cmd_one_list fixed_more_list cmd_more_list detailInfoOfMore_list movement_cmd_list fix_but_failed_list fixed_reRoute_list cmd_reRoute_list skipped_list \
                              notPassPreCheck_list cantChange_list needNoticeCase_list]
    foreach lists_item $resultDict_lists { dict set resultDict $lists_item [list ] }

    er $debug { puts "ifLoop : $ifLoop  | numSinks : $numSinks" }
    dict with resultDict {
      # ---------------------------------------------- 
      # pre check
      # you can add other conditions(scripts) to precheck situation in list of $preCheckConds
      # it will return 1 if any of scripts return true or 1
      set ifDirtyCase [expr !$numSinks || !$netLen || !$ifNetConnected] ; # if 1: have problem
      set ifNeedReRouteNet [expr {$ifLoop in {moderate severe}}] ; # if 1: the net has looped (adapted to one2one and one2more)
      set ifNotSupportCellClass [any x [list $simplizedDriverCellClass {*}$simplizedSinksCellClass] { regexp cantMap_ $x }] ; # now not support these cell class
      set ifComplexOne2More [expr !$ifSimpleOne2More] ; # if 1, now can't fix. it need fix by yourself
      set preCheckConds { 
        {expr $ifDirtyCase}
        {expr $ifNeedReRouteNet}
        {expr $ifNotSupportCellClass}
        {expr $ifComplexOne2More}
      }
      set ifPassPreCheck [expr ![cond_met_any {*}$preCheckConds]]
      if {!$ifPassPreCheck} { ; # NOTICE: include nonConsider and dirtyCase list
        if {$ifDirtyCase} { set precheckFlag_01 "D" } ; # dirty
        if {$ifNeedReRouteNet} {
          set ifFixedSuccessfully 1
          set precheckFlag_02 "R" ; # reRoute
          set cmd_reRoute_list [print_ecoCommand -type delNet -terms $driverPin]
        }
        if {$ifNotSupportCellClass} { set precheckFlag_03 "S" } ; # classNotSupport
        if {$ifComplexOne2More} { set precheckFlag_04 "X" } ; # compleXMore

        set precheckFlag [string cat {*}[lmap flag [info locals precheckFlag_*] { subst \${$flag} }]]
        set notPassPreCheck_list [concat $driverSinksSymbol $precheckFlag $addedInfoToShow]
      } elseif {$ifPassPreCheck} {
        er $debug { puts "Congratulations!!! pass precheck" }
        # ---------------------------------------------- 
        # begin process valid situations!!!
        switch -regexp $driverSinksSymbol {
          "^m?b\[ls\]$"       {set crosspointOfChangeCapacityAndInsertBuffer {15 15} ; set crosspointOfChangeVTandCapacity {4 4} ; set mapList {{0 2} {1 3} {2 4} {3 6} {4 6} {6 8} {8 12}} ; set relativeLoc 0.4 ; set addMethod "refDriver" ; set capacityRange {2 12}}
          "^m?bb$"            {set crosspointOfChangeCapacityAndInsertBuffer {25 25} ; set crosspointOfChangeVTandCapacity {6 6} ; set mapList {{0 3} {1 3} {2 4} {3 6} {4 6} {6 12} {8 12}} ; set relativeLoc 0.5 ; set addMethod "refSink" ; set capacityRange {3 12}}
          "^m?\[ls\]b$"       {set crosspointOfChangeCapacityAndInsertBuffer {20 20} ; set crosspointOfChangeVTandCapacity {5 5} ; set mapList {{0 2} {1 2} {2 2} {3 4} {4 4} {6 4} {8 4}} ; set relativeLoc 0.9 ; set addMethod "refDriver" ; set capacityRange {4 12}}
          "^m?\[ls\]\[ls\]$"  {set crosspointOfChangeCapacityAndInsertBuffer {10 10} ; set crosspointOfChangeVTandCapacity {3 3} ; set mapList {{0 2} {1 2} {2 2} {3 4} {4 4} {6 4} {8 4}} ; set relativeLoc 0.9 ; set addMethod "refDriver" ; set capacityRange {4 12}}
          default             {set crosspointOfChangeCapacityAndInsertBuffer {15 15} ; set crosspointOfChangeVTandCapacity {4 4} ; set mapList {{0 2} {1 3} {2 4} {3 6} {4 6} {6 8} {8 12}} ; set relativeLoc 0.7 ; set addMethod "refDriver" ; set capacityRange {2 12} ; set ifNeedConsiderThisDriverSinksSymbol 1}
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
        set ifInsideFunctionRelationshipThresholdOfChangeCapacityAndInsertBuffer [expr $netLen <= [lindex $crosspointOfChangeCapacityAndInsertBuffer 1] || $netLen >= $netLenLineOfchangeCapacityAndInsertBuffer]; # if this var is 1, you can change capacity(and vt) to fix viol AT001
        set ifInsideFunctionRelationshipThresholdOfChangeVTandCapacity [expr $netLen <= [lindex $crosspointOfChangeVTandCapacity 1] || $netLen >= $netLenLineOfchangeVTandCapacity]; # if this var is 1, you can change vt to fix viol
        er $debug { puts "if inside functions: $ifInsideFunctionRelationshipThresholdOfChangeCapacityAndInsertBuffer" }
        ### change VT {forbidden when Fix Long Net Mode}
        if {!$ifInFixLongNetMode && $ifInsideFunctionRelationshipThresholdOfChangeVTandCapacity && !$ifHaveBeenFastestVTinRange} {
          er $debug { puts "\n$promptInfo : Congratulations!!! you can fix viol by changing VT\n" }
          set toVT [strategy_changeVT_withLUT $driverCellType $VTweight 1]
          if {[operateLUT -type exists -attr [list celltype $toVT]]} {
            set ifFixedSuccessfully 1
            set cmd [print_ecoCommand -type change -celltype $toVT -inst $driverInstname] ; # U008: need move inst when size of toChangeCelltype is different from original size
            set fixedlist [concat $driverSinksSymbol "T" $toVT $addedInfoToShow]
            if {$ifOne2One} { set fixed_one_list $fixedlist ; lappend cmd_one_list $cmd } elseif {$ifSimpleOne2More} { 
              set fixed_more_list $fixedlist ; lappend cmd_more_list $cmd ; set detailInfoOfMore_list [gen_info_of_one2more_case $violValue $driverPin $sinksPin $wiresPts $infoToShow] }
          } else {set ifFixButFailed 1 ; lappend fix_but_failed_list [concat $driverSinksSymbol "failedVt" $toVT $addedInfoToShow]}
        } elseif {$ifInsideFunctionRelationshipThresholdOfChangeVTandCapacity && $ifHaveBeenFastestVTinRange} {
          set ifSkipped 1 ; set skippedFlag_01 "Fvt"
        } 
        ### change Capacity {forbidden when Fix Long Net Mode}
        if {!$ifInFixLongNetMode && !$ifFixedSuccessfully && $ifInsideFunctionRelationshipThresholdOfChangeCapacityAndInsertBuffer && !$ifHaveBeenLargestCapacityInRange} {
          er $debug { puts "\n$promptInfo : Congratulations!!! you can fix viol by changing Capacity\n" }
          set flagInsideFixCap ""
          if {$ifCanChangeVTWhenChangeCapacity && !$ifHaveBeenFastestVTinRange} {
            set toVT [strategy_changeVT_withLUT $driverCellType $VTweight 1]
            if {![operateLUT -type exists -attr [list celltype $toVT]]} { set ifFixButFailed 1 } else { set flagInsideFixCap "T" }
          } else { set toVT $driverCellType }
          if {$ifFixButFailed} {
            lappend fix_but_failed_list [concat $driverSinksSymbol "failedVtWhenCap" $toVT $addedInfoToShow]
          } else {
            set toCap [strategy_changeDriveCapacity_withLUT $toVT 0 $mapList 0 1] ; # TODO: U006: change strategy according to the sinks capacity ; AT002
            if {[operateLUT -type exists -attr [list celltype $toCap]]} {
              set ifFixedSuccessfully 1
              set cmd [print_ecoCommand -type change -celltype $toCap -inst $driverInstname] ; # U008
              set fixedlist [concat $driverSinksSymbol "${flagInsideFixCap}D" $toCap $addedInfoToShow]
              if {$ifOne2One} { set fixed_one_list $fixedlist  ; lappend cmd_one_list $cmd } elseif {$ifSimpleOne2More} { 
                set fixed_more_list $fixedlist ; lappend cmd_more_list $cmd ; set detailInfoOfMore_list [gen_info_of_one2more_case $violValue $driverPin $sinksPin $wiresPts $infoToShow]}
            } else {set ifFixButFailed 1 ; lappend fix_but_failed_list [concat $driverSinksSymbol "failedCap" $toCap $addedInfoToShow]}
          }
        } elseif {!$ifFixedSuccessfully && $ifInsideFunctionRelationshipThresholdOfChangeCapacityAndInsertBuffer && $ifHaveBeenLargestCapacityInRange} { 
          set ifSkipped 1 ; set skippedFlag_02 "Lcap"
        } 
        set skippedFlag [join [lmap flag [info locals skippedFlag_*] { subst \${$flag} }] "/"]
        lappend skipped_list [concat $driverSinksSymbol $skippedFlag $addedInfoToShow]
        ### add repeater (change VT/capacity) U010
        if {!$ifFixedSuccessfully && [expr $netLen >= [lindex $crosspointOfChangeCapacityAndInsertBuffer 1]]} { ; # NOTICE
          er $debug { puts "\n$promptInfo : needInsertBufferToFix\n" }
          if {$numOfMostFrequentInSinksCellClass == 1} { ; # U007: this judgement is simple , you need improve it after
            set suffixAddFlag "" ; # U009 for change VT or/and capacity of driver celltype when adding repeater
            set ifInClkTree [regexp CLK $driverCellClass]
            if {$ifInClkTree} { set refCell [operateLUT -type read -attr [list refclkbuffer]] } else { set refCell [operateLUT -type read -attr [list refbuffer]] }
            set toAdd [strategy_addRepeaterCelltype_withLUT $driverCellType $mostFrequentInSinksCellType $addMethod 0 $capacityRange 0 1 $refCell]
            if {![operateLUT -type exists -attr [list celltype $toAdd]]} {
              lappend fix_but_failed_list [concat $driverSinksSymbol "faildAdd" $toAdd $addedInfoToShow] 
            } else {
              set ifFixedSuccessfully 1
              if {[expr $netLen >= [expr [lindex $crosspointOfChangeCapacityAndInsertBuffer 1] * 2]]} { ; # you can have more space to search when the netLen is long
                set expandAreaWidthHeight {11 11} ; set divOfForceInsert 0.4 ; set multipleOfExpandSpace 1.5
              } else {
                set expandAreaWidthHeight {8 8}   ; set divOfForceInsert 0.6 ; set multipleOfExpandSpace 1.7
              }
              if {$ifOne2One} {
                set fited_wiresPts [fit_path $driverPinPT {*}$sinksPinPT $wiresPts]
                set toLoc [calculate_relative_point_at_path $driverPinPT {*}$sinksPinPT $fited_wiresPts $relativeLoc]
              } elseif {$ifSimpleOne2More} {
                set centerPointOfFartherGroupSinksPin [calculateResistantCenter_fromPoints $fartherGroupSinksPinPt "auto"] 
                set toLoc [calculateRelativePoint $driverPinPT $centerPointOfFartherGroupSinksPin $relativeLoc]
                set detailInfoOfMore_list [gen_info_of_one2more_case $violValue $driverPin $sinksPin $wiresPts $infoToShow]
              }

              set refineLoc [findSpaceToInsertRepeater_using_lutDict -testOrRun run -celltype $toAdd -loc $toLoc -expandAreaWidthHeight $expandAreaWidthHeight -divOfForceInsert $divOfForceInsert -multipleOfExpandSpace $multipleOfExpandSpace]
              lassign $refineLoc refineLocType refineLocPosition refineLocDistance refineLocMovementList
              set baseAddFlag "A_[fm $relativeLoc]"
              if {$ifOne2One} { set termsWhenAdd $sinksPin } elseif {$ifSimpleOne2More} { set termsWhenAdd $fartherGroupSinksPin }
              set cmd [print_ecoCommand -type add -celltype $toAdd -terms $termsWhenAdd -newInstNamePrefix ${newInstNamePrefix}_one2one_[ci one] -loc $refineLocPosition]
              set addTypeFlag [switch $refineLocType { "sufficient" { set tmp "S" } "expandSpace" { set tmp "E" } "forceInsertAfterMove" { set tmp "f" } "forceInsertWithoutMove" { set tmp "F" } "noSpace" { set tmp "N" } } ; set tmp]
              set fixedlist [concat $driverSinksSymbol [string cat $suffixAddFlag $baseAddFlag $addTypeFlag] $toAdd $addedInfoToShow]
              if {$ifOne2One} { set fixed_one_list $fixedlist ; lappend cmd_one_list $cmd } elseif {$ifSimpleOne2More} { 
                set fixed_more_list $fixedlist ; lappend cmd_more_list $cmd ; set detailInfoOfMore_list [gen_info_of_one2more_case $violValue $driverPin $sinksPin $wiresPts $infoToShow] }
              if {$refineLocType in {expandSpace forceInsertAfterMove}} {
                set move_cmd [lmap inst_moveDirectionDistance $refineLocMovementList {
                  lassign $inst_moveDirectionDistance temp_instname temp_moveDirectionDistance
                  lassign $temp_moveDirectionDistance temp_direction temp_distance 
                  set temp_move_cmd [print_ecoCommand -type move -inst $temp_instname -direction $temp_direction -distance $temp_distance]
                }]
                set ifHaveMovements 1
                lappend movement_cmd_list $move_cmd
              } elseif {$refineLocType in {forceInsert noSpace}} {
                set ifNeedNoticeCase 1
                lappend needNoticeCase_list $fixedlist
              }
            }
          } else { 
            # have no this case, cuz it has been filtered when running preCheck: complexMore
          }
        } elseif {!$ifFixedSuccessfully && [expr $netLen < [lindex $crosspointOfChangeCapacityAndInsertBuffer 1]]} { ; # have fastest VT and largest capacity, and it is inside of functionGraph AT001:this var is 1
          set ifCantChange 1
          lappend cantChange_list [concat $driverSinksSymbol "FvtLcap" $addedInfoToShow]
        }
      }
    }
    dict for {infovar infovalue} $allInfo { unset $infovar ; trace remove variable $infovar write onlyReadTrace }
    trace remove variable allInfo write onlyReadTrace
    return [list $resultDict $allInfo]
    #return $resultDict
  }
}

define_proc_arguments sliding_rheostat_of_strategies \
  -info "selector of strategies" \
  -define_args {
    {-violValue "specify the violation value of pin" AFloat float required}
    {-violPin "specify the violation pin" AString string required}
    {-VTweight "specify the VT weight for strategy_changeVT_withLUT proc" AList list optional}
    {-forbiddenVT "specify the VT that is forbidden to use" AList list optional}
    {-driveCapacityRange "specify the range of drive capacity, default: {1 12}" AList list optional}
    {-ifInFixLongNetMode "specify go to Fix Long Net Mode. it will always insert repeater however this viol value of path is small" "" boolean optional}
    {-ifCanChangeVTandCapacityInFixLongNetMode "In Fix Long Net Mode, you can specify this option" "" boolean optional}
    {-ifCanChangeVTWhenChangeCapacity  "trun on/off switch that allow changing VT when changing capacity" "" boolean optional}
    {-ifCanChangeVTcapacityWhenAddRepeater "trun on/off switch that allow changing VT|capacity when adding repeater" "" boolean optional}
    {-newInstNamePrefix "specify the new name for repeater that will be inserted" AString string optional}
    {-promptPrefix "specify the prefix for every type of prompt" AString string optional}  
    {-debug "trun on/off debuging mode that will print more info" "" boolean optional}
  }
