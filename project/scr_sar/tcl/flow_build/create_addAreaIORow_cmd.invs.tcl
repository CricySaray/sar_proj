#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/31 23:10:22 Sunday
# label     : flow_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|misc_proc)
# descrip   : Create appropriate specific command content for the addAIORow command that can be directly executed in the command line; specific 
#             commands with different configurations can be returned by adjusting various parameters of the proc.
# related   : ./get_addAreaIORow_info.invs.tcl: get_addAreaIORow_info
# return    : cmds of addAIORow
# ref       : link url
# --------------------------
source ./get_addAreaIORow_info.invs.tcl; # get_addAreaIORow_info
proc create_addAIORow_cmd {{dieArea_rect {0 0 10 10}} {IO_site_name ""} {numOrRowEveryEdge {1 1 1 1}} {orientOfEveryEdgeInClockWiseOrder_fromTop {MX MY90 MY MX90}}} {
  if {$IO_site_name == "" || [dbget [dbget head.sites.name $IO_site_name -p].size -e] == ""} {
    error "proc create_addAIORow_cmd: check your input: IO_site_name($IO_site_name) not found!!!"
  } else {
    set IO_site_size {*}[dbget [dbget head.sites.name $IO_site_name -p].size -e]
    set info_of_addAIORow [get_addAreaIORow_info $dieArea_rect $IO_site_size $numOrRowEveryEdge]
    set i 0
    set cmds_of_addAIORow [lmap tempinfo $info_of_addAIORow {
      lassign $tempinfo leftBottomPoint numOfSite direction
      switch $direction { H { set tempdirection -H } V { set tempdirection -V }}
      set orientOfSite [lindex $orientOfEveryEdgeInClockWiseOrder_fromTop $i]
      incr i
      set temp_cmd "addAIORow -noSnap -site $IO_site_name -orient $orientOfSite $tempdirection -num $numOfSite -loc $leftBottomPoint"
    }]
    return [join $cmds_of_addAIORow \n]
  }
}
