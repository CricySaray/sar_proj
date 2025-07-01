proc strategy_changeVT {{celltype ""} {weight [[SVT 3] [LVT 1] [HVT 0] [ULVT 0]]} {regExp "D(\\d+).*CPD(U?L?H?VT)?"}} {
  if {$celltype == "" || $celltype == "0x0" || [dbget top.insts.cell.name $celltype -e] == ""} {
    return "0x0" 
  } else {
    set runError [catch {regexp $regExp $celltype wholeName driveLevel VTtype} errorInfo]
    if {$runError || $wholeName == ""} {
      return "0x0" 
    } else {
      if {$VTtype == ""} {set VTtype "SVT"} 
      set avaiableVT [list ]
      foreach VTName_Weight $weight {
        if {[lindex $VTName_Weight 1] > 0} {lappend $avaiableVT $VTName_Weight}
      }
    }
  }
}
