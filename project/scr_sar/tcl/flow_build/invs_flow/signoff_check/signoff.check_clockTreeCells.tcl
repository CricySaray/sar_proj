#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/02 22:16:55 Saturday
# label     : check_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|misc_proc)
# descrip   : check CTS cell type, must be LVT CLK class of cell type
# return    : non-CLK/LVT cell type rpt(output file)
# NOTICE    : $remove_celltype_list: Every item in this list will use the regexp command to match the celltype name. If the match is successful, it will not check whether this cell is a CTS cell.
# ref       : link url
# --------------------------
source ../../../packages/proc_whichProcess_fromStdCellPattern.pt.tcl; # whichProcess_fromStdCellPattern
source ../../../eco_fix/timing_fix/trans_fix/proc_getDriveCapacity_ofCelltype.pt.tcl; # get_driveCapacity_of_celltype
source ../../../eco_fix/timing_fix/trans_fix/proc_get_cellDriveLevel_and_VTtype_of_inst.pt.tcl; # get_cellDriveLevel_and_VTtype_of_inst
source ../../../packages/categorize_overlapping_sets.package.tcl; # categorize_overlapping_sets
source ../../../packages/print_formattedTable.package.tcl; # print_formattedTable
source ../../../packages/print_formattedTable_D2withCategory.package.tcl; # print_formattedTable_D2withCategory
source ../../../packages/count_items.package.tcl; # count_items
proc check_clockTreeCells {args} {
  set remove_celltype_list {RCLIB_PLB DEL}
  set remove_instname_list {}
  set specify_VT           "LVT"
  set celltypeRegExp       {.*D(\d+)BWP.*140([(UL)LH]VT)?$}
  set availableVT          {HVT SVT LVT ULVT}
  set clkFlagExp           {^DCCK|^CK}
  set rptName              "signoff_check_clockTreeCells.rpt"
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  # $specify_VT : ULVT|AR9
  set temp_allCTSinstname_collection [get_ccopt_clock_tree_cells]
  set allCTSinstname_collection [get_cells [lindex $temp_allCTSinstname_collection 0]]
  foreach temp_inst $temp_allCTSinstname_collection { set allCTSinstname_collection [add_to_collection -u $allCTSinstname_collection [get_cells $temp_inst]] }
  set allCTSinstname_collection [filter_collection $allCTSinstname_collection "ref_name !~ ANT* && is_black_box == false && is_pad_cell == false"]
  # deal with and categorize collection
  set error_driveCapacity [add_to_collection "" ""]
  set error_VTtype [add_to_collection "" ""]
  set error_CLKcelltype [add_to_collection "" ""]
  if {$celltypeRegExp eq ""} {
    error "proc check_clockTreeCells: please provide \$celltypeRegExp!!!"
  }
  if {$celltypeRegExp == "" || $availableVT == "" || $clkFlagExp == ""} {
    error "proc check_CTScelltype: check your lutDict info: celltypeRegExp($celltypeRegExp) , availableVT($availableVT) , clkFlagExp($clkFlagExp). check it!!!" 
  }
  set removeCelltypeExp [join $remove_celltype_list "\|"]
  set removeInstnameExp [join $remove_instname_list "\|"]
  set numAllCtsInsts [sizeof_collection $allCTSinstname_collection]
  set numremoveInst 0
  foreach_in_collection instname_itr $allCTSinstname_collection {
    set driveCapacity [get_driveCapacity_of_celltype [get_attribute $instname_itr ref_name] $celltypeRegExp]
    if {$remove_celltype_list ne "" && [regexp $removeCelltypeExp [get_attribute $instname_itr ref_name]]} { incr numremoveInst; continue }
    if {$remove_instname_list ne "" && [regexp $removeInstnameExp [get_attribute $instname_itr full_name]]} { incr numremoveInst; continue }
    if {$driveCapacity < 4} {
      set error_driveCapacity [add_to_collection $error_driveCapacity $instname_itr] ; # drive capacity
    }
    if {$specify_VT in $availableVT && [lindex [get_cellDriveLevel_and_VTtype_of_inst [get_object_name $instname_itr] $celltypeRegExp] end] != $specify_VT} {
      set error_VTtype [add_to_collection $error_VTtype $instname_itr] ; # VT type
    } elseif {$specify_VT ni $availableVT} {
      error "proc check_CTScelltype: \$specify_VT can't in availableVT list"
    }
    if {![regexp $clkFlagExp [get_attribute $instname_itr ref_name]]} {
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
  set totalNum 0
  foreach cate $raw_display_List {
    set cate_name [lindex $cate 0]
    set category_count($cate_name) [llength [lindex $cate 1]]
    incr totalNum $category_count($cate_name)
  }
  set fo [open $rptName w]
  puts $fo $formatedTable_toDisplay
  puts $fo ""
  if {[llength [lindex $raw_display_List 0 1]]} {
    puts $fo ""
    puts $fo "STATISTICS OF CATEGORIES:"
    puts $fo "-------------------------"
    puts $fo [print_formattedTable [lmap cate_name [array names category_count] { set cate_num [list $cate_name $category_count($cate_name)] }]]
    puts $fo ""
  } else {
    puts $fo ""
    puts $fo "# HAVE NO ERROR OF CLK CELL TYPE!!!"
    puts $fo ""
  }
  puts $fo "# num of total ccopt clock tree cells : $numAllCtsInsts"
  puts $fo "# num of total removed inst: $numremoveInst"
  puts $fo ""
  puts $fo "TOTALNUM: $totalNum"
  puts $fo "ctsCellNum $totalNum"
  close $fo
  return [list ctsCellNum $totalNum]
}

define_proc_arguments check_clockTreeCells \
  -info "check clock tree cells"\
  -define_args {
    {-remove_celltype_list "specify the remove list of celltype" AList list optional}
    {-remove_instname_list "specify the remove list of instname" AList list optional}
    {-specify_VT "specify the clock tree vt" AList list optional}
    {-celltypeRegExp "specify the reg expression of celltype to match" AString string optional}
    {-availableVT "specify the list of all vt type" AList list optional}
    {-clkFlagExp "specify the clock cell type flag" AString string optional}
    {-rptName "specify inst to eco when type is add/delete" AString string optional}
  }
