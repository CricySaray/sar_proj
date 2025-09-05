#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/09/05 10:19:29 Friday
# label     : check_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|misc_proc)
#   perl -> (format_sub)
# descrip   : check if missing lef for used cell at invs db or netlist
# return    : 
# ref       : link url
# --------------------------
source ../packages/table_format_with_title.package.tcl; # table_format_with_title
source ../packages/pw_puts_message_to_file_and_window.package.tcl; # pw
source ../packages/add_file_header.package.tcl; # add_file_header
proc check_if_missing_lef {{outputfile "check_if_missing_lef.list"}} {
  set allUsedCells_ptr [dbget top.insts.cell. -u]
  set miss_lef_cells_list [list]
  set match_lef_dict [dict create]
  foreach cell_ptr $allUsedCells_ptr {
    set cell_name [dbget $cell_ptr.name]
    set cell_leffile [dbget $cell_ptr.lefFilename -u -e]
    if {$cell_leffile == ""} {
      lappend miss_lef_cells_list $cell_name
    } else {
      if {![dict exists $match_lef_dict $cell_leffile]} {
        dict set match_lef_dict $cell_leffile [list $cell_name]
      } else {
        dict lappend match_lef_dict $cell_leffile $cell_name
      }
    }
  }
  set lef_matchedCells_list_forTableFormat [list ]
  dict for {lefname cells} $match_lef_dict {
    lappend lef_matchedCells_list_forTableFormat [list "LEF filename" $lefname] [list "detail cells" $cells]
  }
  set fi [open $outputfile w]
  set descrip "missing lef detail"
  add_file_header -fileID $fi -author "sar song" -descrip $descrip -tee
  pw $fi "MISSING LEF LIST: (num of missing lef: [llength $miss_lef_cells_list])"
  pw $fi [join $miss_lef_cells_list \n]
  pw $fi ""
  pw $fi [table_format_with_title $lef_matchedCells_list_forTableFormat 250 "matched lefFilename and cells" ]
  pw $fi ""
  pw $fi "Detail List of Matched:"
  dict for {lefname cells} $match_lef_dict {
    pw $fi [string repeat "-" 25]
    pw $fi "$lefname: "
    pw $fi [join $cells \n]
    pw $fi ""
  }
  close $fi
}
