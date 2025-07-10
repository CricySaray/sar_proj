proc gen_hold_path {{filepath ""} {{timestamp ""}}} {
  if {![file exists $filepath/hold_endpt_$timestamp.list]} { puts "no hold endpt file."; return}
  set fi [open $filepath/hold_endpt_$timestamp.list r]
  set fo [open $filepath/hold_path_$timestamp.list w]
  while {[gets $fi line] > -1} {
    set pin [lindex $line 0]
    set vio [lindex $line 1]
    set pathObj [get_timing_paths -delay_type min -to $pin]
    set pathVio [get_attribute $pathObj slack]
    set pathPoints [list [lrange [lreverse [get_object_name [get_attribute [get_attribute $pathObj points] object]]] 0 end-1]]
    #puts $fo "$pathPoints $pathVio"
    if {"" == $pathObj} {
      puts $fo "$pin $vio" 
    } else {
      puts $fo "$pathPoints $vio" 
    }
  }
  close $fi; close $fo
}
