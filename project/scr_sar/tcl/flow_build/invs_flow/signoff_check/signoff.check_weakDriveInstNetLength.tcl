#!/bin/tclsh
# --------------------------
# author    : clourney semi
# date      : 2026/01/16 17:21:03 Friday
# label     : signoff_check
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc|snippet|signoff_check)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : check weak drive instance net length
# return    : output file and format list
# ref       : link url
# --------------------------
source ../../../eco_fix/timing_fix/trans_fix/proc_get_net_lenth.invs.tcl; # get_net_length
source ../../../packages/table_format_with_title.package.tcl; # table_format_with_title
proc check_weakDriveInstNetLength {args} {
  set driveCapacityGetExp    {.*D(\d+)BWP.*} ; # using regexp
  set lengthThreshold        200
  set driveCapacityThreshold 4
  set rptName                "signoff_check_weakDriveInstNetLength.rpt"
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  set allCelltypes [dbget top.insts.cell.name -u -e]
  set weakDriveCapacityCelltypes [lmap temp_celltype $allCelltypes {
    regexp $driveCapacityGetExp $temp_celltype -> temp_driveCapacity 
    if {$temp_driveCapacity < $driveCapacityThreshold} {
      list $temp_driveCapacity $temp_celltype
    } else { continue }
  }]
  set netLengthLIST [list]
  foreach temp_weakCelltype $weakDriveCapacityCelltypes {
    lassign $temp_weakCelltype temp_driveCapacity temp_celltype
    set weakInsts [dbget [dbget top.insts.cell.name $temp_celltype -p2].name -e] 
    foreach temp_inst $weakInsts {
      set temp_outputTerms [dbget [dbget [dbget top.insts.name $temp_inst -p].instTerms.isOutput 1 -p].name] 
      set temp_netname [dbget [dbget top.insts.instTerms.name $temp_outputTerms -p].net.name -e]
      if {$temp_netname eq ""} { continue } else {
        set temp_length [get_net_length $temp_netname] 
        if {$temp_length > $lengthThreshold} {
          lappend netLengthLIST [list $temp_driveCapacity $temp_celltype $temp_length $temp_netname $temp_outputTerms] 
        }
      }
    }
  }
  set netLengthLIST [lsort -index 2 -real -decreasing $netLengthLIST]
  set totalNum [llength $netLengthLIST]
  set netLengthLIST [linsert $netLengthLIST 0 [list driveCap celltype netLength netName outputTermName]]
  set fo [open $rptName w]
  puts $fo [join [table_format_with_title $netLengthLIST 0 left "" 0] \n]
  puts $fo ""
  puts $fo "TOTALNUM: $totalNum"
  puts $fo "weakDriveNetLength $totalNum"
  close $fo
  return [list weakDriveNetLength $totalNum]
}

define_proc_arguments check_weakDriveInstNetLength \
  -info "check weak drive inst net length"\
  -define_args {
    {-driveCapacityGetExp "specify the expression of drive capacity from celltype to get info" AString string optional}
    {-lengthThreshold "specify the length threshold" AFloat float optional}
    {-driveCapacityThreshold "specify the drive capacity threshold" AFloat float optional}
    {-rptName "specify output file" AString string optional}
  }
