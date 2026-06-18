#!/bin/tclsh
# --------------------------
# author    : aiden song
# date      : 2026/06/13 17:03:13 Saturday
# label     : task_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc|snippet|signoff_check|drc_proc|clock_tree_relative_proc)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : Obtain the driver pin corresponding to the specified violPin. Then check the net length: if it exceeds the threshold, 
#             calculate the number of repeaters to be inserted based on the net length. Finally, generate an ECO script. After running 
#             this script in the INVS shell, execute the subsequent genFile procedure to extract information of the inserted instances 
#             and generate another script, which serves as the final ECO script.
# return    : output eco file
# ref       : link url
# --------------------------
source ../../packages/group_points_by_distribution_and_preferFartherCenterPt.package.tcl; # group_points_by_distribution_and_preferFartherCenterPt
source ../../eco_fix/timing_fix/trans_fix/proc_get_net_lenth.invs.tcl; # get_net_length
source ../../packages/calculate_manhattan_distance.package.tcl; # calculate_manhattan_distance
proc genFile_addMultiRepeaterBasedOnNetLength_ignoreMSV {args} {
  set violTerms                             [list]
  set thresholdOfMinNetLengthToInsertBuffer 170
  set intervalOfRepeater                    170
  set bufferCellType                        PCKBUFFTM4P5P48G3M143H286CPDTRV
  set newBufferPrefix                       "sar_fix_clk_trans_061321"
  set outputfilename                        "middleFile_fix_trans_using_genFile_addMultiRepeaterBasedOnNetLength_ignoreMSV_[clock format [clock seconds] -format "%Y%m%d_%H%M%S"].tcl"
  
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  set cmdsList [list]
  lappend cmdsList "setEcoMode -reset"
  lappend cmdsList "setEcoMode -batchMode true -updateTiming false -refinePlace false -honorDontTouch false -honorDontUse false -honorFixedNetWire false -honorFixedStatus false -honorPowerIntent false"

  set pureTermsList [lmap temp_term $violTerms {
    if {[dbget top.insts.instTerms.name $temp_term -e] ne "" || [dbget top.terms.name $temp_term -e] ne ""} {
      set temp_term
    } else { 
      lappend cmdsList "# ignore violPin cuz of non pin/port object: $temp_term"
      continue
    }
  }]

  set i 0
  set temp_cmdsList [list]
  foreach temp_viol_term $pureTermsList {
    set temp_driver_pin [get_driverPin_honerInstTermsAndPorts $temp_viol_term]
    set temp_driver_pin_pt [lindex [dbget [dbget top.insts.instTerms.name $temp_driver_pin -p].pt -e] 0]
    if {$temp_driver_pin_pt eq ""} {
      set temp_driver_pin_pt [lindex [dbget [dbget top.terms.name $temp_driver_pin -p].pt -e] 0]
      if {$temp_driver_pin_pt eq ""} {
        error "proc genFile_addMultiRepeaterBasedOnNetLength_ignoreMSV: ERROR: pt of driverPin($temp_driver_pin) of violPin($temp_viol_term) is empty!!!"
      }
    }
    set temp_net_name [dbget [dbget top.insts.instTerms.name $temp_driver_pin -p].net.name -e]
    if {$temp_net_name eq ""} {
      set temp_net_name [dbget [dbget top.terms.name $temp_driver_pin -p].net.name -e]
      if {$temp_net_name eq ""} {
        error "proc genFile_addMultiRepeaterBasedOnNetLength_ignoreMSV: ERROR: driverPin($temp_driver_pin) of violPin($temp_viol_term) has no net name!!!"
      }
    }
    set temp_net_length [get_net_length $temp_net_name]
    if {$temp_net_length < $thresholdOfMinNetLengthToInsertBuffer} {
      lappend temp_cmdsList "# ignore violPin of which driverPin($temp_driver_pin) cuz of no exceeding threshold of min net length: $temp_viol_term"
      continue
    }
    set sinks [get_sinkPins_honorInstTermsAndPorts $temp_driver_pin]
    set sink_pt_List [lmap temp_sink $sinks {
      set temp_sink_pt [lindex [dbget [dbget top.insts.instTerms.name $temp_sink -p].pt -e] 0]
      if {$temp_sink_pt eq ""} {
        set temp_sink_pt [lindex [dbget [dbget top.terms.name $temp_sink -p].pt -e] 0]
        if {$temp_sink_pt eq ""} {
          error "proc genFile_addMultiRepeaterBasedOnNetLength_ignoreMSV: ERROR: sinkPin($temp_sink) of driverPin($temp_driver_pin) have no location info!!!"
        }
      }
      list $temp_sink $temp_sink_pt
    }]
    set farthestGroupedSinkPtsList [lindex [group_points_by_distribution_and_preferFartherCenterPt [list $temp_driver_pin $temp_driver_pin_pt] $sink_pt_List] 0]
    lassign $farthestGroupedSinkPtsList temp_sink_pts temp_center_pt
    set temp_manhanttan_distance_from_driverPinPt_to_centerPtOfFarthestGroup [calculate_manhattan_distance $temp_driver_pin_pt $temp_center_pt]
    if {$temp_manhanttan_distance_from_driverPinPt_to_centerPtOfFarthestGroup > $thresholdOfMinNetLengthToInsertBuffer} {
      set temp_count_of_repeaters [expr {int(floor($temp_manhanttan_distance_from_driverPinPt_to_centerPtOfFarthestGroup / $intervalOfRepeater))}]
      set temp_sinks_of_farthest_group [lmap temp_sink_pt $temp_sink_pts {
        lindex $temp_sink_pt 0
      }]
      if {[regexp {\{$temp_sinks_of_farthest_group\}} $temp_cmdsList]} { continue }
      incr i
      lappend temp_cmdsList "ecoAddRepeater -cell $bufferCellType -spreadPrefix ${newBufferPrefix}_pinNo$i -spreadCount $temp_count_of_repeaters -term \{$temp_sinks_of_farthest_group\}"
    } else {
      lappend temp_cmdsList "# ignore violPin of which driverPin($temp_driver_pin) cuz of no exceeding threshold of min net length for manhattan distance: $temp_viol_term"
      continue
    }
  }
  # set temp_cmdsList [lsort -u $temp_cmdsList]
  set cmdsList [concat $cmdsList $temp_cmdsList]
  lappend cmdsList "setEcoMode -reset"

  set fo [open $outputfilename w]
  puts $fo [join $cmdsList \n]
  close $fo
  puts "dump cmds to file: $outputfilename"
  
}

define_proc_arguments genFile_addMultiRepeaterBasedOnNetLength_ignoreMSV \
  -info "genFile_addMultiRepeaterBasedOnNetLength_ignoreMSV"\
  -define_args {
    {-violTerms "specify the viol terms" AString string optional}
    {-thresholdOfMinNetLengthToInsertBuffer "specify threshold of min net length to insert buffer" AString string optional}
    {-intervalOfRepeater "specify the interval of repeater" AFloat float optional}
    {-bufferCellType "specify the celltype of repeater such as buffer/inverter" AString string optional}
    {-newBufferPrefix "specify the prefix of new repeater" AString string optional}
    {-outputfilename "specify the output file name" AString string optional}
  }

#!/bin/tclsh
# --------------------------
# author    : aiden song
# date      : 2026/06/13 23:46:15 Saturday
# label     : task_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc|snippet|signoff_check|drc_proc|clock_tree_relative_proc)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : Based on the repeater insertion positions calculated by the invs tool algorithm, regenerate a script. This script retrieves 
#             the coordinates of each inserted repeater, then generates a new ecoAddRepeater script with position information. Using the 
#             position data, the script obtains the instance hierarchy of the corresponding power domain and inserts the repeaters into 
#             the respective power domains.
# return    : final eco file
# ref       : link url
# --------------------------
source ../../packages/calculate_manhattan_distance.package.tcl; # calculate_manhattan_distance
source ../../eco_fix/timing_fix/trans_fix/proc_calculateResistantCenter_advanced.invs.tcl; # calculateResistantCenter_fromPoints
source ../../packages/get_closest_point_in_boxes.package.tcl; # get_closest_point_in_boxes
source ../../packages/is_point_in_boxes.package.tcl; # is_point_in_boxes
proc genFile_reGetFinalEcoAddRepeaterCmds_fromInvsGui_afterSourceScriptOfGenFile_addMultiRepeaterBasedOnNetLength_ignoreMSV {args} {
  set scriptFrom_genFile_addMultiRepeaterBasedOnNetLength_ignoreMSV "fix_trans_using_genFile_addMultiRepeaterBasedOnNetLength_ignoreMSV_2026.tcl"
  set radius                                                        5 ; # unit um
  set powerDomain_to_hinstGuideName_to_Boxes_List                   {{pd1 hinstGuideName1 {{x y x1 y1} {x y x1 y1}}} {pd2 hinstGuide2 {{x y x1 y1} {x y x1 y1}}} ...}
  set outputfilename                                                "FinalFile_fix_trans_using_genFile_addMultiRepeaterBasedOnNetLength_ignoreMSV_[clock format [clock seconds] -format "%Y%m%d_%H%M%S"].tcl"
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  set fi [open $scriptFrom_genFile_addMultiRepeaterBasedOnNetLength_ignoreMSV r]
  set contentOfScript [split [read $fi] \n]
  close $fi
  set cmdsOfEcoAddRepeater [lsearch -regexp -all -inline $contentOfScript {^ecoAddRepeater -cell}]
  set allPowerdomainBoxes [list]
  foreach temp_pd_boxes $powerDomain_to_hinstGuideName_to_Boxes_List {
    set allPowerdomainBoxes [concat $allPowerdomainBoxes [lindex $temp_pd_boxes 2]]
  }
  set cmdsList [list]

  lappend cmdsList "setEcoMode -reset"
  lappend cmdsList "setEcoMode -batchMode true -updateTiming false -refinePlace false -honorDontTouch false -honorDontUse false -honorFixedNetWire false -honorFixedStatus false -honorPowerIntent false"

  puts "processing ... (total [llength $cmdsOfEcoAddRepeater])"
  set numOfProcess 0
  foreach temp_cmd $cmdsOfEcoAddRepeater {
    incr numOfProcess
    puts -nonewline "$numOfProcess "
    flush stdout
    set indexOfSpreadPrefixPrompt [lsearch -regexp $temp_cmd spreadPrefix]
    if {$indexOfSpreadPrefixPrompt eq ""} {
      error "proc genFile_reGetFinalEcoAddRepeaterCmds_fromInvsGui_afterSourceScriptOfGenFile_addMultiRepeaterBasedOnNetLength_ignoreMSV: ERROR: have no spreadPrefix prompt at script: $scriptFrom_genFile_addMultiRepeaterBasedOnNetLength_ignoreMSV !!!"
    }
    set spreadPrefixName [lindex $temp_cmd [expr {$indexOfSpreadPrefixPrompt + 1}]]
    set indexOfTerms [lsearch -regexp $temp_cmd -term]
    if {$indexOfSpreadPrefixPrompt eq ""} {
      error "proc genFile_reGetFinalEcoAddRepeaterCmds_fromInvsGui_afterSourceScriptOfGenFile_addMultiRepeaterBasedOnNetLength_ignoreMSV: ERROR: have no -term prompt at script: $scriptFrom_genFile_addMultiRepeaterBasedOnNetLength_ignoreMSV"
    }
    set termsOfCmd [lindex $temp_cmd [expr {$indexOfTerms + 1}]]
    set termsCenterPt [calculateResistantCenter_fromPoints [lmap temp_term $termsOfCmd {
      set temp_term_pt [lindex [dbget [dbget top.insts.instTerms.name $temp_term -p].pt -e] 0]
      if {$temp_term_pt eq ""} {
        set temp_term_pt [lindex [dbget [dbget top.terms.name $temp_term -p].pt -e] 0]
        if {$temp_term_pt eq ""} {
          error "proc genFile_reGetFinalEcoAddRepeaterCmds_fromInvsGui_afterSourceScriptOfGenFile_addMultiRepeaterBasedOnNetLength_ignoreMSV: ERROR: pt of term($temp_term) of script($scriptFrom_genFile_addMultiRepeaterBasedOnNetLength_ignoreMSV) is empty!!!"
        }
      }
      set temp_term_pt
    }] auto 3 0.75 3]
    set indexOfBufferCelltype [lsearch -exact $temp_cmd "-cell"]
    set celltypeOfCmd [lindex $temp_cmd [expr {$indexOfBufferCelltype + 1}]]
    set inserted_insts_fromInvsGui [concat [dbget top.insts.name */${spreadPrefixName}_* -e] [dbget top.insts.name ${spreadPrefixName}_* -e]]
    set inserted_inst_pt_manhDist_List [lsort -decreasing -index 2 -real [lmap temp_inst $inserted_insts_fromInvsGui {
      set temp_inst_pt [get_closest_point_in_boxes [lindex [dbget [dbget top.insts.name $temp_inst -p].pt -e] 0] $allPowerdomainBoxes]
      set temp_manhattan_distance_from_inst_to_termsCenterPt [calculate_manhattan_distance $temp_inst_pt $termsCenterPt]
      list $temp_inst $temp_inst_pt $temp_manhattan_distance_from_inst_to_termsCenterPt
    }]]
    set j 0
    foreach temp_inst_pt_manhDist $inserted_inst_pt_manhDist_List {
      lassign $temp_inst_pt_manhDist temp_inst temp_pt temp_manhDist
      foreach temp_pd_boxes $powerDomain_to_hinstGuideName_to_Boxes_List {
        lassign $temp_pd_boxes temp_pdname temp_hinstGuideName temp_pdboxes
        if {[is_point_in_boxes $temp_pt $temp_pdboxes]} { 
          incr j
          lappend cmdsList "ecoAddRepeater -hinstGuide $temp_hinstGuideName -name ${spreadPrefixName}_$j -cell $celltypeOfCmd -radius $radius -term \{$termsOfCmd\} -loc \{$temp_pt\}"
          continue
        }
      }
    }
    
    
  }
  puts ""
  puts "done for analysis of invs Gui inserted repeaters."
  lappend cmdsList "setEcoMode -reset"
  set fo [open $outputfilename w]
  puts $fo [join $cmdsList \n]
  close $fo
  puts "dump final cmds to file: $outputfilename"
}

define_proc_arguments genFile_reGetFinalEcoAddRepeaterCmds_fromInvsGui_afterSourceScriptOfGenFile_addMultiRepeaterBasedOnNetLength_ignoreMSV \
  -info "Based on the repeater insertion positions calculated by the invs tool algorithm, regenerate a script. This script retrieves the coordinates \
        of each inserted repeater, then generates a new ecoAddRepeater script with position information. Using the position data, the script obtains \
        the instance hierarchy of the corresponding power domain and inserts the repeaters into the respective power domains."\
  -define_args {
    {-scriptFrom_genFile_addMultiRepeaterBasedOnNetLength_ignoreMSV "specify the script from middle script" AString string optional}
    {-radius "specify the radius when running ecoAddRepeater" AFloat float optional}
    {-powerDomain_to_hinstGuideName_to_Boxes_List "specify the List of powerDomainName-hinstGuideName-BoxesOfPowerDomain" AList list optional}
    {-outputfilename "specify the output file name" AString string optional}
  }

### below is sub procs

proc get_driverPin_honerInstTermsAndPorts {{pin ""}} {
  if {$pin eq "" || [dbget top.insts.instTerms.name $pin -e] eq "" && [dbget top.terms.name $pin -e] eq ""} {
    error "proc get_driverPin: pin ($pin) can't find in invs db!!!"; # no pin
  } else {
    if {[dbget top.insts.instTerms.name $pin -e] ne ""} {
      set driver [lindex [dbget [dbget [dbget top.insts.instTerms.name $pin -p].net.instTerms.isOutput 1 -p].name -e] 0]
      if {$driver eq ""} {
        set driver [lindex [dbget [dbget [dbget top.insts.instTerms.name $pin -p].net.terms.inOutDir "input" -p].name -e] 0]
        if {$driver eq ""} {
          error "proc get_driverPin_honerInstTermsAndPorts: ERROR: term/pin($pin) has no driver!!!"
        }
      }
    } else {
      set driver [lindex [dbget [dbget [dbget top.terms.name $pin -p].net.instTerms.isOutput 1 -p].name -e] 0]
      if {$driver eq ""} {
        set driver [lindex [dbget [dbget [dbget top.terms.name $pin -p].net.terms.inOutDir "input" -p].name -e] 0]
        if {$driver eq ""} {
          error "proc get_driverPin_honerInstTermsAndPorts: ERROR: term/pin($pin) has no driver!!!"
        }
      }
    }
    set driver [lsort -u $driver]
    if {[llength $driver] == 1} {
      return $driver
    } else {
      error "proc get_driverPin_honerInstTermsAndPorts: ERROR: driver term have one more!!! invalid return value!!!"
    }
  }
}
proc get_sinkPins_honorInstTermsAndPorts {{pin ""}} {
  if {$pin == "" || [dbget top.insts.instTerms.name $pin -e] == ""} {
    error "proc get_sinkPins_honorInstTermsAndPorts: pin ($pin) can't find in invs db!!!" 
  } else {
    set sinks_instTerms_fromInstTermDriver [dbget [dbget [dbget top.insts.instTerms.name $pin -p].net.instTerms.isInput 1 -p].name -e]
    set sinks_ports_fromInstTermDriver [dbget [dbget [dbget top.insts.instTerms.name $pin -p].net.terms.inOutDir "output" -p].name -e]
    set sinks_instTerms_fromPortDriver [dbget [dbget [dbget top.terms.name $pin -p].net.instTerms.isInput 1 -p].name -e]
    set sinks_ports_fromPortDriver [dbget [dbget [dbget top.terms.name $pin -p].net.terms.inOutDir "output" -p].name -e]
    set sinks [concat $sinks_instTerms_fromInstTermDriver $sinks_ports_fromInstTermDriver $sinks_instTerms_fromPortDriver $sinks_ports_fromPortDriver]
    if {$sinks eq ""} {
      error "proc get_sinkPins_honorInstTermsAndPorts: ERROR: have no sink pin/port for driverPin($pin)!!!"
    } else {
      return [lsort -u $sinks]
    }
  }
}
