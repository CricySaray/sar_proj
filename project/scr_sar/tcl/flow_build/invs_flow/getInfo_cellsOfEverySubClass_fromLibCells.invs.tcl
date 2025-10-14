#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/30 19:43:11 Saturday
# label     : misc_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|misc_proc)
# descrip   : get all cell of every subClass from head.libCells
# return    : 
# ref       : link url
# --------------------------
source ../../packages/table_col_format_wrap.package.tcl; # table_col_format_wrap
source ../../packages/add_file_header.package.tcl; # add_file_header
proc get_cells_of_every_subClass_from_libCells {{outputfile ""} {ifFormatToTable 1} {ifShowCellList 1}} {
  if {$outputfile != ""} { set fi [open $outputfile w] }
  try {
    set subClasses [dbget head.libCells.subClass -u -e]
    if {$subClasses == ""} {
      error "proc get_cells_of_every_subClass_from_libCells: this invs db have no every subClass!!!"
    } else {
      set cells_format_list [list ]
      set detail_list_of_cells [list ]
      foreach tempclass $subClasses {
        set classCells [dbget [dbget head.libCells.subClass $tempclass -p].name]
        lappend cells_format_list [list $tempclass [llength $classCells] $classCells]
        set class_cells_to_show [join [list "" [string repeat "-" 25] "$tempclass:" {*}$classCells] \n]
        lappend detail_list_of_cells $class_cells_to_show
      }
      set cells_format_list [lsort -index 1 -integer -increasing $cells_format_list]
      set detail_list_of_cells [lsort -command {
        apply {{a b} {
          upvar 1 cells_format_list cells_format_list_temp
          if {[lindex [lsearch -inline -index 0 $cells_format_list_temp [regsub ":" [lindex $a 1] ""]] 1] > [lindex [lsearch -inline -index 0 $cells_format_list_temp [regsub ":" [lindex $b 1] ""]] 1]} {
            return 1
          } else { return -1 }
        }}
      } $detail_list_of_cells]
      set cells_format_list [linsert $cells_format_list 0]
      set detail_list_of_cells [linsert $detail_list_of_cells 0 "" "" [lrepeat 30 "="] [list Detail list of cells]]
      set formated_cells_list [table_col_format_wrap $cells_format_list 3 20 200]
      if {$outputfile != ""}  { 
        set detailCmd [list $fi $formated_cells_list]
        set listCmd [list $fi [join $detail_list_of_cells \n]]
        set descrip "Displays all libCells in the subClasses of the Database. There are two display formats: tables and lists."
        set usage "To better classify all cells and facilitate search and query"
        add_file_header -fileID $fi -author "sar song" -date "auto" -descrip $descrip -usage $usage -line_width 150 -splitLineWidth 25
      } else { 
        set detailCmd [list $formated_cells_list] 
        set listCmd [list [join $detail_list_of_cells \n]]
      }
      if {$ifFormatToTable} { puts {*}$detailCmd }
      if {$ifShowCellList} { puts {*}$listCmd }
    }
  } finally {
    if {$outputfile != ""} { close $fi }
  }
}
