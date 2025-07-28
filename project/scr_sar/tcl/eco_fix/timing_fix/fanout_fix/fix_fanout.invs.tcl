#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/07/26 17:19:00 Saturday
# label     : task_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|misc_proc)
# descrip   : fix maxFanout/maxCap using K-means algorithm
# ref       : link url
# --------------------------
source ./proc_every.common.tcl; # every
source ./proc_get_driverSinksNameLocations.invs.tcl; # get_driverSinksNameLocations - return {{drivename {x y}} {{sink1name {x y}} {sink2name {x y}} ...}}
source ./proc_group_points_by_distribution.invsGUI.tcl; # group_points_by_distribution 
source ./proc_canSolveViolation_byBufferVT.invs.tcl; # can_solve_violation_by_buffer_vt - return 1, need addRepeater to fix fanout
source ./proc_print_cmdDeleteNet.invs.tcl; # print_cmdDeleteNet
source ../trans_fix/proc_calculateRelativePoint.invs.tcl; # calculateRelativePoint - return {x y}
source ../trans_fix/proc_get_fanoutNum_and_inputTermsName_of_pin.invs.tcl; # get_fanoutNum_and_inputTermsName_of_pin - return {num {numNameList}}
source ../trans_fix/proc_print_ecoCommands.invs.tcl; # print_ecoCommand
source ../trans_fix/proc_get_cell_class.invs.tcl; # get_cell_class
source ../trans_fix/proc_get_cellDriveLevel_and_VTtype_of_inst.invs.tcl; # get_cellDriveLevel_and_VTtype_of_inst - return {instname cellName driveCapacity VTtype}
source ../trans_fix/proc_getPt_ofObj.invs.tcl; # getPt_ofObj - alias gpt
source ../trans_fix/proc_calculateResistantCenter.invs.tcl; # calculateResistantCenter_fromPoints
source ../trans_fix/proc_calculateDistance_betweenTwoPoint.invs.tcl; # calculateDistance
source ../trans_fix/proc_findMostFrequentElementOfList.invs.tcl; # findMostFrequentElement
source ../trans_fix/proc_changeDriveCapacity_of_celltype.invs.tcl; # changeDriveCapacity_of_celltype
source ../trans_fix/proc_getDriveCapacity_ofCelltype.invs.tcl; # get_driveCapacity_of_celltype
source ../trans_fix/proc_formatDecimal.invs.tcl; # fm - formatDecimal
source ../trans_fix/proc_get_net_lenth.invs.tcl; # get_net_length
source ../trans_fix/proc_print_formatedTable.common.tcl; # print_formatedTable
source ../trans_fix/proc_pw_puts_message_to_file_and_window.common.tcl; # pw
source ../trans_fix/proc_strategy_changeVT.invs.tcl; # strategy_changeVT
source ../../../logic_or_and.common.tcl; # eo
source ../../../incr_integer_inself.common.tcl; # ci

proc fix_fanout {args} {
  set file_viol            ""
  set column_viol_pinname  {4 1}
  set refNormalCelltype    "BUFX8AL9"
  set refClkCelltype       "CLKBUFX8AL9"
  set cellRegExp           "X(\\d+).*(A\[HRL\]\\d+)$"
  set fastestVT            "AL9"
  set ecoNewInstNamePrefix ""
  set suffixOfSummaryFile  ""
  set ifDeleteNet          1
  set radius               8
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }

  if {$file_viol == "" || [glob -nocomplain $file_viol] == ""} {
    error "proc fix_fanout: check your input, have no file name: $file_viol !!!"
  } elseif { [llength $column_viol_pinname] != 2 || [every [lmap c $column_viol_pinname {[string is integer $c]}] 1] } {
    error "proc fix_fanout: check your input, or column_viol_pinname($column_viol_pinname) has error!!!"
  } else {

    # read file
    set fi [open $file_viol r]
    set violValue_violDriverPin_violSinkPins_numSinks [list]
    while {[gets $fi line] > -1} {
      set col_viol [expr [lindex $column_viol_pinname 0] - 1]
      set col_pinname [expr [lindex $column_viol_pinname 1] - 1]
      set viol_value [lindex $line $col_viol]
      set viol_pin [lindex $line $col_pinname]
      set driver_pin [get_driver_pin $viol_pin]
      set temp_violValue_violDriverPin_violSinkPins_numSinks [list $viol_value $driver_pin {*}[lreverse [get_fanoutNum_and_inputTermsName_of_pin $driver_pin]]]
      if {[lindex $temp_violValue_violDriverPin_violSinkPins_numSinks end] > 1} {
        lappend violValue_violDriverPin_violSinkPins_numSinks $temp_violValue_violDriverPin_violSinkPins_numSinks
      } else {
        lappend one2one_violValue_violDriverPin_violSinkPin [lrange $temp_violValue_violDriverPin_violSinkPins_numSinks 0 end-1]
      }
    }
    close $fi

    # sort List
    set violValue_violDriverPin_violSinkPins_numSinks [lsort -index 0 -real -decreasing $violValue_violDriverPin_violSinkPins_numSinks]
    set violValue_violDriverPin_violSinkPins_numSinks [lsort -index 0 -increasing [lsort -unique -index 1 $violValue_violDriverPin_violSinkPins_numSinks]]

    # initialize List
    set fixedList [list [list situ method celltypeToFix numLoaded violVal netLen distance ifLoop driveClass driverCelltype driverViolPin numSinks sinksClass]]
    set cmdList [list ]
    set selectLoadedTermsList [list ]
    set needntInsertList [list [list situ violVal netLen distance ifLoop driveClass driverCelltype driverViolPin numSinks sinksClass]]
    set notConsideredList [list [list situ violVal netLen distance ifLoop driveClass driverCelltype driverViolPin numSinks sinksClass]]
    set multipleSinksTypeList [list [list situ violVal netLen distance ifLoop driveClass driverCelltype driverViolPin numSinks sinksClass]]

    # analyze List
    foreach viol_driverPin_sinkPins_numSinks $violValue_violDriverPin_violSinkPins_numSinks {
      lassign $viol_driverPin_sinkPins_numSinks violValue driverPin sinkPins numSinks
      lassign [get_cellDriveLevel_and_VTtype_of_inst $driverPin $cellRegExp] driverInstname driverCelltype driverCapacity driverVT

      set driverSinksInfo [get_driverSinksNameLocations $driverPin]
      set driverLoc [lindex $driverSinksInfo 0 1]
      set distributionInfo [group_points_by_distribution {*}$driverSinksInfo]
      lassign $distributionInfo fartherGroup closerGroup
      lassign $fartherGroup groupedPinnameLocations rawCenterPoint
      set numLoadedSinks [llength $groupedPinnameLocations]
      set loadedSinkPinnames [lmap g $groupedPinnameLocations {lindex $g 0}]
      set driverCellClass [get_cell_class $driverPin]
      set sinksCellClass [lmap sink $sinkPins { ; # rearrange cell class for sinks celltype
        set class [get_cell_class $sink]
        if {$class in {CLKlogic delay sequential}} {
          set class logic
        } elseif {$class in {CLKbuffer CLKinverter inverter}} {
          set class buffer
        }
        set class
      }]
      set uniqueSinksCellClass [findMostFrequentElement $sinksCellClass]
      set violNet [dbget [dbget top.insts.instTerms.name $driverPin -p].net.name]
      set netLength [get_net_length $violNet]
      set sinkPts [lmap sink $sinkPins {set pt [gpt $sink]}]
      set centerPtOfAllSinks [calculateResistantCenter_fromPoints $sinkPts]
      set distanceOfDriver2CenterOfAllSinks [calculateDistance $centerPtOfAllSinks $driverLoc]
      set flagMultipleSinksType 0
      if {[llength $uniqueSinksCellClass] > 1} {
        set flagMultipleSinksType 1
        set uniqueSinksCellClass [lmap type $uniqueSinksCellClass {
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
      } 
      set allInfo [list $violValue $netLength $distanceOfDriver2CenterOfAllSinks "/" $driverCellClass $driverCelltype $driverPin "-$numSinks-" $uniqueSinksCellClass]
      set cmd1 ""
      set flagNeedUseInsertRepeater [ifNeedUseInsertRepeater $driverCelltype $violValue $fastestVT $cellRegExp]
      if {$flagNeedUseInsertRepeater && !$flagMultipleSinksType} {
        # select drive capacity
        set flagNeedChangeCapacityOrVT 0
        set refCelltype $refNormalCelltype
        if {[regexp CLK $driverCellClass]} {
          set refCelltype $refClkCelltype
          set refDriveCapacity [get_driveCapacity_of_celltype $refCelltype $cellRegExp]
          if {$driverCapacity >= 8 } {
            set refCelltype [changeDriveCapacity_of_celltype $refCelltype $refDriveCapacity 8]
          } elseif {$driverCapacity in {4 6}} {
            set refCelltype [changeDriveCapacity_of_celltype $refCelltype $refDriveCapacity 4]
          } else {
            set flagNeedChangeCapacityOrVT 1
          }
        } else {
          set refDriveCapacity [get_driveCapacity_of_celltype $refCelltype $cellRegExp]
          if {$driverCapacity >= 12 } {
            set refCelltype [changeDriveCapacity_of_celltype $refCelltype $refDriveCapacity 12]
          } elseif {$driverCapacity in {8}} {
            set refCelltype [changeDriveCapacity_of_celltype $refCelltype $refDriveCapacity 8]
          } elseif {$driverCapacity in {4 6}} {
            set refCelltype [changeDriveCapacity_of_celltype $refCelltype $refDriveCapacity 4]
          } else {
            set flagNeedChangeCapacityOrVT 1
          }
        }
        if {$driverVT == "AR9"} {
          set refCelltype [strategy_changeVT $refCelltype {{AL9 0} {AR9 1} {AH9 0}} {AL9 AR9 AH9} $cellRegExp 1]
        } elseif {$driverVT == "AL9"} {
          set refCelltype [strategy_changeVT $refCelltype {{AL9 1} {AR9 0} {AH9 0}} {AL9 AR9 AH9} $cellRegExp 1]
        }
        if {$refCelltype == ""} {
          set refCelltype none
        }
# -------------------------------------------------------
# buffer - logic
        if {$driverCellClass in {CLKbuffer CLKinverter buffer inverter} && [llength $uniqueSinksCellClass] == 1 && $uniqueSinksCellClass in {logic} } {
          set relativeIndex 0.6 ; # for buffer to logic
          set locInsertRepeater [calculateRelativePoint $rawCenterPoint $driverLoc $relativeIndex]
          lappend fixedList [list "bl" "MA_[fm $relativeIndex]" $refCelltype "-$numLoadedSinks-" {*}$allInfo]
          if {$ifDeleteNet} { lappend cmd1 [print_cmdDeleteNet $driverPin] }
          lappend cmd1 [print_ecoCommand -type add -term $loadedSinkPinnames -celltype $refCelltype -loc $locInsertRepeater -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci cmd1] -radius $radius]
          lappend selectLoadedTermsList "# for driver pin: loaded num: -$numLoadedSinks- allSinks num: -$numSinks- $driverPin"
          lappend selectLoadedTermsList "alias so[ci select] \"select_obj \{$loadedSinkPinnames\}\""
# -------------------------------------------------------
# buffer - buffer
        } elseif {$driverCelltype in {CLKbuffer CLKinverter buffer inverter} && [llength $uniqueSinksCellClass] == 1 && $uniqueSinksCellClass in {buffer}} {
          set relativeIndex 0.7 ; # for buffer to buffer
          set locInsertRepeater [calculateRelativePoint $rawCenterPoint $driverLoc $relativeIndex]
          lappend fixedList [list "bb" "MA_[fm $relativeIndex]" $refCelltype "-$numLoadedSinks-" {*}$allInfo]
          if {$ifDeleteNet} { lappend cmd1 [print_cmdDeleteNet $driverPin] }
          lappend cmd1 [print_ecoCommand -type add -term $loadedSinkPinnames -celltype $refCelltype -loc $locInsertRepeater -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci cmd1] -radius $radius]
          lappend selectLoadedTermsList "# for driver pin: loaded num: -$numLoadedSinks- allSinks num: -$numSinks- $driverPin"
          lappend selectLoadedTermsList "alias so[ci select] \"select_obj \{$loadedSinkPinnames\}\""
# -------------------------------------------------------
# logic - logic
        } elseif {$driverCelltype in {CLKlogic logic} && [llength $uniqueSinksCellClass] == 1 && $uniqueSinksCellClass in {logic}} {; # delay is not consider now
          set relativeIndex 0.8 ; # for logic to logic
          set locInsertRepeater [calculateRelativePoint $rawCenterPoint $driverLoc $relativeIndex]
          lappend fixedList [list "ll" "MA_[fm $relativeIndex]" $refCelltype "-$numLoadedSinks-" {*}$allInfo]
          if {$ifDeleteNet} { lappend cmd1 [print_cmdDeleteNet $driverPin] }
          lappend cmd1 [print_ecoCommand -type add -term $loadedSinkPinnames -celltype $refCelltype -loc $locInsertRepeater -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci cmd1] -radius $radius]
          lappend selectLoadedTermsList "# for driver pin: loaded num: -$numLoadedSinks- allSinks num: -$numSinks- $driverPin"
          lappend selectLoadedTermsList "alias so[ci select] \"select_obj \{$loadedSinkPinnames\}\""
        }

      } elseif {!$flagNeedUseInsertRepeater && !$flagMultipleSinksType} {
        lappend needntInsertList [list "NI" {*}$allInfo]
        if {$driverVT != $fastestVT && $violValue >= -0.005} { ; # can change VT
          set refCelltype [strategy_changeVT $driverCelltype {{AL9 1} {AR9 0} {AH9 0}} {AL9 AR9 AH9} $cellRegExp 1]
          lappend fixedList [list "NI" "T" $refCelltype "-$numLoadedSinks-" {*}$allInfo]
          lappend cmd1 [print_ecoCommand -type change -celltype $refCelltype -inst $driverInstname]
        } elseif {$driverCapacity < 12 && $violValue >= -0.06} {
          # songNOTE: TODO!!!
        } 
      } elseif {$flagMultipleSinksType} {
        lappend multipleSinksTypeList [list "MT" {*}$allInfo]
      } else { ; # needn't insert repeater
      }
      # add comment for cmdList
      if {$cmd1 != "needntInsert" && $cmd1 != ""} {
        lappend cmdList "# [lindex $fixedList end]"
        if {[llength $cmd1] < 5} {
          set cmdList [concat $cmdList $cmd1]
        } else {
          lappend cmdList $cmd1
        }
      } else {
        lappend notConsideredList [list "NC" {*}$allInfo]
      }
    }
    
    # summary for fixed situation
    set sumFile [eo $suffixOfSummaryFile "fan_summaryOfResult_$suffixOfSummaryFile.list" "fan_summaryOfResult.list"]
    set cmdFile [eo $suffixOfSummaryFile "fan_ecocmds_$suffixOfSummaryFile.tcl" "fan_ecocmds.tcl"]
    set selectLoadedTermsFile [eo $suffixOfSummaryFile "fan_selectLoadedTerms_$suffixOfSummaryFile.tcl" "fan_selectLoadedTerms.tcl"]
    set su [open $sumFile w]
    set cm [open $cmdFile w]
    set sl [open $selectLoadedTermsFile w]
    if {[llength $cmdList] > 1} {
      pw $cm ""
      pw $cm "setEcoMode -reset"
      pw $cm "setEcoMode -batchMode true -updateTiming false -refinePlace false -honorDontTouch false -honorDontUse false -honorFixedNetWire false -honorFixedStatus false"
      pw $cm ""
      pw $cm [join $cmdList \n]
      pw $cm ""
      pw $cm "setEcoMode -reset"
      puts $sl [join $selectLoadedTermsList \n]
    } else {
      pw $cm "# HAVE NO FIXED CMD!!!"
    }
    if {[llength $fixedList] > 1} {
      pw $su "FIXED LIST:"
      pw $su [print_formatedTable $fixedList]
      pw $su ""
    } else {
      pw $su "HAVE NO FIXED SITUATION!!!"
      pw $su ""
    }
    if {[llength $multipleSinksTypeList] > 1} {
      pw $su "MULTIPLE SINKS TYPE LIST:"
      pw $su ""
      pw $su [print_formatedTable $multipleSinksTypeList]
      pw $su ""
    } else {
      pw $su "HAVE NO MULTIPLE-SINKS-TYPE SITUATION!!!"
      pw $su ""
    }
    if {[llength $needntInsertList] > 1} {
      pw $su "NEED NOT INSERT REPEATER (have changed VT or capacity in cmd file):"
      pw $su ""
      pw $su [print_formatedTable $needntInsertList]
      pw $su ""
    } else {
      pw $su "HAVE NO NEED-NOT-INSERT-REPEATER SITUATION!!!"
      pw $su ""
    }
    if {[llength $notConsideredList] > 1} {
      pw $su "NOT CONSIDERED:"
      pw $su [print_formatedTable $notConsideredList]
      pw $su ""
    } else {
      pw $su "HAVE NO NOT-CONSIDERED SITUATION!!!"
      pw $su ""
    }
    close $su ; close $cm ; close $sl
  }
}
define_proc_arguments fix_fanout \
  -info "fix fanout"\
  -define_args {
    {-file_viol "specify violation filename" AString string required}
    {-column_viol_pinname "specify the column of violValue and pinname" AList list optional}
    {-refNormalCelltype "specify ref buffer cell type name" AString string optional}
    {-refClkCelltype "specify ref clk buffer cell type name" AString string optional}
    {-cellRegExp "specify universal regExp for this process celltype, need pick out driveCapacity and VTtype" AString string optional}
    {-fastestVT "specify fastest VTtype for judging if it need insert repeater" AString string optional}
    {-ecoNewInstNamePrefix "specify a new name for inst when adding new repeater" AList list required}
    {-suffixOfSummaryFile "specify suffix of result filename" AString string optional}
    {-ifDeleteNet "specify if deleting net of driverPin" "" boolean optional}
  }

proc get_driver_pin {{pinname ""}} {
  return [dbget [dbget [dbget top.insts.instTerms.name $pinname -p].net.allTerms {.isOutput}].name ]
}

source ../trans_fix/proc_get_cell_class.invs.tcl; # get_cell_class
proc ifNeedUseInsertRepeater {{celltype ""} {violValue ""} {fastestVT "AL9"} {cellRegExp "X(\\d+).*(A\[HRL\]\\d+)$"}} {
  if {$celltype == "" || [dbget head.libCells.name $celltype -e] == "" || ![string is double $violValue]} {
    error "proc ifNeedUseInsertRepeater: check your input!!!"
  } else {
    if {[catch {regexp $cellRegExp $celltype wholename driveCapacity VTtype} errorInfo]} {
      error "can't regexp for celltype: $celltype\n ERROR info: $errorInfo"
    } elseif {![info exists wholename] || ![info exists driveCapacity] || ![info exists VTtype]} {
      error "regexp error: have no expression result for $celltype"
    } else {
      if {$driveCapacity == "05"} {set driveCapacity 0.5} ; # for HH40/M31 std cell library
      set cellclass [get_cell_class $celltype]
      if {$violValue >= -0.005} {
        if {$VTtype == $fastestVT} {
          return 1
        }
        return 0
      } elseif {$violValue >= -0.06} {
        if {$cellclass in {buffer inverter CLKbuffer CLKinverter} && $driveCapacity < 12} {
          if {[regexp CLK $celltype] && $driveCapacity < 8} {; # special rule for clk celltype
            return 0; # can fix viol by changing VT or capacity
          } 
          return 1; # need insert repeater to solve viol
        }
        if {$cellclass in {logic CLKlogic} && $driveCapacity <= 4 } {
          return 0
        }
        return 1
      } else {
        return 1
      }
    }
  }
}
