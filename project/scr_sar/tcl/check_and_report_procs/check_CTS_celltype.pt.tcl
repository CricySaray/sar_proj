#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/02 22:16:55 Saturday
# label     : check_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|misc_proc)
# descrip   : check CTS cell type, must be LVT CLK class of cell type
# return    : non-CLK/LVT cell type rpt(output file)
# NOTICE    : $filter_list: Every item in this list will use the regexp command to match the celltype name. If the match is successful, it will not check whether this cell is a CTS cell.
# ref       : link url
# --------------------------
source ../packages/proc_whichProcess_fromStdCellPattern.pt.tcl; # whichProcess_fromStdCellPattern
source ../eco_fix/timing_fix/trans_fix/proc_getDriveCapacity_ofCelltype.pt.tcl; # get_driveCapacity_of_celltype
source ../eco_fix/timing_fix/trans_fix/proc_get_cellDriveLevel_and_VTtype_of_inst.pt.tcl; # get_cellDriveLevel_and_VTtype_of_inst
source ../packages/categorize_overlapping_sets.package.tcl; # categorize_overlapping_sets
source ../packages/print_formattedTable.package.tcl; # print_formattedTable
source ../packages/print_formattedTable_D2withCategory.package.tcl; # print_formattedTable_D2withCategory
source ../packages/count_items.package.tcl; # count_items
source ../packages/pw_puts_message_to_file_and_window.package.tcl; # pw
source ../eco_fix/timing_fix/lut_build/operateLUT.tcl; # operateLUT
proc check_CTScelltype {{filter_list {RCLIB_PLB DEL}} {specify_VT "ULVT"} {promptERROR "songERROR"}} {
  # $specify_VT : ULVT|AR9
  set allCTSinstname_collection [get_clock_network_objects -type cell -include_clock_gating_network]
  set allCTSinstname_collection [filter_collection $allCTSinstname_collection "ref_name !~ ANT* && is_black_box == false && is_pad_cell == false"]
  # deal with and categorize collection
  set error_driveCapacity [add_to_collection "" ""]
  set error_VTtype [add_to_collection "" ""]
  set error_CLKcelltype [add_to_collection "" ""]
  set process [operateLUT -type read -attr process]
  set regExp [operateLUT -type read -attr celltype_regexp]
  set availableVT [operateLUT -type read -attr vtrange]
  set clkFlag [operateLUT -type read -attr clkflag]
  if {$process == "" || $regExp == "" || $availableVT == "" || $clkFlag == ""} {
    error "proc check_CTScelltype: check your lutDict info: process($process) , regExp($regExp) , availableVT($availableVT) , clkFlag($clkFlag). check it!!!" 
  }
  set filterExp [join $filter_list "\|"]
  foreach_in_collection instname_itr $allCTSinstname_collection {
    set driveCapacity [get_driveCapacity_of_celltype [get_attribute $instname_itr ref_name] $regExp]
    if {[regexp $filterExp [get_attribute $instname_itr ref_name]]} { continue }
    if {$driveCapacity < 4} {
      set error_driveCapacity [add_to_collection $error_driveCapacity $instname_itr] ; # drive capacity
    }
    if {$specify_VT in $availableVT && [lindex [get_cellDriveLevel_and_VTtype_of_inst [get_object_name $instname_itr] $regExp] end] != $specify_VT} {
      set error_VTtype [add_to_collection $error_VTtype $instname_itr] ; # VT type
    } elseif {$specify_VT ni $availableVT} {
      error "proc check_CTScelltype: \$specify_VT can't in availableVT list from process $process"
    }
    if {![regexp $clkFlag [get_attribute $instname_itr ref_name]]} {
      set error_CLKcelltype [add_to_collection $error_CLKcelltype $instname_itr] ; # CLK cell type
    }
  }
  # dump to output file
  # have 7 situations
  set error_driveCapacity_list [get_object_name $error_driveCapacity]
  set error_VTtype_list [get_object_name $error_VTtype]
  set error_CLKcelltype_list [get_object_name $error_CLKcelltype]
  # categorized_List : {{categorizedList1 {item1 item2 ...}} {categorizedList2 {item1 item2 ...}}}
  set categorized_List [categorize_overlapping_sets [list [list greaterThanD4 $error_driveCapacity_list] [list UseVTto$specify_VT $error_VTtype_list] [list UseCLKcelltype $error_CLKcelltype_list]]]
  set raw_display_List [lmap cat_category $categorized_List {
    set cat_inst_celltype [lmap instname [lindex $cat_category end] {
      set celltype [get_attribute [get_cells $instname] ref_name]
      set inst_celltype [list $celltype $instname]
    }]
    set new_cat_category [list [lindex $cat_category 0] $cat_inst_celltype]
  }]
  set formatedTable_toDisplay [print_formattedTable_D2withCategory $raw_display_List]
  array set category_count {}
  foreach cate $raw_display_List {
    set cate_name [lindex $cate 0]
    set category_count($cate_name) [llength [lindex $cate 1]]
  }
  set fo [open cts_celltype.error.rpt w]
  puts $fo $formatedTable_toDisplay
  puts $fo ""
  if {[llength [lindex $raw_display_List 0 1]]} {
    pw $fo ""
    pw $fo "STATISTICS OF CATEGORIES:"
    pw $fo "-------------------------"
    pw $fo [print_formattedTable [lmap cate_name [array names category_count] { set cate_num [list $cate_name $category_count($cate_name)] }]]
    pw $fo ""
  } else {
    pw $fo ""
    pw $fo "# HAVE NO ERROR OF CLK CELL TYPE!!!"
    pw $fo ""
  }
  close $fo
}

