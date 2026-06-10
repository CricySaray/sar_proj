#!/bin/tclsh
# --------------------------
# author    : aiden song
# date      : 2026/05/19 01:24:50 Tuesday
# label     : 
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc|snippet|signoff_check|drc_proc|clock_tree_relative_proc)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : what?
# return    : 
# ref       : link url
# --------------------------
source ../../packages/check_rectangle_placement.package.tcl; # check_rectangle_placement
source ../../packages/every_any.package.tcl; # every
source ../../packages/calculate_manhattan_distance.package.tcl; # calculate_manhattan_distance
source ../../packages/get_route_rects.package.tcl; # get_route_rects
source ../../eco_fix/timing_fix/trans_fix/proc_calculateResistantCenter_advanced.invs.tcl; # calculateResistantCenter_fromPoints
alias sus "subst -nocommands -nobackslashes"
proc genFile_addBuffer_bySpecifiedArea_forOneMoreFanoutCommonSituation {args} {
  set boxlist                       {{} {}} ; # plz input box list in sequence!!!
  set bufferCelltype                BUFFD4BWP143M169H3P48CPDLVT
  set driverPinsList                [list]
  set ifGetInputPinOfProvidedPins   1
  set ifCreateRegionForBuffers      1
  set suffixOfOutputFilename        ""
  set prefixOfAddedRegion           "insts_region_of_add_buffer_fix_trans"
  set outputfilename                "fixLongNetOfPortToPorts_[clock format [clock second] -format "%Y%m%d_%H%M"].tcl"
  set prefixOfAddedBufferName       "sar_addBuffer_for_fixing_trans"
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  if {$suffixOfOutputFilename ne ""} {
    set outputfilename "fixLongNetOfPortToPorts_[clock format [clock second] -format "%Y%m%d_%H%M"]_$suffixOfOutputFilename.tcl"
  }
  if {[lindex $boxlist 0] eq ""} {
    error "proc genFile_addBuffer_bySpecifiedArea_forOneMoreFanoutCommonSituation: ERROR: boxlist is empty!!!"
  }
  if {$driverPinsList eq ""} {
    error "proc genFile_addBuffer_bySpecifiedArea_forOneMoreFanoutCommonSituation: ERROR: driverPinsList is empty!!!"
  }
  set purePinsList [lmap temp_driver_pin $driverPinsList {
    if {[dbget top.insts.instTerms.name $temp_driver_pin -e] ne "" || [dbget top.terms.name $temp_driver_pin -e]} {
      set temp_driver_pin
    } else { continue }
  }]
  if {$purePinsList eq ""} {
    error "proc genFile_addBuffer_bySpecifiedArea_forOneMoreFanoutCommonSituation: ERROR: driverPinsList have no pin object!!!"
  } else {
    puts "totally have [llength $purePinsList] pin objects."
  }
  # set portToPortsList [lmap temp_driver_pin $purePinsList {
  #   set temp_all_terms [dbget [dbget top.terms.name $temp_driver_pin -p].net.terms.name -e]
  #   if {[llength $temp_all_terms] > 1 && [any x $temp_all_terms { expr {[dbget [dbget top.terms.name $x -p].inOutDir -e] eq "output"} }] && [any x $temp_all_terms { expr {[dbget [dbget top.terms.name $x -p].inOutDir -e] eq "input"}  }] && [every x $temp_all_terms { expr {[dbget top.terms.name $x -e] ne ""} }]} {
  #     set temp_driver_pin
  #   } else { continue }
  # }]
  # if {$portToPortsList eq ""} {
  #   error "proc genFile_addBuffer_bySpecifiedArea_forOneMoreFanoutCommonSituation: ERROR: driverPinsList have no inputPort object of portToPort(s)!!!"
  # } else {
  #   puts "totally have [llength $portToPortsList] portToPort(s) port objects."
  # }


  set portsListOfHaveNoInputPort [list]
  set inputPinsList [lmap temp_driver_pin $purePinsList {
    if {[dbget [dbget top.terms.name $temp_driver_pin -p].inOutDir -e] eq "input" || [dbget [dbget top.insts.instTerms.name $temp_driver_pin -p].isOutput] == 1} {
      set temp_portOrPin_driver $temp_driver_pin
    } else {
      if {$ifGetInputPinOfProvidedPins} {
        if {[dbget top.instTerms.name $temp_driver_pin -e] ne ""} {
          set temp_portOrPin_driver [dbget [dbget [dbget top.insts.instTerms.name $temp_driver_pin -p].net.terms.inOutDir input -p].name -e]
          if {$temp_portOrPin_driver eq ""} {
            set temp_portOrPin_driver [dbget [dbget [dbget top.insts.instTerms.name $temp_driver_pin -p].net.instTerms.isOutput 1 -p].name -e]
          }
        } else {
          set temp_portOrPin_driver [dbget [dbget [dbget top.terms.name $temp_driver_pin -p].net.terms.inOutDir input -p].name -e]
          if {$temp_portOrPin_driver eq ""} {
            set temp_portOrPin_driver [dbget [dbget [dbget top.terms.name $temp_driver_pin -p].net.instTerms.isOutput 1 -p].name -e]
          }
        }
        if {$temp_portOrPin_driver ne "" && [llength $temp_portOrPin_driver] == 1} {
          set temp_portOrPin_driver
        } else {
          lappend portsListOfHaveNoInputPort $temp_driver_pin
          continue
        }
      } else {
        continue
      }
    }
  }]
  set inputPinsList [lsort -u $inputPinsList]
  if {$inputPinsList eq ""} {
    error "proc genFile_addBuffer_bySpecifiedArea_forOneMoreFanoutCommonSituation: ERROR: driverPinsList have no input port or output pin object!!!"
  } else {
    puts "totally have [llength $inputPinsList] input port or output pin objects."
  }
  set firstBox [lindex $boxlist 0]
  set lastBox [lindex $boxlist end]

  if {[check_rectangle_placement $boxlist 300 1] == 1} {
    set port_itr_num 1
    set cmdsList [list]
    lappend cmdsList "setEcoMode -reset"
    lappend cmdsList "setEcoMode -batchMode true -updateTiming false -refinePlace false -honorDontTouch false -honorDontUse false -honorFixedNetWire false -honorFixedStatus false"
    set temp_box_region_itr_num 0
    foreach temp_box $boxlist {
      set ${prefixOfAddedRegion}_No$temp_box_region_itr_num [list]
      set box_of_region_No$temp_box_region_itr_num $temp_box
      incr temp_box_region_itr_num
    }
    foreach temp_driver_pin $inputPinsList {
      set inputPortLoc [lindex [dbget [dbget top.terms.name $temp_driver_pin -p].pt -e] 0]
      set outputPortsLoc [dbget [dbget [dbget top.terms.name $temp_driver_pin -p].net.terms.inOutDir output -p].pt -e]
      set resistenceCenterPt [calculateResistantCenter_fromPoints $outputPortsLoc]
      set sequenceBoxesOfInsertBuffer [lreverse [get_route_rects $boxlist $inputPortLoc $resistenceCenterPt]]
      set box_itr_num 1
      foreach temp_box $sequenceBoxesOfInsertBuffer {
        set temp_name_of_buffer ${prefixOfAddedBufferName}_portNo${port_itr_num}_boxNo${box_itr_num}
        lappend cmdsList "ecoAddRepeater -name $temp_name_of_buffer -cell $bufferCelltype -loc \{[db_rect -center $temp_box]\} -term $temp_driver_pin"
        lappend ${prefixOfAddedRegion}_No[lsearch $boxlist $temp_box] $temp_name_of_buffer ; # record insts -> region inst group
        incr box_itr_num
      }
      incr port_itr_num
    }

    lappend cmdsList "setEcoMode -reset"
    set fo [open $outputfilename w]
    if {[llength $cmdsList] > 3 && [lindex $cmdsList 3] ne ""} {
      puts $fo [join $cmdsList \n]
      puts $fo "dbSet \[dbget top.insts.name *${prefixOfAddedBufferName}* -p\].pstatus softFixed"
      set region_added_itr_num 0
      if {$ifCreateRegionForBuffers} {
        # gen cmd of adding inst to instGroup specified box
        puts $fo "set all_added_buffer_by_sar \[dbget top.insts.name *${prefixOfAddedBufferName}*\]"
        foreach temp_box $boxlist {
          if {[dbget top.fplan.groups.name ${prefixOfAddedRegion}_No$region_added_itr_num -e] eq "" || [dbget top.fplan.groups.name ${prefixOfAddedRegion}_No$region_added_itr_num -e] ne "" && [dbget [dbget top.fplan.groups.name ${prefixOfAddedRegion}_No$region_added_itr_num -p].members -e] eq ""} {
            puts $fo "createInstGroup ${prefixOfAddedRegion}_No$region_added_itr_num \{$temp_box\}"
          } else {
            puts $fo "### NOTICE: ERROR: the region: ${prefixOfAddedRegion}_No$region_added_itr_num has existed!!! plz check if it is correct!!!"
            puts "### NOTICE: ERROR: the region: ${prefixOfAddedRegion}_No$region_added_itr_num has existed!!! plz check if it is correct!!!"
          }
          puts $fo "createRegion ${prefixOfAddedRegion}_No$region_added_itr_num \{$temp_box\}"
          foreach temp_inst_of_region [sus \${${prefixOfAddedRegion}_No$region_added_itr_num}] {
            puts $fo "addInstToInstGroup ${prefixOfAddedRegion}_No$region_added_itr_num \[lsearch -all -inline \$all_added_buffer_by_sar *$temp_inst_of_region\]"
          }
          incr region_added_itr_num
        }
      }
      puts "have dump all cmds to file : $outputfilename"
    } else {
      puts $fo "ERROR: have no any eco cmd!!!\nPlease check your correction of value of arguments."
    }
    close $fo
    if {[llength $portsListOfHaveNoInputPort]} {
      puts "NOTICE: there are some ports of \$driverPinsList have no inputPort or have several inputPort!!!  Need to check it!!!"
      puts [join $portsListOfHaveNoInputPort \n]
    }
  } else {
    error "proc genFile_addBuffer_bySpecifiedArea_forOneMoreFanoutCommonSituation: ERROR : boxlist have error !!! plz check it!!!"
  }
}

define_proc_arguments genFile_addBuffer_bySpecifiedArea_forOneMoreFanoutCommonSituation \
  -info "gen cmd to add buffer by specified area(box/rect) for one more fanout of common situation"\
  -define_args {
    {-boxlist "specify the boxlist" AList list optional}
    {-bufferCelltype "specify buffer celltype to add" AString string optional}
    {-driverPinsList "specify the port list to add buffer in sequence" AList list optional}
    {-ifGetInputPinOfProvidedPins "if get inputPort of provided ports list: \$driverPinsList" oneOfString one_of_string {optional value_type {values {0 1}}}}
    {-ifCreateRegionForBuffers "if createRegion for buffers" oneOfString one_of_string {optional value_type {values {0 1}}}}
    {-suffixOfOutputFilename "specify the suffix of output filenam" AString string optional}
    {-outputfilename "specify the output file name" AString string optional}
    {-prefixOfAddedRegion "specify the prefix of added region" AString string optional}
    {-prefixOfAddedBufferName "specify the prefix of added buffer" AString string optional}
  }
