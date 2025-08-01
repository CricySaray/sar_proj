proc fix_trans {args} {
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
  set cellRegExp                               "X(\\d+).*(A\[HRL\]\\d+)$"
  set rangeOfVtSpeed                           {AL9 AR9 AH9}
  set clkNeedVtWeightList                      {{AL9 3} {AR9 0} {AH9 0}};
  set normalNeedVtWeightList                   {{AL9 1} {AR9 3} {AH9 0}};
  set specialNeedVtWeightList                  {{AL9 0} {AR9 3} {AH9 0}};
  set rangeOfDriveCapacityForChange            {1 12}
  set rangeOfDriveCapacityForAdd               {3 12}
  set largerThanDriveCapacityOfChangedCelltype 1
  set ecoNewInstNamePrefix                     "sar_fix_trans_clk_071615"
  set suffixFilename                           "" ;
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
  if {$file_viol_pin == "" || [glob -nocomplain $file_viol_pin] == ""} {
    error "check your input file";
  } else {
    set fi [open $file_viol_pin r]
    set violValue_driverPin_onylOneLoaderPin_D3List [list ];
    set violValue_drivePin_loadPin_numSinks_sinks_D5List [list ];
    set j 0
    while {[gets $fi line] > -1} {
      incr j
      set viol_value [lindex $line [expr [lindex $violValue_pin_columnIndex 0] - 1]]
      set viol_pin   [lindex $line [expr [lindex $violValue_pin_columnIndex 1] - 1]]
      if {![string is double $viol_value] || [dbget top.insts.instTerms.name $viol_pin -e] == ""} {
        error "column([lindex $violValue_pin_columnIndex 0]) is not number, or violPin($viol_pin) can't find";
      }
      if {![if_driver_or_load $viol_pin]} { ;
        set load_pin $viol_pin
        set drive_pin [get_driverPin $load_pin]
        set num_termName_D2List [get_fanoutNum_and_inputTermsName_of_pin $drive_pin]
        if {[lindex $num_termName_D2List 0] == 1} { ;
          lappend violValue_driverPin_onylOneLoaderPin_D3List [list $viol_value $drive_pin [lindex $num_termName_D2List 1]]
        } elseif {[lindex $num_termName_D2List 0] > 1} { ;
          lappend violValue_drivePin_loadPin_numSinks_sinks_D5List [list $viol_value $drive_pin $load_pin [lindex $num_termName_D2List 0] [lindex $num_termName_D2List 1]]
        }
      } else {
        set drive_pin $viol_pin
        set num_termName_D2List [get_fanoutNum_and_inputTermsName_of_pin $drive_pin]
        if {[lindex $num_termName_D2List 0] == 1} { ;
          lappend violValue_driverPin_onylOneLoaderPin_D3List [list $viol_value $drive_pin [lindex $num_termName_D2List 1]]
        } elseif {[lindex $num_termName_D2List 0] > 1} { ;
          set load_pin [lindex [lindex $num_termName_D2List 1] 0]
          lappend violValue_drivePin_loadPin_numSinks_sinks_D5List [list $viol_value $drive_pin $load_pin [lindex $num_termName_D2List 0] [lindex $num_termName_D2List 1]]
        }
        lappend cantExtractList "(Line $j) drivePin - not extract! : $line"
      }
    }
    close $fi
    set violValue_driverPin_onylOneLoaderPin_D3List [lsort -index 0 -real -decreasing $violValue_driverPin_onylOneLoaderPin_D3List]
    set violValue_driverPin_onylOneLoaderPin_D3List [lsort -index 0 -real -decreasing [lsort -unique -index 1 $violValue_driverPin_onylOneLoaderPin_D3List]]
    set violValue_drivePin_loadPin_numSinks_sinks_D5List [lsort -index 0 -real -decreasing $violValue_drivePin_loadPin_numSinks_sinks_D5List]
    set violValue_drivePin_loadPin_numSinks_sinks_D5List [lsort -index 0 -real -increasing [lsort -unique -index 2 $violValue_drivePin_loadPin_numSinks_sinks_D5List]]
    if {$debug} { puts [join $violValue_driverPin_onylOneLoaderPin_D3List \n] }
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
    set fixedPrompts {
      "# symbols of normal methods : all of symbols can combine with each other, which is mix of a lot methods."
      "## T - changedVT, below is toChangeCelltype"
      "## D - changedDriveCapacity, below is toChangeCelltype"
      "## A_09 A_0.9 - near the driver - addedRepeaterCell, below is toAddCelltype"
      "## A_05 A_0.5 - in the middle of driver and sink - addedRepeaterCell, below is toAddCelltype"
      "## A_01 A_0.1 - near the sink   - addedRepeaterCell, below is toAddCelltype"
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
    set fixedList_1v1 [list [list situation method celltypeToFix violVal netLen distance ifLoop driveClass driveCelltype driveViolPin loadClass sinkCelltype loadViolPin]]
    set skippedSituationsPrompt {
      "# NF - have no faster vt"
      "# NL - have no lager drive capacity"
      "# NFL - have no both faster vt and lager drive capacity"
    }
    set skippedList_1v1 [list [list situation method violVal netLen distance ifLoop driveClass driveCelltype driveViolPin loadClass sinkCelltype loadViolPin]]
    set notConsideredPrompt {
      "# NC - not considered situation"
    }
    set notConsideredList_1v1 [list [list situation violVal netLen distance ifLoop driveClass driveCelltype driveViolPin loadClass sinkCelltype loadViolPin]]
    set cmdList $fixedPrompts
    lappend cmdList "setEcoMode -reset"
    lappend cmdList "setEcoMode -batchMode true -updateTiming false -refinePlace false -honorDontTouch false -honorDontUse false -honorFixedNetWire false -honorFixedStatus false"
    lappend cmdList " "
    foreach viol_driverPin_loadPin $violValue_driverPin_onylOneLoaderPin_D3List {;
      if {$debug} { puts "drive: [get_cell_class [lindex $viol_driverPin_loadPin 1]] load: [get_cell_class [lindex $viol_driverPin_loadPin 2]]" }
      foreach var {violnum driveCellClass loadCellClass netName netLength driveInstname driveInstname_celltype_driveLevel_VTtype driveCelltype driveCapacity sinkInstname sinkInstname_celltype_driveLevel_VTtype sinkCelltype sinkCapacity allInfoList} { set $var "" }
      set violnum [lindex $viol_driverPin_loadPin 0]
      set driveCellClass [get_cell_class [lindex $viol_driverPin_loadPin 1]]
      set loadCellClass  [get_cell_class [lindex $viol_driverPin_loadPin 2]]
      set netName [get_object_name [get_nets -of_objects [lindex $viol_driverPin_loadPin 1]]]
      set netLength [get_net_length $netName] ;
      set driveInstname [dbget [dbget top.insts.instTerms.name [lindex $viol_driverPin_loadPin 1] -p2].name]
      set driveInstname_celltype_driveLevel_VTtype [get_cellDriveLevel_and_VTtype_of_inst $driveInstname $cellRegExp]
      set driveCelltype [lindex $driveInstname_celltype_driveLevel_VTtype 1]
      set driveCapacity [lindex $driveInstname_celltype_driveLevel_VTtype 2]
      set sinkInstname [dbget [dbget top.insts.instTerms.name [lindex $viol_driverPin_loadPin 2] -p2].name]
      set sinkInstname_celltype_driveLevel_VTtype [get_cellDriveLevel_and_VTtype_of_inst $sinkInstname $cellRegExp]
      set sinkCelltype [lindex $sinkInstname_celltype_driveLevel_VTtype 1]
      set sinkCapacity [lindex $sinkInstname_celltype_driveLevel_VTtype 2]
      set drivePt [gpt [lindex $viol_driverPin_loadPin 1]]
      set sinkPt [gpt [lindex $viol_driverPin_loadPin 2]]
      set distanceToSink [format "%.3f" [calculateDistance $drivePt $sinkPt]]
      set resultOfCheckRoutingLoop [checkRoutingLoop $distanceToSink $netLength "normal"]
      set ifLoop [switch $resultOfCheckRoutingLoop {
        0 {set result "noLoop"}
        1 {set result "mild"}
        2 {set result "moderate"}
        3 {set result "severe"}
      }]
      set allInfoList [concat $violnum $netLength $distanceToSink $ifLoop \
                              $driveCellClass $driveCelltype [lindex $viol_driverPin_loadPin 1] \
                              $loadCellClass $sinkCelltype [lindex $viol_driverPin_loadPin 2] ]
      set cmd1 ""
      set toChangeCelltype ""
      set toAddCelltype ""
      if {$driveCellClass == "mem"} {
        lappend cantChangeList_1v1 [concat "in_0" "M_D" $allInfoList]
        set cmd1 "cantChange"
      } elseif {$loadCellClass == "mem"} {
        lappend cantChangeList_1v1 [concat "in_0" "M_S" $allInfoList]
        set cmd1 "cantChange"
      } elseif {$driveCellClass in {delay logic CLKlogic} && $loadCellClass in {delay logic CLKlogic}} { ;
        if {$debug} { puts "$netLength $driveCelltype $sinkCelltype [lindex $viol_driverPin_loadPin 1] [lindex $viol_driverPin_loadPin 2]" }
        set refVTweightList [eo [regexp CLK $driveCellClass] $clkNeedVtWeightList $normalNeedVtWeightList]
        set ifHaveFasterVT [re [la [strategy_changeVT $driveCelltype $refVTweightList $rangeOfVtSpeed $cellRegExp 1] $driveCelltype]]
        if {$debug} {puts "if have faster vt: $ifHaveFasterVT"}
        set ifHaveSlowerVT 0
        set ifHaveLargerCapacity [re [la [strategy_changeDriveCapacity $driveCelltype 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1] $driveCelltype]]
        if {$debug} {puts "if have larger capacity: $ifHaveLargerCapacity"}
        set ifHaveSmallerCapacity 0
        if {!$ifHaveFasterVT && !$ifHaveLargerCapacity} {
          lappend skippedList_1v1 [concat "ll:in_1:1" "NFL" $allInfoList]
        } elseif {!$ifHaveFasterVT} {
          lappend skippedList_1v1 [concat "ll:in_1:2" "NF" $allInfoList]
        } elseif {!$ifHaveLargerCapacity} {
          lappend skippedList_1v1 [concat "ll:in_1:3" "NL" $allInfoList]
        }
        if {$violnum < -0.2 && $netLength < 20 || \
            $violnum < -0.1 && $netLength < 10 || \
            $violnum < -0.07 && $netLength < 8 || \
            $violnum < -0.03 && $netLength < 4 \
              } { ;
          if {[expr $ifHaveFasterVT || $ifHaveLargerCapacity] && [expr $driveCapacity <= 4 || [expr $driveCapacity - $sinkCapacity] < 0]} {
            if {$debug} { puts "------" }
            set toChangeCelltype [eo $ifHaveFasterVT [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1] $driveCelltype]
            if {$debug} { puts "ll:in_1:1 FS changeVT : $toChangeCelltype" }
            set toChangeCelltype [eo $ifHaveLargerCapacity [strategy_changeDriveCapacity $toChangeCelltype 0 [eo [expr $driveCapacity <= 2] 2 1] $rangeOfDriveCapacityForChange $cellRegExp 1] $toChangeCelltype]
            if {$debug} { puts "ll:in_1:1 FS changeDrive : $toChangeCelltype" }
            lappend fixedList_1v1 [concat "ll:in_1:1" "FS" $toChangeCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type change -cell $toChangeCelltype -inst $driveInstname]
          } else {
            lappend cantChangeList_1v1 [concat "ll:in_1:1" "S" $allInfoList]
            set cmd1 "cantChange"
          }
        } elseif {$ifHaveFasterVT && $canChangeVT && [expr $violnum >= -0.006 || \
                   $violnum >= -0.01 && $netLength > [expr $unitOfNetLength  * 15 ] || \
                   $violnum >= -0.02 && $netLength > [expr $unitOfNetLength  * 30 ] \
                   ]} { ;
          if {$debug} { puts "in 1: only change VT" }
          set toChangeCelltype [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          if {[regexp -- {0x0:3} $toChangeCelltype]} { lappend cantChangeList_1v1 [concat "ll:in_2:1" "V" $allInfoList]
            set cmd1 "cantChange"
          } elseif {[regexp -- {0x0:4} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "ll:in_2:2" "F" $allInfoList]
            set cmd1 "cantChange"
          } else {
            lappend fixedList_1v1 [concat "ll:in_2:3" "T" $toChangeCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]
          }
        } elseif {$ifHaveLargerCapacity && $canChangeDriveCapacity && $violnum >= -0.04 && $netLength <= [expr $unitOfNetLength * 1.5]} { ;
          if {$debug} { puts "in 2: only change DriveCapacity" }
          set toChangeCelltype [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          if {$debug} { puts $toChangeCelltype }
          if {$driveCapacity == 0.5} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 3 $rangeOfDriveCapacityForChange $cellRegExp 1]
          } elseif {$driveCapacity in {1 2}} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1]
          } elseif {$driveCapacity >= 3} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 1 $rangeOfDriveCapacityForChange $cellRegExp 1]
          }
          if {[regexp -- {0x0:3} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "ll:in_4:1" "O" $allInfoList]
            set cmd1 "cantChange"
          } else {
            lappend fixedList_1v1 [concat "ll:in_4:2" "D" $toChangeCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]
          }
        } elseif {$ifHaveLargerCapacity && $canChangeVTandDriveCapacity && [expr  $violnum >= -0.05 && $netLength <= [expr $unitOfNetLength * 2.2] ||  $violnum >= -0.11 && $netLength <= [expr $unitOfNetLength * 1.4]]} { ;
          if {$debug} { puts "in 3: change VT and DriveCapacity" }
          set toChangeCelltype [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          if {[regexp -- {0x0:3} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "ll:in_5:1" "V" $allInfoList]
            set cmd1 "cantChange"
          } elseif {[regexp -- {0x0:4} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "ll:in_5:2" "F" $allInfoList]
            set cmd1 "cantChange"
          } else {
            if {$driveCapacity <= 1} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1]
            } elseif {$driveCapacity >= 2} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 1 $rangeOfDriveCapacityForChange $cellRegExp 1]
            }
            if {[regexp -- {0x0:3} $toChangeCelltype]} {
              lappend cantChangeList_1v1 [concat "ll:in_5:3" "O" $allInfoList]
              set cmd1 "cantChange"
            } else {
              lappend fixedList_1v1 [concat "ll:in_5:4" "TD" $toChangeCelltype $allInfoList]
              set cmd1 [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]
            }
          }
        } elseif {$canAddRepeater && $violnum < -0.08  && $violnum >= -0.1 && $netLength < [expr $unitOfNetLength * 4] && $netLength > [expr $unitOfNetLength * 2]} { ;
          if {$debug} { puts "in 4: add Repeater" }
          set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $loadCellClass]] $refCLKBufferCelltype $refBufferCelltype]
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 2 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ;
          set toChangeCelltype [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1]
            if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
            set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname];
            lappend fixedList_1v1 [concat "ll:in_6:2" "DA_09" ${toChangeCelltype}_$toAddCelltype $allInfoList]
            set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
            set cmd1 [list $cmd_DA_driveInst $cmd_DA_add]
          } else {
            lappend fixedList_1v1 [concat "ll:in_6:4" "A_09" $toAddCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
          }
        } elseif {$canAddRepeater && $violnum < -0.12 && $netLength > [expr $unitOfNetLength * 9]} { ;
          if {$debug} { puts "in 5: add Repeater refDriver, uncertainly, conservative" }
          if {$debug} { puts "Not in above situation, so NOTICE" }
          set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $loadCellClass]] $refCLKBufferCelltype $refBufferCelltype]
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 4 $rangeOfDriveCapacityForAdd 1 $refCelltype $cellRegExp ];
          set toChangeCelltype [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 8 0 $rangeOfDriveCapacityForChange $cellRegExp 1]
            if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
            set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname];
            lappend fixedList_1v1 [concat "ll:in_7:2" "DA_09" ${toChangeCelltype}_$toAddCelltype $allInfoList]
            if {$debug} {puts "test : ll:in_7:2"}
            set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
            set cmd1 [list $cmd_DA_driveInst $cmd_DA_add]
          } else {
            if {$ifHaveFasterVT} {
              set cmd_TA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]
              lappend fixedList_1v1 [concat "ll:in_7:3" "TA_09" $toAddCelltype $allInfoList]
              set cmd_TA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
              set cmd1 [concat $cmd_TA_driveInst $cmd_TA_add]
            } else {
              lappend fixedList_1v1 [concat "ll:in_7:4" "A_09" $toAddCelltype $allInfoList]
              set cmd1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
            }
          }
        } elseif {$canAddRepeater && $violnum < -0.04 && $violnum > -0.1 && $netLength < [expr $unitOfNetLength * 1]} {;
          set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $loadCellClass]] $refCLKBufferCelltype $refBufferCelltype]
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 2 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ;
          set toChangeCelltype [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 8 0 $rangeOfDriveCapacityForChange $cellRegExp 1] ;
            if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
            set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname];
            lappend fixedList_1v1 [concat "ll:in_6:2" "DA_09" ${toChangeCelltype}_$toAddCelltype $allInfoList]
            set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
            set cmd1 [list $cmd_DA_driveInst $cmd_DA_add]
          } else {
            lappend fixedList_1v1 [concat "ll:in_6:4" "A_09" $toAddCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
          }
        } else { ;
          if {$debug} { puts "in 5: add Repeater refDriver, uncertainly, conservative" }
          if {$debug} { puts "Not in above situation, so NOTICE" }
          set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $loadCellClass]] $refCLKBufferCelltype $refBufferCelltype]
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 2 $rangeOfDriveCapacityForAdd 1 $refCelltype $cellRegExp ];
          set toChangeCelltype [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1]
            if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
            set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname];
            lappend fixedList_1v1 [concat "ll:in_8:2" "DA_09" ${toChangeCelltype}_$toAddCelltype $allInfoList]
            if {$debug} {puts "test : ll:in_8:2"}
            set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
            set cmd1 [list $cmd_DA_driveInst $cmd_DA_add]
          } else {
            lappend fixedList_1v1 [concat "ll:in_8:4" "A_09" $toAddCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
          }
        }
      } elseif {$driveCellClass in {delay logic CLKlogic} && $loadCellClass in {buffer inverter CLKbuffer CLKinverter}} { ;
        if {$debug} { puts "$netLength $driveCelltype $sinkCelltype [lindex $viol_driverPin_loadPin 1] [lindex $viol_driverPin_loadPin 2]" }
        set refVTweightList [eo [regexp CLK $driveCellClass] $clkNeedVtWeightList $normalNeedVtWeightList]
        set ifHaveFasterVT [re [la [strategy_changeVT $driveCelltype $refVTweightList $rangeOfVtSpeed $cellRegExp 1] $driveCelltype]]
        if {$debug} {puts "if have faster vt: $ifHaveFasterVT"}
        set ifHaveSlowerVT 0
        set ifHaveLargerCapacity [re [la [strategy_changeDriveCapacity $driveCelltype 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1] $driveCelltype]]
        if {$debug} {puts "if have larger capacity: $ifHaveLargerCapacity"}
        set ifHaveSmallerCapacity 0
        if {!$ifHaveFasterVT && !$ifHaveLargerCapacity} {
          lappend skippedList_1v1 [concat "lb:in_1:1" "NFL" $allInfoList]
        } elseif {!$ifHaveFasterVT} {
          lappend skippedList_1v1 [concat "lb:in_1:2" "NF" $allInfoList]
        } elseif {!$ifHaveLargerCapacity} {
          lappend skippedList_1v1 [concat "lb:in_1:3" "NL" $allInfoList]
        }
        if {$violnum < -0.2 && $netLength < 20 || \
            $violnum < -0.1 && $netLength < 10 || \
            $violnum < -0.07 && $netLength < 8 || \
            $violnum < -0.03 && $netLength < 4 \
            } { ;
          if {[expr $ifHaveFasterVT || $ifHaveLargerCapacity] && [expr $driveCapacity <= 6 || [expr  $driveCapacity - $sinkCapacity] < 2]} {
            set leftStair [eo [expr $driveCapacity <= 1 && [expr $driveCapacity - $sinkCapacity] <= -5] 4 3]
            set rightStair [eo [expr $driveCapacity <= 1 && [expr $driveCapacity - $sinkCapacity] <= -5] 3 2]
            set leftStair [eo [expr $driveCapacity < 1 && [expr $driveCapacity - $sinkCapacity] <= -10] 5 $leftStair]
            set rightStair [eo [expr $driveCapacity < 1 && [expr $driveCapacity - $sinkCapacity] <= -10] 4 $rightStair]
            if {$debug} { puts "----------------" }
            if {$debug} { puts "driveCapacity: $driveCapacity  | sinkCapacity: $sinkCapacity" }
            if {$debug} { puts "left: $leftStair  right: $rightStair" }
            set toChangeCelltype [eo $ifHaveFasterVT [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1] $driveCelltype]
            set toChangeCelltype [eo $ifHaveLargerCapacity [strategy_changeDriveCapacity $toChangeCelltype 0 [eo [expr $driveCapacity <= 2] $leftStair $rightStair] $rangeOfDriveCapacityForChange $cellRegExp 1] $toChangeCelltype]
            lappend fixedList_1v1 [concat "lb:in_1:1" "FS" $toChangeCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type change -cell $toChangeCelltype -inst $driveInstname]
          } else {
            lappend cantChangeList_1v1 [concat "lb:in_1:1" "S" $allInfoList]
            set cmd1 "cantChange"
          }
        } elseif {$ifHaveFasterVT && $canChangeVT && $violnum >= -0.005} { ;
          if {$debug} { puts "in 1: only change VT" }
          set toChangeCelltype [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          if {[regexp -- {0x0:3} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "lb:in_2:1" "V" $allInfoList]
            set cmd1 "cantChange"
          } elseif {[regexp -- {0x0:4} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "lb:in_2:2" "F" $allInfoList]
            set cmd1 "cantChange"
          } else {
            lappend fixedList_1v1 [concat "lb:in_2:3" "T" $toChangeCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]
          }
        } elseif {$ifHaveLargerCapacity && $canChangeDriveCapacity && $violnum >= -0.015 && $netLength <= [expr $unitOfNetLength * 1.1]} { ;
          if {$debug} { puts "in 2: only change DriveCapacity" }
          set toChangeCelltype [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          if {$debug} { puts $toChangeCelltype }
          if {$driveCapacity == 0.5} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 3 $rangeOfDriveCapacityForChange $cellRegExp 1]
          } elseif {$driveCapacity in {1 2}} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1]
          } elseif {$driveCapacity >= 3} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 1 $rangeOfDriveCapacityForChange $cellRegExp 1]
          }
          if {[regexp -- {0x0:3} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "lb:in_4:1" "O" $allInfoList]
            set cmd1 "cantChange"
          } else {
            lappend fixedList_1v1 [concat "lb:in_4:2" "D" $toChangeCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]
          }
        } elseif {$ifHaveLargerCapacity && $canChangeVTandDriveCapacity && $violnum >= -0.04 && $netLength <= [expr $unitOfNetLength * 1.8]} { ;
          if {$debug} { puts "in 3: change VT and DriveCapacity" }
          set toChangeCelltype [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          if {[regexp -- {0x0:3} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "lb:in_5:1" "V" $allInfoList]
            set cmd1 "cantChange"
          } elseif {[regexp -- {0x0:4} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "lb:in_5:2" "F" $allInfoList]
            set cmd1 "cantChange"
          } else {
            if {$driveCapacity <= 1} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1]
            } elseif {$driveCapacity >= 2} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 1 $rangeOfDriveCapacityForChange $cellRegExp 1]
            }
            if {[regexp -- {0x0:3} $toChangeCelltype]} {
              lappend cantChangeList_1v1 [concat "lb:in_5:3" "O" $allInfoList]
              set cmd1 "cantChange"
            } else {
              lappend fixedList_1v1 [concat "lb:in_5:4" "TD" $toChangeCelltype $allInfoList]
              set cmd1 [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]
            }
          }
        } elseif {$canAddRepeater && $violnum >= -0.12 && $netLength < [expr $unitOfNetLength * 5] && $netLength > [expr $unitOfNetLength * 1]} { ;
          if {$debug} { puts "in 4: add Repeater" }
          set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $loadCellClass]] $refCLKBufferCelltype $refBufferCelltype]
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 3 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ;
          set toChangeCelltype [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1]
            if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
            set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname];
            lappend fixedList_1v1 [concat "lb:in_6:2" "DA_09" ${toChangeCelltype}_$toAddCelltype $allInfoList]
            set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
            set cmd1 [list $cmd_DA_driveInst $cmd_DA_add]
          } else {
            lappend fixedList_1v1 [concat "lb:in_6:4" "A_09" $toAddCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
          }
        } elseif {$canAddRepeater && $violnum < -0.18 && $netLength > [expr $unitOfNetLength * 4]} { ;
          set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $loadCellClass]] $refCLKBufferCelltype $refBufferCelltype]
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 4 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ;
          set toChangeCelltype [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1]
            if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
            set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname];
            lappend fixedList_1v1 [concat "lb:in_7:2" "DAA_0509" ${toChangeCelltype}_$toAddCelltype $allInfoList]
            set cmd_DA_add1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
            set cmd_DA_add2 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
            set cmd1 [list $cmd_DA_driveInst $cmd_DA_add1 $cmd_DA_add2]
          } else {
            lappend fixedList_1v1 [concat "lb:in_7:4" "AA_0509" $toAddCelltype $allInfoList]
            set cmd_AA_add1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
            set cmd_AA_add2 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
            set cmd1 [concat $cmd_AA_add1 $cmd_AA_add2]
          }
        } elseif {$canAddRepeater && $violnum < -0.22 && $netLength > [expr $unitOfNetLength * 4]} { ;
          if {$debug} { puts "in 5: add Repeater refDriver, uncertainly, conservative" }
          if {$debug} { puts "Not in above situation, so NOTICE" }
          set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $loadCellClass]] $refCLKBufferCelltype $refBufferCelltype]
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 4 $rangeOfDriveCapacityForAdd 1 $refCelltype $cellRegExp ];
          set toChangeCelltype [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          if {$driveCapacity < 8 && $ifHaveLargerCapacity} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 6 0 $rangeOfDriveCapacityForChange $cellRegExp 1]
            if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
            set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname];
            lappend fixedList_1v1 [concat "lb:in_8:2" "DAA_0509" ${toChangeCelltype}_$toAddCelltype $allInfoList]
            if {$debug} {puts "test : lb:in_8:2"}
            set cmd_DA_add1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
            set cmd_DA_add2 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
            set cmd1 [list $cmd_DA_driveInst $cmd_DA_add1 $cmd_DA_add2]
            if {$debug} {puts $cmd1}
          } else {
            lappend fixedList_1v1 [concat "lb:in_8:4" "AA_0509" $toAddCelltype $allInfoList]
            set cmd_AA_add1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
            set cmd_AA_add2 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
            set cmd1 [concat $cmd_AA_add1 $cmd_AA_add2]
          }
        } elseif {$canAddRepeater && \
                              [expr $violnum > -0.2 && $netLength < [expr $unitOfNetLength * 4] && $netLength > [expr $unitOfNetLength * 1.5] || \
                                    $violnum > -0.4 && $netLength < [expr $unitOfNetLength * 6] && $netLength > [expr $unitOfNetLength * 2]]} {
          set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $loadCellClass]] $refCLKBufferCelltype $refBufferCelltype]
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 3 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ;
          set toChangeCelltype [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1]
            if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
            set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname];
            lappend fixedList_1v1 [concat "lb:in_9:2" "DA_09" ${toChangeCelltype}_$toAddCelltype $allInfoList]
            set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
            set cmd1 [list $cmd_DA_driveInst $cmd_DA_add]
          } else {
            lappend fixedList_1v1 [concat "lb:in_9:4" "A_09" $toAddCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
          }
        } else {
          set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $loadCellClass]] $refCLKBufferCelltype $refBufferCelltype]
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 3 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ;
          set toChangeCelltype [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1]
            if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
            set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname];
            lappend fixedList_1v1 [concat "lb:in_0:2" "DA_09" ${toChangeCelltype}_$toAddCelltype $allInfoList]
            set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
            set cmd1 [list $cmd_DA_driveInst $cmd_DA_add]
          } else {
            lappend fixedList_1v1 [concat "lb:in_0:4" "A_09" $toAddCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
          }
        }
      } elseif {$driveCellClass in {buffer inverter CLKbuffer CLKinverter} && $loadCellClass in {delay logic CLKlogic}} { ;
        if {$debug} { puts "$netLength $driveCelltype $sinkCelltype [lindex $viol_driverPin_loadPin 1] [lindex $viol_driverPin_loadPin 2]" }
        set refVTweightList [eo [regexp CLK $driveCellClass] $clkNeedVtWeightList $normalNeedVtWeightList]
        set ifHaveFasterVT [re [la [strategy_changeVT $driveCelltype $refVTweightList $rangeOfVtSpeed $cellRegExp 1] $driveCelltype]]
        if {$debug} {puts "if have faster vt: $ifHaveFasterVT"}
        set ifHaveSlowerVT 0
        set ifHaveLargerCapacity [re [la [strategy_changeDriveCapacity $driveCelltype 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1] $driveCelltype]]
        if {$debug} {puts "if have larger capacity: $ifHaveLargerCapacity"}
        set ifHaveSmallerCapacity 0
        if {!$ifHaveFasterVT && !$ifHaveLargerCapacity} {
          lappend skippedList_1v1 [concat "bl:in_1:1" "NFL" $allInfoList]
        } elseif {!$ifHaveFasterVT} {
          lappend skippedList_1v1 [concat "bl:in_1:2" "NF" $allInfoList]
        } elseif {!$ifHaveLargerCapacity} {
          lappend skippedList_1v1 [concat "bl:in_1:3" "NL" $allInfoList]
        }
        if {$violnum < -0.2 && $netLength < 20 || \
            $violnum < -0.1 && $netLength < 10 || \
            $violnum < -0.07 && $netLength < 8 || \
            $violnum < -0.03 && $netLength < 4 \
            } { ;
          if {[expr $ifHaveFasterVT || $ifHaveLargerCapacity] && [expr $driveCapacity <= 4 || [expr  $driveCapacity - $sinkCapacity] < 0]} {
            set toChangeCelltype [eo $ifHaveFasterVT [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1] $driveCelltype]
            set toChangeCelltype [eo $ifHaveLargerCapacity [strategy_changeDriveCapacity $toChangeCelltype 0 [eo [expr $driveCapacity <= 3] 2 1] $rangeOfDriveCapacityForChange $cellRegExp 1] $toChangeCelltype]
            lappend fixedList_1v1 [concat "bl:in_1:1" "FS" $toChangeCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type change -cell $toChangeCelltype -inst $driveInstname]
          } else {
            lappend cantChangeList_1v1 [concat "bl:in_1:1" "S" $allInfoList]
            set cmd1 "cantChange"
          }
        } elseif {$ifHaveFasterVT && $canChangeVT && [expr $violnum >= -0.02 || \
                   $violnum >= -0.01 && $netLength > [expr $unitOfNetLength  * 15 ] || \
                   $violnum >= -0.02 && $netLength > [expr $unitOfNetLength  * 30 ] \
                   ]} { ;
          if {$debug} { puts "in 1: only change VT" }
          set toChangeCelltype [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          if {[regexp -- {0x0:3} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "bl:in_2:1" "V" $allInfoList]
            set cmd1 "cantChange"
          } elseif {[regexp -- {0x0:4} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "bl:in_2:2" "F" $allInfoList]
            set cmd1 "cantChange"
          } else {
            lappend fixedList_1v1 [concat "bl:in_2:3" "T" $toChangeCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]
          }
        } elseif {$ifHaveLargerCapacity && $canChangeDriveCapacity && $violnum >= -0.04 && $netLength <= [expr $unitOfNetLength * 2.1]} { ;
          if {$debug} { puts "in 2: only change DriveCapacity" }
          set toChangeCelltype [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          if {$debug} { puts $toChangeCelltype }
          if {$driveCapacity in {0.5 1 2}} { ;
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 1 $rangeOfDriveCapacityForChange $cellRegExp 1]
          } elseif {$driveCapacity >= 3} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 1 $rangeOfDriveCapacityForChange $cellRegExp 1]
          }
          if {[regexp -- {0x0:3} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "bl:in_4:1" "O" $allInfoList]
            set cmd1 "cantChange"
          } else {
            lappend fixedList_1v1 [concat "bl:in_4:2" "D" $toChangeCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]
          }
        } elseif {$ifHaveLargerCapacity && $canChangeVTandDriveCapacity && $violnum >= -0.06 && $netLength <= [expr $unitOfNetLength * 2.5]} { ;
          if {$debug} { puts "in 3: change VT and DriveCapacity" }
          set toChangeCelltype [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          if {[regexp -- {0x0:3} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "bl:in_5:1" "V" $allInfoList]
            set cmd1 "cantChange"
          } elseif {[regexp -- {0x0:4} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "bl:in_5:2" "F" $allInfoList]
            set cmd1 "cantChange"
          } else {
            if {$driveCapacity <= 1} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1]
            } elseif {$driveCapacity >= 2} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 1 $rangeOfDriveCapacityForChange $cellRegExp 1]
            }
            if {[regexp -- {0x0:3} $toChangeCelltype]} {
              lappend cantChangeList_1v1 [concat "bl:in_5:3" "O" $allInfoList]
              set cmd1 "cantChange"
            } else {
              lappend fixedList_1v1 [concat "bl:in_5:4" "TD" $toChangeCelltype $allInfoList]
              set cmd1 [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]
            }
          }
        } elseif {$canAddRepeater && $violnum < -0.06  && $violnum >= -0.1 && $netLength < [expr $unitOfNetLength * 4] && $netLength > [expr $unitOfNetLength * 2]} { ;
          if {$debug} { puts "in 4: add Repeater" }
          set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $loadCellClass]] $refCLKBufferCelltype $refBufferCelltype]
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 4 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ;
          set toChangeCelltype [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1]
            if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
            set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname];
            lappend fixedList_1v1 [concat "bl:in_6:2" "DA_05" ${toChangeCelltype}_$toAddCelltype $allInfoList]
            set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
            set cmd1 [list $cmd_DA_driveInst $cmd_DA_add]
          } else {
            lappend fixedList_1v1 [concat "bl:in_6:4" "A_05" $toAddCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
          }
        } else { ;
          if {$debug} { puts "in 5: add Repeater refDriver, uncertainly, conservative" }
          if {$debug} { puts "Not in above situation, so NOTICE" }
          set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $loadCellClass]] $refCLKBufferCelltype $refBufferCelltype]
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 3 $rangeOfDriveCapacityForAdd 1 $refCelltype $cellRegExp ];
          set toChangeCelltype [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1]
            if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
            set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname];
            lappend fixedList_1v1 [concat "bl:in_7:2" "DA_05" ${toChangeCelltype}_$toAddCelltype $allInfoList]
            set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
            set cmd1 [list $cmd_DA_driveInst $cmd_DA_add]
          } else {
            lappend fixedList_1v1 [concat "bl:in_7:4" "A_05" $toAddCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
          }
        }
      } elseif {$driveCellClass in {CLKbuffer CLKinverter buffer inverter} && $loadCellClass in {CLKbuffer CLKinverter buffer inverter}} { ;
        if {$debug} { puts "$netLength $driveCelltype $sinkCelltype [lindex $viol_driverPin_loadPin 1] [lindex $viol_driverPin_loadPin 2]" }
        set refVTweightList [eo [regexp CLK $driveCellClass] $clkNeedVtWeightList $normalNeedVtWeightList]
        set ifHaveFasterVT [re [la [strategy_changeVT $driveCelltype $refVTweightList $rangeOfVtSpeed $cellRegExp 1] $driveCelltype]]
        if {$debug} {puts "if have faster vt: $ifHaveFasterVT"}
        set ifHaveSlowerVT 0
        set ifHaveLargerCapacity [re [la [strategy_changeDriveCapacity $driveCelltype 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1] $driveCelltype]]
        if {$debug} {puts "if have larger capacity: $ifHaveLargerCapacity"}
        set ifHaveSmallerCapacity 0
        if {!$ifHaveFasterVT && !$ifHaveLargerCapacity} {
          lappend skippedList_1v1 [concat "bb:in_1:1" "NFL" $allInfoList]
        } elseif {!$ifHaveFasterVT} {
          lappend skippedList_1v1 [concat "bb:in_1:2" "NF" $allInfoList]
        } elseif {!$ifHaveLargerCapacity} {
          lappend skippedList_1v1 [concat "bb:in_1:3" "NL" $allInfoList]
        }
        if {$violnum < -0.2 && $netLength < 20 || \
            $violnum < -0.1 && $netLength < 10 || \
            $violnum < -0.07 && $netLength < 8 || \
            $violnum < -0.03 && $netLength < 4 \
            } { ;
          if {[expr $ifHaveFasterVT || $ifHaveLargerCapacity] && [expr $driveCapacity < 4 || [expr  $driveCapacity - $sinkCapacity] < 0]} {
            set toChangeCelltype [eo $ifHaveFasterVT [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1] $driveCelltype]
            set toChangeCelltype [eo $ifHaveLargerCapacity [strategy_changeDriveCapacity $toChangeCelltype 0 [eo [expr $driveCapacity <= 4] 2 1] $rangeOfDriveCapacityForChange $cellRegExp 1] $toChangeCelltype]
            lappend fixedList_1v1 [concat "bb:in_1:1" "FS" $toChangeCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type change -cell $toChangeCelltype -inst $driveInstname]
          } else {
            lappend cantChangeList_1v1 [concat "bb:in_1:1" "S" $allInfoList]
            set cmd1 "cantChange"
          }
        } elseif {$ifHaveFasterVT && $canChangeVT && [expr $violnum >= -0.015 || \
           $violnum >= -0.02 && $netLength >= [expr $unitOfNetLength * 20]  || \
           $violnum >= -0.03 && $netLength >= [expr $unitOfNetLength * 30] \
          ] } { ;
          if {$debug} { puts "in 1: only change VT" }
          set toChangeCelltype [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          if {[regexp -- {0x0:3} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "bb:in_2:1" "V" $allInfoList]
            set cmd1 "cantChange"
          } elseif {[regexp -- {0x0:4} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "bb:in_2:2" "F" $allInfoList]
            set cmd1 "cantChange"
          } else {
            lappend fixedList_1v1 [concat "bb:in_2:3" "T" $toChangeCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]
          }
        } elseif {$ifHaveLargerCapacity && $canChangeDriveCapacity && $violnum >= -0.04 && $netLength <= [expr $unitOfNetLength * 1.5]} { ;
          if {$debug} { puts "in 2: only change DriveCapacity" }
          set toChangeCelltype [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          if {$debug} { puts $toChangeCelltype }
          if {$driveCapacity in {0.5 1 2}} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1]
          } elseif {$driveCapacity >= 3} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 1 $rangeOfDriveCapacityForChange $cellRegExp 1]
          }
          if {[regexp -- {0x0:3} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "bb:in_4:1" "O" $allInfoList]
            set cmd1 "cantChange"
          } else {
            lappend fixedList_1v1 [concat "bb:in_4:2" "D" $toChangeCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]
          }
        } elseif {$ifHaveLargerCapacity && $canChangeVTandDriveCapacity && $violnum >= -0.07 && $netLength <= [expr $unitOfNetLength * 2.2]} { ;
          if {$debug} { puts "in 3: change VT and DriveCapacity" }
          set toChangeCelltype [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          if {[regexp -- {0x0:3} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "bb:in_5:1" "V" $allInfoList]
            set cmd1 "cantChange"
          } elseif {[regexp -- {0x0:4} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "bb:in_5:2" "F" $allInfoList]
            set cmd1 "cantChange"
          } else {
            if {$driveCapacity <= 1} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1]
            } elseif {$driveCapacity >= 2} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 1 $rangeOfDriveCapacityForChange $cellRegExp 1]
            }
            if {[regexp -- {0x0:3} $toChangeCelltype]} {
              lappend cantChangeList_1v1 [concat "bb:in_5:3" "O" $allInfoList]
              set cmd1 "cantChange"
            } else {
              lappend fixedList_1v1 [concat "bb:in_5:4" "TD" $toChangeCelltype $allInfoList]
              set cmd1 [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]
            }
          }
        } elseif {$canAddRepeater && $violnum < -0.08  && $violnum >= -0.1 && $netLength < [expr $unitOfNetLength * 4] && $netLength > [expr $unitOfNetLength * 2]} { ;
          if {$debug} { puts "in 4: add Repeater" }
          set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $loadCellClass]] $refCLKBufferCelltype $refBufferCelltype]
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 4 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ;
          set toChangeCelltype [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1]
            if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
            set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname];
            lappend fixedList_1v1 [concat "bb:in_6:2" "DA_05" ${toChangeCelltype}_$toAddCelltype $allInfoList]
            set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
            set cmd1 [list $cmd_DA_driveInst $cmd_DA_add]
          } else {
            lappend fixedList_1v1 [concat "bb:in_6:4" "A_05" $toAddCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
          }
        } else { ;
          if {$debug} { puts "in 5: add Repeater refDriver, uncertainly, conservative" }
          if {$debug} { puts "Not in above situation, so NOTICE" }
          set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $loadCellClass]] $refCLKBufferCelltype $refBufferCelltype]
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 3 $rangeOfDriveCapacityForAdd 1 $refCelltype $cellRegExp ];
          set toChangeCelltype [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1]
            if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
            set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname];
            lappend fixedList_1v1 [concat "bb:in_7:2" "DA_05" ${toChangeCelltype}_$toAddCelltype $allInfoList]
            set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
            set cmd1 [list $cmd_DA_driveInst $cmd_DA_add]
          } else {
            lappend fixedList_1v1 [concat "bb:in_7:4" "A_05" $toAddCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
          }
        }
      } elseif {$driveCellClass in {delay logic CLKlogic} && $loadCellClass in {sequential}} {
        if {$debug} { puts "$netLength $driveCelltype $sinkCelltype [lindex $viol_driverPin_loadPin 1] [lindex $viol_driverPin_loadPin 2]" }
        set refVTweightList [eo [regexp CLK $driveCellClass] $clkNeedVtWeightList $normalNeedVtWeightList]
        set ifHaveFasterVT [re [la [strategy_changeVT $driveCelltype $refVTweightList $rangeOfVtSpeed $cellRegExp 1] $driveCelltype]]
        if {$debug} {puts "if have faster vt: $ifHaveFasterVT"}
        set ifHaveSlowerVT 0
        set ifHaveLargerCapacity [re [la [strategy_changeDriveCapacity $driveCelltype 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1] $driveCelltype]]
        if {$debug} {puts "if have larger capacity: $ifHaveLargerCapacity"}
        set ifHaveSmallerCapacity 0
        if {!$ifHaveFasterVT && !$ifHaveLargerCapacity} {
          lappend skippedList_1v1 [concat "ls:in_1:1" "NFL" $allInfoList]
        } elseif {!$ifHaveFasterVT} {
          lappend skippedList_1v1 [concat "ls:in_1:2" "NF" $allInfoList]
        } elseif {!$ifHaveLargerCapacity} {
          lappend skippedList_1v1 [concat "ls:in_1:3" "NL" $allInfoList]
        }
        if {$violnum < -0.2 && $netLength < 20 || \
            $violnum < -0.1 && $netLength < 10 || \
            $violnum < -0.07 && $netLength < 8 || \
            $violnum < -0.03 && $netLength < 4 \
            } { ;
          if {[expr $ifHaveFasterVT || $ifHaveLargerCapacity] && [expr $driveCapacity <= 6 || [expr  $driveCapacity - $sinkCapacity] < 2]} {
            set leftStair [eo [expr $driveCapacity <= 1 && [expr $driveCapacity - $sinkCapacity] <= -5] 4 3]
            set rightStair [eo [expr $driveCapacity <= 1 && [expr $driveCapacity - $sinkCapacity] <= -5] 3 2]
            set leftStair [eo [expr $driveCapacity < 1 && [expr $driveCapacity - $sinkCapacity] <= -10] 5 $leftStair]
            set rightStair [eo [expr $driveCapacity < 1 && [expr $driveCapacity - $sinkCapacity] <= -10] 4 $rightStair]
            if {$debug} { puts "----------------" }
            if {$debug} { puts "driveCapacity: $driveCapacity  | sinkCapacity: $sinkCapacity" }
            if {$debug} { puts "left: $leftStair  right: $rightStair" }
            set toChangeCelltype [eo $ifHaveFasterVT [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1] $driveCelltype]
            set toChangeCelltype [eo $ifHaveLargerCapacity [strategy_changeDriveCapacity $toChangeCelltype 0 [eo [expr $driveCapacity <= 2] $leftStair $rightStair] $rangeOfDriveCapacityForChange $cellRegExp 1] $toChangeCelltype]
            lappend fixedList_1v1 [concat "ls:in_1:1" "FS" $toChangeCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type change -cell $toChangeCelltype -inst $driveInstname]
          } else {
            lappend cantChangeList_1v1 [concat "ls:in_1:1" "S" $allInfoList]
            set cmd1 "cantChange"
          }
        } elseif {$ifHaveFasterVT && $canChangeVT && $violnum >= -0.005} { ;
          if {$debug} { puts "in 1: only change VT" }
          set toChangeCelltype [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          if {[regexp -- {0x0:3} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "ls:in_2:1" "V" $allInfoList]
            set cmd1 "cantChange"
          } elseif {[regexp -- {0x0:4} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "ls:in_2:2" "F" $allInfoList]
            set cmd1 "cantChange"
          } else {
            lappend fixedList_1v1 [concat "ls:in_2:3" "T" $toChangeCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]
          }
        } elseif {$ifHaveLargerCapacity && $canChangeDriveCapacity && $violnum >= -0.01 && $netLength <= [expr $unitOfNetLength * 1.1]} { ;
          if {$debug} { puts "in 2: only change DriveCapacity" }
          set toChangeCelltype [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          if {$debug} { puts $toChangeCelltype }
          if {$driveCapacity == 0.5} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 3 $rangeOfDriveCapacityForChange $cellRegExp 1]
          } elseif {$driveCapacity in {1 2}} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1]
          } elseif {$driveCapacity >= 3} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 1 $rangeOfDriveCapacityForChange $cellRegExp 1]
          }
          if {[regexp -- {0x0:3} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "ls:in_4:1" "O" $allInfoList]
            set cmd1 "cantChange"
          } else {
            lappend fixedList_1v1 [concat "ls:in_4:2" "D" $toChangeCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]
          }
        } elseif {$ifHaveLargerCapacity && $canChangeVTandDriveCapacity && $violnum >= -0.03 && $netLength <= [expr $unitOfNetLength * 1.7]} { ;
          if {$debug} { puts "in 3: change VT and DriveCapacity" }
          set toChangeCelltype [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          if {[regexp -- {0x0:3} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "ls:in_5:1" "V" $allInfoList]
            set cmd1 "cantChange"
          } elseif {[regexp -- {0x0:4} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "ls:in_5:2" "F" $allInfoList]
            set cmd1 "cantChange"
          } else {
            if {$driveCapacity <= 1} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1]
            } elseif {$driveCapacity >= 2} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 1 $rangeOfDriveCapacityForChange $cellRegExp 1]
            }
            if {[regexp -- {0x0:3} $toChangeCelltype]} {
              lappend cantChangeList_1v1 [concat "ls:in_5:3" "O" $allInfoList]
              set cmd1 "cantChange"
            } else {
              lappend fixedList_1v1 [concat "ls:in_5:4" "TD" $toChangeCelltype $allInfoList]
              set cmd1 [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]
            }
          }
        } elseif {$canAddRepeater && $violnum >= -0.12 && $netLength < [expr $unitOfNetLength * 5] && $netLength > [expr $unitOfNetLength * 1]} { ;
          if {$debug} { puts "in 4: add Repeater" }
          set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $loadCellClass]] $refCLKBufferCelltype $refBufferCelltype]
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 3 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ;
          set toChangeCelltype [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1]
            if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
            set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname];
            lappend fixedList_1v1 [concat "ls:in_6:2" "DA_09" ${toChangeCelltype}_$toAddCelltype $allInfoList]
            set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
            set cmd1 [list $cmd_DA_driveInst $cmd_DA_add]
          } else {
            lappend fixedList_1v1 [concat "ls:in_6:4" "A_09" $toAddCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
          }
        } elseif {$canAddRepeater && $violnum < -0.18 && $netLength > [expr $unitOfNetLength * 5]} { ;
          set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $loadCellClass]] $refCLKBufferCelltype $refBufferCelltype]
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 4 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ;
          set toChangeCelltype [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1]
            if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
            set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname];
            lappend fixedList_1v1 [concat "ls:in_7:2" "DAA_0509" ${toChangeCelltype}_$toAddCelltype $allInfoList]
            set cmd_DA_add1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
            set cmd_DA_add2 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
            set cmd1 [list $cmd_DA_driveInst $cmd_DA_add1 $cmd_DA_add2]
          } else {
            lappend fixedList_1v1 [concat "ls:in_7:4" "AA_0509" $toAddCelltype $allInfoList]
            set cmd_AA_add1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
            set cmd_AA_add2 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
            set cmd1 [concat $cmd_AA_add1 $cmd_AA_add2]
          }
        } elseif {$canAddRepeater && $violnum < -0.22 && $netLength > [expr $unitOfNetLength * 5]} { ;
          if {$debug} { puts "in 5: add Repeater refDriver, uncertainly, conservative" }
          if {$debug} { puts "Not in above situation, so NOTICE" }
          set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $loadCellClass]] $refCLKBufferCelltype $refBufferCelltype]
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 4 $rangeOfDriveCapacityForAdd 1 $refCelltype $cellRegExp ];
          set toChangeCelltype [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          if {$driveCapacity < 8 && $ifHaveLargerCapacity} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 6 0 $rangeOfDriveCapacityForChange $cellRegExp 1]
            if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
            set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname];
            lappend fixedList_1v1 [concat "ls:in_8:2" "DAA_0509" ${toChangeCelltype}_$toAddCelltype $allInfoList]
            if {$debug} {puts "test : ls:in_8:2"}
            set cmd_DA_add1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
            set cmd_DA_add2 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
            set cmd1 [list $cmd_DA_driveInst $cmd_DA_add1 $cmd_DA_add2]
            if {$debug} {puts $cmd1}
          } else {
            lappend fixedList_1v1 [concat "ls:in_8:4" "AA_0509" $toAddCelltype $allInfoList]
            set cmd_AA_add1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
            set cmd_AA_add2 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
            set cmd1 [concat $cmd_AA_add1 $cmd_AA_add2]
          }
        } elseif {$canAddRepeater && [expr $violnum > -0.2 && $netLength < [expr $unitOfNetLength * 4] || \
                                    $violnum > -0.4 && $netLength < [expr $unitOfNetLength * 6]]} {
          set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $loadCellClass]] $refCLKBufferCelltype $refBufferCelltype]
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 3 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ;
          set toChangeCelltype [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1]
            if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
            set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname];
            lappend fixedList_1v1 [concat "ls:in_9:2" "DA_09" ${toChangeCelltype}_$toAddCelltype $allInfoList]
            set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
            set cmd1 [list $cmd_DA_driveInst $cmd_DA_add]
          } else {
            lappend fixedList_1v1 [concat "ls:in_9:4" "A_09" $toAddCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
          }
        } else {
          set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $loadCellClass]] $refCLKBufferCelltype $refBufferCelltype]
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 3 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ;
          set toChangeCelltype [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1]
            if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
            set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname];
            lappend fixedList_1v1 [concat "ls:in_0:2" "DA_09" ${toChangeCelltype}_$toAddCelltype $allInfoList]
            set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
            set cmd1 [list $cmd_DA_driveInst $cmd_DA_add]
          } else {
            lappend fixedList_1v1 [concat "ls:in_0:4" "A_09" $toAddCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
          }
        }
      } elseif {$driveCellClass in {sequential} && $loadCellClass in {delay logic CLKlogic}} {
        if {$debug} { puts "$netLength $driveCelltype $sinkCelltype [lindex $viol_driverPin_loadPin 1] [lindex $viol_driverPin_loadPin 2]" }
        set refVTweightList [eo [regexp CLK $driveCellClass] $clkNeedVtWeightList $normalNeedVtWeightList]
        set ifHaveFasterVT [re [la [strategy_changeVT $driveCelltype $refVTweightList $rangeOfVtSpeed $cellRegExp 1] $driveCelltype]]
        if {$debug} {puts "if have faster vt: $ifHaveFasterVT"}
        set ifHaveSlowerVT 0
        set ifHaveLargerCapacity [re [la [strategy_changeDriveCapacity $driveCelltype 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1] $driveCelltype]]
        if {$debug} {puts "if have larger capacity: $ifHaveLargerCapacity"}
        set ifHaveSmallerCapacity 0
        if {!$ifHaveFasterVT && !$ifHaveLargerCapacity} {
          lappend skippedList_1v1 [concat "sl:in_1:1" "NFL" $allInfoList]
        } elseif {!$ifHaveFasterVT} {
          lappend skippedList_1v1 [concat "sl:in_1:2" "NF" $allInfoList]
        } elseif {!$ifHaveLargerCapacity} {
          lappend skippedList_1v1 [concat "sl:in_1:3" "NL" $allInfoList]
        }
        if {$violnum < -0.2 && $netLength < 20 || \
            $violnum < -0.1 && $netLength < 10 || \
            $violnum < -0.07 && $netLength < 8 || \
            $violnum < -0.03 && $netLength < 4 \
            } { ;
          if {[expr $ifHaveFasterVT || $ifHaveLargerCapacity] && [expr $driveCapacity <= 6 || [expr  $driveCapacity - $sinkCapacity] < 2]} {
            set leftStair [eo [expr $driveCapacity <= 1 && [expr $driveCapacity - $sinkCapacity] <= -5] 4 3]
            set rightStair [eo [expr $driveCapacity <= 1 && [expr $driveCapacity - $sinkCapacity] <= -5] 3 2]
            set leftStair [eo [expr $driveCapacity < 1 && [expr $driveCapacity - $sinkCapacity] <= -10] 5 $leftStair]
            set rightStair [eo [expr $driveCapacity < 1 && [expr $driveCapacity - $sinkCapacity] <= -10] 4 $rightStair]
            if {$debug} { puts "----------------" }
            if {$debug} { puts "driveCapacity: $driveCapacity  | sinkCapacity: $sinkCapacity" }
            if {$debug} { puts "left: $leftStair  right: $rightStair" }
            set toChangeCelltype [eo $ifHaveFasterVT [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1] $driveCelltype]
            set toChangeCelltype [eo $ifHaveLargerCapacity [strategy_changeDriveCapacity $toChangeCelltype 0 [eo [expr $driveCapacity <= 2] $leftStair $rightStair] $rangeOfDriveCapacityForChange $cellRegExp 1] $toChangeCelltype]
            lappend fixedList_1v1 [concat "sl:in_1:1" "FS" $toChangeCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type change -cell $toChangeCelltype -inst $driveInstname]
          } else {
            lappend cantChangeList_1v1 [concat "sl:in_1:1" "S" $allInfoList]
            set cmd1 "cantChange"
          }
        } elseif {$ifHaveFasterVT && $canChangeVT && $violnum >= -0.005} { ;
          if {$debug} { puts "in 1: only change VT" }
          set toChangeCelltype [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          if {[regexp -- {0x0:3} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "sl:in_2:1" "V" $allInfoList]
            set cmd1 "cantChange"
          } elseif {[regexp -- {0x0:4} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "sl:in_2:2" "F" $allInfoList]
            set cmd1 "cantChange"
          } else {
            lappend fixedList_1v1 [concat "sl:in_2:3" "T" $toChangeCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]
          }
        } elseif {$ifHaveLargerCapacity && $canChangeDriveCapacity && $violnum >= -0.01 && $netLength <= [expr $unitOfNetLength * 1.1]} { ;
          if {$debug} { puts "in 2: only change DriveCapacity" }
          set toChangeCelltype [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          if {$debug} { puts $toChangeCelltype }
          if {$driveCapacity == 0.5} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 3 $rangeOfDriveCapacityForChange $cellRegExp 1]
          } elseif {$driveCapacity in {1 2}} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1]
          } elseif {$driveCapacity >= 3} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 1 $rangeOfDriveCapacityForChange $cellRegExp 1]
          }
          if {[regexp -- {0x0:3} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "sl:in_4:1" "O" $allInfoList]
            set cmd1 "cantChange"
          } else {
            lappend fixedList_1v1 [concat "sl:in_4:2" "D" $toChangeCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]
          }
        } elseif {$ifHaveLargerCapacity && $canChangeVTandDriveCapacity && $violnum >= -0.03 && $netLength <= [expr $unitOfNetLength * 1.7]} { ;
          if {$debug} { puts "in 3: change VT and DriveCapacity" }
          set toChangeCelltype [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          if {[regexp -- {0x0:3} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "sl:in_5:1" "V" $allInfoList]
            set cmd1 "cantChange"
          } elseif {[regexp -- {0x0:4} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "sl:in_5:2" "F" $allInfoList]
            set cmd1 "cantChange"
          } else {
            if {$driveCapacity <= 1} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1]
            } elseif {$driveCapacity >= 2} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 1 $rangeOfDriveCapacityForChange $cellRegExp 1]
            }
            if {[regexp -- {0x0:3} $toChangeCelltype]} {
              lappend cantChangeList_1v1 [concat "sl:in_5:3" "O" $allInfoList]
              set cmd1 "cantChange"
            } else {
              lappend fixedList_1v1 [concat "sl:in_5:4" "TD" $toChangeCelltype $allInfoList]
              set cmd1 [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]
            }
          }
        } elseif {$canAddRepeater && $violnum >= -0.12 && $netLength < [expr $unitOfNetLength * 5] && $netLength > [expr $unitOfNetLength * 1]} { ;
          if {$debug} { puts "in 4: add Repeater" }
          set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $loadCellClass]] $refCLKBufferCelltype $refBufferCelltype]
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 3 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ;
          set toChangeCelltype [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1]
            if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
            set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname];
            lappend fixedList_1v1 [concat "sl:in_6:2" "DA_09" ${toChangeCelltype}_$toAddCelltype $allInfoList]
            set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
            set cmd1 [list $cmd_DA_driveInst $cmd_DA_add]
          } else {
            lappend fixedList_1v1 [concat "sl:in_6:4" "A_09" $toAddCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
          }
        } elseif {$canAddRepeater && $violnum < -0.18 && $netLength > [expr $unitOfNetLength * 5]} { ;
          set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $loadCellClass]] $refCLKBufferCelltype $refBufferCelltype]
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 4 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ;
          set toChangeCelltype [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1]
            if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
            set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname];
            lappend fixedList_1v1 [concat "sl:in_7:2" "DAA_0509" ${toChangeCelltype}_$toAddCelltype $allInfoList]
            set cmd_DA_add1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
            set cmd_DA_add2 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
            set cmd1 [list $cmd_DA_driveInst $cmd_DA_add1 $cmd_DA_add2]
          } else {
            lappend fixedList_1v1 [concat "sl:in_7:4" "AA_0509" $toAddCelltype $allInfoList]
            set cmd_AA_add1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
            set cmd_AA_add2 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
            set cmd1 [concat $cmd_AA_add1 $cmd_AA_add2]
          }
        } elseif {$canAddRepeater && $violnum < -0.22 && $netLength > [expr $unitOfNetLength * 5]} { ;
          if {$debug} { puts "in 5: add Repeater refDriver, uncertainly, conservative" }
          if {$debug} { puts "Not in above situation, so NOTICE" }
          set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $loadCellClass]] $refCLKBufferCelltype $refBufferCelltype]
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 4 $rangeOfDriveCapacityForAdd 1 $refCelltype $cellRegExp ];
          set toChangeCelltype [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          if {$driveCapacity < 8 && $ifHaveLargerCapacity} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 6 0 $rangeOfDriveCapacityForChange $cellRegExp 1]
            if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
            set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname];
            lappend fixedList_1v1 [concat "sl:in_8:2" "DAA_0509" ${toChangeCelltype}_$toAddCelltype $allInfoList]
            if {$debug} {puts "test : sl:in_8:2"}
            set cmd_DA_add1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
            set cmd_DA_add2 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
            set cmd1 [list $cmd_DA_driveInst $cmd_DA_add1 $cmd_DA_add2]
            if {$debug} {puts $cmd1}
          } else {
            lappend fixedList_1v1 [concat "sl:in_8:4" "AA_0509" $toAddCelltype $allInfoList]
            set cmd_AA_add1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
            set cmd_AA_add2 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
            set cmd1 [concat $cmd_AA_add1 $cmd_AA_add2]
          }
        } elseif {$canAddRepeater && [expr $violnum > -0.2 && $netLength < [expr $unitOfNetLength * 4] || \
                                    $violnum > -0.4 && $netLength < [expr $unitOfNetLength * 6]]} {
          set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $loadCellClass]] $refCLKBufferCelltype $refBufferCelltype]
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 3 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ;
          set toChangeCelltype [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1]
            if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
            set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname];
            lappend fixedList_1v1 [concat "sl:in_9:2" "DA_09" ${toChangeCelltype}_$toAddCelltype $allInfoList]
            set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
            set cmd1 [list $cmd_DA_driveInst $cmd_DA_add]
          } else {
            lappend fixedList_1v1 [concat "sl:in_9:4" "A_09" $toAddCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
          }
        } else {
          set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $loadCellClass]] $refCLKBufferCelltype $refBufferCelltype]
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 3 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ;
          set toChangeCelltype [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1]
            if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
            set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname];
            lappend fixedList_1v1 [concat "sl:in_0:2" "DA_09" ${toChangeCelltype}_$toAddCelltype $allInfoList]
            set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
            set cmd1 [list $cmd_DA_driveInst $cmd_DA_add]
          } else {
            lappend fixedList_1v1 [concat "sl:in_0:4" "A_09" $toAddCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
          }
        }
      } elseif {$driveCellClass in {sequential} && $loadCellClass in {buffer inverter CLKbuffer CLKinverter}} {
        if {$debug} { puts "$netLength $driveCelltype $sinkCelltype [lindex $viol_driverPin_loadPin 1] [lindex $viol_driverPin_loadPin 2]" }
        set refVTweightList [eo [regexp CLK $driveCellClass] $clkNeedVtWeightList $normalNeedVtWeightList]
        set ifHaveFasterVT [re [la [strategy_changeVT $driveCelltype $refVTweightList $rangeOfVtSpeed $cellRegExp 1] $driveCelltype]]
        if {$debug} {puts "if have faster vt: $ifHaveFasterVT"}
        set ifHaveSlowerVT 0
        set ifHaveLargerCapacity [re [la [strategy_changeDriveCapacity $driveCelltype 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1] $driveCelltype]]
        if {$debug} {puts "if have larger capacity: $ifHaveLargerCapacity"}
        set ifHaveSmallerCapacity 0
        if {!$ifHaveFasterVT && !$ifHaveLargerCapacity} {
          lappend skippedList_1v1 [concat "sb:in_1:1" "NFL" $allInfoList]
        } elseif {!$ifHaveFasterVT} {
          lappend skippedList_1v1 [concat "sb:in_1:2" "NF" $allInfoList]
        } elseif {!$ifHaveLargerCapacity} {
          lappend skippedList_1v1 [concat "sb:in_1:3" "NL" $allInfoList]
        }
        if {$violnum < -0.2 && $netLength < 20 || \
            $violnum < -0.1 && $netLength < 10 || \
            $violnum < -0.07 && $netLength < 8 || \
            $violnum < -0.03 && $netLength < 4 \
            } { ;
          if {[expr $ifHaveFasterVT || $ifHaveLargerCapacity] && [expr $driveCapacity <= 6 || [expr  $driveCapacity - $sinkCapacity] < 2]} {
            set leftStair [eo [expr $driveCapacity <= 1 && [expr $driveCapacity - $sinkCapacity] <= -5] 4 3]
            set rightStair [eo [expr $driveCapacity <= 1 && [expr $driveCapacity - $sinkCapacity] <= -5] 3 2]
            set leftStair [eo [expr $driveCapacity < 1 && [expr $driveCapacity - $sinkCapacity] <= -10] 5 $leftStair]
            set rightStair [eo [expr $driveCapacity < 1 && [expr $driveCapacity - $sinkCapacity] <= -10] 4 $rightStair]
            if {$debug} { puts "----------------" }
            if {$debug} { puts "driveCapacity: $driveCapacity  | sinkCapacity: $sinkCapacity" }
            if {$debug} { puts "left: $leftStair  right: $rightStair" }
            set toChangeCelltype [eo $ifHaveFasterVT [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1] $driveCelltype]
            set toChangeCelltype [eo $ifHaveLargerCapacity [strategy_changeDriveCapacity $toChangeCelltype 0 [eo [expr $driveCapacity <= 2] $leftStair $rightStair] $rangeOfDriveCapacityForChange $cellRegExp 1] $toChangeCelltype]
            lappend fixedList_1v1 [concat "sb:in_1:1" "FS" $toChangeCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type change -cell $toChangeCelltype -inst $driveInstname]
          } else {
            lappend cantChangeList_1v1 [concat "sb:in_1:1" "S" $allInfoList]
            set cmd1 "cantChange"
          }
        } elseif {$ifHaveFasterVT && $canChangeVT && $violnum >= -0.005} { ;
          if {$debug} { puts "in 1: only change VT" }
          set toChangeCelltype [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          if {[regexp -- {0x0:3} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "sb:in_2:1" "V" $allInfoList]
            set cmd1 "cantChange"
          } elseif {[regexp -- {0x0:4} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "sb:in_2:2" "F" $allInfoList]
            set cmd1 "cantChange"
          } else {
            lappend fixedList_1v1 [concat "sb:in_2:3" "T" $toChangeCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]
          }
        } elseif {$ifHaveLargerCapacity && $canChangeDriveCapacity && $violnum >= -0.01 && $netLength <= [expr $unitOfNetLength * 1.1]} { ;
          if {$debug} { puts "in 2: only change DriveCapacity" }
          set toChangeCelltype [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          if {$debug} { puts $toChangeCelltype }
          if {$driveCapacity == 0.5} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 3 $rangeOfDriveCapacityForChange $cellRegExp 1]
          } elseif {$driveCapacity in {1 2}} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1]
          } elseif {$driveCapacity >= 3} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 1 $rangeOfDriveCapacityForChange $cellRegExp 1]
          }
          if {[regexp -- {0x0:3} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "sb:in_4:1" "O" $allInfoList]
            set cmd1 "cantChange"
          } else {
            lappend fixedList_1v1 [concat "sb:in_4:2" "D" $toChangeCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]
          }
        } elseif {$ifHaveLargerCapacity && $canChangeVTandDriveCapacity && $violnum >= -0.03 && $netLength <= [expr $unitOfNetLength * 1.7]} { ;
          if {$debug} { puts "in 3: change VT and DriveCapacity" }
          set toChangeCelltype [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          if {[regexp -- {0x0:3} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "sb:in_5:1" "V" $allInfoList]
            set cmd1 "cantChange"
          } elseif {[regexp -- {0x0:4} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "sb:in_5:2" "F" $allInfoList]
            set cmd1 "cantChange"
          } else {
            if {$driveCapacity <= 1} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1]
            } elseif {$driveCapacity >= 2} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 1 $rangeOfDriveCapacityForChange $cellRegExp 1]
            }
            if {[regexp -- {0x0:3} $toChangeCelltype]} {
              lappend cantChangeList_1v1 [concat "sb:in_5:3" "O" $allInfoList]
              set cmd1 "cantChange"
            } else {
              lappend fixedList_1v1 [concat "sb:in_5:4" "TD" $toChangeCelltype $allInfoList]
              set cmd1 [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]
            }
          }
        } elseif {$canAddRepeater && $violnum >= -0.12 && $netLength < [expr $unitOfNetLength * 5] && $netLength > [expr $unitOfNetLength * 1]} { ;
          if {$debug} { puts "in 4: add Repeater" }
          set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $loadCellClass]] $refCLKBufferCelltype $refBufferCelltype]
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 3 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ;
          set toChangeCelltype [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1]
            if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
            set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname];
            lappend fixedList_1v1 [concat "sb:in_6:2" "DA_09" ${toChangeCelltype}_$toAddCelltype $allInfoList]
            set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
            set cmd1 [list $cmd_DA_driveInst $cmd_DA_add]
          } else {
            lappend fixedList_1v1 [concat "sb:in_6:4" "A_09" $toAddCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
          }
        } elseif {$canAddRepeater && $violnum < -0.18 && $netLength > [expr $unitOfNetLength * 5]} { ;
          set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $loadCellClass]] $refCLKBufferCelltype $refBufferCelltype]
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 4 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ;
          set toChangeCelltype [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1]
            if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
            set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname];
            lappend fixedList_1v1 [concat "sb:in_7:2" "DAA_0509" ${toChangeCelltype}_$toAddCelltype $allInfoList]
            set cmd_DA_add1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
            set cmd_DA_add2 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
            set cmd1 [list $cmd_DA_driveInst $cmd_DA_add1 $cmd_DA_add2]
          } else {
            lappend fixedList_1v1 [concat "sb:in_7:4" "AA_0509" $toAddCelltype $allInfoList]
            set cmd_AA_add1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
            set cmd_AA_add2 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
            set cmd1 [concat $cmd_AA_add1 $cmd_AA_add2]
          }
        } elseif {$canAddRepeater && $violnum < -0.22 && $netLength > [expr $unitOfNetLength * 5]} { ;
          if {$debug} { puts "in 5: add Repeater refDriver, uncertainly, conservative" }
          if {$debug} { puts "Not in above situation, so NOTICE" }
          set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $loadCellClass]] $refCLKBufferCelltype $refBufferCelltype]
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 4 $rangeOfDriveCapacityForAdd 1 $refCelltype $cellRegExp ];
          set toChangeCelltype [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          if {$driveCapacity < 8 && $ifHaveLargerCapacity} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 6 0 $rangeOfDriveCapacityForChange $cellRegExp 1]
            if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
            set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname];
            lappend fixedList_1v1 [concat "sb:in_8:2" "DAA_0509" ${toChangeCelltype}_$toAddCelltype $allInfoList]
            if {$debug} {puts "test : sb:in_8:2"}
            set cmd_DA_add1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
            set cmd_DA_add2 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
            set cmd1 [list $cmd_DA_driveInst $cmd_DA_add1 $cmd_DA_add2]
            if {$debug} {puts $cmd1}
          } else {
            lappend fixedList_1v1 [concat "sb:in_8:4" "AA_0509" $toAddCelltype $allInfoList]
            set cmd_AA_add1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
            set cmd_AA_add2 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
            set cmd1 [concat $cmd_AA_add1 $cmd_AA_add2]
          }
        } elseif {$canAddRepeater && [expr $violnum > -0.2 && $netLength < [expr $unitOfNetLength * 4] || \
                                    $violnum > -0.4 && $netLength < [expr $unitOfNetLength * 6]]} {
          set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $loadCellClass]] $refCLKBufferCelltype $refBufferCelltype]
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 3 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ;
          set toChangeCelltype [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1]
            if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
            set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname];
            lappend fixedList_1v1 [concat "sb:in_9:2" "DA_09" ${toChangeCelltype}_$toAddCelltype $allInfoList]
            set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
            set cmd1 [list $cmd_DA_driveInst $cmd_DA_add]
          } else {
            lappend fixedList_1v1 [concat "sb:in_9:4" "A_09" $toAddCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
          }
        } else {
          set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $loadCellClass]] $refCLKBufferCelltype $refBufferCelltype]
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 3 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ;
          set toChangeCelltype [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1]
            if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
            set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname];
            lappend fixedList_1v1 [concat "sb:in_0:2" "DA_09" ${toChangeCelltype}_$toAddCelltype $allInfoList]
            set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
            set cmd1 [list $cmd_DA_driveInst $cmd_DA_add]
          } else {
            lappend fixedList_1v1 [concat "sb:in_0:4" "A_09" $toAddCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
          }
        }
      } elseif {$driveCellClass in {buffer inverter CLKbuffer CLKinverter} && $loadCellClass in {sequential}} {
        if {$debug} { puts "$netLength $driveCelltype $sinkCelltype [lindex $viol_driverPin_loadPin 1] [lindex $viol_driverPin_loadPin 2]" }
        set refVTweightList [eo [regexp CLK $driveCellClass] $clkNeedVtWeightList $normalNeedVtWeightList]
        set ifHaveFasterVT [re [la [strategy_changeVT $driveCelltype $refVTweightList $rangeOfVtSpeed $cellRegExp 1] $driveCelltype]]
        if {$debug} {puts "if have faster vt: $ifHaveFasterVT"}
        set ifHaveSlowerVT 0
        set ifHaveLargerCapacity [re [la [strategy_changeDriveCapacity $driveCelltype 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1] $driveCelltype]]
        if {$debug} {puts "if have larger capacity: $ifHaveLargerCapacity"}
        set ifHaveSmallerCapacity 0
        if {!$ifHaveFasterVT && !$ifHaveLargerCapacity} {
          lappend skippedList_1v1 [concat "bs:in_1:1" "NFL" $allInfoList]
        } elseif {!$ifHaveFasterVT} {
          lappend skippedList_1v1 [concat "bs:in_1:2" "NF" $allInfoList]
        } elseif {!$ifHaveLargerCapacity} {
          lappend skippedList_1v1 [concat "bs:in_1:3" "NL" $allInfoList]
        }
        if {$violnum < -0.2 && $netLength < 20 || \
            $violnum < -0.1 && $netLength < 10 || \
            $violnum < -0.07 && $netLength < 8 || \
            $violnum < -0.03 && $netLength < 4 \
            } { ;
          if {[expr $ifHaveFasterVT || $ifHaveLargerCapacity] && [expr $driveCapacity <= 4 || [expr  $driveCapacity - $sinkCapacity] < 0]} {
            set toChangeCelltype [eo $ifHaveFasterVT [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1] $driveCelltype]
            set toChangeCelltype [eo $ifHaveLargerCapacity [strategy_changeDriveCapacity $toChangeCelltype 0 [eo [expr $driveCapacity <= 3] 2 1] $rangeOfDriveCapacityForChange $cellRegExp 1] $toChangeCelltype]
            lappend fixedList_1v1 [concat "bs:in_1:1" "FS" $toChangeCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type change -cell $toChangeCelltype -inst $driveInstname]
          } else {
            lappend cantChangeList_1v1 [concat "bs:in_1:1" "S" $allInfoList]
            set cmd1 "cantChange"
          }
        } elseif {$ifHaveFasterVT && $canChangeVT && [expr $violnum >= -0.02 || \
                   $violnum >= -0.01 && $netLength > [expr $unitOfNetLength  * 15 ] || \
                   $violnum >= -0.02 && $netLength > [expr $unitOfNetLength  * 30 ] \
                   ]} { ;
          if {$debug} { puts "in 1: only change VT" }
          set toChangeCelltype [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          if {[regexp -- {0x0:3} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "bs:in_2:1" "V" $allInfoList]
            set cmd1 "cantChange"
          } elseif {[regexp -- {0x0:4} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "bs:in_2:2" "F" $allInfoList]
            set cmd1 "cantChange"
          } else {
            lappend fixedList_1v1 [concat "bs:in_2:3" "T" $toChangeCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]
          }
        } elseif {$ifHaveLargerCapacity && $canChangeDriveCapacity && $violnum >= -0.04 && $netLength <= [expr $unitOfNetLength * 2.1]} { ;
          if {$debug} { puts "in 2: only change DriveCapacity" }
          set toChangeCelltype [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          if {$debug} { puts $toChangeCelltype }
          if {$driveCapacity in {0.5 1 2}} { ;
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 1 $rangeOfDriveCapacityForChange $cellRegExp 1]
          } elseif {$driveCapacity >= 3} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 1 $rangeOfDriveCapacityForChange $cellRegExp 1]
          }
          if {[regexp -- {0x0:3} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "bs:in_4:1" "O" $allInfoList]
            set cmd1 "cantChange"
          } else {
            lappend fixedList_1v1 [concat "bs:in_4:2" "D" $toChangeCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]
          }
        } elseif {$ifHaveLargerCapacity && $canChangeVTandDriveCapacity && $violnum >= -0.06 && $netLength <= [expr $unitOfNetLength * 2.5]} { ;
          if {$debug} { puts "in 3: change VT and DriveCapacity" }
          set toChangeCelltype [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          if {[regexp -- {0x0:3} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "bs:in_5:1" "V" $allInfoList]
            set cmd1 "cantChange"
          } elseif {[regexp -- {0x0:4} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "bs:in_5:2" "F" $allInfoList]
            set cmd1 "cantChange"
          } else {
            if {$driveCapacity <= 1} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1]
            } elseif {$driveCapacity >= 2} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 1 $rangeOfDriveCapacityForChange $cellRegExp 1]
            }
            if {[regexp -- {0x0:3} $toChangeCelltype]} {
              lappend cantChangeList_1v1 [concat "bs:in_5:3" "O" $allInfoList]
              set cmd1 "cantChange"
            } else {
              lappend fixedList_1v1 [concat "bs:in_5:4" "TD" $toChangeCelltype $allInfoList]
              set cmd1 [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]
            }
          }
        } elseif {$canAddRepeater && $violnum < -0.06  && $violnum >= -0.1 && $netLength < [expr $unitOfNetLength * 4] && $netLength > [expr $unitOfNetLength * 2]} { ;
          if {$debug} { puts "in 4: add Repeater" }
          set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $loadCellClass]] $refCLKBufferCelltype $refBufferCelltype]
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 4 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ;
          set toChangeCelltype [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1]
            if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
            set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname];
            lappend fixedList_1v1 [concat "bs:in_6:2" "DA_05" ${toChangeCelltype}_$toAddCelltype $allInfoList]
            set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
            set cmd1 [list $cmd_DA_driveInst $cmd_DA_add]
          } else {
            lappend fixedList_1v1 [concat "bs:in_6:4" "A_05" $toAddCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
          }
        } else { ;
          if {$debug} { puts "in 5: add Repeater refDriver, uncertainly, conservative" }
          if {$debug} { puts "Not in above situation, so NOTICE" }
          set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $loadCellClass]] $refCLKBufferCelltype $refBufferCelltype]
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 3 $rangeOfDriveCapacityForAdd 1 $refCelltype $cellRegExp ];
          set toChangeCelltype [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1]
            if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
            set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname];
            lappend fixedList_1v1 [concat "bs:in_7:2" "DA_05" ${toChangeCelltype}_$toAddCelltype $allInfoList]
            set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
            set cmd1 [list $cmd_DA_driveInst $cmd_DA_add]
          } else {
            lappend fixedList_1v1 [concat "bs:in_7:4" "A_05" $toAddCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
          }
        }
      }
      if {$debug} { puts "TEST: $toChangeCelltype" }
      if {$cmd1 != "" && $cmd1 != "cantChange" && [get_driveCapacity_of_celltype $toChangeCelltype $cellRegExp] < $largerThanDriveCapacityOfChangedCelltype} { ;
        set checkedSymbol "C"
        set checkedCmd ""
        set preToChangeCell $toChangeCelltype
        set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype $largerThanDriveCapacityOfChangedCelltype 0 $rangeOfDriveCapacityForChange $cellRegExp 1]
        set checkedCmd [print_ecoCommand -type change -cell $toChangeCelltype -inst $driveInstname]
        if {[llength $cmd1] > 1 && [llength $cmd1] < 5 && ![regexp "0x0" $checkedCmd] && $checkedCmd != ""} {
          set indexChangeCmd [lsearch -regexp $cmd1 "^ecoChangeCell .*"]
          set cmd1 [lreplace $cmd1 $indexChangeCmd $indexChangeCmd $checkedCmd]
        } elseif {[llength $cmd1] >= 5 && [regexp "ecoChangeCell" $cmd1] && ![regexp "0x0" $checkedCmd] && $checkedCmd != ""} {
          set cmd1 $checkedCmd
        }
        set methodColumn [lindex [lindex $fixedList_1v1 end] 1]
        set celltypeToFix [lindex [lindex $fixedList_1v1 end] 2]
        set fixedList_1v1 [lreplace $fixedList_1v1 end end [lreplace [lindex $fixedList_1v1 end] 1 2 [append methodColumn "_" $checkedSymbol ] [regsub $preToChangeCell $celltypeToFix $toChangeCelltype]]]
        if {$debug} { puts "TEST FIXEDLIST large : [llength $fixedList_1v1]" }
        if {$debug} { puts [lindex $fixedList_1v1 end] }
      }
      if {$debug} { puts "TEST END: $cmd1\n   $checkedCmd" }
      if {$cmd1 != "cantChange" && $cmd1 != ""} { ;
        lappend cmdList "# [lindex $fixedList_1v1 end]"
        if {[llength $cmd1] < 5} { ;
          set cmdList [concat $cmdList $cmd1];
        } else {
          lappend cmdList $cmd1
        }
      } elseif {$cmd1 == ""} {
        lappend notConsideredList_1v1 [concat "NC" $allInfoList]
      }
if {$debug} { puts "# -----------------" }
    }
    if {[llength $violValue_drivePin_loadPin_numSinks_sinks_D5List]} {
      lappend cmdList " "
      set beginOfOne2MoreCmds "# BEGIN OF ONE 2 MORE SITUATIONS:"
      lappend cmdList $beginOfOne2MoreCmds
      lappend cmdList " "
    }
    set cantChangePrompts_one2more {
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
    set allInfoPrompt [list violVal dist2cent driveClass driveCelltype driveViolPin numSinks loadClass sinkCelltype loadViolPin]
    set cantChangeList_one2more [list [concat situation sym $allInfoPrompt]]
    set fixedPrompts_one2more {
      "# symbols of normal methods : all of symbols can combine with each other, which is mix of a lot methods."
      "## T - changedVT, below is toChangeCelltype"
      "## D - changedDriveCapacity, below is toChangeCelltype"
      "## A_09 A_0.9 - near the driver - addedRepeaterCell, below is toAddCelltype"
      "## A_05 A_0.5 - in the middle of driver and sink - addedRepeaterCell, below is toAddCelltype"
      "## A_01 A_0.1 - near the sink   - addedRepeaterCell, below is toAddCelltype"
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
      "## 'm' - one 2 more situations, if there are two adjacent m flags at the very beginning, it indicates that in the one-to-many situation, the types of sinks cells have multiple types"
    }
    set fixedList_one2more [list [concat situation method celltypeToFix $allInfoPrompt]]
    set skippedSituationsPrompt_one2more {
      "# NF - have no faster vt"
      "# NL - have no lager drive capacity"
      "# NFL - have no both faster vt and lager drive capacity"
    }
    set skippedList_one2more [list [concat situation method $allInfoPrompt]]
    set notConsideredPrompt_one2more {
      "# NC - not considered situation"
    }
    set notConsideredList_one2more [list [concat situation violValue $allInfoPrompt]]
    set one2moreList_diffTypesOfSinks [list [concat situation types $allInfoPrompt]]
    set one2moreDetailList_withAllViolSinkPinsInfo [list [linsert $allInfoPrompt 2 distanceToSink]]
    foreach violValue_drivePin_loadPin_numSinks_sinks $violValue_drivePin_loadPin_numSinks_sinks_D5List {
      if {$debug} { puts "drive: [get_cell_class [lindex $violValue_drivePin_loadPin_numSinks_sinks 1]] load: [get_cell_class [lindex $violValue_drivePin_loadPin_numSinks_sinks 2]]" }
      foreach var {violnum driveCellClass loadCellClass netName netLength driveInstname driveInstname_celltype_driveLevel_VTtype driveCelltype driveCapacity sinkInstname sinkInstname_celltype_driveLevel_VTtype sinkCelltype sinkCapacity allInfoList numSinks sinksList sinksType sinksPt centerPtOfSinks drivePt distanceOfdrive2CenterPtOfSinks allInfoList} {
        set $var ""
      }
      set violnum [lindex $violValue_drivePin_loadPin_numSinks_sinks 0]
      set driveCellClass [get_cell_class [lindex $violValue_drivePin_loadPin_numSinks_sinks 1]]
      set loadCellClass  [get_cell_class [lindex $violValue_drivePin_loadPin_numSinks_sinks 2]]
      set netName [get_object_name [get_nets -of_objects [lindex $violValue_drivePin_loadPin_numSinks_sinks 1]]]
      set netLength [get_net_length $netName] ;
      set driveInstname [dbget [dbget top.insts.instTerms.name [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -p2].name]
      set driveInstname_celltype_driveLevel_VTtype [get_cellDriveLevel_and_VTtype_of_inst $driveInstname $cellRegExp]
      set driveCelltype [lindex $driveInstname_celltype_driveLevel_VTtype 1]
      set driveCapacity [lindex $driveInstname_celltype_driveLevel_VTtype 2]
      set sinkInstname [dbget [dbget top.insts.instTerms.name [lindex $violValue_drivePin_loadPin_numSinks_sinks 2] -p2].name]
      set sinkInstname_celltype_driveLevel_VTtype [get_cellDriveLevel_and_VTtype_of_inst $sinkInstname $cellRegExp]
      set sinkCelltype [lindex $sinkInstname_celltype_driveLevel_VTtype 1]
      set sinkCapacity [lindex $sinkInstname_celltype_driveLevel_VTtype 2]
      set numSinks [lindex $violValue_drivePin_loadPin_numSinks_sinks 3]
      set sinksList [lindex $violValue_drivePin_loadPin_numSinks_sinks 4]
      set rawSinksType [lmap sink $sinksList { set sinkType [get_cell_class $sink] }]
      set sinksType [lsort -unique $rawSinksType]
      set sinksPt [lmap sink $sinksList {set pt [gpt $sink]}]
      set centerPtOfSinks [calculateResistantCenter_fromPoints  $sinksPt]
      set drivePt [gpt [lindex $violValue_drivePin_loadPin_numSinks_sinks 1]]
      set distanceOfdrive2CenterPtOfSinks [format "%.3f" [calculateDistance $centerPtOfSinks $drivePt]]
      set sinkPt [gpt [lindex $violValue_drivePin_loadPin_numSinks_sinks 2]]
      set distanceToSink [format "%.3f" [calculateDistance $sinkPt $drivePt]]
      set allInfoList [concat $violnum $distanceOfdrive2CenterPtOfSinks \
                              $driveCellClass $driveCelltype [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] "-$numSinks-" \
                              $loadCellClass $sinkCelltype [lindex $violValue_drivePin_loadPin_numSinks_sinks 2] ]
      if {[lsearch -exact -index 5 $one2moreDetailList_withAllViolSinkPinsInfo [lindex $violValue_drivePin_loadPin_numSinks_sinks 1]] > -1 } {
        lappend one2moreDetailList_withAllViolSinkPinsInfo [concat $violnum $distanceOfdrive2CenterPtOfSinks $distanceToSink "/" "/" "/" "/" $loadCellClass $sinkCelltype [lindex $violValue_drivePin_loadPin_numSinks_sinks 2]]
        continue;
      } ;
      lappend one2moreDetailList_withAllViolSinkPinsInfo [concat $violnum $distanceOfdrive2CenterPtOfSinks $distanceToSink $driveCellClass $driveCelltype [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] $numSinks $loadCellClass $sinkCelltype [lindex $violValue_drivePin_loadPin_numSinks_sinks 2]]
      set cmd2 ""
      set toChangeCelltype2 ""
      set toAddCelltype2 ""
      set rawMergeSinksType [lmap sinkType $rawSinksType {
        if {$sinkType in {logic delay CLKlogic}} {
          set t "logic"
        } elseif {$sinkType in {buffer inverter CLKbuffer CLKinverter}} {
          set t "buffer"
        } elseif {$sinkType in {sequential}} {
          set t "sequential"
        }
        set t
      }]
      set mergedSinksType [findMostFrequentElement $rawMergeSinksType 50 1]
      if {[llength $mergedSinksType] == 1} { ;
        if {$driveCellClass in {delay logic CLKlogic} && $mergedSinksType in {delay logic CLKlogic}} {
          set locOffSink 0.8 ;
          set off $locOffSink
          if {$debug} { puts "$distanceOfdrive2CenterPtOfSinks $driveCelltype $sinkCelltype [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] [lindex $violValue_drivePin_loadPin_numSinks_sinks 2]" }
          set refVTweightList [eo [regexp CLK $driveCellClass] $clkNeedVtWeightList $normalNeedVtWeightList]
          set ifHaveFasterVT [re [la [strategy_changeVT $driveCelltype $refVTweightList $rangeOfVtSpeed $cellRegExp 1] $driveCelltype]]
          if {$debug} {puts "if have faster vt: $ifHaveFasterVT"}
          set ifHaveSlowerVT 0
          set ifHaveLargerCapacity [re [la [strategy_changeDriveCapacity $driveCelltype 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1] $driveCelltype]]
          if {$debug} {puts "if have larger capacity: $ifHaveLargerCapacity"}
          set ifHaveSmallerCapacity 0
          if {!$ifHaveFasterVT && !$ifHaveLargerCapacity} {
            lappend skippedList_one2more [concat "mll:in_1:1" "NFL" $allInfoList]
          } elseif {!$ifHaveFasterVT} {
            lappend skippedList_one2more [concat "mll:in_1:2" "NF" $allInfoList]
          } elseif {!$ifHaveLargerCapacity} {
            lappend skippedList_one2more [concat "mll:in_1:3" "NL" $allInfoList]
          }
          if {$violnum < -0.2 && $distanceOfdrive2CenterPtOfSinks < 15 || \
              $violnum < -0.1 && $distanceOfdrive2CenterPtOfSinks < 10 || \
              $violnum < -0.07 && $distanceOfdrive2CenterPtOfSinks < 7 || \
              $violnum < -0.03 && $distanceOfdrive2CenterPtOfSinks < 1 \
                } { ;
            if {[expr $ifHaveFasterVT || $ifHaveLargerCapacity] && [expr $driveCapacity <= 4 || [expr $driveCapacity - $sinkCapacity] < 0]} {
              if {$debug} { puts "------" }
              set toChangeCelltype2 [eo $ifHaveFasterVT [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1] $driveCelltype]
              if {$debug} { puts "mll:in_1:1 FS changeVT : $toChangeCelltype2" }
              set toChangeCelltype2 [eo $ifHaveLargerCapacity [strategy_changeDriveCapacity $toChangeCelltype2 0 [eo [expr $driveCapacity <= 2] 2 1] $rangeOfDriveCapacityForChange $cellRegExp 1] $toChangeCelltype2]
              if {$debug} { puts "mll:in_1:1 FS changeDrive : $toChangeCelltype2" }
              lappend fixedList_one2more [concat "mll:in_1:1" "FS" $toChangeCelltype2 $allInfoList]
              set cmd2 [print_ecoCommand -type change -cell $toChangeCelltype2 -inst $driveInstname]
            } else {
              lappend cantChangeList_one2more [concat "mll:in_1:1" "S" $allInfoList]
              set cmd2 "cantChange"
            }
          } elseif {$ifHaveFasterVT && $canChangeVT && [expr $violnum >= -0.006 || \
                     $violnum >= -0.01 && $distanceOfdrive2CenterPtOfSinks > [expr $unitOfNetLength  * 10 ] || \
                     $violnum >= -0.02 && $distanceOfdrive2CenterPtOfSinks > [expr $unitOfNetLength  * 20 ] \
                     ]} { ;
            if {$debug} { puts "in 1: only change VT" }
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {[regexp -- {0x0:3} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "mll:in_2:1" "V" $allInfoList]
              set cmd2 "cantChange"
            } elseif {[regexp -- {0x0:4} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "mll:in_2:2" "F" $allInfoList]
              set cmd2 "cantChange"
            } else {
              lappend fixedList_one2more [concat "mll:in_2:3" "T" $toChangeCelltype2 $allInfoList]
              set cmd2 [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]
            }
          } elseif {$ifHaveLargerCapacity && $canChangeDriveCapacity && $violnum >= -0.03 && $distanceOfdrive2CenterPtOfSinks <= [expr $unitOfNetLength * 1.2]} { ;
            if {$debug} { puts "in 2: only change DriveCapacity" }
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {$debug} { puts $toChangeCelltype2 }
            if {$driveCapacity == 0.5} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 3 $rangeOfDriveCapacityForChange $cellRegExp 1]
            } elseif {$driveCapacity in {1 2}} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1]
            } elseif {$driveCapacity >= 3} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 1 $rangeOfDriveCapacityForChange $cellRegExp 1]
            }
            if {[regexp -- {0x0:3} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "mll:in_4:1" "O" $allInfoList]
              set cmd2 "cantChange"
            } else {
              lappend fixedList_one2more [concat "mll:in_4:2" "D" $toChangeCelltype2 $allInfoList]
              set cmd2 [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]
            }
          } elseif {$ifHaveLargerCapacity && $canChangeVTandDriveCapacity && [expr  [expr  $violnum >= -0.04 && $distanceOfdrive2CenterPtOfSinks <= [expr $unitOfNetLength * 2.2] ||  $violnum >= -0.11 && $distanceOfdrive2CenterPtOfSinks <= [expr $unitOfNetLength * 1.4]] || \
                                                                                    [expr $violnum >= -0.02  && $distanceOfdrive2CenterPtOfSinks <= [expr $unitOfNetLength * 1.2] && $numSinks > 15] ]} { ;
            if {$debug} { puts "in 3: change VT and DriveCapacity" }
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {[regexp -- {0x0:3} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "mll:in_5:1" "V" $allInfoList]
              set cmd2 "cantChange"
            } elseif {[regexp -- {0x0:4} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "mll:in_5:2" "F" $allInfoList]
              set cmd2 "cantChange"
            } else {
              if {$driveCapacity <= 1} {
                set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1]
              } elseif {$driveCapacity >= 2} {
                set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 1 $rangeOfDriveCapacityForChange $cellRegExp 1]
              }
              if {[regexp -- {0x0:3} $toChangeCelltype2]} {
                lappend cantChangeList_one2more [concat "mll:in_5:3" "O" $allInfoList]
                set cmd2 "cantChange"
              } else {
                lappend fixedList_one2more [concat "mll:in_5:4" "TD" $toChangeCelltype2 $allInfoList]
                set cmd2 [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]
              }
            }
          } elseif {$canAddRepeater && $violnum < -0.08  && [expr  $violnum >= -0.1 && $distanceOfdrive2CenterPtOfSinks < [expr $unitOfNetLength * 4] && $distanceOfdrive2CenterPtOfSinks > [expr $unitOfNetLength * 0.3] && $numSinks <= 5 || \
                                                                   $violnum >= -0.1 && $distanceOfdrive2CenterPtOfSinks < [expr $unitOfNetLength * 2] && $numSinks > 5]} { ;
            if {$debug} { puts "in 4: add Repeater" }
            set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $mergedSinksType]] $refCLKBufferCelltype $refBufferCelltype]
            set toAddCelltype2 [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 2 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ;
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1]
              if {$debug} {puts "$driveCelltype - $toChangeCelltype2"}
              set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname];
              lappend fixedList_one2more [concat "mll:in_6:2" "DA_[fm $off]" ${toChangeCelltype2}_$toAddCelltype2 $allInfoList]
              set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
              set cmd2 [list $cmd_DA_driveInst $cmd_DA_add]
            } else {
              lappend fixedList_one2more [concat "mll:in_6:4" "A_[fm $off]" $toAddCelltype2 $allInfoList]
              set cmd2 [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
            }
          } elseif {$canAddRepeater && $violnum < -0.12 && $distanceOfdrive2CenterPtOfSinks > [expr $unitOfNetLength * 2.5]} { ;
            if {$debug} { puts "in 5: add Repeater refDriver, uncertainly, conservative" }
            if {$debug} { puts "Not in above situation, so NOTICE" }
            set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $mergedSinksType]] $refCLKBufferCelltype $refBufferCelltype]
            set toAddCelltype2 [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 4 $rangeOfDriveCapacityForAdd 1 $refCelltype $cellRegExp ];
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 8 0 $rangeOfDriveCapacityForChange $cellRegExp 1]
              if {$debug} {puts "$driveCelltype - $toChangeCelltype2"}
              set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname];
              lappend fixedList_one2more [concat "mll:in_7:2" "DA_[fm $off]" ${toChangeCelltype2}_$toAddCelltype2 $allInfoList]
              if {$debug} {puts "test : mll:in_7:2"}
              set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
              set cmd2 [list $cmd_DA_driveInst $cmd_DA_add]
            } else {
              if {$ifHaveFasterVT} {
                set cmd_TA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]
                lappend fixedList_one2more [concat "mll:in_7:3" "TA_[fm $off]" $toAddCelltype2 $allInfoList]
                set cmd_TA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
                set cmd2 [concat $cmd_TA_driveInst $cmd_TA_add]
              } else {
                lappend fixedList_one2more [concat "mll:in_7:4" "A_[fm $off]" $toAddCelltype2 $allInfoList]
                set cmd2 [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
              }
            }
          } elseif {$canAddRepeater && $violnum < -0.04 && $violnum > -0.1 && $distanceOfdrive2CenterPtOfSinks < [expr $unitOfNetLength * 0.6]} {;
            set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $mergedSinksType]] $refCLKBufferCelltype $refBufferCelltype]
            set toAddCelltype2 [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 2 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ;
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 8 0 $rangeOfDriveCapacityForChange $cellRegExp 1] ;
              if {$debug} {puts "$driveCelltype - $toChangeCelltype2"}
              set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname];
              lappend fixedList_one2more [concat "mll:in_6:2" "DA_[fm $off]" ${toChangeCelltype2}_$toAddCelltype2 $allInfoList]
              set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
              set cmd2 [list $cmd_DA_driveInst $cmd_DA_add]
            } else {
              lappend fixedList_one2more [concat "mll:in_6:4" "A_[fm $off]" $toAddCelltype2 $allInfoList]
              set cmd2 [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
            }
          } else { ;
            if {$debug} { puts "in 5: add Repeater refDriver, uncertainly, conservative" }
            if {$debug} { puts "Not in above situation, so NOTICE" }
            set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $mergedSinksType]] $refCLKBufferCelltype $refBufferCelltype]
            set toAddCelltype2 [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 3 $rangeOfDriveCapacityForAdd 1 $refCelltype $cellRegExp ];
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1]
              if {$debug} {puts "$driveCelltype - $toChangeCelltype2"}
              set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname];
              lappend fixedList_one2more [concat "mll:in_8:2" "DA_[fm $off]" ${toChangeCelltype2}_$toAddCelltype2 $allInfoList]
              if {$debug} {puts "test : mll:in_8:2"}
              set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
              set cmd2 [list $cmd_DA_driveInst $cmd_DA_add]
            } else {
              lappend fixedList_one2more [concat "mll:in_8:4" "A_[fm $off]" $toAddCelltype2 $allInfoList]
              set cmd2 [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
            }
          }
        } elseif {$driveCellClass in {buffer inverter CLKbuffer CLKinverter} && $mergedSinksType in {buffer inverter CLKbuffer CLKinverter}} {
          set locOffSink 0.6 ;
          set off $locOffSink
          if {$debug} { puts "$distanceOfdrive2CenterPtOfSinks $driveCelltype $sinkCelltype [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] [lindex $violValue_drivePin_loadPin_numSinks_sinks 2]" }
          set refVTweightList [eo [regexp CLK $driveCellClass] $clkNeedVtWeightList $normalNeedVtWeightList]
          set ifHaveFasterVT [re [la [strategy_changeVT $driveCelltype $refVTweightList $rangeOfVtSpeed $cellRegExp 1] $driveCelltype]]
          if {$debug} {puts "if have faster vt: $ifHaveFasterVT"}
          set ifHaveSlowerVT 0
          set ifHaveLargerCapacity [re [la [strategy_changeDriveCapacity $driveCelltype 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1] $driveCelltype]]
          if {$debug} {puts "if have larger capacity: $ifHaveLargerCapacity"}
          set ifHaveSmallerCapacity 0
          if {!$ifHaveFasterVT && !$ifHaveLargerCapacity} {
            lappend skippedList_one2more [concat "mbb:in_1:1" "NFL" $allInfoList]
          } elseif {!$ifHaveFasterVT} {
            lappend skippedList_one2more [concat "mbb:in_1:2" "NF" $allInfoList]
          } elseif {!$ifHaveLargerCapacity} {
            lappend skippedList_one2more [concat "mbb:in_1:3" "NL" $allInfoList]
          }
          if {$violnum < -0.2 && $distanceOfdrive2CenterPtOfSinks < 15 || \
              $violnum < -0.1 && $distanceOfdrive2CenterPtOfSinks < 10 || \
              $violnum < -0.07 && $distanceOfdrive2CenterPtOfSinks < 6 || \
              $violnum < -0.03 && $distanceOfdrive2CenterPtOfSinks < 1 \
                } { ;
            if {[expr $ifHaveFasterVT || $ifHaveLargerCapacity] && [expr $driveCapacity <= 4 || [expr $driveCapacity - $sinkCapacity] < 0]} {
              if {$debug} { puts "------" }
              set toChangeCelltype2 [eo $ifHaveFasterVT [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1] $driveCelltype]
              if {$debug} { puts "mbb:in_1:1 FS changeVT : $toChangeCelltype2" }
              set toChangeCelltype2 [eo $ifHaveLargerCapacity [strategy_changeDriveCapacity $toChangeCelltype2 0 [eo [expr $driveCapacity <= 2] 2 1] $rangeOfDriveCapacityForChange $cellRegExp 1] $toChangeCelltype2]
              if {$debug} { puts "mbb:in_1:1 FS changeDrive : $toChangeCelltype2" }
              lappend fixedList_one2more [concat "mbb:in_1:1" "FS" $toChangeCelltype2 $allInfoList]
              set cmd2 [print_ecoCommand -type change -cell $toChangeCelltype2 -inst $driveInstname]
            } else {
              lappend cantChangeList_one2more [concat "mbb:in_1:1" "S" $allInfoList]
              set cmd2 "cantChange"
            }
          } elseif {$ifHaveFasterVT && $canChangeVT && [expr $violnum >= -0.006 || \
                     $violnum >= -0.01 && $distanceOfdrive2CenterPtOfSinks > [expr $unitOfNetLength  * 10 ] || \
                     $violnum >= -0.02 && $distanceOfdrive2CenterPtOfSinks > [expr $unitOfNetLength  * 20 ] \
                     ]} { ;
            if {$debug} { puts "in 1: only change VT" }
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {[regexp -- {0x0:3} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "mbb:in_2:1" "V" $allInfoList]
              set cmd2 "cantChange"
            } elseif {[regexp -- {0x0:4} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "mbb:in_2:2" "F" $allInfoList]
              set cmd2 "cantChange"
            } else {
              lappend fixedList_one2more [concat "mbb:in_2:3" "T" $toChangeCelltype2 $allInfoList]
              set cmd2 [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]
            }
          } elseif {$ifHaveLargerCapacity && $canChangeDriveCapacity && $violnum >= -0.03 && $distanceOfdrive2CenterPtOfSinks <= [expr $unitOfNetLength * 1.2]} { ;
            if {$debug} { puts "in 2: only change DriveCapacity" }
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {$debug} { puts $toChangeCelltype2 }
            if {$driveCapacity == 0.5} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 3 $rangeOfDriveCapacityForChange $cellRegExp 1]
            } elseif {$driveCapacity in {1 2}} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1]
            } elseif {$driveCapacity >= 3} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 1 $rangeOfDriveCapacityForChange $cellRegExp 1]
            }
            if {[regexp -- {0x0:3} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "mbb:in_4:1" "O" $allInfoList]
              set cmd2 "cantChange"
            } else {
              lappend fixedList_one2more [concat "mbb:in_4:2" "D" $toChangeCelltype2 $allInfoList]
              set cmd2 [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]
            }
          } elseif {$ifHaveLargerCapacity && $canChangeVTandDriveCapacity && [expr  [expr  $violnum >= -0.04 && $distanceOfdrive2CenterPtOfSinks <= [expr $unitOfNetLength * 2.2] ||  $violnum >= -0.11 && $distanceOfdrive2CenterPtOfSinks <= [expr $unitOfNetLength * 1.4]] || \
                                                                                    [expr $violnum >= -0.02  && $distanceOfdrive2CenterPtOfSinks <= [expr $unitOfNetLength * 1.2] && $numSinks > 15] ]} { ;
            if {$debug} { puts "in 3: change VT and DriveCapacity" }
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {[regexp -- {0x0:3} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "mbb:in_5:1" "V" $allInfoList]
              set cmd2 "cantChange"
            } elseif {[regexp -- {0x0:4} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "mbb:in_5:2" "F" $allInfoList]
              set cmd2 "cantChange"
            } else {
              if {$driveCapacity <= 1} {
                set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1]
              } elseif {$driveCapacity >= 2} {
                set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 1 $rangeOfDriveCapacityForChange $cellRegExp 1]
              }
              if {[regexp -- {0x0:3} $toChangeCelltype2]} {
                lappend cantChangeList_one2more [concat "mbb:in_5:3" "O" $allInfoList]
                set cmd2 "cantChange"
              } else {
                lappend fixedList_one2more [concat "mbb:in_5:4" "TD" $toChangeCelltype2 $allInfoList]
                set cmd2 [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]
              }
            }
          } elseif {$canAddRepeater && $violnum < -0.08  && [expr  $violnum >= -0.1 && $distanceOfdrive2CenterPtOfSinks < [expr $unitOfNetLength * 4] && $distanceOfdrive2CenterPtOfSinks > [expr $unitOfNetLength * 0.3] && $numSinks <= 5 || \
                                                                   $violnum >= -0.1 && $distanceOfdrive2CenterPtOfSinks < [expr $unitOfNetLength * 2] && $numSinks > 5]} { ;
            if {$debug} { puts "in 4: add Repeater" }
            set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $mergedSinksType]] $refCLKBufferCelltype $refBufferCelltype]
            set toAddCelltype2 [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 2 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ;
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1]
              if {$debug} {puts "$driveCelltype - $toChangeCelltype2"}
              set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname];
              lappend fixedList_one2more [concat "mbb:in_6:2" "DA_[fm $off]" ${toChangeCelltype2}_$toAddCelltype2 $allInfoList]
              set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
              set cmd2 [list $cmd_DA_driveInst $cmd_DA_add]
            } else {
              lappend fixedList_one2more [concat "mbb:in_6:4" "A_[fm $off]" $toAddCelltype2 $allInfoList]
              set cmd2 [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
            }
          } elseif {$canAddRepeater && $violnum < -0.12 && $distanceOfdrive2CenterPtOfSinks > [expr $unitOfNetLength * 2.5]} { ;
            if {$debug} { puts "in 5: add Repeater refDriver, uncertainly, conservative" }
            if {$debug} { puts "Not in above situation, so NOTICE" }
            set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $mergedSinksType]] $refCLKBufferCelltype $refBufferCelltype]
            set toAddCelltype2 [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 4 $rangeOfDriveCapacityForAdd 1 $refCelltype $cellRegExp ];
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 8 0 $rangeOfDriveCapacityForChange $cellRegExp 1]
              if {$debug} {puts "$driveCelltype - $toChangeCelltype2"}
              set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname];
              lappend fixedList_one2more [concat "mbb:in_7:2" "DA_[fm $off]" ${toChangeCelltype2}_$toAddCelltype2 $allInfoList]
              if {$debug} {puts "test : mbb:in_7:2"}
              set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
              set cmd2 [list $cmd_DA_driveInst $cmd_DA_add]
            } else {
              if {$ifHaveFasterVT} {
                set cmd_TA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]
                lappend fixedList_one2more [concat "mbb:in_7:3" "TA_[fm $off]" $toAddCelltype2 $allInfoList]
                set cmd_TA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
                set cmd2 [concat $cmd_TA_driveInst $cmd_TA_add]
              } else {
                lappend fixedList_one2more [concat "mbb:in_7:4" "A_[fm $off]" $toAddCelltype2 $allInfoList]
                set cmd2 [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
              }
            }
          } elseif {$canAddRepeater && $violnum < -0.04 && $violnum > -0.1 && $distanceOfdrive2CenterPtOfSinks < [expr $unitOfNetLength * $off]} {;
            set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $mergedSinksType]] $refCLKBufferCelltype $refBufferCelltype]
            set toAddCelltype2 [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 2 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ;
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 8 0 $rangeOfDriveCapacityForChange $cellRegExp 1] ;
              if {$debug} {puts "$driveCelltype - $toChangeCelltype2"}
              set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname];
              lappend fixedList_one2more [concat "mbb:in_6:2" "DA_[fm $off]" ${toChangeCelltype2}_$toAddCelltype2 $allInfoList]
              set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
              set cmd2 [list $cmd_DA_driveInst $cmd_DA_add]
            } else {
              lappend fixedList_one2more [concat "mbb:in_6:4" "A_[fm $off]" $toAddCelltype2 $allInfoList]
              set cmd2 [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
            }
          } else { ;
            if {$debug} { puts "in 5: add Repeater refDriver, uncertainly, conservative" }
            if {$debug} { puts "Not in above situation, so NOTICE" }
            set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $mergedSinksType]] $refCLKBufferCelltype $refBufferCelltype]
            set toAddCelltype2 [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 3 $rangeOfDriveCapacityForAdd 1 $refCelltype $cellRegExp ];
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1]
              if {$debug} {puts "$driveCelltype - $toChangeCelltype2"}
              set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname];
              lappend fixedList_one2more [concat "mbb:in_8:2" "DA_[fm $off]" ${toChangeCelltype2}_$toAddCelltype2 $allInfoList]
              if {$debug} {puts "test : mbb:in_8:2"}
              set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
              set cmd2 [list $cmd_DA_driveInst $cmd_DA_add]
            } else {
              lappend fixedList_one2more [concat "mbb:in_8:4" "A_[fm $off]" $toAddCelltype2 $allInfoList]
              set cmd2 [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
            }
          }
        } elseif {$driveCellClass in {delay logic CLKlogic} && $mergedSinksType in {buffer inverter CLKbuffer CLKinverter}} {
          set locOffSink 0.9 ;
          set off $locOffSink
          if {$debug} { puts "$distanceOfdrive2CenterPtOfSinks $driveCelltype $sinkCelltype [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] [lindex $violValue_drivePin_loadPin_numSinks_sinks 2]" }
          set refVTweightList [eo [regexp CLK $driveCellClass] $clkNeedVtWeightList $normalNeedVtWeightList]
          set ifHaveFasterVT [re [la [strategy_changeVT $driveCelltype $refVTweightList $rangeOfVtSpeed $cellRegExp 1] $driveCelltype]]
          if {$debug} {puts "if have faster vt: $ifHaveFasterVT"}
          set ifHaveSlowerVT 0
          set ifHaveLargerCapacity [re [la [strategy_changeDriveCapacity $driveCelltype 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1] $driveCelltype]]
          if {$debug} {puts "if have larger capacity: $ifHaveLargerCapacity"}
          set ifHaveSmallerCapacity 0
          if {!$ifHaveFasterVT && !$ifHaveLargerCapacity} {
            lappend skippedList_one2more [concat "mlb:in_1:1" "NFL" $allInfoList]
          } elseif {!$ifHaveFasterVT} {
            lappend skippedList_one2more [concat "mlb:in_1:2" "NF" $allInfoList]
          } elseif {!$ifHaveLargerCapacity} {
            lappend skippedList_one2more [concat "mlb:in_1:3" "NL" $allInfoList]
          }
          if {$violnum < -0.2 && $distanceOfdrive2CenterPtOfSinks < 15 || \
              $violnum < -0.1 && $distanceOfdrive2CenterPtOfSinks < 7 || \
              $violnum < -0.07 && $distanceOfdrive2CenterPtOfSinks < 4 || \
              $violnum < -0.03 && $distanceOfdrive2CenterPtOfSinks < 1 \
                } { ;
            if {[expr $ifHaveFasterVT || $ifHaveLargerCapacity] && [expr $driveCapacity <= 4 || [expr $driveCapacity - $sinkCapacity] < 0]} {
              if {$debug} { puts "------" }
              set toChangeCelltype2 [eo $ifHaveFasterVT [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1] $driveCelltype]
              if {$debug} { puts "mlb:in_1:1 FS changeVT : $toChangeCelltype2" }
              set toChangeCelltype2 [eo $ifHaveLargerCapacity [strategy_changeDriveCapacity $toChangeCelltype2 0 [eo [expr $driveCapacity <= 2] 2 1] $rangeOfDriveCapacityForChange $cellRegExp 1] $toChangeCelltype2]
              if {$debug} { puts "mlb:in_1:1 FS changeDrive : $toChangeCelltype2" }
              lappend fixedList_one2more [concat "mlb:in_1:1" "FS" $toChangeCelltype2 $allInfoList]
              set cmd2 [print_ecoCommand -type change -cell $toChangeCelltype2 -inst $driveInstname]
            } else {
              lappend cantChangeList_one2more [concat "mlb:in_1:1" "S" $allInfoList]
              set cmd2 "cantChange"
            }
          } elseif {$ifHaveFasterVT && $canChangeVT && [expr $violnum >= -0.006 || \
                     $violnum >= -0.01 && $distanceOfdrive2CenterPtOfSinks > [expr $unitOfNetLength  * 10 ] || \
                     $violnum >= -0.02 && $distanceOfdrive2CenterPtOfSinks > [expr $unitOfNetLength  * 20 ] \
                     ]} { ;
            if {$debug} { puts "in 1: only change VT" }
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {[regexp -- {0x0:3} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "mlb:in_2:1" "V" $allInfoList]
              set cmd2 "cantChange"
            } elseif {[regexp -- {0x0:4} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "mlb:in_2:2" "F" $allInfoList]
              set cmd2 "cantChange"
            } else {
              lappend fixedList_one2more [concat "mlb:in_2:3" "T" $toChangeCelltype2 $allInfoList]
              set cmd2 [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]
            }
          } elseif {$ifHaveLargerCapacity && $canChangeDriveCapacity && $violnum >= -0.03 && $distanceOfdrive2CenterPtOfSinks <= [expr $unitOfNetLength * 1.2]} { ;
            if {$debug} { puts "in 2: only change DriveCapacity" }
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {$debug} { puts $toChangeCelltype2 }
            if {$driveCapacity == 0.5} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 3 $rangeOfDriveCapacityForChange $cellRegExp 1]
            } elseif {$driveCapacity in {1 2}} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1]
            } elseif {$driveCapacity >= 3} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 1 $rangeOfDriveCapacityForChange $cellRegExp 1]
            }
            if {[regexp -- {0x0:3} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "mlb:in_4:1" "O" $allInfoList]
              set cmd2 "cantChange"
            } else {
              lappend fixedList_one2more [concat "mlb:in_4:2" "D" $toChangeCelltype2 $allInfoList]
              set cmd2 [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]
            }
          } elseif {$ifHaveLargerCapacity && $canChangeVTandDriveCapacity && [expr  [expr  $violnum >= -0.04 && $distanceOfdrive2CenterPtOfSinks <= [expr $unitOfNetLength * 2.2] ||  $violnum >= -0.11 && $distanceOfdrive2CenterPtOfSinks <= [expr $unitOfNetLength * 1.4]] || \
                                                                                    [expr $violnum >= -0.02  && $distanceOfdrive2CenterPtOfSinks <= [expr $unitOfNetLength * 1.2] && $numSinks > 15] ]} { ;
            if {$debug} { puts "in 3: change VT and DriveCapacity" }
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {[regexp -- {0x0:3} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "mlb:in_5:1" "V" $allInfoList]
              set cmd2 "cantChange"
            } elseif {[regexp -- {0x0:4} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "mlb:in_5:2" "F" $allInfoList]
              set cmd2 "cantChange"
            } else {
              if {$driveCapacity <= 1} {
                set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1]
              } elseif {$driveCapacity >= 2} {
                set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 1 $rangeOfDriveCapacityForChange $cellRegExp 1]
              }
              if {[regexp -- {0x0:3} $toChangeCelltype2]} {
                lappend cantChangeList_one2more [concat "mlb:in_5:3" "O" $allInfoList]
                set cmd2 "cantChange"
              } else {
                lappend fixedList_one2more [concat "mlb:in_5:4" "TD" $toChangeCelltype2 $allInfoList]
                set cmd2 [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]
              }
            }
          } elseif {$canAddRepeater && $violnum < -0.08  && [expr  $violnum >= -0.1 && $distanceOfdrive2CenterPtOfSinks < [expr $unitOfNetLength * 4] && $distanceOfdrive2CenterPtOfSinks > [expr $unitOfNetLength * 0.3] && $numSinks <= 5 || \
                                                                   $violnum >= -0.1 && $distanceOfdrive2CenterPtOfSinks < [expr $unitOfNetLength * 2] && $numSinks > 5]} { ;
            if {$debug} { puts "in 4: add Repeater" }
            set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $mergedSinksType]] $refCLKBufferCelltype $refBufferCelltype]
            set toAddCelltype2 [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 2 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ;
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1]
              if {$debug} {puts "$driveCelltype - $toChangeCelltype2"}
              set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname];
              lappend fixedList_one2more [concat "mlb:in_6:2" "DA_[fm $off]" ${toChangeCelltype2}_$toAddCelltype2 $allInfoList]
              set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
              set cmd2 [list $cmd_DA_driveInst $cmd_DA_add]
            } else {
              lappend fixedList_one2more [concat "mlb:in_6:4" "A_[fm $off]" $toAddCelltype2 $allInfoList]
              set cmd2 [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
            }
          } elseif {$canAddRepeater && $violnum < -0.12 && $distanceOfdrive2CenterPtOfSinks > [expr $unitOfNetLength * 2.5]} { ;
            if {$debug} { puts "in 5: add Repeater refDriver, uncertainly, conservative" }
            if {$debug} { puts "Not in above situation, so NOTICE" }
            set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $mergedSinksType]] $refCLKBufferCelltype $refBufferCelltype]
            set toAddCelltype2 [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 4 $rangeOfDriveCapacityForAdd 1 $refCelltype $cellRegExp ];
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 8 0 $rangeOfDriveCapacityForChange $cellRegExp 1]
              if {$debug} {puts "$driveCelltype - $toChangeCelltype2"}
              set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname];
              lappend fixedList_one2more [concat "mlb:in_7:2" "DA_[fm $off]" ${toChangeCelltype2}_$toAddCelltype2 $allInfoList]
              if {$debug} {puts "test : mlb:in_7:2"}
              set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
              set cmd2 [list $cmd_DA_driveInst $cmd_DA_add]
            } else {
              if {$ifHaveFasterVT} {
                set cmd_TA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]
                lappend fixedList_one2more [concat "mlb:in_7:3" "TA_[fm $off]" $toAddCelltype2 $allInfoList]
                set cmd_TA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
                set cmd2 [concat $cmd_TA_driveInst $cmd_TA_add]
              } else {
                lappend fixedList_one2more [concat "mlb:in_7:4" "A_[fm $off]" $toAddCelltype2 $allInfoList]
                set cmd2 [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
              }
            }
          } elseif {$canAddRepeater && $violnum < -0.04 && $violnum > -0.1 && $distanceOfdrive2CenterPtOfSinks < [expr $unitOfNetLength * 0.6]} {;
            set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $mergedSinksType]] $refCLKBufferCelltype $refBufferCelltype]
            set toAddCelltype2 [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 2 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ;
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 8 0 $rangeOfDriveCapacityForChange $cellRegExp 1] ;
              if {$debug} {puts "$driveCelltype - $toChangeCelltype2"}
              set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname];
              lappend fixedList_one2more [concat "mlb:in_6:2" "DA_[fm $off]" ${toChangeCelltype2}_$toAddCelltype2 $allInfoList]
              set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
              set cmd2 [list $cmd_DA_driveInst $cmd_DA_add]
            } else {
              lappend fixedList_one2more [concat "mlb:in_6:4" "A_[fm $off]" $toAddCelltype2 $allInfoList]
              set cmd2 [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
            }
          } else { ;
            if {$debug} { puts "in 5: add Repeater refDriver, uncertainly, conservative" }
            if {$debug} { puts "Not in above situation, so NOTICE" }
            set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $mergedSinksType]] $refCLKBufferCelltype $refBufferCelltype]
            set toAddCelltype2 [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 3 $rangeOfDriveCapacityForAdd 1 $refCelltype $cellRegExp ];
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1]
              if {$debug} {puts "$driveCelltype - $toChangeCelltype2"}
              set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname];
              lappend fixedList_one2more [concat "mlb:in_8:2" "DA_[fm $off]" ${toChangeCelltype2}_$toAddCelltype2 $allInfoList]
              if {$debug} {puts "test : mlb:in_8:2"}
              set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
              set cmd2 [list $cmd_DA_driveInst $cmd_DA_add]
            } else {
              lappend fixedList_one2more [concat "mlb:in_8:4" "A_[fm $off]" $toAddCelltype2 $allInfoList]
              set cmd2 [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
            }
          }
        } elseif {$driveCellClass in {buffer inverter CLKbuffer CLKinverter} && $mergedSinksType in {delay logic CLKlogic}} {
          set locOffSink 0.6 ;
          set off $locOffSink
          if {$debug} { puts "$distanceOfdrive2CenterPtOfSinks $driveCelltype $sinkCelltype [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] [lindex $violValue_drivePin_loadPin_numSinks_sinks 2]" }
          set refVTweightList [eo [regexp CLK $driveCellClass] $clkNeedVtWeightList $normalNeedVtWeightList]
          set ifHaveFasterVT [re [la [strategy_changeVT $driveCelltype $refVTweightList $rangeOfVtSpeed $cellRegExp 1] $driveCelltype]]
          if {$debug} {puts "if have faster vt: $ifHaveFasterVT"}
          set ifHaveSlowerVT 0
          set ifHaveLargerCapacity [re [la [strategy_changeDriveCapacity $driveCelltype 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1] $driveCelltype]]
          if {$debug} {puts "if have larger capacity: $ifHaveLargerCapacity"}
          set ifHaveSmallerCapacity 0
          if {!$ifHaveFasterVT && !$ifHaveLargerCapacity} {
            lappend skippedList_one2more [concat "mbl:in_1:1" "NFL" $allInfoList]
          } elseif {!$ifHaveFasterVT} {
            lappend skippedList_one2more [concat "mbl:in_1:2" "NF" $allInfoList]
          } elseif {!$ifHaveLargerCapacity} {
            lappend skippedList_one2more [concat "mbl:in_1:3" "NL" $allInfoList]
          }
          if {$violnum < -0.2 && $distanceOfdrive2CenterPtOfSinks < 20 || \
              $violnum < -0.1 && $distanceOfdrive2CenterPtOfSinks < 15 || \
              $violnum < -0.07 && $distanceOfdrive2CenterPtOfSinks < 10 || \
              $violnum < -0.03 && $distanceOfdrive2CenterPtOfSinks < 5 \
                } { ;
            if {[expr $ifHaveFasterVT || $ifHaveLargerCapacity] && [expr $driveCapacity <= 4 || [expr $driveCapacity - $sinkCapacity] < 0]} {
              if {$debug} { puts "------" }
              set toChangeCelltype2 [eo $ifHaveFasterVT [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1] $driveCelltype]
              if {$debug} { puts "mbl:in_1:1 FS changeVT : $toChangeCelltype2" }
              set toChangeCelltype2 [eo $ifHaveLargerCapacity [strategy_changeDriveCapacity $toChangeCelltype2 0 [eo [expr $driveCapacity <= 2] 2 1] $rangeOfDriveCapacityForChange $cellRegExp 1] $toChangeCelltype2]
              if {$debug} { puts "mbl:in_1:1 FS changeDrive : $toChangeCelltype2" }
              lappend fixedList_one2more [concat "mbl:in_1:1" "FS" $toChangeCelltype2 $allInfoList]
              set cmd2 [print_ecoCommand -type change -cell $toChangeCelltype2 -inst $driveInstname]
            } else {
              lappend cantChangeList_one2more [concat "mbl:in_1:1" "S" $allInfoList]
              set cmd2 "cantChange"
            }
          } elseif {$ifHaveFasterVT && $canChangeVT && [expr $violnum >= -0.006 || \
                     $violnum >= -0.01 && $distanceOfdrive2CenterPtOfSinks > [expr $unitOfNetLength  * 10 ] || \
                     $violnum >= -0.02 && $distanceOfdrive2CenterPtOfSinks > [expr $unitOfNetLength  * 20 ] \
                     ]} { ;
            if {$debug} { puts "in 1: only change VT" }
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {[regexp -- {0x0:3} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "mbl:in_2:1" "V" $allInfoList]
              set cmd2 "cantChange"
            } elseif {[regexp -- {0x0:4} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "mbl:in_2:2" "F" $allInfoList]
              set cmd2 "cantChange"
            } else {
              lappend fixedList_one2more [concat "mbl:in_2:3" "T" $toChangeCelltype2 $allInfoList]
              set cmd2 [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]
            }
          } elseif {$ifHaveLargerCapacity && $canChangeDriveCapacity && $violnum >= -0.05 && $distanceOfdrive2CenterPtOfSinks <= [expr $unitOfNetLength * 1.7]} { ;
            if {$debug} { puts "in 2: only change DriveCapacity" }
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {$debug} { puts $toChangeCelltype2 }
            if {$driveCapacity == 0.5} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 3 $rangeOfDriveCapacityForChange $cellRegExp 1]
            } elseif {$driveCapacity in {1 2}} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1]
            } elseif {$driveCapacity >= 3} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 1 $rangeOfDriveCapacityForChange $cellRegExp 1]
            }
            if {[regexp -- {0x0:3} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "mbl:in_4:1" "O" $allInfoList]
              set cmd2 "cantChange"
            } else {
              lappend fixedList_one2more [concat "mbl:in_4:2" "D" $toChangeCelltype2 $allInfoList]
              set cmd2 [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]
            }
          } elseif {$ifHaveLargerCapacity && $canChangeVTandDriveCapacity && [expr  [expr  $violnum >= -0.07 && $distanceOfdrive2CenterPtOfSinks <= [expr $unitOfNetLength * 2.9] ||  $violnum >= -0.11 && $distanceOfdrive2CenterPtOfSinks <= [expr $unitOfNetLength * 1.8]] || \
                                                                                    [expr $violnum >= -0.04  && $distanceOfdrive2CenterPtOfSinks <= [expr $unitOfNetLength * 1.8] && $numSinks > 15] ]} { ;
            if {$debug} { puts "in 3: change VT and DriveCapacity" }
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {[regexp -- {0x0:3} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "mbl:in_5:1" "V" $allInfoList]
              set cmd2 "cantChange"
            } elseif {[regexp -- {0x0:4} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "mbl:in_5:2" "F" $allInfoList]
              set cmd2 "cantChange"
            } else {
              if {$driveCapacity <= 1} {
                set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1]
              } elseif {$driveCapacity >= 2} {
                set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 1 $rangeOfDriveCapacityForChange $cellRegExp 1]
              }
              if {[regexp -- {0x0:3} $toChangeCelltype2]} {
                lappend cantChangeList_one2more [concat "mbl:in_5:3" "O" $allInfoList]
                set cmd2 "cantChange"
              } else {
                lappend fixedList_one2more [concat "mbl:in_5:4" "TD" $toChangeCelltype2 $allInfoList]
                set cmd2 [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]
              }
            }
          } elseif {$canAddRepeater && $violnum < -0.08  && [expr  $violnum >= -0.14 && $distanceOfdrive2CenterPtOfSinks < [expr $unitOfNetLength * 6] && $distanceOfdrive2CenterPtOfSinks > [expr $unitOfNetLength * 0.3] && $numSinks <= 7 || \
                                                                   $violnum >= -0.14 && $distanceOfdrive2CenterPtOfSinks < [expr $unitOfNetLength * 3.5] && $numSinks > 7]} { ;
            if {$debug} { puts "in 4: add Repeater" }
            set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $mergedSinksType]] $refCLKBufferCelltype $refBufferCelltype]
            set toAddCelltype2 [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 2 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ;
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1]
              if {$debug} {puts "$driveCelltype - $toChangeCelltype2"}
              set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname];
              lappend fixedList_one2more [concat "mbl:in_6:2" "DA_[fm $off]" ${toChangeCelltype2}_$toAddCelltype2 $allInfoList]
              set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
              set cmd2 [list $cmd_DA_driveInst $cmd_DA_add]
            } else {
              lappend fixedList_one2more [concat "mbl:in_6:4" "A_[fm $off]" $toAddCelltype2 $allInfoList]
              set cmd2 [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
            }
          } elseif {$canAddRepeater && $violnum < -0.17 && $distanceOfdrive2CenterPtOfSinks > [expr $unitOfNetLength * 2.1]} { ;
            if {$debug} { puts "in 5: add Repeater refDriver, uncertainly, conservative" }
            if {$debug} { puts "Not in above situation, so NOTICE" }
            set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $mergedSinksType]] $refCLKBufferCelltype $refBufferCelltype]
            set toAddCelltype2 [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 4 $rangeOfDriveCapacityForAdd 1 $refCelltype $cellRegExp ];
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 6 0 $rangeOfDriveCapacityForChange $cellRegExp 1]
              if {$debug} {puts "$driveCelltype - $toChangeCelltype2"}
              set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname];
              lappend fixedList_one2more [concat "mbl:in_7:2" "DA_[fm $off]" ${toChangeCelltype2}_$toAddCelltype2 $allInfoList]
              if {$debug} {puts "test : mbl:in_7:2"}
              set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
              set cmd2 [list $cmd_DA_driveInst $cmd_DA_add]
            } else {
              if {$ifHaveFasterVT} {
                set cmd_TA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]
                lappend fixedList_one2more [concat "mbl:in_7:3" "TA_[fm $off]" $toAddCelltype2 $allInfoList]
                set cmd_TA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
                set cmd2 [list $cmd_TA_driveInst $cmd_TA_add]
              } else {
                lappend fixedList_one2more [concat "mbl:in_7:4" "A_[fm $off]" $toAddCelltype2 $allInfoList]
                set cmd2 [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
              }
            }
          } elseif {$canAddRepeater && $violnum < -0.04 && $violnum > -0.16 && $distanceOfdrive2CenterPtOfSinks < [expr $unitOfNetLength * $off]} {;
            set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $mergedSinksType]] $refCLKBufferCelltype $refBufferCelltype]
            set toAddCelltype2 [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 2 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ;
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 6 0 $rangeOfDriveCapacityForChange $cellRegExp 1] ;
              if {$debug} {puts "$driveCelltype - $toChangeCelltype2"}
              set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname];
              lappend fixedList_one2more [concat "mbl:in_6:2" "DA_[fm $off]" ${toChangeCelltype2}_$toAddCelltype2 $allInfoList]
              set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
              set cmd2 [list $cmd_DA_driveInst $cmd_DA_add]
            } else {
              lappend fixedList_one2more [concat "mbl:in_6:4" "A_[fm $off]" $toAddCelltype2 $allInfoList]
              set cmd2 [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
            }
          } else { ;
            if {$debug} { puts "in 5: add Repeater refDriver, uncertainly, conservative" }
            if {$debug} { puts "Not in above situation, so NOTICE" }
            set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $mergedSinksType]] $refCLKBufferCelltype $refBufferCelltype]
            set toAddCelltype2 [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 3 $rangeOfDriveCapacityForAdd 1 $refCelltype $cellRegExp ];
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1]
              if {$debug} {puts "$driveCelltype - $toChangeCelltype2"}
              set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname];
              lappend fixedList_one2more [concat "mbl:in_8:2" "DA_[fm $off]" ${toChangeCelltype2}_$toAddCelltype2 $allInfoList]
              if {$debug} {puts "test : mbl:in_8:2"}
              set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
              set cmd2 [list $cmd_DA_driveInst $cmd_DA_add]
            } else {
              lappend fixedList_one2more [concat "mbl:in_8:4" "A_[fm $off]" $toAddCelltype2 $allInfoList]
              set cmd2 [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
            }
          }
        } elseif {$driveCellClass in {buffer inverter CLKbuffer CLKinverter} && $mergedSinksType in {sequential}} {
          set locOffSink 0.6 ;
          set off $locOffSink
          if {$debug} { puts "$distanceOfdrive2CenterPtOfSinks $driveCelltype $sinkCelltype [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] [lindex $violValue_drivePin_loadPin_numSinks_sinks 2]" }
          set refVTweightList [eo [regexp CLK $driveCellClass] $clkNeedVtWeightList $normalNeedVtWeightList]
          set ifHaveFasterVT [re [la [strategy_changeVT $driveCelltype $refVTweightList $rangeOfVtSpeed $cellRegExp 1] $driveCelltype]]
          if {$debug} {puts "if have faster vt: $ifHaveFasterVT"}
          set ifHaveSlowerVT 0
          set ifHaveLargerCapacity [re [la [strategy_changeDriveCapacity $driveCelltype 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1] $driveCelltype]]
          if {$debug} {puts "if have larger capacity: $ifHaveLargerCapacity"}
          set ifHaveSmallerCapacity 0
          if {!$ifHaveFasterVT && !$ifHaveLargerCapacity} {
            lappend skippedList_one2more [concat "mbs:in_1:1" "NFL" $allInfoList]
          } elseif {!$ifHaveFasterVT} {
            lappend skippedList_one2more [concat "mbs:in_1:2" "NF" $allInfoList]
          } elseif {!$ifHaveLargerCapacity} {
            lappend skippedList_one2more [concat "mbs:in_1:3" "NL" $allInfoList]
          }
          if {$violnum < -0.2 && $distanceOfdrive2CenterPtOfSinks < 20 || \
              $violnum < -0.1 && $distanceOfdrive2CenterPtOfSinks < 15 || \
              $violnum < -0.07 && $distanceOfdrive2CenterPtOfSinks < 10 || \
              $violnum < -0.03 && $distanceOfdrive2CenterPtOfSinks < 5 \
                } { ;
            if {[expr $ifHaveFasterVT || $ifHaveLargerCapacity] && [expr $driveCapacity <= 4 || [expr $driveCapacity - $sinkCapacity] < 0]} {
              if {$debug} { puts "------" }
              set toChangeCelltype2 [eo $ifHaveFasterVT [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1] $driveCelltype]
              if {$debug} { puts "mbs:in_1:1 FS changeVT : $toChangeCelltype2" }
              set toChangeCelltype2 [eo $ifHaveLargerCapacity [strategy_changeDriveCapacity $toChangeCelltype2 0 [eo [expr $driveCapacity <= 2] 2 1] $rangeOfDriveCapacityForChange $cellRegExp 1] $toChangeCelltype2]
              if {$debug} { puts "mbs:in_1:1 FS changeDrive : $toChangeCelltype2" }
              lappend fixedList_one2more [concat "mbs:in_1:1" "FS" $toChangeCelltype2 $allInfoList]
              set cmd2 [print_ecoCommand -type change -cell $toChangeCelltype2 -inst $driveInstname]
            } else {
              lappend cantChangeList_one2more [concat "mbs:in_1:1" "S" $allInfoList]
              set cmd2 "cantChange"
            }
          } elseif {$ifHaveFasterVT && $canChangeVT && [expr $violnum >= -0.006 || \
                     $violnum >= -0.01 && $distanceOfdrive2CenterPtOfSinks > [expr $unitOfNetLength  * 10 ] || \
                     $violnum >= -0.02 && $distanceOfdrive2CenterPtOfSinks > [expr $unitOfNetLength  * 20 ] \
                     ]} { ;
            if {$debug} { puts "in 1: only change VT" }
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {[regexp -- {0x0:3} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "mbs:in_2:1" "V" $allInfoList]
              set cmd2 "cantChange"
            } elseif {[regexp -- {0x0:4} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "mbs:in_2:2" "F" $allInfoList]
              set cmd2 "cantChange"
            } else {
              lappend fixedList_one2more [concat "mbs:in_2:3" "T" $toChangeCelltype2 $allInfoList]
              set cmd2 [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]
            }
          } elseif {$ifHaveLargerCapacity && $canChangeDriveCapacity && $violnum >= -0.05 && $distanceOfdrive2CenterPtOfSinks <= [expr $unitOfNetLength * 1.7]} { ;
            if {$debug} { puts "in 2: only change DriveCapacity" }
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {$debug} { puts $toChangeCelltype2 }
            if {$driveCapacity == 0.5} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 3 $rangeOfDriveCapacityForChange $cellRegExp 1]
            } elseif {$driveCapacity in {1 2}} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1]
            } elseif {$driveCapacity >= 3} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 1 $rangeOfDriveCapacityForChange $cellRegExp 1]
            }
            if {[regexp -- {0x0:3} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "mbs:in_4:1" "O" $allInfoList]
              set cmd2 "cantChange"
            } else {
              lappend fixedList_one2more [concat "mbs:in_4:2" "D" $toChangeCelltype2 $allInfoList]
              set cmd2 [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]
            }
          } elseif {$ifHaveLargerCapacity && $canChangeVTandDriveCapacity && [expr  [expr  $violnum >= -0.07 && $distanceOfdrive2CenterPtOfSinks <= [expr $unitOfNetLength * 2.9] ||  $violnum >= -0.11 && $distanceOfdrive2CenterPtOfSinks <= [expr $unitOfNetLength * 1.8]] || \
                                                                                    [expr $violnum >= -0.04  && $distanceOfdrive2CenterPtOfSinks <= [expr $unitOfNetLength * 1.8] && $numSinks > 15] ]} { ;
            if {$debug} { puts "in 3: change VT and DriveCapacity" }
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {[regexp -- {0x0:3} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "mbs:in_5:1" "V" $allInfoList]
              set cmd2 "cantChange"
            } elseif {[regexp -- {0x0:4} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "mbs:in_5:2" "F" $allInfoList]
              set cmd2 "cantChange"
            } else {
              if {$driveCapacity <= 1} {
                set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1]
              } elseif {$driveCapacity >= 2} {
                set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 1 $rangeOfDriveCapacityForChange $cellRegExp 1]
              }
              if {[regexp -- {0x0:3} $toChangeCelltype2]} {
                lappend cantChangeList_one2more [concat "mbs:in_5:3" "O" $allInfoList]
                set cmd2 "cantChange"
              } else {
                lappend fixedList_one2more [concat "mbs:in_5:4" "TD" $toChangeCelltype2 $allInfoList]
                set cmd2 [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]
              }
            }
          } elseif {$canAddRepeater && $violnum < -0.08  && [expr  $violnum >= -0.14 && $distanceOfdrive2CenterPtOfSinks < [expr $unitOfNetLength * 6] && $distanceOfdrive2CenterPtOfSinks > [expr $unitOfNetLength * 0.3] && $numSinks <= 7 || \
                                                                   $violnum >= -0.14 && $distanceOfdrive2CenterPtOfSinks < [expr $unitOfNetLength * 3.5] && $numSinks > 7]} { ;
            if {$debug} { puts "in 4: add Repeater" }
            set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $mergedSinksType]] $refCLKBufferCelltype $refBufferCelltype]
            set toAddCelltype2 [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 2 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ;
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1]
              if {$debug} {puts "$driveCelltype - $toChangeCelltype2"}
              set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname];
              lappend fixedList_one2more [concat "mbs:in_6:2" "DA_[fm $off]" ${toChangeCelltype2}_$toAddCelltype2 $allInfoList]
              set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
              set cmd2 [list $cmd_DA_driveInst $cmd_DA_add]
            } else {
              lappend fixedList_one2more [concat "mbs:in_6:4" "A_[fm $off]" $toAddCelltype2 $allInfoList]
              set cmd2 [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
            }
          } elseif {$canAddRepeater && $violnum < -0.17 && $distanceOfdrive2CenterPtOfSinks > [expr $unitOfNetLength * 2.1]} { ;
            if {$debug} { puts "in 5: add Repeater refDriver, uncertainly, conservative" }
            if {$debug} { puts "Not in above situation, so NOTICE" }
            set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $mergedSinksType]] $refCLKBufferCelltype $refBufferCelltype]
            set toAddCelltype2 [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 4 $rangeOfDriveCapacityForAdd 1 $refCelltype $cellRegExp ];
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 6 0 $rangeOfDriveCapacityForChange $cellRegExp 1]
              if {$debug} {puts "$driveCelltype - $toChangeCelltype2"}
              set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname];
              lappend fixedList_one2more [concat "mbs:in_7:2" "DA_[fm $off]" ${toChangeCelltype2}_$toAddCelltype2 $allInfoList]
              if {$debug} {puts "test : mbs:in_7:2"}
              set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
              set cmd2 [list $cmd_DA_driveInst $cmd_DA_add]
            } else {
              if {$ifHaveFasterVT} {
                set cmd_TA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]
                lappend fixedList_one2more [concat "mbs:in_7:3" "TA_[fm $off]" $toAddCelltype2 $allInfoList]
                set cmd_TA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
                set cmd2 [concat $cmd_TA_driveInst $cmd_TA_add]
              } else {
                lappend fixedList_one2more [concat "mbs:in_7:4" "A_[fm $off]" $toAddCelltype2 $allInfoList]
                set cmd2 [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
              }
            }
          } elseif {$canAddRepeater && $violnum < -0.04 && $violnum > -0.16 && $distanceOfdrive2CenterPtOfSinks < [expr $unitOfNetLength * $off]} {;
            set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $mergedSinksType]] $refCLKBufferCelltype $refBufferCelltype]
            set toAddCelltype2 [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 2 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ;
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1] ;
              if {$debug} {puts "$driveCelltype - $toChangeCelltype2"}
              set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname];
              lappend fixedList_one2more [concat "mbs:in_6:2" "DA_[fm $off]" ${toChangeCelltype2}_$toAddCelltype2 $allInfoList]
              set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
              set cmd2 [list $cmd_DA_driveInst $cmd_DA_add]
            } else {
              lappend fixedList_one2more [concat "mbs:in_6:4" "A_[fm $off]" $toAddCelltype2 $allInfoList]
              set cmd2 [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
            }
          } else { ;
            if {$debug} { puts "in 5: add Repeater refDriver, uncertainly, conservative" }
            if {$debug} { puts "Not in above situation, so NOTICE" }
            set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $mergedSinksType]] $refCLKBufferCelltype $refBufferCelltype]
            set toAddCelltype2 [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 3 $rangeOfDriveCapacityForAdd 1 $refCelltype $cellRegExp ];
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1]
              if {$debug} {puts "$driveCelltype - $toChangeCelltype2"}
              set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname];
              lappend fixedList_one2more [concat "mbs:in_8:2" "DA_[fm $off]" ${toChangeCelltype2}_$toAddCelltype2 $allInfoList]
              if {$debug} {puts "test : mbs:in_8:2"}
              set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
              set cmd2 [list $cmd_DA_driveInst $cmd_DA_add]
            } else {
              lappend fixedList_one2more [concat "mbs:in_8:4" "A_[fm $off]" $toAddCelltype2 $allInfoList]
              set cmd2 [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
            }
          }
        } elseif {$driveCellClass in {sequential} && $mergedSinksType in {buffer inverter CLKbuffer CLKinverter}} {
          set locOffSink 0.9 ;
          set off $locOffSink
          if {$debug} { puts "$distanceOfdrive2CenterPtOfSinks $driveCelltype $sinkCelltype [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] [lindex $violValue_drivePin_loadPin_numSinks_sinks 2]" }
          set refVTweightList [eo [regexp CLK $driveCellClass] $clkNeedVtWeightList $normalNeedVtWeightList]
          set ifHaveFasterVT [re [la [strategy_changeVT $driveCelltype $refVTweightList $rangeOfVtSpeed $cellRegExp 1] $driveCelltype]]
          if {$debug} {puts "if have faster vt: $ifHaveFasterVT"}
          set ifHaveSlowerVT 0
          set ifHaveLargerCapacity [re [la [strategy_changeDriveCapacity $driveCelltype 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1] $driveCelltype]]
          if {$debug} {puts "if have larger capacity: $ifHaveLargerCapacity"}
          set ifHaveSmallerCapacity 0
          if {!$ifHaveFasterVT && !$ifHaveLargerCapacity} {
            lappend skippedList_one2more [concat "msb:in_1:1" "NFL" $allInfoList]
          } elseif {!$ifHaveFasterVT} {
            lappend skippedList_one2more [concat "msb:in_1:2" "NF" $allInfoList]
          } elseif {!$ifHaveLargerCapacity} {
            lappend skippedList_one2more [concat "msb:in_1:3" "NL" $allInfoList]
          }
          if {$violnum < -0.2 && $distanceOfdrive2CenterPtOfSinks < 15 || \
              $violnum < -0.1 && $distanceOfdrive2CenterPtOfSinks < 7 || \
              $violnum < -0.07 && $distanceOfdrive2CenterPtOfSinks < 4 || \
              $violnum < -0.03 && $distanceOfdrive2CenterPtOfSinks < 1 \
                } { ;
            if {[expr $ifHaveFasterVT || $ifHaveLargerCapacity] && [expr $driveCapacity <= 4 || [expr $driveCapacity - $sinkCapacity] < 0]} {
              if {$debug} { puts "------" }
              set toChangeCelltype2 [eo $ifHaveFasterVT [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1] $driveCelltype]
              if {$debug} { puts "msb:in_1:1 FS changeVT : $toChangeCelltype2" }
              set toChangeCelltype2 [eo $ifHaveLargerCapacity [strategy_changeDriveCapacity $toChangeCelltype2 0 [eo [expr $driveCapacity <= 2] 2 1] $rangeOfDriveCapacityForChange $cellRegExp 1] $toChangeCelltype2]
              if {$debug} { puts "msb:in_1:1 FS changeDrive : $toChangeCelltype2" }
              lappend fixedList_one2more [concat "msb:in_1:1" "FS" $toChangeCelltype2 $allInfoList]
              set cmd2 [print_ecoCommand -type change -cell $toChangeCelltype2 -inst $driveInstname]
            } else {
              lappend cantChangeList_one2more [concat "msb:in_1:1" "S" $allInfoList]
              set cmd2 "cantChange"
            }
          } elseif {$ifHaveFasterVT && $canChangeVT && [expr $violnum >= -0.006 || \
                     $violnum >= -0.01 && $distanceOfdrive2CenterPtOfSinks > [expr $unitOfNetLength  * 10 ] || \
                     $violnum >= -0.02 && $distanceOfdrive2CenterPtOfSinks > [expr $unitOfNetLength  * 20 ] \
                     ]} { ;
            if {$debug} { puts "in 1: only change VT" }
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {[regexp -- {0x0:3} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "msb:in_2:1" "V" $allInfoList]
              set cmd2 "cantChange"
            } elseif {[regexp -- {0x0:4} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "msb:in_2:2" "F" $allInfoList]
              set cmd2 "cantChange"
            } else {
              lappend fixedList_one2more [concat "msb:in_2:3" "T" $toChangeCelltype2 $allInfoList]
              set cmd2 [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]
            }
          } elseif {$ifHaveLargerCapacity && $canChangeDriveCapacity && $violnum >= -0.03 && $distanceOfdrive2CenterPtOfSinks <= [expr $unitOfNetLength * 1.2]} { ;
            if {$debug} { puts "in 2: only change DriveCapacity" }
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {$debug} { puts $toChangeCelltype2 }
            if {$driveCapacity == 0.5} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 3 $rangeOfDriveCapacityForChange $cellRegExp 1]
            } elseif {$driveCapacity in {1 2}} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1]
            } elseif {$driveCapacity >= 3} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 1 $rangeOfDriveCapacityForChange $cellRegExp 1]
            }
            if {[regexp -- {0x0:3} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "msb:in_4:1" "O" $allInfoList]
              set cmd2 "cantChange"
            } else {
              lappend fixedList_one2more [concat "msb:in_4:2" "D" $toChangeCelltype2 $allInfoList]
              set cmd2 [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]
            }
          } elseif {$ifHaveLargerCapacity && $canChangeVTandDriveCapacity && [expr  [expr  $violnum >= -0.04 && $distanceOfdrive2CenterPtOfSinks <= [expr $unitOfNetLength * 2.2] ||  $violnum >= -0.11 && $distanceOfdrive2CenterPtOfSinks <= [expr $unitOfNetLength * 1.4]] || \
                                                                                    [expr $violnum >= -0.02  && $distanceOfdrive2CenterPtOfSinks <= [expr $unitOfNetLength * 1.2] && $numSinks > 15] ]} { ;
            if {$debug} { puts "in 3: change VT and DriveCapacity" }
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {[regexp -- {0x0:3} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "msb:in_5:1" "V" $allInfoList]
              set cmd2 "cantChange"
            } elseif {[regexp -- {0x0:4} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "msb:in_5:2" "F" $allInfoList]
              set cmd2 "cantChange"
            } else {
              if {$driveCapacity <= 1} {
                set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1]
              } elseif {$driveCapacity >= 2} {
                set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 1 $rangeOfDriveCapacityForChange $cellRegExp 1]
              }
              if {[regexp -- {0x0:3} $toChangeCelltype2]} {
                lappend cantChangeList_one2more [concat "msb:in_5:3" "O" $allInfoList]
                set cmd2 "cantChange"
              } else {
                lappend fixedList_one2more [concat "msb:in_5:4" "TD" $toChangeCelltype2 $allInfoList]
                set cmd2 [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]
              }
            }
          } elseif {$canAddRepeater && $violnum < -0.08  && [expr  $violnum >= -0.1 && $distanceOfdrive2CenterPtOfSinks < [expr $unitOfNetLength * 4] && $distanceOfdrive2CenterPtOfSinks > [expr $unitOfNetLength * 0.3] && $numSinks <= 5 || \
                                                                   $violnum >= -0.1 && $distanceOfdrive2CenterPtOfSinks < [expr $unitOfNetLength * 2] && $numSinks > 5]} { ;
            if {$debug} { puts "in 4: add Repeater" }
            set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $mergedSinksType]] $refCLKBufferCelltype $refBufferCelltype]
            set toAddCelltype2 [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 2 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ;
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1]
              if {$debug} {puts "$driveCelltype - $toChangeCelltype2"}
              set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname];
              lappend fixedList_one2more [concat "msb:in_6:2" "DA_[fm $off]" ${toChangeCelltype2}_$toAddCelltype2 $allInfoList]
              set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
              set cmd2 [list $cmd_DA_driveInst $cmd_DA_add]
            } else {
              lappend fixedList_one2more [concat "msb:in_6:4" "A_[fm $off]" $toAddCelltype2 $allInfoList]
              set cmd2 [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
            }
          } elseif {$canAddRepeater && $violnum < -0.12 && $distanceOfdrive2CenterPtOfSinks > [expr $unitOfNetLength * 2.5]} { ;
            if {$debug} { puts "in 5: add Repeater refDriver, uncertainly, conservative" }
            if {$debug} { puts "Not in above situation, so NOTICE" }
            set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $mergedSinksType]] $refCLKBufferCelltype $refBufferCelltype]
            set toAddCelltype2 [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 4 $rangeOfDriveCapacityForAdd 1 $refCelltype $cellRegExp ];
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 8 0 $rangeOfDriveCapacityForChange $cellRegExp 1]
              if {$debug} {puts "$driveCelltype - $toChangeCelltype2"}
              set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname];
              lappend fixedList_one2more [concat "msb:in_7:2" "DA_[fm $off]" ${toChangeCelltype2}_$toAddCelltype2 $allInfoList]
              if {$debug} {puts "test : msb:in_7:2"}
              set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
              set cmd2 [list $cmd_DA_driveInst $cmd_DA_add]
            } else {
              if {$ifHaveFasterVT} {
                set cmd_TA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]
                lappend fixedList_one2more [concat "msb:in_7:3" "TA_[fm $off]" $toAddCelltype2 $allInfoList]
                set cmd_TA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
                set cmd2 [concat $cmd_TA_driveInst $cmd_TA_add]
              } else {
                lappend fixedList_one2more [concat "msb:in_7:4" "A_[fm $off]" $toAddCelltype2 $allInfoList]
                set cmd2 [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
              }
            }
          } elseif {$canAddRepeater && $violnum < -0.04 && $violnum > -0.1 && $distanceOfdrive2CenterPtOfSinks < [expr $unitOfNetLength * 0.6]} {;
            set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $mergedSinksType]] $refCLKBufferCelltype $refBufferCelltype]
            set toAddCelltype2 [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 2 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ;
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 8 0 $rangeOfDriveCapacityForChange $cellRegExp 1] ;
              if {$debug} {puts "$driveCelltype - $toChangeCelltype2"}
              set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname];
              lappend fixedList_one2more [concat "msb:in_6:2" "DA_[fm $off]" ${toChangeCelltype2}_$toAddCelltype2 $allInfoList]
              set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
              set cmd2 [list $cmd_DA_driveInst $cmd_DA_add]
            } else {
              lappend fixedList_one2more [concat "msb:in_6:4" "A_[fm $off]" $toAddCelltype2 $allInfoList]
              set cmd2 [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
            }
          } else { ;
            if {$debug} { puts "in 5: add Repeater refDriver, uncertainly, conservative" }
            if {$debug} { puts "Not in above situation, so NOTICE" }
            set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $mergedSinksType]] $refCLKBufferCelltype $refBufferCelltype]
            set toAddCelltype2 [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 3 $rangeOfDriveCapacityForAdd 1 $refCelltype $cellRegExp ];
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1]
              if {$debug} {puts "$driveCelltype - $toChangeCelltype2"}
              set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname];
              lappend fixedList_one2more [concat "msb:in_8:2" "DA_[fm $off]" ${toChangeCelltype2}_$toAddCelltype2 $allInfoList]
              if {$debug} {puts "test : msb:in_8:2"}
              set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
              set cmd2 [list $cmd_DA_driveInst $cmd_DA_add]
            } else {
              lappend fixedList_one2more [concat "msb:in_8:4" "A_[fm $off]" $toAddCelltype2 $allInfoList]
              set cmd2 [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
            }
          }
        } elseif {$driveCellClass in {delay logic CLKlogic} && $mergedSinksType in {sequential}} {
          set locOffSink 0.8 ;
          set off $locOffSink
          if {$debug} { puts "$distanceOfdrive2CenterPtOfSinks $driveCelltype $sinkCelltype [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] [lindex $violValue_drivePin_loadPin_numSinks_sinks 2]" }
          set refVTweightList [eo [regexp CLK $driveCellClass] $clkNeedVtWeightList $normalNeedVtWeightList]
          set ifHaveFasterVT [re [la [strategy_changeVT $driveCelltype $refVTweightList $rangeOfVtSpeed $cellRegExp 1] $driveCelltype]]
          if {$debug} {puts "if have faster vt: $ifHaveFasterVT"}
          set ifHaveSlowerVT 0
          set ifHaveLargerCapacity [re [la [strategy_changeDriveCapacity $driveCelltype 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1] $driveCelltype]]
          if {$debug} {puts "if have larger capacity: $ifHaveLargerCapacity"}
          set ifHaveSmallerCapacity 0
          if {!$ifHaveFasterVT && !$ifHaveLargerCapacity} {
            lappend skippedList_one2more [concat "mls:in_1:1" "NFL" $allInfoList]
          } elseif {!$ifHaveFasterVT} {
            lappend skippedList_one2more [concat "mls:in_1:2" "NF" $allInfoList]
          } elseif {!$ifHaveLargerCapacity} {
            lappend skippedList_one2more [concat "mls:in_1:3" "NL" $allInfoList]
          }
          if {$violnum < -0.2 && $distanceOfdrive2CenterPtOfSinks < 15 || \
              $violnum < -0.1 && $distanceOfdrive2CenterPtOfSinks < 10 || \
              $violnum < -0.07 && $distanceOfdrive2CenterPtOfSinks < 7 || \
              $violnum < -0.03 && $distanceOfdrive2CenterPtOfSinks < 1 \
                } { ;
            if {[expr $ifHaveFasterVT || $ifHaveLargerCapacity] && [expr $driveCapacity <= 4 || [expr $driveCapacity - $sinkCapacity] < 0]} {
              if {$debug} { puts "------" }
              set toChangeCelltype2 [eo $ifHaveFasterVT [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1] $driveCelltype]
              if {$debug} { puts "mls:in_1:1 FS changeVT : $toChangeCelltype2" }
              set toChangeCelltype2 [eo $ifHaveLargerCapacity [strategy_changeDriveCapacity $toChangeCelltype2 0 [eo [expr $driveCapacity <= 2] 2 1] $rangeOfDriveCapacityForChange $cellRegExp 1] $toChangeCelltype2]
              if {$debug} { puts "mls:in_1:1 FS changeDrive : $toChangeCelltype2" }
              lappend fixedList_one2more [concat "mls:in_1:1" "FS" $toChangeCelltype2 $allInfoList]
              set cmd2 [print_ecoCommand -type change -cell $toChangeCelltype2 -inst $driveInstname]
            } else {
              lappend cantChangeList_one2more [concat "mls:in_1:1" "S" $allInfoList]
              set cmd2 "cantChange"
            }
          } elseif {$ifHaveFasterVT && $canChangeVT && [expr $violnum >= -0.006 || \
                     $violnum >= -0.01 && $distanceOfdrive2CenterPtOfSinks > [expr $unitOfNetLength  * 10 ] || \
                     $violnum >= -0.02 && $distanceOfdrive2CenterPtOfSinks > [expr $unitOfNetLength  * 20 ] \
                     ]} { ;
            if {$debug} { puts "in 1: only change VT" }
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {[regexp -- {0x0:3} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "mls:in_2:1" "V" $allInfoList]
              set cmd2 "cantChange"
            } elseif {[regexp -- {0x0:4} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "mls:in_2:2" "F" $allInfoList]
              set cmd2 "cantChange"
            } else {
              lappend fixedList_one2more [concat "mls:in_2:3" "T" $toChangeCelltype2 $allInfoList]
              set cmd2 [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]
            }
          } elseif {$ifHaveLargerCapacity && $canChangeDriveCapacity && $violnum >= -0.03 && $distanceOfdrive2CenterPtOfSinks <= [expr $unitOfNetLength * 1.2]} { ;
            if {$debug} { puts "in 2: only change DriveCapacity" }
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {$debug} { puts $toChangeCelltype2 }
            if {$driveCapacity == 0.5} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 3 $rangeOfDriveCapacityForChange $cellRegExp 1]
            } elseif {$driveCapacity in {1 2}} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1]
            } elseif {$driveCapacity >= 3} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 1 $rangeOfDriveCapacityForChange $cellRegExp 1]
            }
            if {[regexp -- {0x0:3} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "mls:in_4:1" "O" $allInfoList]
              set cmd2 "cantChange"
            } else {
              lappend fixedList_one2more [concat "mls:in_4:2" "D" $toChangeCelltype2 $allInfoList]
              set cmd2 [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]
            }
          } elseif {$ifHaveLargerCapacity && $canChangeVTandDriveCapacity && [expr  [expr  $violnum >= -0.04 && $distanceOfdrive2CenterPtOfSinks <= [expr $unitOfNetLength * 2.2] ||  $violnum >= -0.11 && $distanceOfdrive2CenterPtOfSinks <= [expr $unitOfNetLength * 1.4]] || \
                                                                                    [expr $violnum >= -0.02  && $distanceOfdrive2CenterPtOfSinks <= [expr $unitOfNetLength * 1.2] && $numSinks > 15] ]} { ;
            if {$debug} { puts "in 3: change VT and DriveCapacity" }
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {[regexp -- {0x0:3} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "mls:in_5:1" "V" $allInfoList]
              set cmd2 "cantChange"
            } elseif {[regexp -- {0x0:4} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "mls:in_5:2" "F" $allInfoList]
              set cmd2 "cantChange"
            } else {
              if {$driveCapacity <= 1} {
                set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1]
              } elseif {$driveCapacity >= 2} {
                set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 1 $rangeOfDriveCapacityForChange $cellRegExp 1]
              }
              if {[regexp -- {0x0:3} $toChangeCelltype2]} {
                lappend cantChangeList_one2more [concat "mls:in_5:3" "O" $allInfoList]
                set cmd2 "cantChange"
              } else {
                lappend fixedList_one2more [concat "mls:in_5:4" "TD" $toChangeCelltype2 $allInfoList]
                set cmd2 [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]
              }
            }
          } elseif {$canAddRepeater && $violnum < -0.08  && [expr  $violnum >= -0.1 && $distanceOfdrive2CenterPtOfSinks < [expr $unitOfNetLength * 4] && $distanceOfdrive2CenterPtOfSinks > [expr $unitOfNetLength * 0.3] && $numSinks <= 5 || \
                                                                   $violnum >= -0.1 && $distanceOfdrive2CenterPtOfSinks < [expr $unitOfNetLength * 2] && $numSinks > 5]} { ;
            if {$debug} { puts "in 4: add Repeater" }
            set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $mergedSinksType]] $refCLKBufferCelltype $refBufferCelltype]
            set toAddCelltype2 [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 2 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ;
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1]
              if {$debug} {puts "$driveCelltype - $toChangeCelltype2"}
              set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname];
              lappend fixedList_one2more [concat "mls:in_6:2" "DA_[fm $off]" ${toChangeCelltype2}_$toAddCelltype2 $allInfoList]
              set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
              set cmd2 [list $cmd_DA_driveInst $cmd_DA_add]
            } else {
              lappend fixedList_one2more [concat "mls:in_6:4" "A_[fm $off]" $toAddCelltype2 $allInfoList]
              set cmd2 [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
            }
          } elseif {$canAddRepeater && $violnum < -0.12 && $distanceOfdrive2CenterPtOfSinks > [expr $unitOfNetLength * 2.5]} { ;
            if {$debug} { puts "in 5: add Repeater refDriver, uncertainly, conservative" }
            if {$debug} { puts "Not in above situation, so NOTICE" }
            set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $mergedSinksType]] $refCLKBufferCelltype $refBufferCelltype]
            set toAddCelltype2 [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 4 $rangeOfDriveCapacityForAdd 1 $refCelltype $cellRegExp ];
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 8 0 $rangeOfDriveCapacityForChange $cellRegExp 1]
              if {$debug} {puts "$driveCelltype - $toChangeCelltype2"}
              set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname];
              lappend fixedList_one2more [concat "mls:in_7:2" "DA_[fm $off]" ${toChangeCelltype2}_$toAddCelltype2 $allInfoList]
              if {$debug} {puts "test : mls:in_7:2"}
              set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
              set cmd2 [list $cmd_DA_driveInst $cmd_DA_add]
            } else {
              if {$ifHaveFasterVT} {
                set cmd_TA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]
                lappend fixedList_one2more [concat "mls:in_7:3" "TA_[fm $off]" $toAddCelltype2 $allInfoList]
                set cmd_TA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
                set cmd2 [concat $cmd_TA_driveInst $cmd_TA_add]
              } else {
                lappend fixedList_one2more [concat "mls:in_7:4" "A_[fm $off]" $toAddCelltype2 $allInfoList]
                set cmd2 [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
              }
            }
          } elseif {$canAddRepeater && $violnum < -0.04 && $violnum > -0.1 && $distanceOfdrive2CenterPtOfSinks < [expr $unitOfNetLength * 0.6]} {;
            set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $mergedSinksType]] $refCLKBufferCelltype $refBufferCelltype]
            set toAddCelltype2 [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 2 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ;
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 8 0 $rangeOfDriveCapacityForChange $cellRegExp 1] ;
              if {$debug} {puts "$driveCelltype - $toChangeCelltype2"}
              set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname];
              lappend fixedList_one2more [concat "mls:in_6:2" "DA_[fm $off]" ${toChangeCelltype2}_$toAddCelltype2 $allInfoList]
              set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
              set cmd2 [list $cmd_DA_driveInst $cmd_DA_add]
            } else {
              lappend fixedList_one2more [concat "mls:in_6:4" "A_[fm $off]" $toAddCelltype2 $allInfoList]
              set cmd2 [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
            }
          } else { ;
            if {$debug} { puts "in 5: add Repeater refDriver, uncertainly, conservative" }
            if {$debug} { puts "Not in above situation, so NOTICE" }
            set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $mergedSinksType]] $refCLKBufferCelltype $refBufferCelltype]
            set toAddCelltype2 [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 3 $rangeOfDriveCapacityForAdd 1 $refCelltype $cellRegExp ];
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1]
              if {$debug} {puts "$driveCelltype - $toChangeCelltype2"}
              set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname];
              lappend fixedList_one2more [concat "mls:in_8:2" "DA_[fm $off]" ${toChangeCelltype2}_$toAddCelltype2 $allInfoList]
              if {$debug} {puts "test : mls:in_8:2"}
              set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
              set cmd2 [list $cmd_DA_driveInst $cmd_DA_add]
            } else {
              lappend fixedList_one2more [concat "mls:in_8:4" "A_[fm $off]" $toAddCelltype2 $allInfoList]
              set cmd2 [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
            }
          }
        } elseif {$driveCellClass in {sequential} && $mergedSinksType in {delay logic CLKlogic}} {
          set locOffSink 0.8 ;
          set off $locOffSink
          if {$debug} { puts "$distanceOfdrive2CenterPtOfSinks $driveCelltype $sinkCelltype [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] [lindex $violValue_drivePin_loadPin_numSinks_sinks 2]" }
          set refVTweightList [eo [regexp CLK $driveCellClass] $clkNeedVtWeightList $normalNeedVtWeightList]
          set ifHaveFasterVT [re [la [strategy_changeVT $driveCelltype $refVTweightList $rangeOfVtSpeed $cellRegExp 1] $driveCelltype]]
          if {$debug} {puts "if have faster vt: $ifHaveFasterVT"}
          set ifHaveSlowerVT 0
          set ifHaveLargerCapacity [re [la [strategy_changeDriveCapacity $driveCelltype 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1] $driveCelltype]]
          if {$debug} {puts "if have larger capacity: $ifHaveLargerCapacity"}
          set ifHaveSmallerCapacity 0
          if {!$ifHaveFasterVT && !$ifHaveLargerCapacity} {
            lappend skippedList_one2more [concat "msl:in_1:1" "NFL" $allInfoList]
          } elseif {!$ifHaveFasterVT} {
            lappend skippedList_one2more [concat "msl:in_1:2" "NF" $allInfoList]
          } elseif {!$ifHaveLargerCapacity} {
            lappend skippedList_one2more [concat "msl:in_1:3" "NL" $allInfoList]
          }
          if {$violnum < -0.2 && $distanceOfdrive2CenterPtOfSinks < 15 || \
              $violnum < -0.1 && $distanceOfdrive2CenterPtOfSinks < 10 || \
              $violnum < -0.07 && $distanceOfdrive2CenterPtOfSinks < 7 || \
              $violnum < -0.03 && $distanceOfdrive2CenterPtOfSinks < 1 \
                } { ;
            if {[expr $ifHaveFasterVT || $ifHaveLargerCapacity] && [expr $driveCapacity <= 4 || [expr $driveCapacity - $sinkCapacity] < 0]} {
              if {$debug} { puts "------" }
              set toChangeCelltype2 [eo $ifHaveFasterVT [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1] $driveCelltype]
              if {$debug} { puts "msl:in_1:1 FS changeVT : $toChangeCelltype2" }
              set toChangeCelltype2 [eo $ifHaveLargerCapacity [strategy_changeDriveCapacity $toChangeCelltype2 0 [eo [expr $driveCapacity <= 2] 2 1] $rangeOfDriveCapacityForChange $cellRegExp 1] $toChangeCelltype2]
              if {$debug} { puts "msl:in_1:1 FS changeDrive : $toChangeCelltype2" }
              lappend fixedList_one2more [concat "msl:in_1:1" "FS" $toChangeCelltype2 $allInfoList]
              set cmd2 [print_ecoCommand -type change -cell $toChangeCelltype2 -inst $driveInstname]
            } else {
              lappend cantChangeList_one2more [concat "msl:in_1:1" "S" $allInfoList]
              set cmd2 "cantChange"
            }
          } elseif {$ifHaveFasterVT && $canChangeVT && [expr $violnum >= -0.006 || \
                     $violnum >= -0.01 && $distanceOfdrive2CenterPtOfSinks > [expr $unitOfNetLength  * 10 ] || \
                     $violnum >= -0.02 && $distanceOfdrive2CenterPtOfSinks > [expr $unitOfNetLength  * 20 ] \
                     ]} { ;
            if {$debug} { puts "in 1: only change VT" }
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {[regexp -- {0x0:3} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "msl:in_2:1" "V" $allInfoList]
              set cmd2 "cantChange"
            } elseif {[regexp -- {0x0:4} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "msl:in_2:2" "F" $allInfoList]
              set cmd2 "cantChange"
            } else {
              lappend fixedList_one2more [concat "msl:in_2:3" "T" $toChangeCelltype2 $allInfoList]
              set cmd2 [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]
            }
          } elseif {$ifHaveLargerCapacity && $canChangeDriveCapacity && $violnum >= -0.03 && $distanceOfdrive2CenterPtOfSinks <= [expr $unitOfNetLength * 1.2]} { ;
            if {$debug} { puts "in 2: only change DriveCapacity" }
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {$debug} { puts $toChangeCelltype2 }
            if {$driveCapacity == 0.5} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 3 $rangeOfDriveCapacityForChange $cellRegExp 1]
            } elseif {$driveCapacity in {1 2}} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1]
            } elseif {$driveCapacity >= 3} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 1 $rangeOfDriveCapacityForChange $cellRegExp 1]
            }
            if {[regexp -- {0x0:3} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "msl:in_4:1" "O" $allInfoList]
              set cmd2 "cantChange"
            } else {
              lappend fixedList_one2more [concat "msl:in_4:2" "D" $toChangeCelltype2 $allInfoList]
              set cmd2 [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]
            }
          } elseif {$ifHaveLargerCapacity && $canChangeVTandDriveCapacity && [expr  [expr  $violnum >= -0.04 && $distanceOfdrive2CenterPtOfSinks <= [expr $unitOfNetLength * 2.2] ||  $violnum >= -0.11 && $distanceOfdrive2CenterPtOfSinks <= [expr $unitOfNetLength * 1.4]] || \
                                                                                    [expr $violnum >= -0.02  && $distanceOfdrive2CenterPtOfSinks <= [expr $unitOfNetLength * 1.2] && $numSinks > 15] ]} { ;
            if {$debug} { puts "in 3: change VT and DriveCapacity" }
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {[regexp -- {0x0:3} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "msl:in_5:1" "V" $allInfoList]
              set cmd2 "cantChange"
            } elseif {[regexp -- {0x0:4} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "msl:in_5:2" "F" $allInfoList]
              set cmd2 "cantChange"
            } else {
              if {$driveCapacity <= 1} {
                set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1]
              } elseif {$driveCapacity >= 2} {
                set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 1 $rangeOfDriveCapacityForChange $cellRegExp 1]
              }
              if {[regexp -- {0x0:3} $toChangeCelltype2]} {
                lappend cantChangeList_one2more [concat "msl:in_5:3" "O" $allInfoList]
                set cmd2 "cantChange"
              } else {
                lappend fixedList_one2more [concat "msl:in_5:4" "TD" $toChangeCelltype2 $allInfoList]
                set cmd2 [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]
              }
            }
          } elseif {$canAddRepeater && $violnum < -0.08  && [expr  $violnum >= -0.1 && $distanceOfdrive2CenterPtOfSinks < [expr $unitOfNetLength * 4] && $distanceOfdrive2CenterPtOfSinks > [expr $unitOfNetLength * 0.3] && $numSinks <= 5 || \
                                                                   $violnum >= -0.1 && $distanceOfdrive2CenterPtOfSinks < [expr $unitOfNetLength * 2] && $numSinks > 5]} { ;
            if {$debug} { puts "in 4: add Repeater" }
            set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $mergedSinksType]] $refCLKBufferCelltype $refBufferCelltype]
            set toAddCelltype2 [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 2 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ;
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1]
              if {$debug} {puts "$driveCelltype - $toChangeCelltype2"}
              set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname];
              lappend fixedList_one2more [concat "msl:in_6:2" "DA_[fm $off]" ${toChangeCelltype2}_$toAddCelltype2 $allInfoList]
              set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
              set cmd2 [list $cmd_DA_driveInst $cmd_DA_add]
            } else {
              lappend fixedList_one2more [concat "msl:in_6:4" "A_[fm $off]" $toAddCelltype2 $allInfoList]
              set cmd2 [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
            }
          } elseif {$canAddRepeater && $violnum < -0.12 && $distanceOfdrive2CenterPtOfSinks > [expr $unitOfNetLength * 2.5]} { ;
            if {$debug} { puts "in 5: add Repeater refDriver, uncertainly, conservative" }
            if {$debug} { puts "Not in above situation, so NOTICE" }
            set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $mergedSinksType]] $refCLKBufferCelltype $refBufferCelltype]
            set toAddCelltype2 [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 4 $rangeOfDriveCapacityForAdd 1 $refCelltype $cellRegExp ];
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 8 0 $rangeOfDriveCapacityForChange $cellRegExp 1]
              if {$debug} {puts "$driveCelltype - $toChangeCelltype2"}
              set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname];
              lappend fixedList_one2more [concat "msl:in_7:2" "DA_[fm $off]" ${toChangeCelltype2}_$toAddCelltype2 $allInfoList]
              if {$debug} {puts "test : msl:in_7:2"}
              set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
              set cmd2 [list $cmd_DA_driveInst $cmd_DA_add]
            } else {
              if {$ifHaveFasterVT} {
                set cmd_TA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]
                lappend fixedList_one2more [concat "msl:in_7:3" "TA_[fm $off]" $toAddCelltype2 $allInfoList]
                set cmd_TA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
                set cmd2 [concat $cmd_TA_driveInst $cmd_TA_add]
              } else {
                lappend fixedList_one2more [concat "msl:in_7:4" "A_[fm $off]" $toAddCelltype2 $allInfoList]
                set cmd2 [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
              }
            }
          } elseif {$canAddRepeater && $violnum < -0.04 && $violnum > -0.1 && $distanceOfdrive2CenterPtOfSinks < [expr $unitOfNetLength * 0.6]} {;
            set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $mergedSinksType]] $refCLKBufferCelltype $refBufferCelltype]
            set toAddCelltype2 [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 2 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ;
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 8 0 $rangeOfDriveCapacityForChange $cellRegExp 1] ;
              if {$debug} {puts "$driveCelltype - $toChangeCelltype2"}
              set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname];
              lappend fixedList_one2more [concat "msl:in_6:2" "DA_[fm $off]" ${toChangeCelltype2}_$toAddCelltype2 $allInfoList]
              set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
              set cmd2 [list $cmd_DA_driveInst $cmd_DA_add]
            } else {
              lappend fixedList_one2more [concat "msl:in_6:4" "A_[fm $off]" $toAddCelltype2 $allInfoList]
              set cmd2 [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
            }
          } else { ;
            if {$debug} { puts "in 5: add Repeater refDriver, uncertainly, conservative" }
            if {$debug} { puts "Not in above situation, so NOTICE" }
            set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $mergedSinksType]] $refCLKBufferCelltype $refBufferCelltype]
            set toAddCelltype2 [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 3 $rangeOfDriveCapacityForAdd 1 $refCelltype $cellRegExp ];
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1]
              if {$debug} {puts "$driveCelltype - $toChangeCelltype2"}
              set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname];
              lappend fixedList_one2more [concat "msl:in_8:2" "DA_[fm $off]" ${toChangeCelltype2}_$toAddCelltype2 $allInfoList]
              if {$debug} {puts "test : msl:in_8:2"}
              set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
              set cmd2 [list $cmd_DA_driveInst $cmd_DA_add]
            } else {
              lappend fixedList_one2more [concat "msl:in_8:4" "A_[fm $off]" $toAddCelltype2 $allInfoList]
              set cmd2 [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
            }
          }
        }
      } elseif {[llength $mergedSinksType] > 1} {;
        set sinksType [lmap type $sinksType {
          switch $type {
            "buffer" {set t "b"}
            "inverter" {set t "i"}
            "logic" {set t "l"}
            "CLKbuffer" {set t "f"}
            "CLKinverter" {set t "n"}
            "CLKlogic" {set t "o"}
            "delay" {set t "d"}
            "sequential" {set t "s"}
            default {set t "N"}
          }
          set t
        }]
        lappend one2moreList_diffTypesOfSinks [concat "MT" [join $sinksType "/"] $allInfoList ]
      }
if {$debug} { puts "TEST: $toChangeCelltype2" }
      if {$cmd2 != "" && $cmd2 != "cantChange" && [get_driveCapacity_of_celltype $toChangeCelltype2 $cellRegExp] < $largerThanDriveCapacityOfChangedCelltype} { ;
        set checkedSymbol "C"
        set checkedCmd ""
        set preToChangeCell $toChangeCelltype2
        set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 $largerThanDriveCapacityOfChangedCelltype 0 $rangeOfDriveCapacityForChange $cellRegExp 1]
        set checkedCmd [print_ecoCommand -type change -cell $toChangeCelltype2 -inst $driveInstname]
        if {[llength $cmd2] > 1 && [llength $cmd2] < 5 && ![regexp "0x0" $checkedCmd] && $checkedCmd != ""} {
          set indexChangeCmd [lsearch -regexp $cmd2 "^ecoChangeCell .*"]
          set cmd2 [lreplace $cmd2 $indexChangeCmd $indexChangeCmd $checkedCmd]
        } elseif {[llength $cmd2] >= 5 && [regexp "ecoChangeCell" $cmd2] && ![regexp "0x0" $checkedCmd] && $checkedCmd != ""} {
          set cmd2 $checkedCmd
        }
        set methodColumn [lindex [lindex $fixedList_one2more end] 1]
        set celltypeToFix [lindex [lindex $fixedList_one2more end] 2]
        set fixedList_one2more [lreplace $fixedList_one2more end end [lreplace [lindex $fixedList_one2more end] 1 2 [append methodColumn "_" $checkedSymbol ] [regsub $preToChangeCell $celltypeToFix $toChangeCelltype2]]]
        if {$debug} { puts "TEST FIXEDLIST large : [llength $fixedList_one2more]" }
        if {$debug} { puts [lindex $fixedList_one2more end] }
      }
      if {$debug} { puts "TEST END: $cmd2\n   $checkedCmd" }
      if {[llength $sinksType] > 1} {
        set situMerged [lindex [lindex $fixedList_one2more end] 0]
        set fixedList_one2more [lreplace $fixedList_one2more end end [lreplace [lindex $fixedList_one2more end] 0 0 [string cat "m" $situMerged]]]
      }
      if {$cmd2 != "cantChange" && $cmd2 != ""} { ;
        lappend cmdList "# [lindex $fixedList_one2more end]"
        if {[llength $cmd2] < 5} { ;
          set cmdList [concat $cmdList $cmd2];
        } else {
          lappend cmdList $cmd2
        }
      } elseif {$cmd2 == "" && [llength $mergedSinksType] == 1} { ;
        lappend notConsideredList_one2more [concat "NC" $allInfoList]
      }
      if {$debug} { puts "# -----------------" }
    }
    lappend cmdList " "
    lappend cmdList "setEcoMode -reset"
    set fixedSituationSortNumber [lmap item $fixedList_1v1 {
      set symbol [lindex $item 0]
    }]
    set situs [lsort -unique $fixedSituationSortNumber]
    foreach s $situs { set num_$s 0 }
    foreach item $fixedSituationSortNumber {
      foreach s $situs {
        if {$item == $s} {
          incr num_$s;
        }
      }
    }
    set fixedMethodSortNumber [lmap item $fixedList_1v1 {
      set symbol [lindex $item 1]
    }]
    set methods [lsort -unique $fixedMethodSortNumber]
    foreach m $methods { set num_$m 0 }
    foreach item $fixedMethodSortNumber {
      foreach method $methods {
        if {$item == $method} {
          incr num_$method;
        }
      }
    }
    set fixedSituationSortNumber_one2more [lmap item $fixedList_one2more {
      set symbol [lindex $item 0]
    }]
    set m_situs [lsort -unique $fixedSituationSortNumber_one2more]
    foreach s $m_situs { set num_$s 0 }
    foreach item $fixedSituationSortNumber_one2more {
      foreach s $m_situs {
        if {$item == $s} {
          incr m_num_$s;
        }
      }
    }
    set fixedMethodSortNumber_one2more [lmap item $fixedList_one2more {
      set symbol [lindex $item 1]
    }]
    set m_methods [lsort -unique $fixedMethodSortNumber_one2more]
    foreach m $m_methods { set num_$m 0 }
    foreach item $fixedMethodSortNumber_one2more {
      foreach method $m_methods {
        if {$item == $method} {
          incr m_num_$method;
        }
      }
    }
    set ce [open $cantExtractFile w]
    set co [open $cmdFile w]
    set sf [open $sumFile w]
    set di [open $one2moreDetailViolInfo w]
    if {1} {
      if {[info exists cantExtractList]} {
        puts $ce "CANT EXTRACT:"
        puts $ce ""
        puts $ce [join $cantExtractList \n]
      } else {
        puts $ce "HAVE NO CANT EXTRACT LIST!!!"
        puts $ce ""
      }
      if {[regexp {ecoChangeCell|ecoAddRepeater} $cmdList]} {
        set beginIndexOfOne2MoreCmds [expr [lsearch -exact $cmdList $beginOfOne2MoreCmds] + 2]
        set endIndexOfOne2MoreCmds [expr [lindex [lsearch -exact -all $cmdList "setEcoMode -reset"] end] - 2]
        set reverseOne2MoreCmdFromCmdList [reverseListRange $cmdList $beginIndexOfOne2MoreCmds $endIndexOfOne2MoreCmds 0 0 1 "#"] ;
        pw $co [join $cmdList \n]
      } else {
        pw $co ""
        pw $co "# HAVE NO CMD!!!"
        pw $co ""
      }
      pw $sf "Summary of fixed:"
      pw $sf ""
      pw $sf "FIXED LIST"
      pw $sf [join $fixedPrompts \n]
      pw $sf ""
      if {[llength $fixedList_1v1] > 1} {
        pw $sf [print_formatedTable $fixedList_1v1]
        pw $sf "total fixed : [expr [llength $fixedList_1v1] - 1]"
        pw $sf ""
        pw $sf "situ  num"
        foreach s $situs { set num [eval set -nonewline \${num_${s}}]; lappend situ_number [list $s $num] }
        pw $sf [print_formatedTable $situ_number]
        pw $sf ""
        pw $sf "method num"
        foreach m $methods { set num [eval set -nonewline \${num_${m}}]; lappend method_number [list $m $num] }
        pw $sf [print_formatedTable $method_number]
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
        pw $sf [print_formatedTable $cantChangeList_1v1]
        pw $sf ""
      } else {
        pw $sf ""
        pw $sf "# HAVE NO CANT CHANGE LIST!!!"
        pw $sf ""
      }
      if {[llength $skippedList_1v1] > 1} {
        pw $sf "SKIPPED LIST"
        pw $sf [join $skippedSituationsPrompt \n]
        pw $sf ""
        pw $sf [print_formatedTable $skippedList_1v1]
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
        pw $sf [print_formatedTable $notConsideredList_1v1]
        pw $sf "total non-considered [expr [llength $notConsideredList_1v1] - 1]"
      } else {
        pw $sf ""
        pw $sf "# HAVE NO NON-CONSIDERED LIST!!!"
        pw $sf ""
      }
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
          pw $sf [print_formatedTable $reversedFixedList_one2more]
          pw $sf "total fixed : [expr [llength $fixedList_one2more] - 1]"
          pw $sf ""
          pw $sf "situ  num"
          foreach s $m_situs { set num [eval set -nonewline \${m_num_${s}}]; lappend m_situ_number [list $s $num] }
          pw $sf [print_formatedTable $m_situ_number]
          pw $sf ""
          pw $sf "method num"
          foreach m $m_methods { set num [eval set -nonewline \${m_num_${m}}]; lappend m_method_number [list $m $num] }
          pw $sf [print_formatedTable $m_method_number]
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
          pw $sf [print_formatedTable $cantChangeList_one2more]
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
          pw $sf [print_formatedTable $skippedList_one2more]
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
          pw $sf [print_formatedTable $notConsideredList_one2more]
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
          pw $sf [print_formatedTable $one2moreList_diffTypesOfSinks]
          pw $sf "total viol drivePin (sorted) with diff types of sinks: [expr [llength [lsort -unique -index 6 $one2moreList_diffTypesOfSinks]] - 1]"
          pw $sf ""
        } else {
          pw $sf ""
          pw $sf "# HAVE NO DIFF-TYPES-Of-SINKS LIST!!!"
          pw $sf ""
        }
        puts $di "ONE to MORE SITUATIONS (different sinks cell class!!! need to improve, i can't fix now)"
        puts $di ""
        puts $di [print_formatedTable $one2moreDetailList_withAllViolSinkPinsInfo]
        puts $di "total of all viol sinks : [expr [llength $one2moreDetailList_withAllViolSinkPinsInfo] - 1]"
        puts $di "total of all viol drivePin (sorted) : [expr [llength [lsort -unique -index 5 $one2moreDetailList_withAllViolSinkPinsInfo]] - 1]"
        puts $di ""
      } else {
        pw $sf "HAVE NO ONE 2 MORE SITUATION!!!"
      }
      pw $sf ""
      pw $sf "TWO SITUATIONS OF ALL VIOLATIONS:"
      pw $sf "#  --------------------------- #"
      if {[llength $violValue_driverPin_onylOneLoaderPin_D3List] > 1} {
        pw $sf "1 v 1    number: [llength $violValue_driverPin_onylOneLoaderPin_D3List]"
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
    {-debug "debug mode" "" boolean optional}
  }
alias ci "counter"
catch {unset counters}
proc counter {input {holdon 0} {start 1}} {
    global counters
    if {![info exists counters($input)]} {
        set counters($input) [expr $start - 1]
    }
    if {!$holdon} {
      incr counters($input)
    }
    return "$counters($input)"
}
proc la {args} {
	if {[llength $args] == 0} {
		error "la: requires at least one argument";
	}
	if {[llength $args] % 2 != 0} {
		error "la: requires arguments in pairs: variable value"
	}
	for {set i 0} {$i < [llength $args]} {incr i 2} {
		set varName [lindex $args $i]
		set expectedValue [lindex $args [expr {$i+1}]]
		if {$varName ne $expectedValue} {
			return 0  ;
		}
	}
	return 1  ;
}
proc lo {args} {
	if {[llength $args] == 0} {
		error "lo: requires at least one argument"
	}
	if {[llength $args] % 2 != 0} {
		error "lo: requires arguments in pairs: variable value"
	}
	for {set i 0} {$i < [llength $args]} {incr i 2} {
		set varName [lindex $args $i]
		set expectedValue [lindex $args [expr {$i+1}]]
		if {$varName eq $expectedValue} {
			return 1  ;
		}
	}
	return 0  ;
}
proc al {args} {
	if {[llength $args] == 0} {
		error "al: requires at least one argument"
	}
	foreach arg $args {
		if {$arg eq "" || ([string is integer -strict $arg] && $arg == 0)} {
			return 0  ;
		}
	}
	return 1  ;
}
proc ol {args} {
	if {[llength $args] == 0} {
		error "ol: requires at least one argument"
	}
	foreach arg $args {
		if {$arg ne "" && (![string is integer -strict $arg] || $arg != 0)} {
			return 1  ;
		}
	}
	return 0  ;
}
proc re {args} {
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
	if {[info exist list]} {
		return [lmap item $list {expr {![_to_boolean $item]}}]
	} elseif {[info exist dict]} {
		if {[llength $args] != 1} {
			error "Dictionary mode requires exactly one dictionary argument"
		}
		set resultDict [dict create]
		dict for {key value} [lindex $dict 0] {
			dict set resultDict $key [expr {![_to_boolean $value]}]
		}
		return $resultDict
	} else {
		if {[llength $args] != 1} {
			error "Single value mode requires exactly one argument"
		}
		return [expr {![_to_boolean [lindex $args 0]]}]
	}
}
define_proc_arguments re \
  -info ":re ?-list|-dict? value(s) - Logical negation of values"\
  -define_args {
	  {value "boolean value" "" boolean optional}
    {-list "list mode" AList list optional}
    {-dict "dict mode" ADict list optional}
  }
proc _to_boolean {value} {
	switch -exact -- [string tolower $value] {
		"1" - "true" - "yes" - "on" { return 1 }
		"0" - "false" - "no" - "off" { return 0 }
		default {
			if {[string is integer -strict $value]} {
				return [expr {$value != 0}]
			}
			error "Cannot convert '$value' to boolean"
		}
	}
}
alias eo "ifEmptyZero"
proc ifEmptyZero {value trueValue falseValue} {
    if {[llength [info level 0]] != 4} {
        error "Usage: ifEmptyZero value trueValue falseValue"
    }
    if {$value eq "" || [string trim $value] eq ""} {
        return $falseValue
    }
    set numericValue [string is double -strict $value]
    if {$numericValue} {
        if {[expr {$value == 0}]} {
            return $falseValue
        }
    } elseif {$value eq "0"} {
        return $falseValue
    }
    return $trueValue
}
alias gpt "getPt_ofObj"
proc getPt_ofObj {{obj ""}} {
  if {[lindex $obj 0] == [lindex [lindex $obj 0 ] 0]} {
    set obj [lindex $obj 0]
  }
  if {$obj == ""} {
    set obj [dbget selected.name -e] ;
  }
  if {$obj == "" || [dbget top.insts.name $obj -e] == "" && [dbget top.insts.instTerms.name $obj -e] == ""} {
    return "0x0:1";
  } else {
    set inst_ptr [dbget top.insts.name $obj -e -p]
    set pin_ptr  [dbget top.insts.instTerms.name $obj -e -p]
    if {$inst_ptr != ""} {
      set inst_pt [lindex [dbget $inst_ptr.pt] 0]
      return $inst_pt
    } elseif {$pin_ptr != ""} {
      set pin_pt [lindex [dbget $pin_ptr.pt] 0]
      return $pin_pt
    }
  }
}
proc get_net_length {{net ""}} {
  if {[lindex $net 0] == [lindex $net 0 0]} {
    set net [lindex $net 0]
  }
	if {$net == "0x0" || [dbget top.nets.name $net -e] == ""} {
		return "0x0:1"
	} else {
    set wires_split_length [dbget [dbget top.nets.name $net -u -p].wires.length]
    set net_length 0
    foreach wire_len $wires_split_length {
      set net_length [expr $net_length + $wire_len]
    }
    return $net_length
	}
}
alias gl "get_net_length"
proc if_driver_or_load {{pin ""}} {
  if {$pin == "" || $pin == "0x0" || [dbget top.insts.instTerms.name $pin -e] == ""} {
    return "0x0:1"
  } else {
    if {[dbget [dbget top.insts.instTerms.name $pin -p].isOutput] == 1} {
      return 1
    } else {
      return 0
    }
  }
}
proc get_fanoutNum_and_inputTermsName_of_pin {{pin ""}} {
  if {$pin == "" || $pin == "0x0" || [dbget top.insts.instTerms.name $pin -e] == ""} {
    return "0x0:1"
  } else {
    set netOfPinPtr  [dbget [dbget top.insts.instTerms.name $pin -p].net.]
    set netNameOfPin [dbget $netOfPinPtr.name]
    set fanoutNum    [dbget $netOfPinPtr.numInputTerms]
    set allinstTerms [dbget $netOfPinPtr.instTerms.name]
    set inputTermsName "[lsearch -all -inline -not -exact $allinstTerms $pin]"
    set numToInputTermName [list ]
    lappend numToInputTermName $fanoutNum
    lappend numToInputTermName $inputTermsName
    return $numToInputTermName
  }
}
proc get_driverPin {{pin ""}} {
  if {$pin == "" || [dbget top.insts.instTerms.name $pin -e] == ""} {
    error "proc get_driverPin: pin ($pin) can't find in invs db!!!";
  } else {
    set driver [lindex [dbget [dbget [dbget top.insts.instTerms.name $pin -p].net.instTerms.isOutput 1 -p].name ] 0]
    return $driver
  }
}
proc get_loadPins {{pin ""}} {
  if {$pin == "" || [dbget top.insts.instTerms.name $pin -e] == ""} {
    error "proc get_loadPins: pin ($pin) can't find in invs db!!!"
  } else {
  }
}
proc get_cellDriveLevel_and_VTtype_of_inst {{instOrPin ""} {regExp "D(\\d+).*CPD(U?L?H?VT)?"}} {
  if {$instOrPin == "" || $instOrPin == "0x0" || [dbget top.insts.name $instOrPin -e] == "" && [dbget top.insts.instTerms.name $instOrPin -e] == ""} {
    return "0x0:1"
  } else {
    if {[dbget top.insts.name $instOrPin -e] != ""} {
      set cellName [dbget [dbget top.insts.name $instOrPin -p].cell.name]
      set instname $instOrPin
    } else {
      set cellName [dbget [dbget top.insts.instTerms.name $instOrPin -p2].cell.name]
      set instname [dbget [dbget top.insts.instTerms.name $instOrPin -p2].name]
    }
    set wholeName 0
    set levelNum 0
    set VTtype 0
    set runError [catch {regexp $regExp $cellName wholeName levelNum VTtype} errorInfo]
    if {$runError || $wholeName == ""} {
      return "0x0:2"
    } else {
      if {$VTtype == ""} {set VTtype "SVT"}
      if {$levelNum == "05"} {set levelNumTemp 0.5} else {set levelNumTemp [expr $levelNum]}
      set instName_cellName_driveLevel_VTtype_List [list ]
      lappend instName_cellName_driveLevel_VTtype_List $instname
      lappend instName_cellName_driveLevel_VTtype_List $cellName
      lappend instName_cellName_driveLevel_VTtype_List $levelNumTemp
      lappend instName_cellName_driveLevel_VTtype_List $VTtype
      return $instName_cellName_driveLevel_VTtype_List
    }
  }
}
proc get_cell_class {{instOrPinOrCelltype ""}} {
  if {$instOrPinOrCelltype == "" || $instOrPinOrCelltype == "0x0" || [expr  {[dbget top.insts.name $instOrPinOrCelltype -e] == "" && [dbget top.insts.instTerms.name $instOrPinOrCelltype -e] == ""}]} {
    return "0x0:1";
  } else {
    if {[dbget top.insts.name $instOrPinOrCelltype -e] != ""} {
      return [logic_of_mux $instOrPinOrCelltype]
    } elseif {[dbget top.insts.instTerms.name $instOrPinOrCelltype -e] != ""} {
      set inst_ofPin [dbget [dbget top.insts.instTerms.name $instOrPinOrCelltype -p2].name]
      return [logic_of_mux $inst_ofPin]
    } elseif {[dbget head.libCells.name $instOrPinOrCelltype -e] != ""} {
      return [logic_of_mux $instOrPinOrCelltype]
    }
  }
}
proc logic_of_mux {instOrCelltype} {
  if {[dbget top.insts.name $instOrCelltype -e] != ""} {
    set celltype [dbget [dbget top.insts.name $instOrCelltype -p].cell.name]
    if {[get_property [get_cells $instOrCelltype] is_memory_cell]} {
      return "mem"
    } elseif {[get_property [get_cells $instOrCelltype] is_sequential]} {
      return "sequential"
    } elseif {[regexp {CLK} $celltype]} {
      if {[get_property [get_cells $instOrCelltype] is_buffer]} {
        return "CLKbuffer"
      } elseif {[get_property [get_cells $instOrCelltype] is_inverter]} {
        return "CLKinverter"
      } elseif {[get_property [get_cells $instOrCelltype] is_combinational]} {
        return "CLKlogic"
      } else {
        return "CLKcell"
      }
    } elseif {[regexp {^DEL} $celltype] && [get_property [get_cells $instOrCelltype] is_buffer]} {
      return "delay"
    } elseif {[get_property [get_cells $instOrCelltype] is_buffer]} {
      return "buffer"
    } elseif {[get_property [get_cells $instOrCelltype] is_inverter]} {
      return "inverter"
    } elseif {[get_property [get_cells $instOrCelltype] is_integrated_clock_gating_cell]} {
      return "gating"
    } elseif {[get_property [get_cells $instOrCelltype] is_combinational]} {
      return "logic"
    } else {
      return "other"
    }
  } elseif {[dbget head.libCells.name $instOrPinOrCelltype -e] == ""} {
    if {[lsort -unique [get_property [get_lib_cells $instOrCelltype] is_memory_cell]]} {
      return "mem"
    } elseif {[lsort -unique [get_property [get_lib_cells $instOrCelltype] is_sequential]]} {
      return "sequential"
    } elseif {[regexp {CLK} $instOrCelltype]} {
      if {[lsort -unique [get_property [get_lib_cells $instOrCelltype] is_buffer]]} {
        return "CLKbuffer"
      } elseif {[lsort -unique [get_property [get_lib_cells $instOrCelltype] is_inverter]]} {
        return "CLKinverter"
      } elseif {[lsort -unique [get_property [get_lib_cells $instOrCelltype] is_combinational]]} {
        return "CLKlogic"
      } else {
        return "CLKcell"
      }
    } elseif {[regexp {^DEL} $instOrCelltype] && [lsort -unique [get_property [get_lib_cells $instOrCelltype] is_buffer]]} {
      return "delay"
    } elseif {[lsort -unique [get_property [get_lib_cells $instOrCelltype] is_buffer]]} {
      return "buffer"
    } elseif {[lsort -unique [get_property [get_lib_cells $instOrCelltype] is_inverter]]} {
      return "inverter"
    } elseif {[lsort -unique [get_property [get_lib_cells $instOrCelltype] is_integrated_clock_gating_cell]]} {
      return "gating"
    } elseif {[lsort -unique [get_property [get_lib_cells $instOrCelltype] is_combinational]]} {
      return "logic"
    } else {
      return "other"
    }
  }
}
proc strategy_changeVT {{celltype ""} {weight {{SVT 3} {LVT 1} {ULVT 0}}} {speed {ULVT LVT SVT}} {regExp "D(\\d+).*CPD(U?L?H?VT)?"} {ifForceValid 1}} {
  if {$celltype == "" || $celltype == "0x0" || [dbget head.libCells.name $celltype -e] == ""} {
    return "0x0:1"
  } else {
    set runError [catch {regexp $regExp $celltype wholeName driveLevel VTtype} errorInfo]
    if {$runError || $wholeName == ""} {
      return "0x0:2";
    } else {
      set processType [whichProcess_fromStdCellPattern $celltype]
      if {$VTtype == ""} {set VTtype "SVT"; puts "notice: blank vt type"}
      set weight0VTList [lmap vt_weight [lsort -unique -index 0 [lsearch -all -inline -index 1 -regexp $weight "0"]] {set vt [lindex $vt_weight 0]}]
      set avaiableVT [lsearch -all -inline -index 1 -regexp $weight "\[1-9\]"];
      set availableVTsorted [lsort -index 1 -integer -decreasing $avaiableVT]
      set ifInAvailableVTList [lsearch -index 0 $availableVTsorted $VTtype]
      set availableVTnameList [lmap vt_weight $availableVTsorted {set temp [lindex $vt_weight 0]}]
      if {$availableVTnameList == $VTtype} {
        return $celltype;
      } elseif {$ifInAvailableVTList == -1} {
        if {$ifForceValid} {
          if {[lsearch -inline $weight0VTList $VTtype] != ""} {
            set speedList_notWeight0 $speed
            foreach weight0 $weight0VTList {
              set speedList_notWeight0 [lsearch -exact -inline -all -not $speedList_notWeight0 $weight0]
            }
            if {$processType == "TSMC"} {
              set useVT [lindex $speedList_notWeight0 end]
              if {$useVT == ""} {
                return "0x0:4";
              } else {
                if {$useVT == "SVT"} {
                  return [regsub "$VTtype" $celltype ""]
                } elseif {$VTtype == "SVT"} {
                  return [regsub "$" $celltype $useVT]
                } else {
                  return [regsub $VTtype $celltype $useVT]
                }
              }
            } elseif {$processType == "HH"} {
              return [regsub $VTtype $celltype [lindex $speedList_notWeight0 end]]
            }
          }
        } else {
          return "0x0:3";
        }
      } else {
        set changeableVT [lsearch -exact -index 0 -all -inline -not $availableVTsorted $VTtype]
        set nowSpeedIndex [lsearch -exact $speed $VTtype]
        set moreFastVTinSpeed [lreplace $speed $nowSpeedIndex end]
        set useVT ""
        foreach vt $changeableVT {
          if {[lsearch -exact $moreFastVTinSpeed [lindex $vt 0]] > -1} {
            set useVT "[lindex $vt 0]"
            break
          } else {
            return $celltype ;
          }
        }
        if {$processType == "TSMC"} {
          if {$useVT == ""} {
            return "0x0:4";
          } else {
            if {$useVT == "SVT"} {
              return [regsub "$VTtype" $celltype ""]
            } elseif {$VTtype == "SVT"} {
              return [regsub "$" $celltype $useVT]
            } else {
              return [regsub $VTtype $celltype $useVT]
            }
          }
        } elseif {$processType == "HH"} {
          return [regsub $VTtype $celltype $useVT]
        }
      }
    }
  }
}
proc whichProcess_fromStdCellPattern {{celltype ""}} {
  if {$celltype == "" || $celltype == "0x0" || [dbget head.libCells.name $celltype -e] == ""} {
    return "0x0:1";
  } else {
    if {[regexp BWP $celltype]} {
      set processType "TSMC"
    } elseif {[regexp {A[HRL]\d+$} $celltype]} {
      set processType "HH"
    } else {
      return "0x0:1";
    }
    return $processType
  }
}
proc strategy_addRepeaterCelltype {{driverCelltype ""} {loaderCelltype ""} {method "refDriver|refLoader|auto"} {forceSpecifyDriveCapacibility 4} {driveRange {4 16}} {ifGetBigDriveNumInAvaialbeDriveCapacityList 1} {refType "BUFD4BWP6T16P96CPD"} {regExp "D(\\d+).*CPD(U?L?H?VT)?"} } {
  if {$driverCelltype == "" || $loaderCelltype == "" || [dbget top.insts.cell.name $driverCelltype -e] == "" || [dbget top.insts.cell.name $loaderCelltype -e] == ""} {
    error "proc strategy_addRepeaterCelltype: check your input !!!";
  } else {
    set runError0 [catch {regexp $regExp $refType wholeNameR levelNumR VTtypeR} errorInfoR]
    set runError1 [catch {regexp $regExp $driverCelltype wholeNameD levelNumD VTtypeD} errorInfoD]
    set runError2 [catch {regexp $regExp $loaderCelltype wholeNameL levelNumL VTtypeL} errorInfoL]
    if {$runError1 || $runError2 || ![info exists wholeNameR] || ![info exists wholeNameD] || ![info exists wholeNameL]} {
      error "proc strategy_addRepeaterCelltype: can't regexp";
    } else {
      if {[llength $driveRange] == 2 && [expr {"[dbget head.libCells.name [changeDriveCapacity_of_celltype $refType $levelNumR [lindex $driveRange 0]] -e]" == "" || "[dbget head.libCells.name [changeDriveCapacity_of_celltype $refType $levelNumR [lindex $driveRange 1]] -e]" == ""}]} {
        error "proc strategy_addRepeaterCelltype: check your var driveRange , have no celltype in std cell library for min or max driveCapacity from driveRange";
      } elseif {[llength $driveRange] == 2} {
        set driveRangeRight [lsort -integer -increasing $driveRange]
      }
      if {$forceSpecifyDriveCapacibility} {
        set toCelltype [changeDriveCapacity_of_celltype $refType $levelNumR $forceSpecifyDriveCapacibility]
        if {[dbget head.libCells.name $toCelltype -e] == ""} {
          error "proc strategy_addRepeaterCelltype: force specified drive capacity is not valid: $forceSpecifyDriveCapacibility";
        } else {
          return $toCelltype
        }
      }
      set processType [whichProcess_fromStdCellPattern $refType]
      if {$processType == "TSMC"} {
        regsub D$levelNumR $refType D* searchCelltypeExp
      } elseif {$processType == "HH"} {
        regsub X$levelNumR $refType X* searchCelltypeExp
      }
      set availableCelltypeList [dbget head.libCells.name $searchCelltypeExp]
      set availableDriveCapacityIntegerList [lmap celltype $availableCelltypeList {
        regexp $regExp $celltype wholename driveLevel VTtype
        if {$driveLevel == "05"} {continue} else { set driveLevel [expr int($driveLevel)]}
      }]
      switch $method {
        "refDriver" {
          if {$levelNumD == "05"} {set levelNumD 0.5};
          set toDriveNum [find_nearestNum_atIntegerList $availableDriveCapacityIntegerList $levelNumD $ifGetBigDriveNumInAvaialbeDriveCapacityList 1]
          if {$toDriveNum <  [lindex $driveRangeRight 0]} {
            set toCelltype [changeDriveCapacity_of_celltype $refType $levelNumR [lindex $driveRangeRight 0]]
            return $toCelltype
          } elseif {$toDriveNum > [lindex $driveRangeRight 1]} {
            set toCelltype [changeDriveCapacity_of_celltype $refType $levelNumR [lindex $driveRangeRight 1]]
            return $toCelltype
          } else {
            set toCelltype [changeDriveCapacity_of_celltype $refType $levelNumR $toDriveNum]
            return $toCelltype
          }
        }
        "refLoader" {
          if {$levelNumL == "05"} {set levelNumD 0.5};
          set toDriveNum [find_nearestNum_atIntegerList $availableDriveCapacityIntegerList $levelNumL $ifGetBigDriveNumInAvaialbeDriveCapacityList 1]
          if {$toDriveNum <  [lindex $driveRangeRight 0]} {
            set toCelltype [changeDriveCapacity_of_celltype $refType $levelNumR [lindex $driveRangeRight 0]]
            return $toCelltype
          } elseif {$toDriveNum > [lindex $driveRangeRight 1]} {
            set toCelltype [changeDriveCapacity_of_celltype $refType $levelNumR [lindex $driveRangeRight 1]]
            return $toCelltype
          } else {
            set toCelltype [changeDriveCapacity_of_celltype $refType $levelNumR $toDriveNum]
            return $toCelltype
          }
        }
        "auto" {
        }
      }
    }
  }
}
# Skipping already processed file: ./proc_whichProcess_fromStdCellPattern.invs.tcl
proc find_nearestNum_atIntegerList {{realList {}} number {returnBigOneFlag 1} {ifClamp 1}} {
  set s [lsort -unique -increasing -real $realList]
  set idx [lsearch -exact -real $s $number]
  if {$idx != -1} {
    return [lsearch -inline -real -exact $s $number] ;
  }
  if {[llength $realList] == 1 && $ifClamp} {
    return [lindex $realList 0]
  } elseif {$ifClamp && $number < [lindex $s 0]} {
    return [lindex $s 0]
  } elseif {$ifClamp && $number > [lindex $s end]} { ;
    return [lindex $s 1]
  } elseif {$number < [lindex $s 0] || $number > [lindex $s end]} {
    error "proc find_nearestNum_atIntegerList: your number is not in the range of list (without turning on switch \$ifClamp)";
  }
  foreach i $s {
    set next_i [lindex $s [expr [lsearch $s $i] + 1]]
    if {$i < $number && $number < $next_i} {
      set lowerIdx [lsearch $s $i]
      break
    }
  }
  set upperIdx [expr {$lowerIdx + 1}]
  return [lindex $s [expr {$returnBigOneFlag ? $upperIdx : $lowerIdx}]]
}
proc changeDriveCapacity_of_celltype {{refType "BUFD4BWP6T16P96CPD"} {originalDriveCapacibility 0} {toDriverCapacibility 0}} {
  set processType [whichProcess_fromStdCellPattern $refType]
  if {$processType == "TSMC"} { ;
    regsub "D${originalDriveCapacibility}BWP" $refType "D${toDriverCapacibility}BWP" toCelltype
    return $toCelltype
  } elseif {$processType == "HH"} { ;
    if {$toDriverCapacibility == 0.5} {set toDriverCapacibility "05"}
    regsub [subst {(.*)X${originalDriveCapacibility}}] $refType [subst {\\1X${toDriverCapacibility}}] toCelltype
    return $toCelltype
  } else {
    error "proc changeDriveCapacity_of_celltype: process of std cell is not belong to TSMC or HH!!!"
  }
}
# Skipping already processed file: ./proc_whichProcess_fromStdCellPattern.invs.tcl
proc strategy_changeDriveCapacity {{celltype ""} {forceSpecifyDriveCapacity 4} {changeStairs 1} {driveRange {1 16}} {regExp "D(\\d+)BWP.*CPD(U?L?H?VT)?"} {ifClamp 1} {debug 0}} {
  if {$celltype == "" || $celltype == "0x0" || [dbget head.libCells.name $celltype -e ] == ""} {
    error "proc strategy_changeDriveCapacity: check your input!!!"
  } else {
    set runError [catch {regexp $regExp $celltype wholename driveLevel VTtype} errorInfo]
    if {$runError || $wholename == ""} {
      error "proc strategy_changeDriveCapacity: can't regexp!!!"
    } else {
      if {$driveLevel == "05"} { ;
        set driveLevelNum 0.5
      } else {
        set driveLevelNum [expr int($driveLevel)]
      }
      set processType [whichProcess_fromStdCellPattern $celltype]
      set toDrive 0
      if {$forceSpecifyDriveCapacity } {
        set toDrive $forceSpecifyDriveCapacity
        if {$processType == "TSMC"} {
          regsub "D${driveLevel}BWP" $celltype "D${toDrive}BWP" toCelltype
          if {[dbget head.libCells.name $toCelltype -e] == ""} {
            return "0x0:4";
          } else {
            return $toCelltype
          }
        } elseif {$processType == "HH"} {
          regsub [subst {(.*)X${driveLevel}}] $celltype [subst {\\1X${toDrive}}] toCelltype
          if {[dbget head.libCells.name $toCelltype -e] == ""} {
            return $celltype ;
            return "0x0:4";
          } else {
            return $toCelltype
          }
        }
      }
      set ifHaveRangeFlag 1
      if {![llength $driveRange]} {
        set ifHaveRangeFlag 0
      } else {
        set driveRangeRight [lsort -integer -increasing $driveRange]
      }
      set toDrive_temp [expr $driveLevelNum * ($changeStairs * 2)]
if {$debug} { puts "strategy_changeDriveCapacity : celltype : $celltype  driveLevelNum : $driveLevelNum stairs : $changeStairs toDrive_tmp : $toDrive_temp" }
      if {$processType == "TSMC"} {
        regsub D${driveLevel}BWP $celltype D*BWP searchCelltypeExp
      } elseif {$processType == "HH"} {
        regsub [subst {(.*)X$driveLevel}] $celltype [subst {\\1X*}] searchCelltypeExp
      }
      set availableCelltypeList [dbget head.libCells.name $searchCelltypeExp]
      set availableDriveCapacityList [lmap Acelltype $availableCelltypeList {
        regexp $regExp $Acelltype wholename AdriveLevel AVTtype
        if {$AdriveLevel == "05"} {set AdriveLevel 0.5} else { set AdriveLevel}
      }]
      if {$toDrive_temp <= 8} {
        set toDrive [find_nearestNum_atIntegerList $availableDriveCapacityList $toDrive_temp 1 1]
      } else {
        set toDrive [find_nearestNum_atIntegerList $availableDriveCapacityList $toDrive_temp 0 1]
      }
if {$debug} { puts "strategy_changeDriveCapacity2 : toDrive : $toDrive" }
      if {$ifHaveRangeFlag} {
        set maxAvailableDriveOnRange [find_nearestNum_atIntegerList $availableDriveCapacityList [lindex $driveRangeRight 1] 0 1]
        set minAvailableDriveOnRnage [find_nearestNum_atIntegerList $availableDriveCapacityList [lindex $driveRangeRight 0] 1 1]
      } else {
        return "0x0:5";
      }
if {$debug} { puts "- > $minAvailableDriveOnRnage $maxAvailableDriveOnRange" }
      if {$ifClamp && $toDrive > $maxAvailableDriveOnRange} {
        set toDrive $maxAvailableDriveOnRange
      } elseif {$ifClamp && $toDrive < $minAvailableDriveOnRnage} {
        set toDrive $minAvailableDriveOnRnage
      } elseif {[expr !$ifClamp && $toDrive > $maxAvailableDriveOnRange] || [expr !$ifClamp && $toDrive < $minAvailableDriveOnRnage]} {
        return "0x0:3";
      }
      if {[regexp BWP $celltype]} { ;
        regsub "D${driveLevel}BWP" $celltype "D${toDrive}BWP" toCelltype
        return $toCelltype
      } elseif {[regexp {.*X\d+.*A[RHL]\d+} $celltype]} { ;
        if {$toDrive == 0.5} {set toDrive "05"}
        regsub [subst {(.*)X${driveLevel}}] $celltype [subst {\\1X${toDrive}}] toCelltype
        return $toCelltype
      }
    }
  }
}
# Skipping already processed file: ./proc_whichProcess_fromStdCellPattern.invs.tcl
# Skipping already processed file: ./proc_find_nearestNum_atIntegerList.invs.tcl
proc print_ecoCommand {args} {
  set type                "change";
  set inst                ""
  set terms               ""
  set celltype            ""
  set newInstNamePrefix   ""
  set loc                 {}
  set relativeDistToSink  ""
  set radius              ""
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  if {$type == ""} {
    return "0x0:1";
  } else {
    if {$type == "change"} {
      if {$inst == "" || $celltype == "" || [dbget top.insts.name $inst -e] == "" || [dbget head.libCells.name $celltype -e] == ""} {
        return "pe:0x0:2";
      }
      return "ecoChangeCell -cell $celltype -inst $inst"
    } elseif {$type == "add"} {
      if {$celltype == "" || [dbget head.libCells.name $celltype -e] == "" || ![llength $terms]} {
        return "0x0:3";
      }
      if {$newInstNamePrefix != ""} {
        if {[llength $loc] && [ifInBoxes $loc]} {
          if {$radius != "" && [string is double $radius]} {
            return "ecoAddRepeater -name $newInstNamePrefix -cell $celltype -term \{$terms\} -loc \{$loc\} -radius $radius"
          } else {
            return "ecoAddRepeater -name $newInstNamePrefix -cell $celltype -term \{$terms\} -loc \{$loc\}"
          }
        } elseif {[llength $loc] && ![ifInBoxes $loc]} {
          return "0x0:4";
        } elseif {![llength $loc] && $relativeDistToSink != "" && $relativeDistToSink > 0 && $relativeDistToSink < 1} {
          if {$radius != "" && [string is double $radius]} {
            return "ecoAddRepeater -name $newInstNamePrefix -cell $celltype -term \{$terms\} -relativeDistToSink $relativeDistToSink -radius $radius"
          } else {
            return "ecoAddRepeater -name $newInstNamePrefix -cell $celltype -term \{$terms\} -relativeDistToSink $relativeDistToSink"
          }
        } else {
          return "ecoAddRepeater -name $newInstNamePrefix -cell $celltype -term \{$terms\}"
        }
      } else {
        if {[llength $loc] && [ifInBoxes $loc]} {
          if {$radius != "" && [string is double $radius]} {
            return "ecoAddRepeater -cell $celltype -term \{$terms\} -loc \{$loc\} -radius $radius"
          } else {
            return "ecoAddRepeater -cell $celltype -term \{$terms\} -loc \{$loc\}"
          }
        } elseif {[llength $loc] && ![ifInBoxes $loc]} {
          return "0x0:6";
        } elseif {![llength $loc] && $relativeDistToSink != "" && $relativeDistToSink > 0 && $relativeDistToSink < 1} {
          if {$radius != "" && [string is double $radius]} {
            return "ecoAddRepeater -cell $celltype -term \{$terms\} -relativeDistToSink $relativeDistToSink -radius $radius"
          } else {
            return "ecoAddRepeater -cell $celltype -term \{$terms\} -relativeDistToSink $relativeDistToSink"
          }
        } elseif {$relativeDistToSink != "" && $relativeDistToSink <= 0 || $relativeDistToSink >= 1} {
          return "0x0:7";
        } else {
          return "ecoAddRepeater -cell $celltype -term \{$terms\}"
        }
      }
    } elseif {$type == "delete"} {
      if {$inst == "" || [dbget top.insts.name $inst -e] == ""} {
        return "0x0:5";
      }
      return "ecoDeleteRepeater -inst $inst"
    } else {
      return "0x0:0";
    }
  }
}
define_proc_arguments print_ecoCommand \
  -info "print eco command"\
  -define_args {
    {-type "specify the type of eco" oneOfString one_of_string {required value_type {values {change add delete}}}}
    {-inst "specify inst to eco when type is add/delete" AString string optional}
    {-terms "specify terms to eco when type is add" AString string optional}
    {-celltype "specify celltype to add when type is add" AString string optional}
    {-newInstNamePrefix "specify new inst name prefix when type is add" AString string optional}
    {-loc "specify location of new inst when type is add" AString string optional}
    {-relativeDistToSink "specify relative value when type is add.(use it when loader is only one)" AFloat float optional}
    {-radius "specify radius searching location" AFloat float optional}
  }
proc ifInBoxes {{loc {0 0}} {boxes {{}}}} {
  if {![llength [lindex $boxes 0]]} {
    set fplanBoxes [lindex [dbget top.fplan.boxes] 0]
  }
  foreach box $fplanBoxes {
    if {[ifInBox $loc $box]} {
      return 1
    }
  }
  return 0
}
proc ifInBox {{loc {0 0}} {box {0 0 10 10}}} {
  set xRange [list [lindex $box 0] [lindex $box 2]]
  set yRange [list [lindex $box 1] [lindex $box 3]]
  set x [lindex $loc 0]
  set y [lindex $loc 1]
  if {[lindex $xRange 0] < $x && $x < [lindex $xRange 1] && [lindex $yRange 0] < $y && $y < [lindex $yRange 1]} {
    return 1
  } else {
    return 0
  }
}
# Skipping already processed file: ./proc_ifInBoxes.invs.tcl
proc print_formatedTable {{dataList {}}} {
  set text ""
  foreach row $dataList {
      append text [join $row "\t"]
      append text "\n"
  }
  set pipe [open "| column -t" w+]
  puts -nonewline $pipe $text
  close $pipe w
  set formattedLines [list ]
  while {[gets $pipe line] > -1} {
    lappend formattedLines $line
  }
  close $pipe
  return [join $formattedLines \n]
}
proc pw {{fileId ""} {message ""}} {
  puts $message
  puts $fileId $message
}
proc strategy_clampDriveCapacity_BetweenDriverSink {{driverCelltype ""} {sinkCelltype ""} {toCheckCelltype ""} {regExp "D(\\d+)BWP.*CPD(U?L?H?VT)?"} {refDriverOrSink "refSink"} {maxExcessRatio 0.5}} {
  if {$driverCelltype == "" || [dbget head.libCells.name $driverCelltype -e] == "" || $sinkCelltype == "" || [dbget head.libCells.name $sinkCelltype -e] == "" || $toCheckCelltype == "" || [dbget head.libCells.name $toCheckCelltype -e] == ""} {
    error "proc strategy_clampDriveCapacity_BetweenDriverSink: check your input!!!"
  } else {
    set runError1 [catch {regexp $regExp $driverCelltype wholename1 driveLevel1 VTtype} errorInfo]
    set runError2 [catch {regexp $regExp $sinkCelltype wholename2 driveLevel2 VTtype} errorInfo]
    set runError3 [catch {regexp $regExp $toCheckCelltype wholename3 driveLevel3 VTtype} errorInfo]
    if {$runError1 || $runError2 || $runError3 || ![info exists wholename1] || ![info exists wholename2] || ![info exists wholename3]} {
      error "proc strategy_clampDriveCapacity_BetweenDriverSink: can't regexp!!!"
    } else {
      if {$driveLevel1 == "05"} { set driveLevel1 0.5 } else { set driveLevel1 [expr int($driveLevel)] }
      if {$driveLevel2 == "05"} { set driveLevel2 0.5 } else { set driveLevel2 [expr int($driveLevel)] }
      if {$driveLevel3 == "05"} { set driveLevel3 0.5 } else { set driveLevel3 [expr int($driveLevel)] }
      if {$refDriverOrSink == "refDriver"} {
        set rawResultDrive [lindex [lsort -increasing -real [concat [expr $driveLevel1 * (1 + $maxExcessRatio)] $driveLevel3]] 0] ;
      } elseif {$refDriverOrSink == "refSink"} {
        set rawResultDrive [lindex [lsort -increasing -real [concat [expr $driveLevel2 * (1 + $maxExcessRatio)] $driveLevel3]] 0] ;
      } elseif {$refDriverOrSink == "autoBig"} {
        lassign [lsort -increasing -real [concat $driveLevel1 $driveLevel2]] minDrive maxDrive
        set rawResultDrive [lindex [lsort -increasing -real [concat [expr $maxDrive * (1 + $maxExcessRatio)] $driveLevel3]] 0] ;
      } elseif {$refDriverOrSink == "autoSmall"} {
        lassign [lsort -increasing -real [concat $driveLevel1 $driveLevel2]] minDrive maxDrive
        set rawResultDrive [lindex [lsort -increasing -real [concat [expr $minDrive * (1 + $maxExcessRatio)] $driveLevel3]] 0] ;
      } else {
        error "check your input!!! var refDriverOrSink can specify: refSink|refDriver|autoBig|autoSmall"
      }
      set processType [whichProcess_fromStdCellPattern $toCheckCelltype]
      if {$processType == "TSMC"} {
        regsub D${driveLevel}BWP $celltype D*BWP searchCelltypeExp
      } elseif {$processType == "HH"} {
        regsub [subst {(.*)X$driveLevel}] $celltype [subst {\\1X*}] searchCelltypeExp
      }
      set availableCelltypeList [dbget head.libCells.name $searchCelltypeExp]
      set availableDriveCapacityList [lsort -unique [lmap Acelltype $availableCelltypeList {
        regexp $regExp $Acelltype wholename AdriveLevel AVTtype
        if {$AdriveLevel == "05"} {set AdriveLevel 0.5} else { set AdriveLevel}
      }]]
      set resultDrive [find_nearestNum_atIntegerList $availableDriveCapacityList $rawResultDrive 0 1] ;
      return [changeDriveCapacity_of_celltype $toCheckCelltype $driveLevel3 $resultDrive]
    }
  }
}
# Skipping already processed file: ./proc_whichProcess_fromStdCellPattern.invs.tcl
# Skipping already processed file: ./proc_find_nearestNum_atIntegerList.invs.tcl
# Skipping already processed file: ./proc_changeDriveCapacity_of_celltype.invs.tcl
proc calculateResistantCenter_fromPoints {pointsList {filterStrategy "auto"} {threshold 3.0} {densityThreshold 0.75} {minPoints 5}} {
  set pointCount [llength $pointsList]
  if {$pointCount == 0} {
    return "0x0:1";
  }
  set sumX 0.0
  set sumY 0.0
  foreach point $pointsList {
    lassign $point x y
    set sumX [expr {$sumX + $x}]
    set sumY [expr {$sumY + $y}]
  }
  set rawMeanX [expr {$sumX / $pointCount}]
  set rawMeanY [expr {$sumY / $pointCount}]
  set distances {}
  foreach point $pointsList {
    lassign $point x y
    set dx [expr {$x - $rawMeanX}]
    set dy [expr {$y - $rawMeanY}]
    lappend distances [expr {sqrt($dx*$dx + $dy*$dy)}]
  }
  switch -- $filterStrategy {
    "never" {
      return [list $rawMeanX $rawMeanY]
    }
    "always" {
      set shouldFilter 1
    }
    "auto" {
      set sumDist 0.0
      foreach dist $distances {
        set sumDist [expr {$sumDist + $dist}]
      }
      set avgDist [expr {$sumDist / $pointCount}]
      set sumSqDiff 0.0
      foreach dist $distances {
        set diff [expr {$dist - $avgDist}]
        set sumSqDiff [expr {$sumSqDiff + ($diff * $diff)}]
      }
      set stdDev [expr {sqrt($sumSqDiff / $pointCount)}]
      if {$stdDev < 1e-10} {
        set shouldFilter 0
        set skewness 0.0
      } else {
        set sumCubedDiff 0.0
        foreach dist $distances {
          set diff [expr {$dist - $avgDist}]
          set sumCubedDiff [expr {$sumCubedDiff + ($diff * $diff * $diff)}]
        }
        set skewness [expr {$sumCubedDiff / ($pointCount * ($stdDev ** 3))}]
      }
      set adjustedOutlierThreshold $threshold
      set adjustedDensityThreshold $densityThreshold
      if {$skewness > 1.0} {
        set adjustedOutlierThreshold [expr {$threshold * (1.0 + $skewness/5.0)}]
      }
      if {$avgDist < 1e-10} {
        set shouldFilter 0
        set relativeStdDev 0.0
      } else {
        set relativeStdDev [expr {$stdDev / $avgDist}]
        if {$relativeStdDev > 0.5} {
          set reductionFactor [expr {0.2 * ($relativeStdDev - 0.5)}]
          set adjustedDensityThreshold [expr {$densityThreshold * (1.0 - $reductionFactor)}]
        }
      }
      if {$stdDev >= 1e-10} {
        set inlierCount 0
        foreach dist $distances {
          if {$dist <= $adjustedOutlierThreshold * $stdDev} {
            incr inlierCount
          }
        }
        set inlierRatio [expr {$inlierCount / double($pointCount)}]
        if {$inlierRatio < $adjustedDensityThreshold} {
          set shouldFilter 1
        } else {
          set shouldFilter 0
        }
      }
    }
    default {
      error "Invalid filterStrategy: must be 'auto', 'always', or 'never'"
    }
  }
  if {!$shouldFilter || $pointCount < $minPoints} {
    return [list $rawMeanX $rawMeanY]
  }
  set sumDist 0.0
  foreach dist $distances {
    set sumDist [expr {$sumDist + $dist}]
  }
  set avgDist [expr {$sumDist / $pointCount}]
  set sumSqDiff 0.0
  foreach dist $distances {
    set diff [expr {$dist - $avgDist}]
    set sumSqDiff [expr {$sumSqDiff + ($diff * $diff)}]
  }
  set stdDev [expr {sqrt($sumSqDiff / $pointCount)}]
  if {$stdDev < 1e-10} {
    return [list $rawMeanX $rawMeanY]
  }
  set filteredPoints {}
  for {set i 0} {$i < $pointCount} {incr i} {
    if {[lindex $distances $i] <= $threshold * $stdDev} {
      lappend filteredPoints [lindex $pointsList $i]
    }
  }
  if {[llength $filteredPoints] == 0} {
    return [list $rawMeanX $rawMeanY]
  }
  set sumX 0.0
  set sumY 0.0
  foreach point $filteredPoints {
    lassign $point x y
    set sumX [expr {$sumX + $x}]
    set sumY [expr {$sumY + $y}]
  }
  return [list [expr {$sumX / [llength $filteredPoints]}] [expr {$sumY / [llength $filteredPoints]}]]
}
proc zip {list1 list2} {
  set result {}
  for {set i 0} {$i < [min [llength $list1] [llength $list2]]} {incr i} {
    lappend result [list [lindex $list1 $i] [lindex $list2 $i]]
  }
  return $result
}
proc min {a b} {
  expr {$a < $b ? $a : $b}
}
proc calculateRelativePoint {startPoint endPoint {relativeValue 0.5} {clampValue 1} {epsilon 1e-10}} {
  if {[llength $startPoint] != 2 || [llength $endPoint] != 2} {
    error "Both startPoint and endPoint must be 2D coordinates in the format {x y}"
  }
  lassign $startPoint startX startY
  lassign $endPoint endX endY
  if {$clampValue} {
    if {$relativeValue < 0.0} {
      set relativeValue 0.0
    } elseif {$relativeValue > 1.0} {
      set relativeValue 1.0
    }
  } else {
    if {$relativeValue < 0.0 - $epsilon || $relativeValue > 1.0 + $epsilon} {
      error "relativeValue must be between 0 and 1 (or use clampValue=1 to auto-clamp)"
    }
  }
  set x [expr {$startX + $relativeValue * ($endX - $startX)}]
  set y [expr {$startY + $relativeValue * ($endY - $startY)}]
  if {abs($relativeValue - 0.0) < $epsilon} {
    set x $startX
    set y $startY
  } elseif {abs($relativeValue - 1.0) < $epsilon} {
    set x $endX
    set y $endY
  }
  set x [format "%.3f" $x]
  set y [format "%.3f" $y]
  return [list $x $y]
}
proc calculateDistance {point1 point2 {epsilon 1e-10} {maxValue 1.0e+100}} {
  if {[llength $point1] != 2 || [llength $point2] != 2} {
    error "Both points must be 2D coordinates in the format {x y}"
  }
  lassign $point1 x1 y1
  lassign $point2 x2 y2
  if {![string is double -strict $x1] || ![string is double -strict $y1] || ![string is double -strict $x2] || ![string is double -strict $y2]} {
    error "Coordinates must be valid numeric values"
  }
  foreach coord [list $x1 $y1 $x2 $y2] {
    if {abs($coord) > $maxValue} {
      error "Coordinate value exceeds maximum allowed ($maxValue)"
    }
  }
  set dx [expr {$x2 - $x1}]
  set dy [expr {$y2 - $y1}]
  if {abs($dx) > $maxValue || abs($dy) > $maxValue} {
    error "Coordinate difference exceeds maximum allowed ($maxValue)"
  }
  set sumSq [expr {$dx*$dx + $dy*$dy}]
  if {$sumSq < $epsilon} {
    return 0.0
  }
  return [format "%.3f" [expr {sqrt($sumSq)}]]
}
proc findMostFrequentElement {inputList {minPercentage 50.0} {returnUnique 1}} {
	set listLength [llength $inputList]
	if {$listLength == 0} {
		error "proc findMostFrequentElement: input list is empty!!!"
	}
	array set count {}
	foreach element $inputList {
		incr count($element)
	}
	set maxCount 0
	foreach element [array names count] {
		if {$count($element) > $maxCount} {
			set maxCount $count($element)
		}
	}
	set frequencyPercentage [expr {($maxCount * 100.0) / $listLength}]
	if {$frequencyPercentage < $minPercentage} {
		if {$returnUnique} {
			return [lsort -unique $inputList]  ;
		} else {
			return ""  ;
		}
	}
	set mostFrequentElements {}
	foreach element [array names count] {
		if {$count($element) == $maxCount} {
			lappend mostFrequentElements $element
		}
	}
	return [lindex $mostFrequentElements 0]
}
proc reverseListRange {listVar {startIdx ""} {endIdx ""} {deep 0} {groupSize 0} {groupByHash 0} {hashMarker "#"} {allowMixedGroups 0}} {
  if {![string is list -strict $listVar]} {
    error "Input is not a valid list: '$listVar'"
  }
  set originalList $listVar
  set listLen [llength $originalList]
  if {$groupSize > 0 && $groupByHash} {
    error "Cannot enable both 'groupSize' and 'groupByHash' modes simultaneously"
  }
  if {$groupSize < 0} {
    error "groupSize must be a non-negative integer, got: $groupSize"
  }
  if {$groupSize > 0 && $listLen > 0 && $groupSize > $listLen} {
    error "groupSize ($groupSize) larger than list length ($listLen)"
  }
  if {![string is boolean -strict $groupByHash]} {
    error "groupByHash must be 0 or 1, got: $groupByHash"
  }
  if {$hashMarker eq ""} {
    error "hashMarker cannot be an empty string"
  }
  if {$startIdx eq ""} {set startIdx 0}
  if {$endIdx eq ""} {set endIdx [expr {$listLen - 1}]}
  if {$startIdx eq "end"} {set startIdx [expr {$listLen - 1}]}
  if {$endIdx eq "end"} {set endIdx [expr {$listLen - 1}]}
  foreach idx {startIdx endIdx} {
    if {![string is integer -strict [set $idx]]} {
      error "$idx must be a valid integer or 'end', got: [set $idx]"
    }
    if {[set $idx] < 0} {
      set $idx [expr {$listLen + [set $idx]}]
    }
    if {[set $idx] < 0 || [set $idx] >= $listLen} {
      error "$idx ([set $idx]) out of bounds (original list length $listLen)"
    }
  }
  if {$startIdx > $endIdx} {
    error "startIdx ($startIdx) cannot be greater than endIdx ($endIdx)"
  }
  set groups [list]
  if {$groupSize > 0} {
    for {set i 0} {$i < $listLen} {incr i $groupSize} {
      set groupEnd [expr {min($i + $groupSize - 1, $listLen - 1)}]
      lappend groups [lrange $originalList $i $groupEnd]
    }
  } elseif {$groupByHash} {
    set currentGroup [list]
    for {set i 0} {$i < $listLen} {incr i} {
      set elem [lindex $originalList $i]
      set isMarker [expr {
        [string index [lindex $elem 0] 0] eq $hashMarker
        ? 1
        : ([string index $elem 0] eq $hashMarker ? 1 : 0)
      }]
      if {$isMarker && [llength $currentGroup] > 0} {
        lappend groups $currentGroup
        set currentGroup [list $elem]
      } else {
        lappend currentGroup $elem
      }
    }
    if {[llength $currentGroup] > 0} {
      lappend groups $currentGroup
    }
  } else {
    foreach elem $originalList {
      lappend groups [list $elem]
    }
  }
  set groupCount [llength $groups]
  if {$groupSize > 0 || $groupByHash} {
    set groupElementRanges [list]
    set elemPos 0
    foreach group $groups {
      set groupLen [llength $group]
      lappend groupElementRanges [list $elemPos [expr {$elemPos + $groupLen - 1}]]
      incr elemPos $groupLen
    }
    set startGroup -1
    set endGroup -1
    for {set g 0} {$g < $groupCount} {incr g} {
      lassign [lindex $groupElementRanges $g] gStart gEnd
      if {$startGroup == -1 && $gEnd >= $startIdx} {
        set startGroup $g
      }
      if {$gStart <= $endIdx} {
        set endGroup $g
      }
    }
    if {$startGroup == -1} {set startGroup 0}
    if {$endGroup == -1} {set endGroup [expr {$groupCount - 1}]}
    if {$startGroup > $endGroup} {
      error "No groups overlap with the specified element range ($startIdx-$endIdx)"
    }
  } else {
    set startGroup $startIdx
    set endGroup $endIdx
    set startGroup [expr {max(0, min($startGroup, $groupCount - 1))}]
    set endGroup [expr {max(0, min($endGroup, $groupCount - 1))}]
  }
  set groupsToReverse [lrange $groups $startGroup $endGroup]
  set reversedGroups [lreverse $groupsToReverse]
  set groupedResult [lreplace $groups $startGroup $endGroup {*}$reversedGroups]
  set result [list]
  foreach group $groupedResult {
    lappend result {*}$group
  }
  if {$deep} {
    set deepResult [list]
    foreach elem $result {
      if {[llength $elem] > 1 && [string is list -strict $elem]} {
        set subListLen [llength $elem]
        set subStartIdx [expr {min($startIdx, $subListLen - 1)}]
        set subEndIdx [expr {min($endIdx, $subListLen - 1)}]
        lappend deepResult [reverseListRange $elem $subStartIdx $subEndIdx 1 0 0]
      } else {
        lappend deepResult $elem
      }
    }
    set result $deepResult
  }
  return $result
}
if {0} {
  set testList {a b c d e f {g h} #i j k #l m n}
  puts "示例1：无分组反转整个列表"
  puts "原始: $testList"
  puts "结果: [reverseListRange $testList]\n"
  puts "示例2：每2个元素一组，反转1-4元素"
  puts "原始: $testList"
  puts "结果: [reverseListRange $testList 1 4 0 2]\n"
  puts "示例3：按#号分组，反转所有组"
  puts "原始: $testList"
  puts "结果: [reverseListRange $testList 0 end 0 0 1]\n"
  puts "示例4：深度反转子列表"
  puts "原始: $testList"
  puts "结果: [reverseListRange $testList 0 end 1 0 1]\n"
  puts "示例5：分组+深度反转"
  puts "原始: {1 {2 3} 4 #5 6 {7 8} #9 10}"
  puts "结果: [reverseListRange {1 {2 3} 4 #5 6 {7 8} #9 10} 0 end 1 0 1]"
}
alias fm "formatDecimal"
proc formatDecimal {value {fixedLength 2} {strictRange 1} {padZero 1}} {
	if {![string is double -strict $value]} {
		error "Invalid input: '$value' is not a valid decimal number"
	}
	if {$strictRange && ($value <= 0.0 || $value >= 1.0)} {
		error "Value must be between 0 and 1 (exclusive)"
	}
	set strValue [string map {"0." ""} [format "%.15g" $value]]
	if {$strValue eq ""} {
		if {$padZero} {
			return "0[string repeat "0" [expr {$fixedLength - 1}]]"
		} else {
			return "0"
		}
	}
	if {$fixedLength > 0} {
		set remainingLength [expr {$fixedLength - 1}]
		if {$remainingLength <= 0} {
			return "0"
		}
		if {$padZero} {
			set paddedValue [string range [format "%0*s" $remainingLength $strValue] 0 $remainingLength-1]
		} else {
			set paddedValue [string range $strValue 0 $remainingLength-1]
		}
		return "0$paddedValue"
	} else {
		return "0$strValue"
	}
}
proc checkRoutingLoop {straightDistance netLength {severityLevel "normal"}} {
	if {![string is double -strict $straightDistance] || $straightDistance <= 0} {
		error "PROC checkRoutingLoop: Invalid parameter 'straightDistance' - must be a positive number ($straightDistance)"
	}
	if {![string is double -strict $netLength] || $netLength <= 0} {
		error "PROC checkRoutingLoop: Invalid parameter 'netLength' - must be a positive number ($netLength)"
	}
	set straightDistance [expr {double($straightDistance)}]
	set netLength [expr {double($netLength)}]
	set thresholds [dict create \
		normal  {1.5 2.0 3.0} \
		relaxed {1.8 2.5 3.5} \
		strict  {1.2 1.8 2.5}
	]
	if {![dict exists $thresholds $severityLevel]} {
		puts "WARNING: Unknown severity level '$severityLevel', using default 'normal'"
		set severityLevel "normal"
	}
	lassign [dict get $thresholds $severityLevel] mildThreshold moderateThreshold severeThreshold
	set lengthRatio [expr {$netLength / $straightDistance}]
	if {$lengthRatio <= $mildThreshold} {
		return 0 ;
	} elseif {$lengthRatio <= $moderateThreshold} {
		return 1 ;
	} elseif {$lengthRatio <= $severeThreshold} {
		return 2 ;
	} else {
		return 3 ;
	}
}
proc getLoopDescription {loopLevel} {
	switch -- $loopLevel {
		0 { return "No Loop" }
		1 { return "Mild Loop" }
		2 { return "Moderate Loop" }
		3 { return "Severe Loop" }
		default { return "Unknown Level" }
	}
}
if {0} {
	puts "Testing checkRoutingLoop procedure:"
	puts "Straight Distance\tNet Length\tSeverity Level\tLoop Level\tDescription"
	puts "------------------------------------------------------------"
	foreach {dist length level} {
		10.0   12.0   normal
		10.0   18.0   normal
		10.0   22.0   normal
		10.0   35.0   normal
		10.0   12.0   strict
		10.0   12.0   relaxed
		10.0   -5.0   normal
		abc    20.0   normal
	} {
		puts -nonewline "$dist\t\t$length\t\t$level\t\t"
		if {[catch {set result [checkRoutingLoop $dist $length $level]} errMsg]} {
			puts "ERROR: $errMsg"
		} else {
			set desc [getLoopDescription $result]
			puts "$result\t\t$desc"
		}
	}
}
