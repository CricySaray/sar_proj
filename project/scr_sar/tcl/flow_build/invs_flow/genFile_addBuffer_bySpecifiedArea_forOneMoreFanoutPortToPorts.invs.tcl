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
proc genFile_addBuffer_bySpecifiedArea_forOneMoreFanoutPortToPorts {args} {
  set boxlist                       {{} {}} ; # plz input box list in sequence!!!
  set bufferCelltype                BUFFD4BWP143M169H3P48CPDLVT
  set portlist                      [list]
  set ifGetInputPortOfProvidedPorts 1
  set ifCreateRegionForBuffers      1
  set suffixOfOutputFilename        ""
  set prefixOfAddedRegion           "insts_of_region_to_box"
  set outputfilename                "fixLongNetOfPortToPorts_[clock format [clock second] -format "%Y%m%d_%H%M"].tcl"
  set prefixOfAddedBufferName       "sar_addBuffer_for_portToPorts"
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  if {$suffixOfOutputFilename ne ""} {
    set outputfilename "fixLongNetOfPortToPorts_[clock format [clock second] -format "%Y%m%d_%H%M"]_$suffixOfOutputFilename.tcl"
  }
  if {[lindex $boxlist 0] eq ""} {
    error "proc genFile_addBuffer_bySpecifiedArea_forOneMoreFanoutPortToPorts: ERROR: boxlist is empty!!!"
  }
  if {$portlist eq ""} {
    error "proc genFile_addBuffer_bySpecifiedArea_forOneMoreFanoutPortToPorts: ERROR: portlist is empty!!!"
  }
  set purePortsList [lmap temp_port $portlist {
    if {[dbget top.terms.name $temp_port -e] ne ""} {
      set temp_port
    } else { continue }
  }]
  if {$purePortsList eq ""} {
    error "proc genFile_addBuffer_bySpecifiedArea_forOneMoreFanoutPortToPorts: ERROR: portlist have no port/terms object!!!"
  } else {
    puts "totally have [llength $purePortsList] port objects."
  }
  set portToPortsList [lmap temp_port $purePortsList {
    set temp_all_terms [dbget [dbget top.terms.name $temp_port -p].net.terms.name -e]
    if {[llength $temp_all_terms] > 1 && [any x $temp_all_terms { expr {[dbget [dbget top.terms.name $x -p].inOutDir -e] eq "output"} }] && [any x $temp_all_terms { expr {[dbget [dbget top.terms.name $x -p].inOutDir -e] eq "input"}  }] && [every x $temp_all_terms { expr {[dbget top.terms.name $x -e] ne ""} }]} {
      set temp_port
    } else { continue }
  }]
  if {$portToPortsList eq ""} {
    error "proc genFile_addBuffer_bySpecifiedArea_forOneMoreFanoutPortToPorts: ERROR: portlist have no inputPort object of portToPort(s)!!!"
  } else {
    puts "totally have [llength $portToPortsList] portToPort(s) port objects."
  }

  set portsListOfHaveNoInputPort [list]
  set inputPortList [lmap temp_port $portToPortsList {
    if {[dbget [dbget top.terms.name $temp_port -p].inOutDir -e] eq "input"} {
      set temp_inputPort $temp_port
    } else {
      if {$ifGetInputPortOfProvidedPorts} {
        set temp_inputPort [dbget [dbget top.terms.name $temp_port -p].net.terms.name -e]
        foreach temp_port_when_get_input_port $temp_inputPort {
          if {[dbget [dbget top.terms.name $temp_port_when_get_input_port -p].inOutDir] eq "input"} {
            set temp_inputPort $temp_port_when_get_input_port
            break
          }
        }
        if {$temp_inputPort ne "" && [llength $temp_inputPort] == 1} {
          set temp_inputPort
        } else {
          lappend portsListOfHaveNoInputPort $temp_port
          continue
        }
      } else {
        continue
      }
    }
  }]
  set inputPortList [lsort -u $inputPortList]
  if {$inputPortList eq ""} {
    error "proc genFile_addBuffer_bySpecifiedArea_forOneMoreFanoutPortToPorts: ERROR: portlist have no input port/terms object!!!"
  } else {
    puts "totally have [llength $inputPortList] input port objects."
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
    foreach temp_port $inputPortList {
      set inputPortLoc [lindex [dbget [dbget top.terms.name $temp_port -p].pt -e] 0]
      set outputPortsLoc [dbget [dbget [dbget top.terms.name $temp_port -p].net.terms.inOutDir output -p].pt -e]
      set resistenceCenterPt [calculateResistantCenter_fromPoints $outputPortsLoc]
      set sequenceBoxesOfInsertBuffer [get_route_rects $boxlist $inputPortLoc $resistenceCenterPt]
      set box_itr_num 1
      foreach temp_box $sequenceBoxesOfInsertBuffer {
        set temp_name_of_buffer ${prefixOfAddedBufferName}_portNo${port_itr_num}_boxNo${box_itr_num}
        lappend cmdsList "ecoAddRepeater -name $temp_name_of_buffer -cell $bufferCelltype -loc \{[db_rect -center $temp_box]\} -term $temp_port"
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
      puts "have dump all cmds to file : $outputfilename"
    } else {
      puts $fo "ERROR: have no any eco cmd!!!\nPlease check your correction of value of arguments."
    }
    close $fo
    if {[llength $portsListOfHaveNoInputPort]} {
      puts "NOTICE: there are some ports of \$portlist have no inputPort or have several inputPort!!!  Need to check it!!!"
      puts [join $portsListOfHaveNoInputPort \n]
    }
  } else {
    error "proc genFile_addBuffer_bySpecifiedArea_forOneMoreFanoutPortToPorts: ERROR : boxlist have error !!! plz check it!!!"
  }
}

define_proc_arguments genFile_addBuffer_bySpecifiedArea_forOneMoreFanoutPortToPorts \
  -info "gen cmd to add buffer by specified area(box/rect) for one more fanout port"\
  -define_args {
    {-boxlist "specify the boxlist" AList list optional}
    {-bufferCelltype "specify buffer celltype to add" AString string optional}
    {-portlist "specify the port list to add buffer in sequence" AList list optional}
    {-ifGetInputPortOfProvidedPorts "if get inputPort of provided ports list: \$portlist" oneOfString one_of_string {optional value_type {values {0 1}}}}
    {-ifCreateRegionForBuffers "if createRegion for buffers" oneOfString one_of_string {optional value_type {values {0 1}}}}
    {-suffixOfOutputFilename "specify the suffix of output filenam" AString string optional}
    {-outputfilename "specify the output file name" AString string optional}
    {-prefixOfAddedRegion "specify the prefix of added region" AString string optional}
    {-prefixOfAddedBufferName "specify the prefix of added buffer" AString string optional}
  }
