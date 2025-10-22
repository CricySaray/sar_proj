#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/07/13 15:25:05 Sunday
# label     : task_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|misc_proc)
# descrip   : fix trans/longnet/maxCapacitance
# special using: songNOTE: When you want to fix the max capacitance, it is recommended to turn off the three switches: canChangeVT, canChangeDriveCapacity, 
#               and canChangeVtWhenChangeCapacity, which means not allowing only the replacement of vt. When the driving size of your violating 
#               driver is small, you can allow changeDriveCapacity; if it is large, then turn off the changeDriveCapacity switch. Generally, 
#               maxCap issues are all one2more problems, so in most cases, you need to addRepeater. Therefore, just addRepeater is also fine.
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
#       NOTICE: You can use the -honorPowerIntent false command in setEcoMode to prevent the checking of different power domains. This allows buffers to be inserted into 
#               nets across different power domains.
# TODO: 1 v more: calculate lenth between every sinks of driveCell, and classify them to one or more group in order to fix fanout or set ecoAddRepeater -term {... ...}
# TODO: songNOTE: judge mem and ip celltype!!! if driver is mem/ip, it can't fix. if sink is mem/ip, it can fix driver
# TODO: U005: Add a switch to control whether to allow the execution of mandatory insertion of inst operations in the eco script (even when there is insufficient space 
#             after expand space). This switch needs to be added to the cmd_List and written into the ecoScript. You can set this switch in the eco script and determine 
#             whether to allow such mandatory insertion based on specific circumstances.
# TODO: U006 Add a space-constrained mode, try not to introduce new area, so that refinePlace cannot successfully place all insts in appropriate 
#       positions. Meanwhile, when adding a driver, it is also necessary to calculate the width, height, and area of the cell to prevent 
#       replacing cells with excessively large areas.
# --------------------------
#
# songNOTE: DEFENSIVE FIX:
#   if inst is mem/IP, it can't be changed DriveCapacibility and can't move location
#   TODO: get previous fixing summary, and check if it is fixed in new iteration fix!
#   TODO: deal with summary, select violated drivePin, driveInst, sinkPin and sinkInst in invsGUI for convenience return time
#
# fix long net:
#   get drive net len in PT:看看一个buf驱动和他同级的buffer时，不违例的net len最长长度，这个需要大量测试，每个项目都不一样。（脚本处理） tcl在pt里面获取海量原始数据，然后perl来处理和统计。为了给fix long net和fix trans脚本提供判断依据。
#     buf/inv cell | drive net len
# --------
# 01 get info of viol cell: pin cellname celltype driveNum netlength
source ../../../packages/logic_AND_OR.package.tcl; # operators: lo la ol al re eo - return 0|1
source ../../../packages/print_formattedTable.package.tcl; # print_formattedTable D2 list - return 0, puts formated table
source ../../../packages/pw_puts_message_to_file_and_window.package.tcl; # pw - advanced puts
source ./proc_if_driver_or_load.invs.tcl; # if_driver_or_load - 1: driver  0: load
source ./proc_reverseListRange.invs.tcl; # reverseListRange - return reversed list
source ./proc_summarize_all_list_to_display.display.tcl; # summarize_all_list_to_display 
source ./proc_mux_of_strategies.invs.tcl; # mux_of_strategies

# The principle of minimum information
proc fix_trans {args} {
  # default value for all var
  set file_viol_pin                            ""
  set columnDelimiter                          {} ; # will not seperate if is {}. will sepeate or tablize using linux cmd 'column' if is not {} (empty)
  set violValue_pin_columnIndex                {4 1}
  set canChangeVT                              1
  set canChangeDriveCapacity                   1
  set canChangeVtWhenChangeCapacity            1
  set canAddRepeater                           1
  set canChangeVtCapacityWhenAddingRepeater    1
  set maxWidthForString                        80
  set normalNeedVtWeightList                   {{LVT 1} {SVT 3} {HVT 0}}; # normal std cell can use AL9 and AR9, but weight of AR9 is larger
  set forbiddenVT                              {} ; # can be list
  set driveCapacityRange                       {1 12} ; # Please write them in the format where smaller drive numbers come first and larger drive numbers come after.
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
  # Check if the fillers have been deleted first from the invs db. If not, you need to delete the fillers first!
  set coreInnerBoundaryRects [operateLUT -type read -attr core_inner_boundary_rects] 
  set allCoreInstBoxes [dbget top.insts.box]
  set rectsRemovedAllCoreInstsBoxes [dbShape -output area $coreInnerBoundaryRects ANDNOT $allCoreInstBoxes]
  if {!$rectsRemovedAllCoreInstsBoxes} {
    error "proc fix_trans: check your invs db: NEED DELETE FILLER!!! Please check whether the inserted filler has not been deleted!"
  } elseif {$rectsRemovedAllCoreInstsBoxes <= [expr {[dbShape -output area $coreInnerBoundaryRects] * 0.1}]} {
    error "proc fix_trans: check your invs db: now the current core area density is too high, reaching 90%. It is recommended to check \
      if there are any undeleted fillers in the invs db. If it is confirmed to be correct and further fixing is still needed, set the \
      \$ifForceFixWhenHighCoreAreaDensity switch to 1." 
  }
  set sumFile                                 [eo $suffixFilename "sor_summary_of_result_$suffixFilename.list" "sor_summary_of_result.list" ]
  set cantExtractFile                         [eo $suffixFilename "sor_cantExtract_$suffixFilename.list" "sor_cantExtract.list"]
  set cmdFile                                 [eo $suffixFilename "sor_ecocmds_$suffixFilename.tcl" "sor_ecocmds.tcl"]
  set one2moreDetailSinksInfoFile             [eo $suffixFilename "sor_one2moreDetailViolInfo_$suffixFilename.tcl" "sor_one2moreDetailViolInfo.tcl"]
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
      if {$columnDelimiter != {}} { set line [lmap tmpColumn [split $line $columnDelimiter] { if {$tmpColumn == {}} { continue } else { set tmpColumn } }] } ; # remove empty item
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
    set allInfoTableTitle [list violVal netLen ruleLen ifLoop -sub- class driverType driverPin -num- class sinkType sinkPin]
    ## not pass precheck info
    set notPassPreCheckPrompts {
      "# not pass precheck symbols"
      "## D - Dirty | R - ReRoute | S - classNotSupport | X - compleXMore"
    }
    ## changed info
    set fixedPrompts {
      "# symbols of normal methods : all of symbols can combine with each other, which is mix of a lot methods."
      "## T - changedVT, below is toChangeCelltype"
      "## D - changedDriveCapacity, below is toChangeCelltype"
      "## A_09 A_0.9 - near the driver - addedRepeaterCell, below is toAddCelltype"
      "## A_01 A_0.1 - near the sink   - addedRepeaterCell, below is toAddCelltype"
      "## dTL_ : (when add repeater) dTL represents the operation of changing the VT of the driver celltype, where L stands for LVT, d stands for driver celltype, and T stands for change VT. "
      "##        The final underscore '_' is used to separate it from another operation. This symbol will be placed at the very front of the entire symbol, hence the trailing underscore."
      "## dD4_ : (when add repeater) dD4 represents the operation of changing the driveCapacity of the driver celltype, where 4 stands for the drive size of the driver celltype after the "
      "##        change, d stands for driver celltype, and D stands for changeDriveCapacity. The final underscore is used to separate it from another operation. This "
      "##        symbol is generally placed at the beginning or middle of the entire symbol, hence the trailing underscore for separation."
      "## suffix: S - sufficient | E - sufficient with expanding space | f - force insert with movement | F - force insert without movement | N - no space to insert"
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
    set fixed_List [list [list Symbol Methods useCell {*}$allInfoTableTitle]]
    # skipped situation info
    set skippedPrompts {
      "# NF - have no faster vt" 
      "# NL - have no lager drive capacity"
      "# NFL - have no both faster vt and lager drive capacity"
    }
    # fix_but_failed_List info
    set fixButFailedPrompts {
      "# tried to fix the violation case, but failed to do so due to certain reasons."
      "# failedVt         : When replacing the VT, the cell type after replacement is not in libCells.This may be due to an issue with the storage in the lutDict "
      "#                    variable, or it could be that the cell itself does not have all VT types. Alternatively, check the changeVT proc."
      "# failedVtWhenCap  : Same as failedVt."
      "# failedCap        : An error occurred when changing the drive size of the celltype. The celltype after the change does not exist in the current libCells. "
      "#                    Please check the changeDriveCapacity proc."
    }
    # cantChange_List info
    set VTrange [operateLUT -type read -attr {vtrange}] ; # The order of VTs in this variable is arranged from the fastest to the slowest.
    foreach temp_vt $forbiddenVT {
      set VTrange [lsearch -not -all -inline -exact $VTrange $temp_vt]
    }
    if {$VTrange == ""} {
      error "proc get_allInfo_fromPin: check your input: forbiddenVT($forbiddenVT), Currently, the vtrange obtained from lutDict is ([operateLUT -type read -attr vtrange]), \
        and after removing the forbidden VT types specified by the forbiddenVT variable, there are no allowable VT types left, which is not permitted. This will cause subsequent \
        fixing procedures to fail to run correctly."
    }
    dict set allInfo farthestVT [lindex $VTrange 0] 
    set cantChangePrompts {
      "# The violation cases that cannot be fixed already have the maximum allowable drive and the fastest allowable VT type. Meanwhile, "
      "#   the netLength fails to meet the length requirement for inserting a buffer or inverter."
      "# FvtLcap : farthest vt($farthestVT) and largest drive capacity([lindex $driveCapacityRange end])!!!"
    }
    # needNoticeCase_List info
    set needNoticeCasePrompts {
      "# When inserting a repeater, there is not enough space for placement. During the insertion of the repeater, the largest space will be searched based on a 15μm width and "
      "#   height rectangle at the initially determined insertion point (this width and height will change according to input parameters). Then, using this space as a reference, "
      "#   the inst will be moved left and right within the row where this space is located to free up sufficient space."
    }
    set simpleDisplayList [list notPassPreCheck_List fix_but_failed_List skipped_List cantChange_List needNoticeCase_List]
    foreach templist $simpleDisplayList { set $templist [list [list Symbol Type {*}$allInfoTableTitle]] }
    set detailInfoOfMore_List [list [list violValue perSinkLen netLen ruleLen ifLoop driverClass driverType driverPin -numSinks- class sinkType sinkPin]]
    # ------
    # init LIST
    set cmd_reRoute_List [list ] ; set fix_but_failed_List [list ]
    set cmd_List [list]
    lappend cmd_List "" "setEcoMode -reset" "setEcoMode -batchMode true -updateTiming false -refinePlace false -honorDontTouch false -honorDontUse false -honorFixedNetWire false -honorFixedStatus false" ""
    set ifNeedFindSpaceInCoreArea 0
    set fixed_one_List_temp [list] ; set cmd_one_List_temp [list] ; set fixed_more_List_temp [list] ; set cmd_more_List_temp [list]
    foreach case $violValue_driverPin_LIST {
      lassign $case violValue driverPin
      lassign [mux_of_strategies \
        -violValue $violValue \
        -violPin $driverPin \
        -VTweight $normalNeedVtWeightList \
        -newInstNamePrefix $ecoNewInstNamePrefix \
        -ifInFixLongNetMode [expr !$canChangeVT && !$canChangeDriveCapacity] \
        -ifCanChangeVTandCapacityInFixLongNetMode 1 \
        -ifCanChangeVTWhenChangeCapacity $canChangeVtWhenChangeCapacity \
        -ifCanChangeVTcapacityWhenAddRepeater $canChangeVtCapacityWhenAddingRepeater \
        -forbiddenVT $forbiddenVT \
        -driveCapacityRange $driveCapacityRange \
        -ifCanChangeVT $canChangeVT \
        -ifCanAddRepeater $canAddRepeater] resultDict allInfo
      
      proc onlyReadTrace {var_name index operation} { error "proc onlyReadTrace in proc: fix_trans: variable($var_name) is read-only, you can't write it!!!" }
      trace add variable allInfo write onlyReadTrace 
      trace add variable resultDict write onlyReadTrace
      dict for {infovar infovalue} [concat $resultDict $allInfo] { set $infovar $infovalue ; trace add variable $infovar write onlyReadTrace}
      if {$ifAddRepeater} { set ifNeedFindSpaceInCoreArea 1 }
      if {!$ifPassPreCheck} {
        lappend notPassPreCheck_List $notPassPreCheck_list
        if {$ifNeedReRouteNet} { lappend cmd_reRoute_List "# $notPassPreCheck_list" $cmd_reRoute_list }
      } else {
        if {$ifOne2One && $ifFixedSuccessfully} {
          lappend fixed_one_List_temp $fixed_one_list
          lappend cmd_one_List_temp "# $fixed_one_list" {*}$cmd_one_list
        } elseif {$ifSimpleOne2More && $ifFixedSuccessfully} {
          lappend fixed_more_List_temp $fixed_more_list 
          lappend cmd_more_List_temp "# $fixed_more_list" {*}$cmd_more_list
        }
        if {$ifHaveMovements} { lappend [eo $ifOne2One cmd_one_List_temp cmd_more_List_temp] {*}$movement_cmd_list }
        if {$ifFixButFailed} { lappend fix_but_failed_List {*}$fix_but_failed_list }
        if {$ifSkipped} { lappend skipped_List {*}$skipped_list }
        if {$ifCantChange && !$ifFixedSuccessfully} { lappend cantChange_List {*}$cantChange_list }
        if {$ifNeedNoticeCase} { lappend needNoticeCase_List {*}$needNoticeCase_list }
      }
      if {!$ifOne2One} { lappend detailInfoOfMore_List {*}$detailInfoOfMore_list }
      dict for {infovar infovalue} [concat $resultDict $allInfo] { unset $infovar ; trace remove variable $infovar write onlyReadTrace }
      trace remove variable allInfo write onlyReadTrace 
      trace remove variable resultDict write onlyReadTrace
    }
    if {false && $ifNeedFindSpaceInCoreArea} { ; # This checking function is already executed at the very beginning of the `fix_trans` proc, so there is no need to execute it here.
      set coreInnerBoundaryRects [operateLUT -type read -attr core_inner_boundary_rects] 
      set allCoreInstBoxes [dbget top.insts.box]
      set rectsRemovedAllCoreInstsBoxes [dbShape -output area $coreInnerBoundaryRects ANDNOT $allCoreInstBoxes]
      if {!$rectsRemovedAllCoreInstsBoxes} {
        error "proc fix_trans: check your invs db: When addressing a violation case, it is necessary to insert a repeater, but there is no available space for insertion. Please check whether the inserted filler has not been deleted!"
      }
    }
    set fixed_List [concat $fixed_List $fixed_one_List_temp $fixed_more_List_temp]
    set cmd_List [concat $cmd_List $cmd_one_List_temp $cmd_more_List_temp]
    set fixed_List [lsearch -not -regexp -all -inline $fixed_List {^\s*$}]
    set cmd_List [lsearch -not -regexp -all -inline $cmd_List {^\s*$}]
    lappend cmd_List  "" "setEcoMode -reset"
    set ListVarCollection [info locals *_List] ; # try to test
    set PromptsVarCollection [info locals *Prompts]
    set ListVarDict [dict create]
    set titleOfListMap {{{# COMMANDS OF FIXED CASES:} cmd_List} {{## reRoute COMMANDS:} cmd_reRoute_List} {{FIXED CASES LIST:} fixed_List} {{NOT PASS PRECHECK LIST:} notPassPreCheck_List} {{FIX BUT FAILED LIST:} fix_but_failed_List} {{SKIPPED LIST:} skipped_List} {{CAN'T CHANGE LIST:} cantChange_List} {{NEED NOTICE CASE LIST:} needNoticeCase_List} {{DETAIL INFO OF ONE2MORE CASES:} detailInfoOfMore_List}}
    set filesIncludeListMap [subst {{$cmdFile {fixedPrompts cmd_List cmd_reRoute_List}} {$sumFile {notPassPreCheckPrompts notPassPreCheck_List fixedPrompts fixed_List fixButFailedPrompts fix_but_failed_List skippedPrompts skipped_List cantChangePrompts cantChange_List needNoticeCasePrompts needNoticeCase_List}} {$one2moreDetailSinksInfoFile {detailInfoOfMore_List}}}]
    foreach ListVar [concat $ListVarCollection $PromptsVarCollection] { dict set ListVarDict $ListVar [subst \${$ListVar}] }
    set needDumpWindowList {cmd_List fixed_List notPassPreCheck_List fix_but_failed_List skipped_List cantChange_List needNoticeCase_List}
    set needLimitStringWidth {fixed_List notPassPreCheck_List fix_but_failed_List skipped_List cantChange_List needNoticeCase_List}
    set needInsertSequenceNumberColumn {fixed_List notPassPreCheck_List fix_but_failed_List skipped_List cantChange_List needNoticeCase_List}
    set notNeedCountSum [concat [info locals *Prompts] "cmd_List cmd_reRoute_List"]
    set notNeedFormatTableList [concat [info locals *Prompts] "cmd_List cmd_reRoute_List cmd_List cmd_reRoute_List"]
    set notNeedTitleHeader [info locals *Prompts]
    set columnToCountSumMapList {{1 {notPassPreCheck_List fixed_List fix_but_failed_List skipped_List cantChange_List needNoticeCase_List}}}
    set onlyCountTotalNumList {detailInfoOfMore_List fixedPrompts}
    set defaultColumnToCountSum 0
    set maxWidthForString $maxWidthForString
    
    summarize_all_list_to_display \
      -listsDict $ListVarDict \
      -titleOfListMap $titleOfListMap \
      -filesIncludeListMap $filesIncludeListMap \
      -needDumpWindowList $needDumpWindowList \
      -needLimitStringWidth $needLimitStringWidth \
      -needInsertSequenceNumberColumn $needInsertSequenceNumberColumn \
      -notNeedCountSum $notNeedCountSum \
      -notNeedFormatTableList $notNeedFormatTableList \
      -notNeedTitleHeader $notNeedTitleHeader \
      -maxWidthForString $maxWidthForString \
      -columnToCountSumMapList $columnToCountSumMapList \
      -onlyCountTotalNumList $onlyCountTotalNumList \
      -defaultColumnToCountSum $defaultColumnToCountSum
  }
}
define_proc_arguments fix_trans \
  -info "fix transition"\
  -define_args {
    {-file_viol_pin "specify violation filename" AString string required}
    {-columnDelimiter "specify the delimiter of column at file" AString string optional}
    {-violValue_pin_columnIndex "specify the column of violValue and pinname" AList list optional}
    {-canChangeVT "if it use strategy of changing VT" oneOfString one_of_string {optional value_type {values {0 1}}}}
    {-canChangeDriveCapacity "if it use strategy of changing drive capacity" oneOfString one_of_string {optional value_type {values {0 1}}}}
    {-canChangeVtWhenChangeCapacity "if can change vt when changing drive capacity" oneOfString one_of_string {optional value_type {values {0 1}}}}
    {-canAddRepeater "if it use strategy of adding repeater" oneOfString one_of_string {optional value_type {values {0 1}}}}
    {-canChangeVtCapacityWhenAddingRepeater "if can change vt and capacity when adding repeater" oneOfString one_of_string {optional value_type {values {0 1}}}}
    {-maxWidthForString "specify the max width of every string of list" AInteger int optional}
    {-normalNeedVtWeightList "specify normal(std cell need) vt weight list" AList list optional}
    {-forbiddenVT "specify the VT that is forbidden to use" AList list optional}
    {-driveCapacityRange "specify the range of drive capacity, default: {1 12}" AList list optional}
    {-largerThanDriveCapacityOfChangedCelltype "specify drive capacity to meet rule in FIXED U001" AList list optional}
    {-ecoNewInstNamePrefix "specify a new name for inst when adding new repeater" AList list required}
    {-suffixFilename "specify suffix of result filename" AString string optional}
    {-promptPrefix "specify the prefix of prompt" AString string optional}
    {-debug "debug mode" "" boolean optional}
  }
