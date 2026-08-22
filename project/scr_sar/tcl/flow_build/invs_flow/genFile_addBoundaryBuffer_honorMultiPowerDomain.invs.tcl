#!/bin/tclsh
# --------------------------
# author    : aiden song
# date      : 2026/06/02 11:24:57 Tuesday
# label     : task_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc|snippet|signoff_check|drc_proc|clock_tree_relative_proc)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : add boundary buffer honer Multi power-domain
# return    : cmds file
# ref       : link url
# --------------------------
source ../../packages/get_closest_point_in_boxes.package.tcl; # get_closest_point_in_boxes
proc genFile_addBoudaryBuffer_honorMultiPowerDomain {args} {
  set powerdomainBoxesList                       {{PD_CORE {{1 1 2 2}}} {}}
  set portToInsertBuoundaryBufferList            [list]
  set bufferTypeListToInsertWhenMultiPowerdomain {{PD_CORE BUFFD4}}
  set shrinkOffsetOfEveryBoxes                   2 ; # um
  set prefixOfInsertedBuffer                     "sar_fix_boundary_buffer"
  set outputfilename                             "fix_boundary_buffer.[clock format [clock seconds] -format "%Y/%m/%d_%H%M%S%A"].tcl"
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  if {$powerdomainBoxesList eq ""} {
    error "proc genFile_addBoudaryBuffer_honorMultiPowerDomain: ERROR: plz input correct pd and boxes List!!!"
  }
  if {$portToInsertBuoundaryBufferList eq ""} {
    error "proc genFile_addBoudaryBuffer_honorMultiPowerDomain: ERROR: plz input correct port list to insert boundary buffer!!!"
  }
  if {$bufferTypeListToInsertWhenMultiPowerdomain eq ""} {
    error "proc genFile_addBoudaryBuffer_honorMultiPowerDomain: ERROR: plz input correct pdname & buffer celltype List!!!"
  }
  set haveNoPd_portList [list]
  set cmdsList [list]
  set i 0

  lappend cmdsList "setEcoMode -reset"
  lappend cmdsList "setEcoMode -batchMode true -updateTiming false -refinePlace false -honorDontTouch false -honorDontUse false -honorFixedNetWire false -honorFixedStatus false"

setEcoMode -reset

  foreach temp_port $portToInsertBuoundaryBufferList {
    set temp_port_pd [dbget [dbget top.terms.name $temp_port -p].pd.name -e]
    if {$temp_port_pd eq ""} {
      lappend haveNoPd_portList $temp_port
      continue
      # error "proc genFile_addBoudaryBuffer_honorMultiPowerDomain: ERROR: port($temp_port) has no powerdomain name, plz check it!!!"
    } else {
      set temp_boxes [dbShape [lindex [lsearch -index 0 -inline $powerdomainBoxesList $temp_port_pd] 1] SIZE -$shrinkOffsetOfEveryBoxes]
      set temp_buffer [lindex [lsearch -index 0 -inline $bufferTypeListToInsertWhenMultiPowerdomain $temp_port_pd] 1]
      set temp_port_loc [lindex [dbget [dbget top.terms.name $temp_port -p].pt -e] 0]
      set temp_loc [get_closest_point_in_boxes $temp_port_loc $temp_boxes]
      incr i
      set cmd "ecoAddRepeater -name ${prefixOfInsertedBuffer}_$i -cell $temp_buffer -term $temp_port -loc \{$temp_loc\}"
      lappend cmdsList $cmd
    }
  }
  lappend cmdsList "setEcoMode -reset"
  lappend cmdsList "dbSet \[dbget top.insts.name *${prefixOfInsertedBuffer}* -p\].pstatus softFixed"
  lappend cmdsList "foreach x \[dbget top.insts.name *${prefixOfInsertedBuffer}*\] { specifyInstPad \$x -top 1 -bottom 0 -left 4 -right 4 }"
  set fo [open $outputfilename w]
  puts $fo [join $cmdsList \n]
  close $fo
  puts "have dump cmds of adding boundary buffer to file: $outputfilename"
}

define_proc_arguments genFile_addBoudaryBuffer_honorMultiPowerDomain \
  -info "add boundary buffer honer Multi power-domain"\
  -define_args {
    {-powerdomainBoxesList "specify the powerdomain boxes list" AList list optional}
    {-portToInsertBuoundaryBufferList "specify the port-to-insertBuffer list" AList list optional}
    {-bufferTypeListToInsertWhenMultiPowerdomain "specify the pd-to-bufferCelltype list" AList list optional}
    {-shrinkOffsetOfEveryBoxes "specify the offset to shrink boxes for every pd boxes" AFloat float optional}
    {-prefixOfInsertedBuffer "specify the prefix of inserted buffer" AString string optional}
    {-outputfilename "specify the output file name" AString string optional}
  }
