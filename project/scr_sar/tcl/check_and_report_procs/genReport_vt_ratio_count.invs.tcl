#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/10/15 14:18:04 Wednesday
# label     : report_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : Read all insts in the design, classify them by different vt types, and calculate the ratio
# return    : output file
# ref       : link url
# --------------------------
source ../packages/table_format_with_title.package.tcl; # table_format_with_title
proc genReport_vt_ratio_count {args} {
  set vtTypeExpNameList {{{BWP$} SVT} {{BWPLVT$} LVT} {{BWPHVT$} HVT}}
  set outputFilename    "vt_ratio.rpt"
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  if {$outputFilename == ""} {
    error "proc genReport_vt_ratio_count: check your input: output file name must be provided!!!" 
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
    list $temp_vtname $temp_len_withoutPhysical $temp_len_withPhysical $temp_ratio_withoutPhysical $temp_ratio_withPhysical $temp_area_ratio_withoutPhysical $temp_area_ratio_withPhysical
  }]
  set ratioOfVT [linsert $ratioOfVT 0 [list "VT type" "count(wo physical)" "count(wi phys)" "count ratio(wo phys)" "count ratio(wi phys)" "area ratio(wo phys)" "area ratio(wi phys)"]]
  set fo [open $outputFilename w]
  puts $fo [join [table_format_with_title $ratioOfVT 0 left "count and ratio of every vt type specified by user" 1] \n]
  if {[llength $suffixInfo] > 1} {
    puts $fo ""
    puts $fo [join $suffixInfo \n]
  }
  close $fo
}

define_proc_arguments genReport_vt_ratio_count \
  -info "gen report for vt ratio and count"\
  -define_args {
    {-vtTypeExpNameList "specify the exp_name list for every vt type" AList list optional}
    {-outputFilename "specify the output file name" AString string optional}
  }
