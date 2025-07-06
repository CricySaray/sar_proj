proc strategy_addRepeaterCelltype {{driverCelltype ""} {loaderCelltype ""} {method ""} {toAddBuffer ""}} {
  if {$driverCelltype == "" || $loaderCelltype == "" || [dbget top.insts.cell.name $driverCelltype -e] == "" || [dbget top.insts.cell.name $loaderCelltype -e] == ""} {
    return "0x0:1"; # check your input 
  } else {
    
  }
}
