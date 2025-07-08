proc strategy_addRepeaterCelltype {{driverCelltype ""} {loaderCelltype ""} {method "refDriver|refLoader|auto"} {forceSpecifyDriveCapacibility 4} {refType "BUFD4BWP6T16P96CPD"} {regExp "D(\\d+).*CPD(U?L?H?VT)?"}} {
  if {$driverCelltype == "" || $loaderCelltype == "" || [dbget top.insts.cell.name $driverCelltype -e] == "" || [dbget top.insts.cell.name $loaderCelltype -e] == ""} {
    return "0x0:1"; # check your input 
  } else {
    set runError0 [catch {regexp $regExp $refType wholeNameR levelNumR VTtypeR} errorInfoR]
    set runError1 [catch {regexp $regExp $driverCelltype wholeNameD levelNumD VTtypeD} errorInfoD]
    set runError2 [catch {regexp $regExp $loaderCelltype wholeNameL levelNumL VTtypeL} errorInfoL]
    if {$runError1 || $runError2} {
      return "0x0:2"; # check regexp expression 
    } else {
      # if specify the value of drvie capacibility
      if {$forceSpecifyDriveCapacibility} {
        set toCelltype [changeDriveCapacibility_of_celltype $refType $levelNumR $forceSpecifyDriveCapacibility]
        if {$toCelltype == "0x0:1"} {
          return "0x0:3"; # can't identify where the celltype is come from
        } else {
          return $toCelltype
        }
      }
      switch $method {
        "refDriver" {
          set toCelltype [changeDriveCapacibility_of_celltype $refType $levelNumR $levelNumD]
          if {$toCelltype == "0x0:1"} {
            return "0x0:4";  # can't identify where the celltype is come from
          } else {
            return $toCelltype 
          }
        } 
        "refLoader" {
          set toCelltype [changeDriveCapacibility_of_celltype $refType $levelNumR $levelNumL] 
          if {$toCelltype == "0x0:1"} {
            return "0x0:5"; # can't identify where the celltype is come from
          } else {
            return $toCelltype 
          }
        }
        "auto" {
          # improve after
        }
      }
    }
  }
}
source ./proc_whichProcess_fromStdCellPattern.invs.tcl; # proc: whichProcess_fromStdCellPattern
proc changeDriveCapacibility_of_celltype {{refType "BUFD4BWP6T16P96CPD"} {originalDriveCapacibility 0} {toDriverCapacibility 0}} {
  set processType [whichProcess_fromStdCellPattern $refType]
  if {$processType == "TSMC"} { ; # TSMC
    regsub D${originalDriveCapacibility}BWP $refType D${toDriverCapacibility}BWP toCelltype
    return $toCelltype
  } elseif {$processType == "HH"} { ; # HH40 huahonghongli
    regsub X${originalDriveCapacibility} $refType X${toDriverCapacibility} toCelltype
    return $toCelltype
  }
  
}
