#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/07/15 10:55:56 Tuesday
# label     : atomic_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|misc_proc)
# descrip   : create floorplan shape in init stage
# ref       : link url
# --------------------------
proc create_floorplan_shape {{rect {}}} {
  floorplan -filp f -b 
}
