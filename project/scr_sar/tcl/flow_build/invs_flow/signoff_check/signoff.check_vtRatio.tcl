#!/bin/tclsh
# --------------------------
# author    : clourney semi
# date      : 2026/01/16 15:09:23 Friday
# label     : signoff_check
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc|snippet|signoff_check)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : check vt ratio
# return    : output file and format list
# ref       : link url
# --------------------------
source ../../../packages/table_format_with_title.package.tcl; # table_format_with_title
proc check_vtRatio {args} {
  set vtTypeExpNameList {{{BWP.*140HVT$} HVT} {{BWP.*140$} SVT} {{BWP.*140LVT$} LVT} {{BWP.*140ULVT} ULVT}}
  set rptName    "signoff_check_vtRatio.rpt"
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  if {$rptName == ""} {
    error "proc check_vtRatio: check your input: output file name must be provided!!!" 
  }
  set totalVtInst_withoutPhysical 0
  set totalVtInst_onlyPhysical 0
  set totalVtInst_withPhysical 0
  set area_totalVtInst_withoutPhysical 0
  set area_totalVtInst_onlyPhysical 0
  set area_totalVtInst_withPhysical 0
  proc _add {a b} { expr {$a + $b} }
  set contentVTtypeName [lmap temp_exp_name $vtTypeExpNameList {
    lassign $temp_exp_name temp_exp temp_vtname
    set temp_len_withoutPhysical [llength [dbget -regexp [dbget top.insts.isPhysOnly 0 -p].cell.name $temp_exp -e]]
    set temp_len_onlyPhysical [llength [dbget -regexp [dbget top.insts.isPhysOnly 1 -p].cell.name $temp_exp -e]]
    set temp_len_withPhysical [expr $temp_len_withoutPhysical + $temp_len_onlyPhysical]
    if {!$temp_len_withoutPhysical} {
      set temp_area_withoutPhysical 0 
    } else {
      set temp_area_withoutPhysical [struct::list::Lfold [dbget [dbget -regexp [dbget top.insts.isPhysOnly 0 -p].cell.name $temp_exp -p2].area] 0 _add]
    }
    if {!$temp_len_onlyPhysical} {
      set temp_area_onlyPhysical 0
    } else {
      set temp_area_onlyPhysical [struct::list::Lfold [dbget [dbget -regexp [dbget top.insts.isPhysOnly 1 -p].cell.name $temp_exp -p2].area] 0 _add]
    }
    if {!$temp_len_withPhysical} {
      set temp_area_withPhysical 0
    } else {
      set temp_area_withPhysical [expr $temp_area_withoutPhysical + $temp_area_onlyPhysical]
    }
    set totalVtInst_withoutPhysical [expr {$totalVtInst_withoutPhysical + $temp_len_withoutPhysical}] 
    set totalVtInst_onlyPhysical [expr {$totalVtInst_onlyPhysical + $temp_len_onlyPhysical}]
    set totalVtInst_withPhysical [expr {$totalVtInst_withPhysical + $temp_len_withPhysical}]
    set area_totalVtInst_withoutPhysical [expr {$area_totalVtInst_withoutPhysical + $temp_area_withoutPhysical}]
    set area_totalVtInst_onlyPhysical [expr {$area_totalVtInst_onlyPhysical + $temp_area_onlyPhysical}]
    set area_totalVtInst_withPhysical [expr {$area_totalVtInst_withPhysical + $temp_area_withPhysical}]
    list $temp_vtname $temp_len_withoutPhysical $temp_len_onlyPhysical $temp_len_withPhysical $temp_area_withoutPhysical $temp_area_onlyPhysical $temp_area_withPhysical
  }]
  set suffixInfo {
    "# Please note info below:" 
  }
  set ratioOfVT [lmap temp_content $contentVTtypeName {
    lassign $temp_content temp_vtname temp_len_withoutPhysical temp_len_onlyPhysical temp_len_withPhysical temp_area_withoutPhysical temp_area_onlyPhysical temp_area_withPhysical
    if {!$totalVtInst_withoutPhysical || !$area_totalVtInst_withoutPhysical} {
      set temp_ratio_withoutPhysical "0.0%"
      set temp_area_ratio_withoutPhysical "0.0%"
      lappend suffixInfo "# $temp_vtname total count == 0, ratio and area can't calculate it!!!"
    } else {
      set temp_ratio_withoutPhysical "[format "%.2f" [expr {double($temp_len_withoutPhysical) / $totalVtInst_withoutPhysical * 100}]]%"
      set temp_area_ratio_withoutPhysical "[format "%.2f" [expr {$temp_area_withoutPhysical / $area_totalVtInst_withoutPhysical * 100}]]%"
    }
    if {!$totalVtInst_onlyPhysical || !$area_totalVtInst_onlyPhysical} {
      set temp_ratio_onlyPhysical "0.0%" 
      set temp_area_ratio_onlyPhysical "0.0%" 
      # lappend suffixInfo "# $temp_vtname total count == 0, ratio and area can't calculate it!!!"
    } else {
      set temp_ratio_onlyPhysical "[format "%.2f" [expr {double($temp_len_onlyPhysical) / $totalVtInst_onlyPhysical * 100}]]%"
      set temp_area_ratio_onlyPhysical "[format "%.2f" [expr {$temp_area_onlyPhysical / $area_totalVtInst_onlyPhysical * 100}]]%"
    }
    if {!$totalVtInst_withPhysical || !$area_totalVtInst_withPhysical} {
      set temp_ratio_withPhysical "0.0%"
      set temp_area_ratio_withPhysical "0.0%"
      lappend suffixInfo "# $temp_vtname total count == 0, ratio and area can't calculate it!!!"
    } else {
      set temp_ratio_withPhysical "[format "%.2f" [expr {double($temp_len_withPhysical) / $totalVtInst_withPhysical * 100}]]%"
      set temp_area_ratio_withPhysical "[format "%.2f" [expr {$temp_area_withPhysical / $area_totalVtInst_withPhysical * 100}]]%"
    }
    # list $temp_vtname $temp_len_withoutPhysical $temp_len_withPhysical $temp_ratio_withoutPhysical $temp_ratio_withPhysical $temp_area_ratio_withoutPhysical $temp_area_ratio_withPhysical
    list $temp_vtname $temp_len_withoutPhysical $temp_ratio_withoutPhysical [format "%.2f" $temp_area_withoutPhysical] $temp_area_ratio_withoutPhysical
  }]
  # set ratioOfVT [linsert $ratioOfVT 0 [list "VT type" "count(wo physical)" "count(wi phys)" "count ratio(wo phys)" "count ratio(wi phys)" "area ratio(wo phys)" "area ratio(wi phys)"]]
  set ratioOfVT [linsert $ratioOfVT 0 [list "VTtype" "count(woPhys)" "countRatio(woPhys)" "area(woPhys)" "areaRatio(woPhys)"]]
  set ratioOfVt_transposed [list]
  foreach temp_vtlist $ratioOfVT {
    if {$ratioOfVt_transposed eq ""} {
      set ratioOfVt_transposed [lindex $ratioOfVT 0] 
    } else {
      set i 0 
      foreach temp_item $ratioOfVt_transposed {
        lset ratioOfVt_transposed $i [concat $temp_item [lindex $temp_vtlist $i]]
        incr i 
      }
    }
  }
  set fo [open $rptName w]
  puts $fo [join [table_format_with_title $ratioOfVt_transposed 0 left "count and ratio of every vt type specified by user" 0] \n]
  if {[llength $suffixInfo] > 1} {
    puts $fo ""
    puts $fo [join $suffixInfo \n]
  }
  set indexOfAreaRatio [lsearch [lindex $ratioOfVT 0] "areaRatio(woPhys)"]
  set lvtAreaRatio [lindex [lsearch -inline -exact -index 0 $ratioOfVT LVT] $indexOfAreaRatio]
  set ulvtAreaRatio [lindex [lsearch -inline -exact -index 0 $ratioOfVT ULVT] $indexOfAreaRatio]
  puts $fo "lvtAreaRatio $lvtAreaRatio ulvtAreaRatio $ulvtAreaRatio"
  close $fo
  return [list lvtAreaRatio $lvtAreaRatio ulvtAreaRatio $ulvtAreaRatio]
}

define_proc_arguments check_vtRatio \
  -info "check vt ratio and count"\
  -define_args {
    {-vtTypeExpNameList "specify the exp_name list for every vt type" AList list optional}
    {-rptName "specify the output file name" AString string optional}
  }
