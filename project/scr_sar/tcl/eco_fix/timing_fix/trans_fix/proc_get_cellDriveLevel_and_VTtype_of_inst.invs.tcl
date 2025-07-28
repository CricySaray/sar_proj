#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : Wed Jul  2 20:20:11 CST 2025
# label     : atomic_proc
#   -> (atomic_proc|display_proc)
# descrip   : get cell drive capacibility and VT type of a instOrPin. ONLY one instance!!!
# updata    : 2025/07/27 12:09:25 Sunday
#             can input inst or pin (can only input inst name before)
# ref       : link url
# --------------------------
proc get_cellDriveLevel_and_VTtype_of_inst {{instOrPin ""} {regExp "D(\\d+).*CPD(U?L?H?VT)?"}} {
  # NOTE: $regExp need specific pattern to match info correctly!!! search doubao AI
  # \ need use \\ to adapt. like : \\d+
  if {$instOrPin == "" || $instOrPin == "0x0" || [dbget top.insts.name $instOrPin -e] == "" && [dbget top.insts.instTerms.name $instOrPin -e] == ""} {
    return "0x0:1"
  } else {
    if {[dbget top.insts.name $instOrPin -e] != ""} {
      set cellName [dbget [dbget top.insts.name $instOrPin -p].cell.name] 
      set instname $instOrPin
    } else {
      set cellName [dbget [dbget top.insts.instTerms.name $instOrPin -p2].cell.name]
      set instname [dbget [dbget top.insts.instTerms.name $instOrPin -p2].name]
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
