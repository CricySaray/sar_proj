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
    set violValue_violDriverPin_violSinkPins_numSinks [lsort -index 0 -real -decreasing $violValue_violDriverPin_violSinkPins_numSinks]
    set violValue_violDriverPin_violSinkPins_numSinks [lsort -index 0 -increasing [lsort -unique -index 1 $violValue_violDriverPin_violSinkPins_numSinks]]
    set fixedList [list [list situ method celltypeToFix numLoaded violVal netLen distance ifLoop driveClass driverCelltype driverViolPin numSinks sinksClass]]
    set cmdList [list ]
    set selectLoadedTermsList [list ]
    set needntInsertList [list [list situ violVal netLen distance ifLoop driveClass driverCelltype driverViolPin numSinks sinksClass]]
    set notConsideredList [list [list situ violVal netLen distance ifLoop driveClass driverCelltype driverViolPin numSinks sinksClass]]
    set multipleSinksTypeList [list [list situ violVal netLen distance ifLoop driveClass driverCelltype driverViolPin numSinks sinksClass]]
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
      set sinksCellClass [lmap sink $sinkPins { ;
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
        if {$driverCellClass in {CLKbuffer CLKinverter buffer inverter} && [llength $uniqueSinksCellClass] == 1 && $uniqueSinksCellClass in {logic} } {
          set relativeIndex 0.6 ;
          set locInsertRepeater [calculateRelativePoint $rawCenterPoint $driverLoc $relativeIndex]
          lappend fixedList [list "bl" "MA_[fm $relativeIndex]" $refCelltype "-$numLoadedSinks-" {*}$allInfo]
          if {$ifDeleteNet} { lappend cmd1 [print_cmdDeleteNet $driverPin] }
          lappend cmd1 [print_ecoCommand -type add -term $loadedSinkPinnames -celltype $refCelltype -loc $locInsertRepeater -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci cmd1] -radius $radius]
          lappend selectLoadedTermsList "# for driver pin: loaded num: -$numLoadedSinks- allSinks num: -$numSinks- $driverPin"
          lappend selectLoadedTermsList "alias so[ci select] \"select_obj \{$loadedSinkPinnames\}\""
        } elseif {$driverCelltype in {CLKbuffer CLKinverter buffer inverter} && [llength $uniqueSinksCellClass] == 1 && $uniqueSinksCellClass in {buffer}} {
          set relativeIndex 0.7 ;
          set locInsertRepeater [calculateRelativePoint $rawCenterPoint $driverLoc $relativeIndex]
          lappend fixedList [list "bb" "MA_[fm $relativeIndex]" $refCelltype "-$numLoadedSinks-" {*}$allInfo]
          if {$ifDeleteNet} { lappend cmd1 [print_cmdDeleteNet $driverPin] }
          lappend cmd1 [print_ecoCommand -type add -term $loadedSinkPinnames -celltype $refCelltype -loc $locInsertRepeater -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci cmd1] -radius $radius]
          lappend selectLoadedTermsList "# for driver pin: loaded num: -$numLoadedSinks- allSinks num: -$numSinks- $driverPin"
          lappend selectLoadedTermsList "alias so[ci select] \"select_obj \{$loadedSinkPinnames\}\""
        } elseif {$driverCelltype in {CLKlogic logic} && [llength $uniqueSinksCellClass] == 1 && $uniqueSinksCellClass in {logic}} {;
          set relativeIndex 0.8 ;
          set locInsertRepeater [calculateRelativePoint $rawCenterPoint $driverLoc $relativeIndex]
          lappend fixedList [list "ll" "MA_[fm $relativeIndex]" $refCelltype "-$numLoadedSinks-" {*}$allInfo]
          if {$ifDeleteNet} { lappend cmd1 [print_cmdDeleteNet $driverPin] }
          lappend cmd1 [print_ecoCommand -type add -term $loadedSinkPinnames -celltype $refCelltype -loc $locInsertRepeater -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci cmd1] -radius $radius]
          lappend selectLoadedTermsList "# for driver pin: loaded num: -$numLoadedSinks- allSinks num: -$numSinks- $driverPin"
          lappend selectLoadedTermsList "alias so[ci select] \"select_obj \{$loadedSinkPinnames\}\""
        }
      } elseif {!$flagNeedUseInsertRepeater && !$flagMultipleSinksType} {
        lappend needntInsertList [list "NI" {*}$allInfo]
        if {$driverVT != $fastestVT && $violValue >= -0.005} { ;
          set refCelltype [strategy_changeVT $driverCelltype {{AL9 1} {AR9 0} {AH9 0}} {AL9 AR9 AH9} $cellRegExp 1]
          lappend fixedList [list "NI" "T" $refCelltype "-$numLoadedSinks-" {*}$allInfo]
          lappend cmd1 [print_ecoCommand -type change -celltype $refCelltype -inst $driverInstname]
        } elseif {$driverCapacity < 12 && $violValue >= -0.06} {
        }
      } elseif {$flagMultipleSinksType} {
        lappend multipleSinksTypeList [list "MT" {*}$allInfo]
      } else { ;
      }
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
proc ifNeedUseInsertRepeater {{celltype ""} {violValue ""} {fastestVT "AL9"} {cellRegExp "X(\\d+).*(A\[HRL\]\\d+)$"}} {
  if {$celltype == "" || [dbget head.libCells.name $celltype -e] == "" || ![string is double $violValue]} {
    error "proc ifNeedUseInsertRepeater: check your input!!!"
  } else {
    if {[catch {regexp $cellRegExp $celltype wholename driveCapacity VTtype} errorInfo]} {
      error "can't regexp for celltype: $celltype\n ERROR info: $errorInfo"
    } elseif {![info exists wholename] || ![info exists driveCapacity] || ![info exists VTtype]} {
      error "regexp error: have no expression result for $celltype"
    } else {
      if {$driveCapacity == "05"} {set driveCapacity 0.5} ;
      set cellclass [get_cell_class $celltype]
      if {$violValue >= -0.005} {
        if {$VTtype == $fastestVT} {
          return 1
        }
        return 0
      } elseif {$violValue >= -0.06} {
        if {$cellclass in {buffer inverter CLKbuffer CLKinverter} && $driveCapacity < 12} {
          if {[regexp CLK $celltype] && $driveCapacity < 8} {;
            return 0;
          }
          return 1;
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
proc every {{List {}} {judgeValue true}} {
  set flag 1
  foreach temp $List {
    if {$temp == $judgeValue} {continue}
    set flag 0; break
  }
  return $flag
}
proc get_driverSinksNameLocations {{pinName ""}} { ;
  if {$pinName == "" || [dbget top.insts.instTerms.name $pinName -e] == ""} {
    error "proc get_rootLeafBranchData: check your input, can't find driver pin: $pinName"
  } else {
    set pin_ptr [dbget top.insts.instTerms.name $pinName -p]
    if {[dbget $pin_ptr.isOutput]} {
      set driverPin_ptr $pin_ptr
    } else {
      set driverPin_ptr [dbget $pin_ptr.net.allTerms {.isOutput}]
    }
    set driverPin_name [dbget $driverPin_ptr.name]
    set driverPin_loc [lindex [dbget $driverPin_ptr.pt] 0]
    set sinksNum [dbget $driverPin_ptr.net.numInputTerms]
    set sinksPins_ptr [dbget $driverPin_ptr.net.allTerms {.isInput}]
    set sinksPins_loc [dbget $sinksPins_ptr.pt]
    set wiresLines [dbget $driverPin_ptr.net.wires.pts]
    set driverInfo [list $driverPin_name $driverPin_loc]
    set sinksInfo [lmap sink_ptr $sinksPins_ptr {
      set pinname [dbget $sink_ptr.name]
      set pinloc  [lindex [dbget $sink_ptr.pt] 0]
      set keyvalue [list $pinname $pinloc]
    }]
    return [list $driverInfo $sinksInfo] ;
  }
}
proc group_points_by_distribution {start_point end_points {debug 0}} {
	if {[llength $start_point] != 2} {
		error "Invalid start point format, should be {name {x y}}"
	}
	foreach ep $end_points {
		if {[llength $ep] != 2} {
			error "Invalid end point format, should be {name {x y}}"
		}
	}
	set start_name [lindex $start_point 0]
	set start_coords [lindex $start_point 1]
	set sx [lindex $start_coords 0]
	set sy [lindex $start_coords 1]
	if {$debug} {
		puts "DEBUG: Start point - $start_name ($sx, $sy)"
		puts "DEBUG: Total [llength $end_points] end points to group"
	}
	set distances {}
	foreach ep $end_points {
		set ep_name [lindex $ep 0]
		set ep_coords [lindex $ep 1]
		set epx [lindex $ep_coords 0]
		set epy [lindex $ep_coords 1]
		set dx [expr {$epx - $sx}]
		set dy [expr {$epy - $sy}]
		set dist [expr {sqrt($dx*$dx + $dy*$dy)}]
		lappend distances [list $ep_name $dist $ep_coords]
		if {$debug} {
			puts "DEBUG: Point $ep_name at ($epx, $epy) distance to start: $dist"
		}
	}
	set sorted_dists [lsort -index 1 $distances]
	set center1 [list $sx $sy]
	set far_point [lindex $sorted_dists end]
	set center2 [lindex $far_point 2]
	if {$debug} {
		puts "DEBUG: Initial center1: ($sx, $sy)"
		puts "DEBUG: Initial center2: [lindex $center2 0], [lindex $center2 1]"
	}
	for {set iter 0} {$iter < 3} {incr iter} {
		if {$debug} {
			puts "DEBUG: Iteration $iter"
		}
		set group1 {}
		set group2 {}
		foreach point $distances {
			set p_name [lindex $point 0]
			set p_coords [lindex $point 2]
			set px [lindex $p_coords 0]
			set py [lindex $p_coords 1]
			set dx1 [expr {$px - [lindex $center1 0]}]
			set dy1 [expr {$py - [lindex $center1 1]}]
			set dist1 [expr {sqrt($dx1*$dx1 + $dy1*$dy1)}]
			set dx2 [expr {$px - [lindex $center2 0]}]
			set dy2 [expr {$py - [lindex $center2 1]}]
			set dist2 [expr {sqrt($dx2*$dx2 + $dy2*$dy2)}]
			if {$dist1 < $dist2} {
				lappend group1 $p_name
				if {$debug} {
					puts "DEBUG: Point $p_name assigned to group1 (Dist to C1: $dist1, C2: $dist2)"
				}
			} else {
				lappend group2 $p_name
				if {$debug} {
					puts "DEBUG: Point $p_name assigned to group2 (Dist to C1: $dist1, C2: $dist2)"
				}
			}
		}
		set sum_x1 0.0
		set sum_y1 0.0
		foreach p_name $group1 {
			foreach ep $end_points {
				if {[lindex $ep 0] eq $p_name} {
					set coords [lindex $ep 1]
					set sum_x1 [expr {$sum_x1 + [lindex $coords 0]}]
					set sum_y1 [expr {$sum_y1 + [lindex $coords 1]}]
					break
				}
			}
		}
		set count1 [llength $group1]
		if {$count1 > 0} {
			set center1 [list [expr {$sum_x1 / $count1}] [expr {$sum_y1 / $count1}]]
			set center1 [format "%.2f %.2f" {*}$center1]
			if {$debug} {
				puts "DEBUG: New center1: [format "%.2f" [lindex $center1 0]], [format "%.2f" [lindex $center1 1]]"
			}
		}
		set sum_x2 0.0
		set sum_y2 0.0
		foreach p_name $group2 {
			foreach ep $end_points {
				if {[lindex $ep 0] eq $p_name} {
					set coords [lindex $ep 1]
					set sum_x2 [expr {$sum_x2 + [lindex $coords 0]}]
					set sum_y2 [expr {$sum_y2 + [lindex $coords 1]}]
					break
				}
			}
		}
		set count2 [llength $group2]
		if {$count2 > 0} {
			set center2 [list [expr {$sum_x2 / $count2}] [expr {$sum_y2 / $count2}]]
			set center2 [format "%.2f %.2f" {*}$center2]
			if {$debug} {
				puts "DEBUG: New center2: [format "%.2f" [lindex $center2 0]], [format "%.2f" [lindex $center2 1]]"
			}
		}
	}
	set dx1 [expr {[lindex $center1 0] - $sx}]
	set dy1 [expr {[lindex $center1 1] - $sy}]
	set dist1 [expr {sqrt($dx1*$dx1 + $dy1*$dy1)}]
	set dx2 [expr {[lindex $center2 0] - $sx}]
	set dy2 [expr {[lindex $center2 1] - $sy}]
	set dist2 [expr {sqrt($dx2*$dx2 + $dy2*$dy2)}]
	set group1_data [list]
	foreach p_name $group1 {
		foreach ep $end_points {
			if {[lindex $ep 0] eq $p_name} {
				lappend group1_data $ep
				break
			}
		}
	}
	set group2_data [list]
	foreach p_name $group2 {
		foreach ep $end_points {
			if {[lindex $ep 0] eq $p_name} {
				lappend group2_data $ep
				break
			}
		}
	}
	if {$dist1 >= $dist2} {
		set result [list [list $group1_data $center1] [list $group2_data $center2]]
		if {$debug} {puts "INFO: Group 1's center is farther from the start point (Distance: [format "%.2f" $dist1])"}
	} else {
		set result [list [list $group2_data $center2] [list $group1_data $center1]]
		if {$debug} { puts "INFO: Group 2's center is farther from the start point (Distance: [format "%.2f" $dist2])" }
	}
  if {$debug} {
    puts "Grouping completed!"
    puts "Group 1 (Center farther from start, Center: [format "%.2f" [lindex [lindex $result 0 1] 0]], [format "%.2f" [lindex [lindex $result 0 1] 1]]):"
    foreach p [lindex $result 0 0] { puts "  - [lindex $p 1] : [lindex $p 0]" }
    puts "Group 2 (Center closer to start, Center: [format "%.2f" [lindex [lindex $result 1 1] 0]], [format "%.2f" [lindex [lindex $result 1 1] 1]]):"
    foreach p [lindex $result 0 1] { puts "  - [lindex $p 1] : [lindex $p 0]" }
  }
	return $result
}
proc can_solve_violation_by_buffer_vt {violation netlength} {
  if {![string is double -strict $violation] || ![string is double -strict $netlength]} {
    error "Parameters must be numeric"
  }
  if {$violation >= 0} {
    return 0
  }
  set max_solvable_violation 0.0
  if {$netlength <= 10} {
    set max_solvable_violation -0.010
  } elseif {$netlength >= 100} {
    set max_solvable_violation -0.040
  } else {
    if {$netlength <= 50} {
      set slope [expr (-0.030 - (-0.010)) / (50 - 10)]
      set max_solvable_violation [expr -0.010 + $slope * ($netlength - 10)]
    } else {
      set slope [expr (-0.040 - (-0.030)) / (100 - 50)]
      set max_solvable_violation [expr -0.030 + $slope * ($netlength - 50)]
    }
  }
  if {$violation >= $max_solvable_violation} {
    return 1  ;
  } else {
    return 0  ;
  }
}
if {0} {
  puts [can_solve_violation_by_buffer_vt -0.005 15]   ;
  puts [can_solve_violation_by_buffer_vt -0.020 30]   ;
  puts [can_solve_violation_by_buffer_vt -0.050 80]   ;
  puts [can_solve_violation_by_buffer_vt 0.005 50]    ;
}
proc print_cmdDeleteNet {{pinOrNet ""}} {
  if {$pinOrNet == "" || [dbget top.insts.instTerms.name $pinOrNet -e] == "" && [dbget top.nets.name $pinOrNet -e] == ""}  {
    error "proc print_cmdDeleteNet: check your input!!!"
  } else {
    set pin_ptr [dbget top.insts.instTerms.name $pinOrNet -e -p]
    set net_ptr [dbget top.nets.name $pinOrNet -e]
    if {$pin_ptr != ""} {
      set netName [dbget $pin_ptr.net.name]
      return "editDelete -net $netName"
    } elseif {$net_ptr != ""} {
      set netName [dbget $net_ptr.name]
      return "editDelete -net $netName"
    }
  }
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
proc calculateResistantCenter_fromPoints {pointsList {threshold 0}} {
  if {![llength $pointsList]} {
    return "0x0:1";
  } elseif {$threshold <= 0} {
    set sumX 0.0
    set sumY 0.0
    set count 0
    foreach point $pointsList {
      lassign $point x y
      set sumX [expr {$sumX + $x}]
      set sumY [expr {$sumY + $y}]
      incr count
    }
    return [list [expr {$sumX / $count}] [expr {$sumY / $count}]]
  } else {
    set sumX 0.0
    set sumY 0.0
    set count 0
    foreach point $pointsList {
      lassign $point x y
      set sumX [expr {$sumX + $x}]
      set sumY [expr {$sumY + $y}]
      incr count
    }
    set meanX [expr {$sumX / $count}]
    set meanY [expr {$sumY / $count}]
    set distances {}
    foreach point $pointsList {
      lassign $point x y
      set dx [expr {$x - $meanX}]
      set dy [expr {$y - $meanY}]
      set dist [expr {sqrt($dx*$dx + $dy*$dy)}]
      lappend distances $dist
    }
    set sumDist 0.0
    foreach dist $distances {
      set sumDist [expr {$sumDist + $dist}]
    }
    set avgDist [expr {$sumDist / $count}]
    set sumSqDiff 0.0
    foreach dist $distances {
      set diff [expr {$dist - $avgDist}]
      set sumSqDiff [expr {$sumSqDiff + ($diff * $diff)}]
    }
    set stdDev [expr {sqrt($sumSqDiff / $count)}]
    set filteredPoints {}
    for {set i 0} {$i < $count} {incr i} {
      if {[lindex $distances $i] <= $threshold * $stdDev} {
        lappend filteredPoints [lindex $pointsList $i]
      }
    }
    if {[llength $filteredPoints] == 0} {
      return [list $meanX $meanY]
    }
    set sumX 0.0
    set sumY 0.0
    set count 0
    foreach point $filteredPoints {
      lassign $point x y
      set sumX [expr {$sumX + $x}]
      set sumY [expr {$sumY + $y}]
      incr count
    }
    return [list [expr {$sumX / $count}] [expr {$sumY / $count}]]
  }
}
proc shouldFilterCoordinates {pointsList {densityThreshold 0.75} {outlierThreshold 3.0} {minPoints 5}} {
    set pointCount [llength $pointsList]
    if {$pointCount < $minPoints} {
        return 0 ;
    }
    set sumX 0.0
    set sumY 0.0
    foreach point $pointsList {
        lassign $point x y
        set sumX [expr {$sumX + $x}]
        set sumY [expr {$sumY + $y}]
    }
    set centerX [expr {$sumX / $pointCount}]
    set centerY [expr {$sumY / $pointCount}]
    set distances {}
    foreach point $pointsList {
        lassign $point x y
        set dx [expr {$x - $centerX}]
        set dy [expr {$y - $centerY}]
        lappend distances [expr {sqrt($dx*$dx + $dy*$dy)}]
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
    set sumCubedDiff 0.0
    foreach dist $distances {
        set diff [expr {$dist - $avgDist}]
        set sumCubedDiff [expr {$sumCubedDiff + ($diff * $diff * $diff)}]
    }
    set skewness [expr {$sumCubedDiff / ($pointCount * ($stdDev ** 3))}]
    set adjustedOutlierThreshold $outlierThreshold
    set adjustedDensityThreshold $densityThreshold
    if {$skewness > 1.0} {
        set adjustedOutlierThreshold [expr {$outlierThreshold * (1.0 + $skewness/5.0)}]
    }
    set relativeStdDev [expr {$stdDev / $avgDist}]
    if {$relativeStdDev > 0.5} {
        set reductionFactor [expr {0.2 * ($relativeStdDev - 0.5)}]
        set adjustedDensityThreshold [expr {$densityThreshold * (1.0 - $reductionFactor)}]
    }
    set inlierCount 0
    foreach dist $distances {
        if {$dist <= $adjustedOutlierThreshold * $stdDev} {
            incr inlierCount
        }
    }
    set inlierRatio [expr {$inlierCount / double($pointCount)}]
    if {$inlierRatio < $adjustedDensityThreshold} {
        return 1 ;
    } else {
        return 0 ;
    }
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
proc get_driveCapacity_of_celltype {{celltype ""} {regExp "X(\\d+).*(A\[HRL\]\\d+)$"}} {
  if {$celltype == "" || $celltype == "0x0" || [dbget head.libCells.name $celltype -e ] == ""} { ;
    return "0x0:1";
  } else {
    set wholename 0
    set driveLevel 0
    set VTtype 0
    regexp $regExp $celltype wholename driveLevel VTtype
    if {$driveLevel == "05"} {set driveLevel 0.5}
    return $driveLevel
  }
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
# Skipping already processed file: ./proc_whichProcess_fromStdCellPattern.invs.tcl
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
# Skipping already processed file: ../trans_fix/proc_get_cell_class.invs.tcl
