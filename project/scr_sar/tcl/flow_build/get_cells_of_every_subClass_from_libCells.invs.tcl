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
proc get_cells_of_every_subClass_from_libCells {{outputfile ""}} {
  if {$outputfile != ""} { set fi [open $outputfile w] }
  try {
    set subClasses [dbget head.libCells.subClass -u -e]
    if {$subClasses == ""} {
      error "proc get_cells_of_every_subClass_from_libCells: this invs db have no every subClass!!!"
    } else {
      foreach tempclass $subClasses {
        set class_cells [join [list [lrepeat 25 "-"] "$tempclass:" {*}[dbget [dbget head.libCells.subClass $tempclass -p].name]] \n]
        if {$outputfile != ""}  { set afterCmd  [list $fi $class_cells]} else { set afterCmd [list $class_cells] }
        puts {*}$afterCmd
      }
    }
  } finally {
    if {$outputfile != ""} { close $fi }
  }
}
