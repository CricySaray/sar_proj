#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/07/12 18:06:56 Saturday
# label     : misc_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|misc_proc)
# descrip   : Transfer all files whose specified file is sourced to another file, and can support source at most twice.
# ref       : link url
# --------------------------
proc cat_all { filename } {
  set fi [open $filename r]
  set fo [open all_${filename} w]
  set lines_source  [list ]
  while {[gets $fi line] > -1} {
    if {![regexp {source} $line]} {
      puts $fo $line
    } else {
      lappend lines_source $line
    }
  }
  foreach sou $lines_source {
    foreach s $sou {
      regsub ";" $s "" item
      if {[glob -nocomplain -- $item] != ""} {
        puts $item
        puts $fo "# $sou"
        set fs [open $item r]

        set li_source [list]
        while {[gets $fs li] > -1} {
          if {![regexp {source} $li]} {
            puts $fo $li
          } else {
            lappend li_source $li
          }
        }
        foreach sou2 $li_source {
          foreach s2 $sou2 {
            regsub ";" $s2 "" it2
            set ff [glob -nocomplain -- $it2]
            if {$ff != ""} {
              puts $it2
              puts $fo "# $sou2"
              set fs2 [open $it2 r]
              puts $fo [read $fs2]; # <- if you will write third loop, you can expand it here.
              close $fs2
            }
          }
        }


        puts $fo [read $fs]
        close $fs
      }
    }
  }
  close $fi; close $fo
}

cat_all fix_trans.invs.tcl
