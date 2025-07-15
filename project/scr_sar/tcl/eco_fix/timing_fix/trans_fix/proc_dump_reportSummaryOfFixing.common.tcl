proc dump_reportSummaryOfFixing {infoList {violValue celltype violPin type fixMethodOrReasonOfUnfix}} {
  if {$infoList == "" } {
    return "0x0:1"; # check your input 
  } else {
    
  }
}

proc to_std_list_forDumpInput {{rawList {}} celltype type fixMethodOrReasonOfUnfix} {
  return [lappend [linsert $rawList 1 $celltype] $type $fixMethodOrReasonOfUnfix]
}
