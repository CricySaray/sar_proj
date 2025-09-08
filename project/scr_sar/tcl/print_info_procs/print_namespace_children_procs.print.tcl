#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/26 09:06:40 Tuesday
# label     : misc_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|misc_proc)
# descrip   : print all children procs of namespace
# return    : output file
# ref       : link url
# --------------------------
set fo [open namespace_cmds_body.tcl w]
set all_namespaces [namespace children ::]
foreach namespace $all_namespaces {
  set namespace_cmds [info procs ${namespace}::*]
  puts $fo "### --------------------------------------------------" 
  puts $fo "### namespace : $namespace"
  foreach cmd $namespace_cmds {
    puts $fo "# ------------------------"
    puts $fo "# cmd: $cmd body"
    puts $fo [info body $cmd]
    puts $fo "# "
    set procs [info proc ${cmd}::*]
    if {$procs != ""} {
      foreach temp_proc $procs {
        puts $fo "# - proc: $temp_proc body:" 
        puts $fo [info body $temp_proc]
        puts $fo "# "
      }
    }
  }
}
close $fo
