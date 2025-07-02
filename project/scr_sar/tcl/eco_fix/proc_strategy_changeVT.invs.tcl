proc strategy_changeVT {{celltype ""} {weight {{SVT 3} {LVT 1} {ULVT 0}}} {speed {ULVT LVT SVT}} {regExp "D(\\d+).*CPD(U?L?H?VT)?"}} {
  # $weight:0 is stand for no using
  # $speed: the fastest must be in front. like ULVT must be the first
  if {$celltype == "" || $celltype == "0x0" || [dbget head.libCells.name $celltype -e] == ""} {
    return "0x0:1" 
  } else {
    # get now VTtype
    set runError [catch {regexp $regExp $celltype wholeName driveLevel VTtype} errorInfo]
    if {$runError || $wholeName == ""} {
      return "0x0:2"; # check if $regExp pattern is correct 
    } else {
      if {$VTtype == ""} {set VTtype "SVT"} 
      set avaiableVT [lsearch -all -inline -index 1 -regexp $weight "\[1-9\]"]; # remove weight:0 VT
      # user-defined avaiable VT type
      set avaiableVTsorted [lsort -index 1 -integer -decreasing $avaiableVT]
      set nowVTindex [lsearch -all -index 0 $avaiableVTsorted $VTtype]
      if {$nowVTindex == ""} {
        return "0x0:3"; # cell type can't be allowed to use, don't change VT type
      } else {
        # get changeable VT type according to provided cell type 
        set changeableVT [lsearch -exact -index 0 -all -inline -not $avaiableVTsorted $VTtype]
        puts $changeableVT
        # judge if changeable VT types have faster type than nowVTtype of provided cell type
        set nowSpeedIndex [lsearch -exact $speed $VTtype]
        set moreFastVTinSpeed [lreplace $speed $nowSpeedIndex end]
        set useVT ""
        foreach vt $changeableVT {
          if {[lsearch -exact $moreFastVTinSpeed [lindex $vt 0]] > -1} {
            set useVT "[lindex $vt 0]"
            break
          }
        }
        # NOTE: these VT type set now is only for TSMC cell pattern
        # TSMC cell VT type pattern: 
        #   SVT: xxxCPD
        #   LVT: xxxCPDLVT
        #   ULVT: xxxCPDULVT
        if {$useVT == ""} {
          return "0x0:4"; # don't have faster VT
        } else {
          #return $useVT 
          if {$useVT == "SVT"} {
            return [regsub "$VTtype" $celltype ""]
          } elseif {$VTtype == "SVT"} {
            return [regsub "$" $celltype $useVT] 
          } else {
            return [regsub $VTtype $celltype $useVT] 
          }
        }
      }
    }
  }
}
