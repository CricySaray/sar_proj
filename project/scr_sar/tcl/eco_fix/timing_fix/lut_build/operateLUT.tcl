#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/12 16:27:00 Tuesday
# label     : db_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|misc_proc)
# descrip   : API of sar LUT
# related   : ../lut_build/build_sar_LUT_usingDICT.tcl
# return    : 
# ref       : link url
# --------------------------
proc operateLUT {args} {
  set type "read"
  set attr [list ]
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg) 
  }
  global lutDict
  if {$type == "read"} {
    set ifErr [catch {set result [dict get $lutDict {*}$attr]} errInfo]
    if {$ifErr} {
      error "proc operateLUT: check your input: attr($attr) not found!!!" 
    } else {
      return $result
    }
  } elseif {$type == "test"} {
    set ifErr [catch {set result [dict exists $lutDict {*}$attr]} errInfo]
    if {$ifErr} {
      return 0
    } else {
      return 1
    }
  }
}
define_proc_arguments operateLUT \
  -info "operateLUT" \
  -define_args {
    {-type "specify type of operation" oneOfString one_of_string {required value_type {values {read exists}}}} 
    {-attr "specify attribute of obj" AList list required}
  }

