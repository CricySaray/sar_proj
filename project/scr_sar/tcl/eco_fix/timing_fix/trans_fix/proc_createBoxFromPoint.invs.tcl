#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/07/22 10:28:05 Tuesday
# label     : gui_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|misc_proc)
# descrip   : what?
# ref       : link url
proc createBoxFromPoint {args} {
  set coords       {0 0}
  set square       1
  set padding      {10}
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  # Validate coordinates
  if {[llength $coords] != 2} {
    error "Coordinates must be a list of two values (x y)"
  }
  foreach {x y} $coords {}
  # Validate padding count
  set padCount [llength $padding]
  if {$padCount ni {1 2 4}} {
    error "Padding must be 1, 2, or 4 values"
  }
  # Calculate box coordinates based on square/rectangle mode
  if {$square} {
    if {$padCount != 1} {
      error "Square mode requires exactly 1 padding value"
    }
    set pad [lindex $padding 0]
    set left [expr {$x - $pad}]
    set right [expr {$x + $pad}]
    set bottom [expr {$y - $pad}]
    set top [expr {$y + $pad}]
  } else {
    switch $padCount {
      1 {
        set pad [lindex $padding 0]
        set left [expr {$x - $pad}]
        set right [expr {$x + $pad}]
        set bottom [expr {$y - $pad}]
        set top [expr {$y + $pad}]
      }
      2 {
        lassign $padding horiz vert
        set left [expr {$x - $horiz}]
        set right [expr {$x + $horiz}]
        set bottom [expr {$y - $vert}]
        set top [expr {$y + $vert}]
      }
      4 {
        lassign $padding topPad bottomPad leftPad rightPad
        set left [expr {$x - $leftPad}]
        set right [expr {$x + $rightPad}]
        set bottom [expr {$y - $bottomPad}]
        set top [expr {$y + $topPad}]
      }
    }
  }
  # Validate box coordinates
  if {$left >= $right} {
    error "Left coordinate ($left) must be less than right ($right)"
  }
  if {$bottom >= $top} {
    error "Bottom coordinate ($bottom) must be less than top ($top)"
  }
  return [list $left $bottom $right $top]
}
# Define procedure attributes using Synopsys command
define_proc_arguments createBoxFromPoint \
  -info "Create a box from a center point with specified padding" \
  -define_args {
    {-coords "Center coordinates (x y)" "x y" list required}
    {-square "Create square box (1) or rectangle (0)" "" boolean optional}
    {-padding "Padding values (1, 2, or 4 elements)" "values" list optional}
  } 
