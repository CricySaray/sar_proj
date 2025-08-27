#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/07/13 15:25:05 Sunday
# label     : task_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|misc_proc)
# descrip   : fix trans
# update    : 2025/07/18 19:51:29 Friday
#           (U001) check if changed cell meet rule that is larger than specified drive capacity(such as X1) at end of fixing looping
#                  if $largerThanDriveCapacityOfChangedCelltype is X1, so drive capacity of needing to ecoChangeCell must be larger than X1
# update    : 2025/07/20 01:43:43 Sunday
#           (U003) fixed logic error: in proc get_driveCapacity_of_celltype, input check part: dbget top.insts.cell.name can only get exist cell of name. 
#           it will return 0x0:1 when you input changed celltype that is not exist in now design. and it will get to checking loop, so result toCelltype 
#           drive capacity be smaller
# update    : 2025/07/21 20:25:25 Monday
#           (U004) fixed summary of situations and methods for one2more violation
#
# TODO: judge powerdomain area and which powerdomain the inst is belong to, get accurate location of toAddRepeater, 
#       to fix IMPOPT-616
#       1) get powerdomains name, 2) get powerdomain area, 3) get powerdomain which the inst is belong to, 4) get location of inst, 5) calculate the loc of toAddRepeater
# TODO: 1 v more: calculate lenth between every sinks of driveCell, and classify them to one or more group in order to fix fanout or set ecoAddRepeater -term {... ...}
# TODO: songNOTE: judge mem and ip celltype!!! if driver is mem/ip, it can't fix. if sink is mem/ip, it can fix driver
# --------------------------
#
# songNOTE: DEFENSIVE FIX:
#   if inst is mem/IP, it can't be changed DriveCapacibility and can't move location
#   TODO: get previous fixing summary, and check if it is fixed in new iteration fix!
#   TODO: deal with summary, select violated drivePin, driveInst, sinkPin and sinkInst in invsGUI for convenience
# return time
#
# fix long net:
#   get drive net len in PT:看看一个buf驱动和他同级的buffer时，不违例的net len最长长度，这个需要大量测试，每个项目都不一样。（脚本处理） tcl在pt里面获取海量原始数据，然后perl来处理和统计。为了给fix long net和fix trans脚本提供判断依据。
#     buf/inv cell | drive net len
# --------
# 01 get info of viol cell: pin cellname celltype driveNum netlength
source ../../../packages/incr_integer_inSelf.package.tcl; # ci(proc counter), don't use array: counters
source ../../../packages/logic_AND_OR.package.tcl; # operators: lo la ol al re eo - return 0|1
source ../../../packages/print_formattedTable.package.tcl; # print_formattedTable D2 list - return 0, puts formated table
source ../../../packages/pw_puts_message_to_file_and_window.package.tcl; # pw - advanced puts
source ./proc_getPt_ofObj.invs.tcl; # gpt - return pt(location) of object
source ./proc_get_net_lenth.invs.tcl; # get_net_length - num
source ./proc_if_driver_or_load.invs.tcl; # if_driver_or_load - 1: driver  0: load
source ./proc_get_fanoutNum_and_inputTermsName_of_pin.invs.tcl; # get_fanoutNum_and_inputTermsName_of_pin - return list [num termsNameList] || get_driverPin - return drivePin
source ./proc_get_cellDriveLevel_and_VTtype_of_inst.invs.tcl; # get_cellDriveLevel_and_VTtype_of_inst - return [instname cellName driveLevel VTtype]
source ./proc_get_cell_class.invs.tcl; # get_cell_class - return logic|buffer|inverter|CLKcell|sequential|gating|other
source ./proc_strategy_changeVT.invs.tcl; # strategy_changeVT - return VT-changed cellname
source ./proc_strategy_addRepeaterCelltype.invs.tcl; # strategy_addRepeaterCelltype - return toAddCelltype
source ./proc_strategy_changeDriveCapacity_of_driveCell.invs.tcl; # strategy_changeDriveCapacity - return toChangeCelltype
source ./proc_print_ecoCommands.invs.tcl; # print_ecoCommand - return command string (only one command)
source ./proc_ifInBoxes.invs.tcl; # ifInBoxes - return 0|1
source ./proc_strategy_clampDriveCapacity_BetweenDriverSink.invs.tcl; # strategy_clampDriveCapacity_BetweenDriverSink - return celltype
source ./proc_calculateResistantCenter_advanced.invs.tcl; # calculateResistantCenter_fromPoints - input pointsList, return center pt
source ./proc_calculateRelativePoint.invs.tcl; # calculateRelativePoint - return relative point
source ./proc_calculateDistance_betweenTwoPoint.invs.tcl; # calculateDistance - return value of distance
source ./proc_findMostFrequentElementOfList.invs.tcl; # findMostFrequentElement - return string
source ./proc_reverseListRange.invs.tcl; # reverseListRange - return reversed list
source ./proc_formatDecimal.invs.tcl; # formatDecimal/fm - return string converted from number
source ./proc_checkRoutingLoop.invs.tcl; # checkRoutingLoop - return number

source ./proc_mux_of_strategies.invs.tcl; # mux_of_strategies

# The principle of minimum information
proc fix_trans {args} {
  # default value for all var
  set file_viol_pin                            ""
  set violValue_pin_columnIndex                {4 1}
  set canChangeVT                              1
  set canChangeDriveCapacity                   1
  set canChangeVTandDriveCapacity              1
  set canAddRepeater                           1
  set unitOfNetLength                          10
  set refBufferCelltype                        "BUFX4AR9"
  set refInverterCelltype                      "INVX4AR9"
  set refCLKBufferCelltype                     "CLKBUFX4AL9"
  set refCLKInverterCelltype                   "CLKINVX4AL9"
  set cellRegExp                               ".*X(\\d+).*(A\[HRL\]\\d+)$"
  set rangeOfVtSpeed                           {AL9 AR9 AH9}
  set clkNeedVtWeightList                      {{AL9 3} {AR9 0} {AH9 0}}; # weight:0 is stand for forbidden using
  set normalNeedVtWeightList                   {{AL9 1} {AR9 3} {AH9 0}}; # normal std cell can use AL9 and AR9, but weight of AR9 is larger
  set specialNeedVtWeightList                  {{AL9 0} {AR9 3} {AH9 0}}; # for checking AH9(HVT), if violated drive inst is HVT, change it. it oftenly is used to change to almost vt like RVT/SVT.
  set rangeOfDriveCapacityForChange            {1 12}
  set rangeOfDriveCapacityForAdd               {3 12}
  set largerThanDriveCapacityOfChangedCelltype 1
  set ecoNewInstNamePrefix                     "sar_fix_trans_clk_071615"
  set suffixFilename                           "" ; # for example : eco4
  set promptPrefix                             "# song"
  set debug                                    0
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  set sumFile                                 [eo $suffixFilename "sor_summary_of_result_$suffixFilename.list" "sor_summary_of_result.list" ]
  set cantExtractFile                         [eo $suffixFilename "sor_cantExtract_$suffixFilename.list" "sor_cantExtract.list"]
  set cmdFile                                 [eo $suffixFilename "sor_ecocmds_$suffixFilename.tcl" "sor_ecocmds.tcl"]
  set one2moreDetailViolInfo                  [eo $suffixFilename "sor_one2moreDetailViolInfo_$suffixFilename.tcl" "sor_one2moreDetailViolInfo.tcl"]
  # songNOTE: only deal with loadPin viol situation, ignore drivePin viol situation
  # $violValue_pin_columnIndex  : for example : {3 1}
  #   violPin   xxx   violValue   xxx   xxx
  #   you can specify column of violValue and violPin
  if {$file_viol_pin == "" || [glob -nocomplain $file_viol_pin] == ""} {
    error "check your input file"; # check your file 
  } else {
    set fi [open $file_viol_pin r]
    set violValue_driverPin_LIST [list ]
    # ------------------------------------
    # sort two class for all viol situations
    set j 0
    while {[gets $fi line] > -1} {
      incr j
      set viol_value [lindex $line [expr [lindex $violValue_pin_columnIndex 0] - 1]]
      set viol_pin   [lindex $line [expr [lindex $violValue_pin_columnIndex 1] - 1]]
      if {![string is double $viol_value] || [dbget top.insts.instTerms.name $viol_pin -e] == ""} {
        error "column([lindex $violValue_pin_columnIndex 0]) is not number, or violPin($viol_pin) can't find"; # column([lindex $violValue_pin_columnIndex 0]) is not number
      }
      if {![if_driver_or_load $viol_pin]} {
        set load_pin $viol_pin 
        set drive_pin [get_driverPin $load_pin]
        lappend violValue_driverPin_LIST [list $viol_value $drive_pin]
      } elseif {[if_driver_or_load $viol_pin]} {
        set drive_pin $viol_pin 
        lappend violValue_driverPin_LIST [list $viol_value $drive_pin]
      } else {
        lappend cantExtractList "(Line $j) pin($pin) is not driver pin or sink pin - not extract! : $line"
      }
    }
    close $fi
    # -----------------------
    # sort and check D3List correction : $violValue_driverPin_LIST
    set violValue_driverPin_LIST [lsort -index 0 -real -decreasing $violValue_driverPin_LIST]
    set violValue_driverPin_LIST [lsort -index 0 -real -decreasing [lsort -unique -index 1 $violValue_driverPin_LIST]]
    if {$debug} { puts [join $violValue_driverPin_LIST \n] }
    # ----------------------
    # info collections
    ## cant change info
    set cantChangePrompts {
      "# error/warning symbols"
      "# changeVT:"
      "## V - the celltype to changeVT is forbidden to use, like {AL9 0} which of weight:0 is forbidden to use"
      "## F - don't have faster VT to change, like celltype is LVT or ULVT, which is no faster VT than LVT or ULVT"
      "# changeDriveCapacity"
      "## O - out of acceptable drive capacity list. if you specify the range of useful drive capacity like $rangeOfDriveCapacityForChange, toChangeCelltype capacity can't be out of it."
      "# addRepeaterCelltype"
      "## N - toAddCelltype is not acceptable celltype from std cell library"
      "# special situation:(need fix by your hand)"
      "## S - violation value is very huge but net length is short"
      "# special inst"
      "## M_D - drive inst is mem"
      "## M_S - sink inst is mem"
    }
    set cantChangeList_1v1 [list [list situation method violVal netLen distance ifLoop driveClass driveCelltype driveViolPin loadClass sinkCelltype loadViolPin]]
    ## changed info
    set fixedPrompts {
      "# symbols of normal methods : all of symbols can combine with each other, which is mix of a lot methods."
      "## T - changedVT, below is toChangeCelltype"
      "## D - changedDriveCapacity, below is toChangeCelltype"
      "## A_09 A_0.9 - near the driver - addedRepeaterCell, below is toAddCelltype"
      "## A_05 A_0.5 - in the middle of driver and sink - addedRepeaterCell, below is toAddCelltype"
      "## A_01 A_0.1 - near the sink   - addedRepeaterCell, below is toAddCelltype"
      "## S - sufficient | f - force insert with movement | F - force insert without movement | N - no space to insert"
      "# special fixed"
      "## FS - fix special situation: change driveCelltype (changeVT and changeDriveCapacity)"
      "## _C - checked driveCapacity of celltype at every end of fixing loop "
      ""
      "# symbol of cell class:"
      "## 'l' - logic class: logic/CLKlogic/delay"
      "## 'b' - buffer class: buffer/inverter/CLKbuffer/CLKinverter"
      "## 's' - sequential class: sequential"
      "## 'e' - mem class: mem"
      "## 'i' - IP class: IP, an ip buffer will be middle between IP and logic at normal situation"
      "## 'p' - IOpad class: IOpad"
      "## 't' - dt - dont touch cell class: dontouch"
      "## 'u' - du - dont use cell class: dontuse"
    }
    set fixedList_one2one [list [list situation method celltypeToFix violVal netLen distance ifLoop driveClass driveCelltype driveViolPin loadClass sinkCelltype loadViolPin]]
    # skipped situation info
    set skippedSituationsPrompt {
      "# NF - have no faster vt" 
      "# NL - have no lager drive capacity"
      "# NFL - have no both faster vt and lager drive capacity"
    }
    set skippedList_one2one [list [list situation method violVal netLen distance ifLoop driveClass driveCelltype driveViolPin loadClass sinkCelltype loadViolPin]]
    set notConsideredPrompt {
      "# NC - not considered situation"
    }
    set notConsideredList_1v1 [list [list situation violVal netLen distance ifLoop driveClass driveCelltype driveViolPin loadClass sinkCelltype loadViolPin]]
    # ------
    # init LIST
    set cmdList $fixedPrompts
    lappend cmdList "setEcoMode -reset"
    lappend cmdList "setEcoMode -batchMode true -updateTiming false -refinePlace false -honorDontTouch false -honorDontUse false -honorFixedNetWire false -honorFixedStatus false"
    lappend cmdList " "

    foreach case $violValue_driverPin_LIST {
      lassign $case violValue driverPin
      lassign [mux_of_strategies -violValue $violValue -violPin $driverPin -VTweight $normalNeedVtWeightList -newInstNamePrefix $ecoNewInstNamePrefix -ifCanChangeVTandCapacityInFixLongNetMode -ifCanChangeVTWhenChangeCapacity -ifCanChangeVTcapacityWhenAddRepeater] resultDict allInfo
      
      proc onlyReadTrace {var_name index operation} { error "proc onlyReadTrace in proc: fix_trans: variable($var_name) is read-only, you can't write it!!!" }
      trace add variable allInfo write onlyReadTrace 
      trace add variable resultDict write onlyReadTrace
      dict for {infovar infovalue} [concat $resultDict $allInfo] { set $infovar $infovalue ; trace add variable $infovar write onlyReadTrace}
      if {!$ifPassPreCheck} {
        if {$ifDirtyCase} { lappend dirtyCase_List $dirtyCase_list ; set precheckFlag_01 "D" } ; # dirty
        if {$ifNeedReRouteNet} { lappend fixed_reRoute_List $fixed_reRoute_list ; set precheckFlag_02 "R" } ; #reRoute
        if {$ifNotSupportCellClass} { lappend nonConsidered_List $nonConsidered_list ; set precheckFlag_03 "S" } ; # classNotSupport
        if {$ifComplexOne2More} { lappend nonConsidered_List $nonConsidered_list ; set precheckFlag_04 "X" } ; # complexMore
      } else {
        if {$ifOne2One} {
           
        }
      }

      dict for {infovar infovalue} [concat $resultDict $allInfo] { unset $infovar ; trace remove variable $infovar write onlyReadTrace }
      trace remove variable allInfo write onlyReadTrace 
      trace remove variable resultDict write onlyReadTrace
    }
    

    # print to window
    ## file that can't extract cuz it is drivePin
    set ce [open $cantExtractFile w]
    set co [open $cmdFile w]
    set sf [open $sumFile w]
    set di [open $one2moreDetailViolInfo w]
    if {1} {
      
      ### can't extract
      if {[info exists cantExtractList]} { 
        puts $ce "CANT EXTRACT:"
        puts $ce ""
        puts $ce [join $cantExtractList \n] 
      } else {
        puts $ce "HAVE NO CANT EXTRACT LIST!!!" 
        puts $ce ""
      }
      if {[regexp {ecoChangeCell|ecoAddRepeater} $cmdList]} {
        ### file of cmds 
        set beginIndexOfOne2MoreCmds [expr [lsearch -exact $cmdList $beginOfOne2MoreCmds] + 2]
        set endIndexOfOne2MoreCmds [expr [lindex [lsearch -exact -all $cmdList "setEcoMode -reset"] end] - 2]
        set reverseOne2MoreCmdFromCmdList [reverseListRange $cmdList $beginIndexOfOne2MoreCmds $endIndexOfOne2MoreCmds 0 0 1 "#"] ; # BUG: have no effect
        pw $co [join $cmdList \n]
      } else {
        pw $co ""
        pw $co "# HAVE NO CMD!!!" 
        pw $co ""
      }
      ### file of summary
      pw $sf "Summary of fixed:"
      pw $sf ""
      pw $sf "FIXED LIST"
      pw $sf [join $fixedPrompts \n]
      pw $sf ""

      ## 1 v 1
      if {[llength $fixedList_one2one] > 1} {
        pw $sf [print_formattedTable $fixedList_one2one]
        pw $sf "total fixed : [expr [llength $fixedList_one2one] - 1]"
        pw $sf ""
        pw $sf "situ  num"
        foreach s $situs { set num [eval set -nonewline \${num_${s}}]; lappend situ_number [list $s $num] }
        pw $sf [print_formattedTable $situ_number]
        pw $sf ""
        pw $sf "method num"
        foreach m $methods { set num [eval set -nonewline \${num_${m}}]; lappend method_number [list $m $num] }
        pw $sf [print_formattedTable $method_number]
        pw $sf ""
      } else {
        pw $sf ""
        pw $sf "# HAVE NO FIXED LIST!!!" 
        pw $sf ""
      }
      if {[llength $cantChangeList_1v1] > 1} {
        pw $sf "CANT CHANGE LIST"
        pw $sf [join $cantChangePrompts \n]
        pw $sf ""
        pw $sf [print_formattedTable $cantChangeList_1v1]
        pw $sf ""
      } else {
        pw $sf ""
        pw $sf "# HAVE NO CANT CHANGE LIST!!!" 
        pw $sf ""
      }
      if {[llength $skippedList_one2one] > 1} {
        pw $sf "SKIPPED LIST"
        pw $sf [join $skippedSituationsPrompt \n]
        pw $sf ""
        pw $sf [print_formattedTable $skippedList_one2one]
        pw $sf ""
      } else {
        pw $sf ""
        pw $sf "# HAVE NO SKIPPED LIST!!!" 
        pw $sf ""
      }
      if {[llength $notConsideredList_1v1] > 1} {
        pw $sf "NOT CONSIDERED LIST"
        pw $sf ""
        pw $sf [join $notConsideredPrompt \n]
        pw $sf ""
        pw $sf [print_formattedTable $notConsideredList_1v1]
        pw $sf "total non-considered [expr [llength $notConsideredList_1v1] - 1]"
      } else {
        pw $sf ""
        pw $sf "# HAVE NO NON-CONSIDERED LIST!!!"
        pw $sf "" 
      }

      ## one 2 more
      ### primarily focus on driver capacity and cell type, if have too many loaders, can fix fanout! (need notice some sticks)
      if {[llength $violValue_drivePin_loadPin_numSinks_sinks_D5List] > 1} {
        if {[llength $fixedList_one2more] > 1} {
          pw $sf ""
          pw $sf "FIXED CELL LIST: ONE 2 MORE"
          pw $sf [join $fixedPrompts_one2more \n]
          pw $sf ""
          if {[llength $fixedList_one2more] >= 2} {
            set reversedFixedList_one2more [reverseListRange $fixedList_one2more 1 end 0]
          } else {
            set reversedFixedList_one2more $fixedList_one2more
          }
          pw $sf [print_formattedTable $reversedFixedList_one2more]
          pw $sf "total fixed : [expr [llength $fixedList_one2more] - 1]"
          pw $sf ""
          pw $sf "situ  num"
          foreach s $m_situs { set num [eval set -nonewline \${m_num_${s}}]; lappend m_situ_number [list $s $num] }
          pw $sf [print_formattedTable $m_situ_number]
          pw $sf ""
          pw $sf "method num"
          foreach m $m_methods { set num [eval set -nonewline \${m_num_${m}}]; lappend m_method_number [list $m $num] }
          pw $sf [print_formattedTable $m_method_number]
          pw $sf ""
        } else {
          pw $sf ""
          pw $sf "# HAVE NO FIXED LIST!!!" 
          pw $sf ""
        }
        if {[llength $cantChangeList_one2more] > 1} {
          pw $sf "CANT CHANGE LIST: ONE 2 MORE"
          pw $sf [join $cantChangePrompts_one2more \n]
          pw $sf ""
          pw $sf [print_formattedTable $cantChangeList_one2more]
          pw $sf ""
        } else {
          pw $sf ""
          pw $sf "# HAVE NO CANT CHANGE LIST!!!"
          pw $sf ""
        }
        if {[llength $skippedList_one2more] > 1} {
          pw $sf "SKIPPED LIST: ONE 2 MORE"
          pw $sf [join $skippedSituationsPrompt_one2more \n]
          pw $sf ""
          pw $sf [print_formattedTable $skippedList_one2more]
          pw $sf ""
        } else {
          pw $sf ""
          pw $sf "# HAVE NO SKIPPED LIST!!!" 
          pw $sf ""
        }
        if {[llength $notConsideredList_one2more] > 1} {
          pw $sf "NOT CONSIDERED LIST: ONE 2 MORE"
          pw $sf ""
          pw $sf [join $notConsideredPrompt_one2more \n]
          pw $sf ""
          pw $sf [print_formattedTable $notConsideredList_one2more]
          pw $sf "total non-considered [expr [llength [lsort -unique -index 5 $notConsideredList_one2more]] - 1]"
          pw $sf ""
        } else {
          pw $sf ""
          pw $sf "# HAVE NO NON-CONSIDERED LIST!!!" 
          pw $sf ""
        }
        if {[llength $one2moreList_diffTypesOfSinks] > 1} {
          pw $sf "DIFF TYPES OF SINKS: ONE 2 MORE"
          pw $sf ""
          pw $sf [print_formattedTable $one2moreList_diffTypesOfSinks]
          pw $sf "total viol drivePin (sorted) with diff types of sinks: [expr [llength [lsort -unique -index 6 $one2moreList_diffTypesOfSinks]] - 1]"
          pw $sf ""
        } else {
          pw $sf ""
          pw $sf "# HAVE NO DIFF-TYPES-Of-SINKS LIST!!!" 
          pw $sf ""
        }
        
        puts $di "ONE to MORE SITUATIONS (different sinks cell class!!! need to improve, i can't fix now)"
        puts $di ""
        puts $di [print_formattedTable $one2moreDetailList_withAllViolSinkPinsInfo]
        puts $di "total of all viol sinks : [expr [llength $one2moreDetailList_withAllViolSinkPinsInfo] - 1]"
        puts $di "total of all viol drivePin (sorted) : [expr [llength [lsort -unique -index 5 $one2moreDetailList_withAllViolSinkPinsInfo]] - 1]"
        puts $di ""

      } else {
        pw $sf "HAVE NO ONE 2 MORE SITUATION!!!" 
      }
      # summary of two situations
      pw $sf ""
      pw $sf "TWO SITUATIONS OF ALL VIOLATIONS:"
      pw $sf "#  --------------------------- #"
      if {[llength $violValue_driverPin_LIST] > 1} {
        pw $sf "1 v 1    number: [llength $violValue_driverPin_LIST]"
      } else {
        pw $sf "have NO 1 v 1 situation!!!" 
      }
      if {[llength $violValue_drivePin_loadPin_numSinks_sinks_D5List] > 1} {
        pw $sf "1 v more number: [llength [lsort -unique -index 1 $violValue_drivePin_loadPin_numSinks_sinks_D5List]]"
      } else {
        pw $sf "have NO one2more situation!!!" 
      }
      pw $sf ""
    }
    close $ce
    close $co
    close $sf
    close $di
  }
}
define_proc_arguments fix_trans \
  -info "fix transition"\
  -define_args {
    {-file_viol_pin "specify violation filename" AString string required}
    {-violValue_pin_columnIndex "specify the column of violValue and pinname" AList list optional}
    {-canChangeVT "if it use strategy of changing VT" "" boolean optional}
    {-canChangeDriveCapacity "if it use strategy of changing drive capacity" "" boolean optional}
    {-canChangeVTandDriveCapacity "if it use strategy of changing VT and drive capacity" "" boolean optional}
    {-canAddRepeater "if it use strategy of adding repeater" "" boolean optional}
    {-unitOfNetLength "sepcify unit of min net length" AFloat float optional}
    {-refBufferCelltype "specify ref buffer cell type name" AString string optional}
    {-refInverterCelltype "specify ref inverter cell type name" AString string optional}
    {-refCLKBufferCelltype "specify ref clk buffer cell type name" AString string optional}
    {-refCLKInverterCelltype "specify ref clk inverter cell type name" AString string optional}
    {-cellRegExp "specify universal regExp for this process celltype, need pick out driveCapacity and VTtype" AString string optional}
    {-rangeOfVtSpeed "specify range of vt speed, it will be different from every process" AList list optional}
    {-clkNeedVtWeightList "specify vt weight list clock-needed" AList list optional}
    {-normalNeedVtWeightList "specify normal(std cell need) vt weight list" AList list optional}
    {-specialNeedVtWeightList "specify special check for VT in violated drive inst" AList list optional}
    {-rangeOfDriveCapacityForChange "specify range of drive capacity for ecoChangeCell" AList list optional}
    {-rangeOfDriveCapacityForAdd "specify range of drive capacity for ecoAddRepeater" AList list optional}
    {-largerThanDriveCapacityOfChangedCelltype "specify drive capacity to meet rule in FIXED U001" AList list optional}
    {-ecoNewInstNamePrefix "specify a new name for inst when adding new repeater" AList list required}
    {-suffixFilename "specify suffix of result filename" AString string optional}
    {-promptPrefix "specify the prefix of prompt" AString string optional}
    {-debug "debug mode" "" boolean optional}
  }
# needn't to set options as below:
#    {-sumFile "specify summary filename" AString string optional}
#    {-cantExtractFile "specify cantExtract file name" AString string optional}
#    {-cmdFile "specify cmd file name" AString string optional}
#    {-one2moreDetailViolInfo "specify one2more detailed viol info, there are all violated sinks pin and other info" AString string optional}

