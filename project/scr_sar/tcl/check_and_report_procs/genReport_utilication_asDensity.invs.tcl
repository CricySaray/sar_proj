#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/09/12 09:19:45 Friday
# label     : report_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|report_proc|misc_proc)
#   perl -> (format_sub)
# descrip   : gen report of utilization of std cell/macros
# return    : rpt
# ref       : link url
# --------------------------
source ../packages/add_file_header.package.tcl; # add_file_header
source ../packages/pw_puts_message_to_file_and_window.package.tcl; # pw
source ../packages/count_items_forD1List.package.tcl; # count_items_forD1List
source ../packages/print_formattedTable.package.tcl; # print_formattedTable
source ../packages/split_and_align_forString.package.tcl; # split_and_align_forString
proc genReport_utilization_asDensity {args} {
  set classInCoreArea "core"
  set outputfile      "[dbget top.name].rpt" ; # please write as format: output.list or output.rpt, which is split by '.'
  set suffixOfFile    "" ; # add prefix for output file
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  if {$suffixOfFile != "" && [llength [split $outputfile "."]] > 1} {
    set outputfilename [join [lset [split $outputfile "."] end-1 "[lindex [split $outputfile "."] end-1]_$suffixOfFile"] "."] 
  } elseif {$suffixOfFile != "" && [llength [split $outputfile "."]] == 1} {
    set outputfilename [string append outputfile "_" $suffixOfFile]
  } else { set outputfilename $outputfile }
  set fi [open $outputfilename w]
  set descrip "display some density, count and area of std cell or macro."
  add_file_header -fileID $fi -author "sar song" -descrip $descrip
  set stdcells_ptr [dbget top.insts.cell.subClass $classInCoreArea -p2]
  set stdcellNum [llength $stdcells_ptr]
  set stdcellArea [dbget $stdcells_ptr.area]
  proc add_temp {a b} {return [expr {$a + $b}]}
  proc multiple_temp {a b} {return [expr {$a * $b}]}
  set totalAreaOfStdCell [struct::list::Lfold $stdcellArea 0 add_temp] ; # using tcl lib at invs
  set stdcell_celltypes [dbget $stdcells_ptr.cell.name -e]
  set stdcell_and_blockTypes [concat $stdcell_celltypes [dbget [dbget top.insts.cell.subClass block -p].name]]
  set stdcell_and_block_celltype_count [count_items_forD1List $stdcell_and_blockTypes]
  set stdcell_and_block_celltype_area_num [lsort -index 2 -decreasing -integer [lmap temp_celltype_count $stdcell_and_block_celltype_count {
    lassign $temp_celltype_count temp_celltype temp_count 
    set temp_area [expr [join {*}[dbget [dbget head.libCells.name $temp_celltype -p].size] " * "]]
    list $temp_celltype $temp_area $temp_count
  }]]
  set stdcell_and_block_celltype_area_num [linsert $stdcell_and_block_celltype_area_num 0 [list celltype area num_at_db]]
  set coreBox [dbget top.fplan.coreBox -e]
  if {$coreBox != ""} {
    set coreArea [db_rect -area {*}$coreBox]
    set blockInsts_ptr [dbget top.insts.cell.subClass block -p2 -e]
    set block_validArea 0
    set block_withPlaceHalo_validArea 0
    if {$blockInsts_ptr != ""} {
      foreach blockinst_ptr $blockInsts_ptr {
        set blockinst_pstatus [dbget $blockinst_ptr.pstatus] 
        set blockinst_rect {*}[dbget $blockinst_ptr.boxes] 
        set blockinst_withPlaceHalo_rect [dbShape -output hrect [dbget $blockinst_ptr.pHaloPoly -e]]
        if {$blockinst_pstatus in {placed fixed}} { ; # if status of block inst is placed or fixed, valid block area will be influence by location
          set blockinst_valid_rect [dbShape -output hrect $blockinst_rect AND $coreBox]
          set block_validArea [expr {$block_validArea + [struct::list::Lfold [lmap temp_rect $blockinst_valid_rect { db_rect -area $temp_rect }] 0 add_temp]}]
          set blockinst_withPlaceHalo_valid_rect [dbShape -output hrect $blockinst_withPlaceHalo_rect AND $coreBox]
          set block_withPlaceHalo_validArea [expr {$block_withPlaceHalo_validArea + [struct::list::Lfold [lmap temp_pHalo $blockinst_withPlaceHalo_valid_rect { db_rect -area $temp_pHalo }] 0 add_temp]}]
        } elseif {$blockinst_pstatus in {unplaced}} {
          set block_validArea [expr {$block_validArea + [struct::list::Lfold [lmap temp_rect $blockinst_rect { db_rect -area $temp_rect }] 0 add_temp]}]
          set block_withPlaceHalo_validArea [expr {$block_withPlaceHalo_validArea + [struct::list::Lfold [lmap temp_pHalo $blockinst_withPlaceHalo_rect { db_rect -area $temp_pHalo }] 0 add_temp]}]
        }
        set temp_block_validArea [expr {$block_validArea + [struct::list::Lfold [lmap temp_rect $blockinst_rect { db_rect -area $temp_rect }] 0 add_temp]}]
        set temp_block_withPlaceHalo_validArea [expr {$block_withPlaceHalo_validArea + [struct::list::Lfold [lmap temp_pHalo $blockinst_withPlaceHalo_rect { db_rect -area $temp_pHalo }] 0 add_temp]}]
      }
      set blocksNum [llength $blockInsts_ptr]
    } else {
      set blocksNum 0
    }
  } else {
    error "proc genReport_utilization_asDensity: coreBox is empty or can't get!!!" 
  }
  set contentRaw [list \
    "Density: [format "%.2f" [expr $totalAreaOfStdCell / ($coreArea - $temp_block_validArea)* 100]]% (std cells only, exclude macros without place halo) 'area of all std cells at netlist / (area of coreBox - area of macro without place halo)'" \
    "Density: [format "%.2f" [expr $totalAreaOfStdCell / ($coreArea - $temp_block_withPlaceHalo_validArea)* 100]]% (std cells only, exclude macros with place halo) 'area of all std cells at netlist / (area of coreBox - area of macro with place halo)'" \
    "Density: [format "%.2f" [expr ($totalAreaOfStdCell + $block_validArea) / $coreArea * 100]]% (std cells + macro) (area of all std cells and macros\[IPs and memories\] / area of coreBox)" \
    "core area : $coreArea" \
    "Macro Number: $blocksNum" \
    "Macro area (without halo): $temp_block_validArea" \
    "Macro area (with halo): $temp_block_withPlaceHalo_validArea" \
    "std cell number : $stdcellNum" \
    "std cell area : $totalAreaOfStdCell" \
    "all insts number (std cells + macros) : [expr {$stdcellNum + $blocksNum}]" \
  ]
  set content [split_and_align_forString $contentRaw ":" "left" 0]
  pw $fi [join $content \n]
  pw $fi ""
  pw $fi "Detail info of every celltype(std cell and macro) sorted by num of insts of every celltype: "
  pw $fi [print_formattedTable $stdcell_and_block_celltype_area_num]
  close $fi
}
define_proc_arguments genReport_utilization_asDensity \
  -info "gen report for utilization of std cell/macro"\
  -define_args {
    {-classInCoreArea "specify the class of core area" AString string optional}
    {-outputfile "specify the filename to output" AString string optional}
    {-suffixOfFile "specify the suffix of output file" AString string optional}
  }
