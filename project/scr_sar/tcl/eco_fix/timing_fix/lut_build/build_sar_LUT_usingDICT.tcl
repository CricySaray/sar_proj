#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/08 09:48:33 Friday
# label     : db_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|misc_proc)
# descrip   : build the LUT(look-up table) for some fixed design info in order to reduce complexity and other levels of running time
# return    : tcl script to create dict database(it is convenient for searching. it can save permently and source it whenever you need it.)
#             dict database include:
#             dictName: $LUT_filename
#               layer1 attribute: designName/mainCoreRowHeight/mainCoreSiteWidth/celltype 
#               layer2 attribute of celltype: [allLibCellTypeNames(like BUFX3AR9/INVX8AL9/...)] 
#               layer3 attribute of every item of celltype(layer2): class/size (AT001)
# ref       : link url
# --------------------------
source ../../../packages/print_formattedTable.package.tcl; # print_formattedTable
source ../../../eco_fix/timing_fix/trans_fix/proc_findMostFrequentElementOfList.invs.tcl; # findMostFrequentElement
source ../trans_fix/proc_get_cell_class.invs.tcl; # get_cell_class ; get_class_of_celltype
proc build_sar_LUT_usingDICT {{LUT_filename "sar_LUT.tcl"} {promptPrefix "# song"} {lutDictName "lutDict"}} {
  set promptINFO [string cat $promptPrefix "INFO"] ; set promptERROR [string cat $promptPrefix "ERROR"] ; set promptWARN [string cat $promptPrefix "WARN"]
  global expandedMapList
  #puts "expandedMapList: $expandedMapList"
  set fo [open $LUT_filename w]
  puts $fo "set $lutDictName \[dict create\]"
  set designName [dbget top.name -e] 
  if {$designName == ""} { puts $fo "$promptERROR : have no design name!!!" } else { puts $fo "dict set $lutDictName designName $designName" }
  set rowHeightAllList [dbget top.fplan.rows.box_sizey -e]
  if {$rowHeightAllList == ""} { 
    puts $fo "$promptERROR : have no row defination!!!" 
  } else { 
    set mainCoreRowHeight [findMostFrequentElement $rowHeightAllList 50.0 1]
    puts $fo "dict set $lutDictName mainCoreRowHeight $mainCoreRowHeight" 
  }
  set siteWidthAllList [dbget top.fplan.rows.site.size_x -e]
  if {$siteWidthAllList == ""} { 
    puts $fo "$promptERROR : have no site defination!!!" 
  } else {
    set mainCoreSiteWidth [findMostFrequentElement $siteWidthAllList 50.0 1]
    puts $fo "dict set $lutDictName mainCoreSiteWidth $mainCoreSiteWidth"
  }
  set allCellType_ptrList [dbget head.libCells.]
  if {$allCellType_ptrList == ""} { 
    puts $fo "$promptERROR : have no celltype in library!!!" 
  } else {
    set sortedCellType_ptrList [lsort -increasing -unique $allCellType_ptrList]
    set celltype_class_size_D3List [lmap temptype_ptr $sortedCellType_ptrList {
      set temptypename [dbget $temptype_ptr.name]
      set tempclass [get_class_of_celltype $temptypename $expandedMapList] 
      set tempsize [lindex [dbget $temptype_ptr.size] 0]
      set temp_typename_class_size "{{$temptypename $tempclass {$tempsize}}}"
    }]
    set sorted_celltype_class_size_D3List [lsort $celltype_class_size_D3List]
    puts $fo "set celltype_subAttributes \{"
    puts $fo [print_formattedTable $sorted_celltype_class_size_D3List]
    puts $fo "\}"
    puts $fo "foreach temp_celltype_attribute \$celltype_subAttributes \{"
    puts $fo "  set celltypeName \[lindex \$temp_celltype_attribute 0\]"
    puts $fo "  set cellclass \[lindex \$temp_celltype_attribute 1\]"
    puts $fo "  set cellsize \[lindex \$temp_celltype_attribute 2\]"
    puts $fo "  dict set $lutDictName celltype \$celltypeName class \$cellclass" ; # AT001
    puts $fo "  dict set $lutDictName celltype \$celltypeName size \$cellsize" ; # AT001
    puts $fo "\}"
  }
  close $fo
}
