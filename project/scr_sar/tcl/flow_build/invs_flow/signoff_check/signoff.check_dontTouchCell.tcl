#!/bin/tclsh
# --------------------------
# author    : clourney semi
# date      : 2026/01/20 09:24:14 Tuesday
# label     : signoff_check
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc|snippet|signoff_check)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : check dont touch cell list
# return    : output file and format list
# ref       : link url
# --------------------------
source ../../../flow_build/common/convert_file_to_list.common.tcl; # convert_file_to_list
source ../../../packages/every_any.package.tcl; # every
proc check_dontTouchCell {args} {
  set setSizeOkInstFileList                         ""
  set setDontTouchInstFileList                      ""
  set setBoundaryHierPinDontTouchModuleNameFileList ""
  set rptName                                       "signoff_check_dontTouchCell.rpt"
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  set fo [open $rptName w]
  set sizeOkList [list]
  set dontTouchList [list]
  set boundaryHierPinDontTouchMoudleNameList [list]
  puts $fo "Reading Input file:"
  puts $fo "# setSizeOkInstFileList: file num: [llength $setSizeOkInstFileList]"
  foreach temp_sizeokfile $setSizeOkInstFileList {
    if {[file exists $temp_sizeokfile]} {
      lappend sizeOkList {*}[convert_file_to_list $temp_sizeokfile]
      puts $fo "# read file successfully: $temp_sizeokfile"
    } else {
      puts $fo "# read file ERROR(FAILED): $temp_sizeokfile" 
    }
  }
  puts $fo ""
  puts $fo "# setDontTouchInstFileList: file num: [llength $setDontTouchInstFileList]"
  foreach temp_dontTouchFile $setDontTouchInstFileList {
    if {[file exists $temp_dontTouchFile]} {
      lappend dontTouchList {*}[convert_file_to_list $temp_dontTouchFile]
      puts $fo "# read file successfully: $temp_dontTouchFile" 
    } else {
      puts $fo "# read file ERROR(FAILED): $temp_dontTouchFile" 
    }
  }
  puts $fo ""
  puts $fo "# setBoundaryHierPinDontTouchModuleNameFileList: file num: [llength $setBoundaryHierPinDontTouchModuleNameFileList]"
  foreach temp_modulefile $setBoundaryHierPinDontTouchModuleNameFileList {
    if {[file exists $temp_modulefile]} {
      lappend boundaryHierPinDontTouchMoudleNameList {*}[convert_file_to_list $temp_modulefile]
      puts $fo "# read file successfully: $temp_modulefile"
    } else {
      puts $fo "# read file ERROR(FAILED): $temp_modulefile" 
    }
  }
  puts $fo ""
  
  if {[every x $sizeOkList { expr {$x in $dontTouchList} }] && [llength $sizeOkList] && [llength $dontTouchList]} {
    puts $fo "There are some inst name overlapped between sizeOk and dontTouch(true), it will be set dontTouch(true), please double check it: "
    foreach temp_sizeok $sizeOkList {
      if {$temp_sizeok in $dontTouchList} {
        puts $fo $temp_sizeok 
      } 
    }
  }
  set sizeOkList [lsort -u $sizeOkList]
  set dontTouchList [lsort -u $dontTouchList]
  set boundaryHierPinDontTouchMoudleNameList [lsort -u $boundaryHierPinDontTouchMoudleNameList]
  set allObjToDealWithNum [expr {[llength $sizeOkList] + [llength $dontTouchList]}]
  puts $fo "--------------"
  set noFoundSizeOkInstList [list]
  set failedSetSizkOkInstList [list]
  set sizeOkSuccessNum 0
  foreach temp_sizeok $sizeOkList {
    if {[dbget top.insts.name $temp_sizeok -e] ne ""} {
      if {[dbget [dbget top.insts.name $temp_sizeok -p].dontTouch -e] eq "sizkOk"} {
        puts $fo "success(set inst sizeOk): $temp_sizeok" 
        incr sizeOkSuccessNum
      } else {
        lappend failedSetSizkOkInstList $temp_sizeok
      }
    } else {
      lappend noFoundSizeOkInstList $temp_sizeok
    }
  }
  set noFoundDontTouchInstList [list]
  set failedSetDontTouchInstList [list]
  set dontTouchSuccessNum 0
  foreach temp_donttouch $dontTouchList {
    if {[dbget top.insts.name $temp_donttouch -e] ne ""} {
      if {[dbget [dbget top.insts.name $temp_donttouch -p].dontTouch -e] eq "true"} {
        puts $fo "success(set inst dontTouch true): $temp_donttouch" 
        incr dontTouchSuccessNum
      } else {
        lappend failedSetDontTouchInstList $temp_donttouch
      }
    } else {
      lappend noFoundDontTouchInstList $temp_donttouch
    }
  }
  set failedSetDontTouchHierPinList [list]
  set dontTouchHierPinSuccessNum 0
  foreach temp_moduleName $boundaryHierPinDontTouchMoudleNameList {
    deselectAll
    select_obj [get_pins -of $temp_moduleName -q]
    set hierPins_ptr [dbget selected.]
    foreach temp_hierpin_ptr $hierPins_ptr {
      incr allObjToDealWithNum
      if {[dbget $temp_hierpin_ptr.dontTouch] eq "true"} {
        puts $fo "success(set dontTouchHierPin true): [dbget $temp_hierpin_ptr.name]"
        incr dontTouchHierPinSuccessNum  
      } else {
        lappend failedSetDontTouchHierPinList [dbget $temp_hierpin_ptr.name]
      }
    }
  }
  set totalNum [expr {[llength $noFoundSizeOkInstList] + [llength $failedSetSizkOkInstList] + [llength $noFoundDontTouchInstList] + [llength $failedSetDontTouchInstList] + [llength $failedSetDontTouchHierPinList]}]
  if {$totalNum > 0} {
    puts $fo "failed to set dontTouch or sizeOk list:" 
    if {$noFoundSizeOkInstList ne ""} {
      foreach temp_nofound_sizeok $noFoundSizeOkInstList { puts $fo "noFoundSizeOkInst: $temp_nofound_sizeok" } 
      puts $fo ""
    }
    if {$failedSetSizkOkInstList ne ""} { 
      foreach temp_failed_sizeok $failedSetSizkOkInstList { puts $fo "failedSetSizeOkInst: $temp_failed_sizeok" }
      puts $fo ""
    }
    if {$noFoundDontTouchInstList ne ""} {
      foreach temp_nofound_doutTouch $noFoundDontTouchInstList { puts $fo "noFoundDontTouchInst: $temp_nofound_doutTouch" } 
      puts $fo ""
    }
    if {$failedSetDontTouchInstList ne ""} {
      foreach temp_failed_dontTouch $failedSetDontTouchInstList { puts $fo "failedSetDontTouchInst: $temp_failed_dontTouch" } 
      puts $fo ""
    }
    if {$failedSetDontTouchHierPinList ne ""} {
      foreach temp_failed_hierpin_dontTouch $failedSetDontTouchHierPinList { puts $fo "failedSetDontTouchHierPin: $temp_failed_hierpin_dontTouch" } 
      puts $fo ""
    }
  }
  puts $fo "num of all object to deal with : $allObjToDealWithNum"
  puts $fo ""
  puts $fo "success sizeOk num: $sizeOkSuccessNum"
  puts $fo "success dontTouch num: $dontTouchSuccessNum"
  puts $fo "success dontTouchHierPin num: $dontTouchHierPinSuccessNum"
  puts $fo ""
  puts $fo "noFoundSizeOkInst num: [llength $noFoundSizeOkInstList]"
  puts $fo "failedSetSizeOkInst num: [llength $failedSetSizkOkInstList]"
  puts $fo "noFoundDontTouchInst num: [llength $noFoundDontTouchInstList]"
  puts $fo "failedSetDontTouchInst num: [llength $failedSetDontTouchInstList]"
  puts $fo "failedSetDontTouchHierPin num: [llength $failedSetDontTouchHierPinList]"
  puts $fo ""
  puts $fo "TOTALNUM: $totalNum"
  puts $fo "dontTouchFail $totalNum"
  close $fo
  return [list dontTouchFail $totalNum]
}
define_proc_arguments check_dontTouchCell \
  -info "check dont touch cell"\
  -define_args {
    {-setSizeOkInstFileList "file name list to set sizeok inst" AList list optional}
    {-setDontTouchInstFileList "file name list to set dontTouch inst" AList list optional}
    {-setBoundaryHierPinDontTouchModuleNameFileList "file name list to set dontTouch hier pin" AList list optional}
    {-rptName "specify inst to eco when type is add/delete" AString string optional}
  }
