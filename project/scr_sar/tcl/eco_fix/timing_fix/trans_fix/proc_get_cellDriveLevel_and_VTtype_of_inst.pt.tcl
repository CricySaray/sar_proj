#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/02 23:20:24 Saturday
# label     : atomic_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|misc_proc)
# descrip   : get cell drive capacibility and VT type of a instOrPin. ONLY one instance!!! (pt edition)
# updata    : 2025/07/27 12:09:25 Sunday
#             can input inst or pin (can only input inst name before)
# return    : [list]
# ref       : link url
# --------------------------
proc get_cellDriveLevel_and_VTtype_of_inst {{instOrPin ""} {regExp "D(\\d+).*CPD(U?L?H?VT)?"}} {
  # NOTE: $regExp need specific pattern to match info correctly!!! search doubao AI
  # \ need use \\ to adapt. like : \\d+
  if {$instOrPin == "" || $instOrPin == "0x0" || ![sizeof_collection [get_cells -q $instOrPin]] && ![sizeof_collection [get_pins -q $instOrPin]]} {
    return "0x0:1"
  } else {
    if {[get_object_name [get_cells -q $instOrPin]] != ""} {
      set cellName [get_attribute [get_cells -q $instOrPin] ref_name] 
      set instname $instOrPin
    } else {
      set cellName [get_attribute [get_cells -q -of $instOrPin] ref_name]
      set instname [get_object_name [get_cells -q -of $instOrPin]]
    }
    # NOTE: expression of get drive level need modify by different design and standard cell library.
    set wholeName 0
    set levelNum 0
    set VTtype 0
    set runError [catch {regexp $regExp $cellName wholeName levelNum VTtype} errorInfo]
    if {$runError || $wholeName == ""} {
      # if error, check your regexp expression
      return "0x0:2" 
    } else {
      if {$VTtype == ""} {set VTtype "SVT"}
      if {$levelNum == "05"} {set levelNumTemp 0.5} else {set levelNumTemp [expr $levelNum]}
      set instName_cellName_driveLevel_VTtype_List [list ]
      lappend instName_cellName_driveLevel_VTtype_List $instname
      lappend instName_cellName_driveLevel_VTtype_List $cellName
      lappend instName_cellName_driveLevel_VTtype_List $levelNumTemp
      lappend instName_cellName_driveLevel_VTtype_List $VTtype
      return $instName_cellName_driveLevel_VTtype_List
    }
  }
}
