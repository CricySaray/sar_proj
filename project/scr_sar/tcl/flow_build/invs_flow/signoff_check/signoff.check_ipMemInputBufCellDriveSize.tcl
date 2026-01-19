#!/bin/tclsh
# --------------------------
# author    : clourney semi
# date      : 2026/01/19 14:42:50 Monday
# label     : signoff_check
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc|snippet|signoff_check)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : check ip/mem input pin buffer cell drive capacity size
# return    : output file and format list
# ref       : link url
# --------------------------
source ../../../eco_fix/timing_fix/trans_fix/proc_getDriveCapacity_ofCelltype.pt.tcl; # get_driveCapacity_of_celltype
source ../../../packages/table_format_with_title.package.tcl; # table_format_with_title
proc check_ipMemInputBufCellDriveSize {args} {
  set removeInstExpList {mesh}
  set removeCelltypeExpList {TIE}
  set celltypeExp       {.*D(\d+)BWP.*140([(UL)LH]VT)?$}
  set sizeThreshold     4
  set rptName           "signoff_check_ipMemInputBufCellDriveSize.rpt"
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  set allIpMems_ptr [dbget top.insts.cell.subClass block -p2]
  set totalNum 0
  set fo [open $rptName w]
  set finalList [list]
  if {$allIpMems_ptr ne ""} {
    foreach temp_inst_ptr $allIpMems_ptr {
      if {![regexp [join $removeInstExpList "\|"] [dbget $temp_inst_ptr.name]]} {
        set inputInsts_ptr [dbget [dbget $temp_inst_ptr.instTerms.isInput 1 -p].net.instTerms.inst.cell.name $celltypeExp -regexp -p2]
        foreach temp_inputinst_ptr $inputInsts_ptr {
          set temp_celltype [dbget $temp_inputinst_ptr.cell.name -e]
          if {$temp_celltype ne ""} {
            set temp_driverCapacity [get_driveCapacity_of_celltype $temp_celltype $celltypeExp] 
            if {$temp_driverCapacity < $sizeThreshold} {
              lappend finalList [list $temp_driverCapacity $temp_celltype [dbget $temp_inputinst_ptr.name]] 
            }
          }
        }
      }
    }
  }
  set totalNum [llength $finalList]
  set finalList [linsert $finalList 0 [list size celltype instname]]
  puts $fo [join [table_format_with_title $finalList 0 left "" 0] \n]
  puts $fo ""
  puts $fo "TOTALNUM: $totalNum"
  puts $fo "ipMemInputBufSize $totalNum"
  close $fo
  return [list ipMemInputBufSize $totalNum]
}

define_proc_arguments check_ipMemInputBufCellDriveSize \
  -info "check ip/mem input buffer cell drive capacity size"\
  -define_args {
    {-removeInstExpList "specify the remove inst using expression list" AList list optional}
    {-removeCelltypeExpList "specify the remove celltype using expression list" AList list optional}
    {-celltypeExp "specify the celltype expression to match and get drive capacity" AString string optional}
    {-sizeThreshold "specify the drive capacity size threshold" AInt int optional}
    {-rptName "specify inst to eco when type is add/delete" AString string optional}
  }
