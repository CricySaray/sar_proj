proc strategy_changeDriveCapacibility {{celltype ""} {driveRange {1 16}} {regExp "D(\\d+).*CPD(U?L?H?VT)?"}} {
  if {$celltype == "" || $celltype == "0x0" || [dbget head.libCells.name $celltype -e ] == ""} {
    return "0x0:1" 
  } else {
    #get now Drive Capacibility
    set runError [catch {regexp $regExp $celltype wholename driveLevel VTtype} errorInfo]
    if {$runError || $wholename == ""} {
      return "0x0:2" 
    } else {
      set driveRangeRight [lsort -integer -increasing $driveRange]
      if {$driveLevel < [lindex $driveRangeRight 0] || $driveLevel > [lindex $driveRangeRight 1]} {
        return "0x0:3"; # out of driveRange, not to change Drive Capcibility 
      } else {
        
      }
    }
  }
}
