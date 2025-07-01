proc get_cellDriveLevel_and_VTtype_of_inst {{inst ""}} {
  if {$inst == "" || $inst == "0x0" || [dbget top.insts.name $inst -e] == ""} {
    return "0x0" 
  } else {
    set cellName [dbget [dbget top.insts.name $inst -p].cell.name] 
    # NOTE: expression of get drive level need modify by different design and standard cell library.
    set runError [catch {regexp -expanded {D(\d+)BWP.*CPD(U?LVT)?} $cellName wholeName levelNum VTtype} errorInfo]
    if {$runError} {
      # if error, check your regexp expression
      return "0x0" 
    } else {
      if {$VTtype == ""} {set VTtype "SVT"}
      set instName_cellName_driveLevel_VTtype_List [list ]
      lappend instName_cellName_driveLevel_VTtype_List $inst
      lappend instName_cellName_driveLevel_VTtype_List $cellName
      lappend instName_cellName_driveLevel_VTtype_List $levelNum
      lappend instName_cellName_driveLevel_VTtype_List $VTtype
      return $instName_cellName_driveLevel_VTtype_List
    }
  }
}
