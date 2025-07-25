proc get_rootLeafBranchData {{pinName ""}} {
  if {$pinName == "" || [dbget top.insts.instTerms.name $pinName -e] == ""} {
    error "proc get_rootLeafBranchData: check your input, can't find driver pin: $pinName" 
  } else {
    set pin_ptr [dbget top.insts.instTerms.name $pinName -p]
    if {[dbget $pin_ptr.isOutput]} {
      set driverPin_ptr $pin_ptr
    } else {
      set driverPin_ptr [dbget $pin_ptr.net.allTerms {.isOutput}] 
    }
    set driverPin_name [dbget $driverPin_ptr.name]
    set driverPin_loc [lindex [dbget $driverPin_ptr.pt] 0]
    set sinksNum [dbget $driverPin_ptr.net.numInputTerms]
    set sinksPins_ptr [dbget $driverPin_ptr.net.allTerms {.isInput}]
    set sinksPins_loc [dbget $sinksPins_ptr.pt]
    set wiresLines [dbget $driverPin_ptr.net.wires.pts]

    set result [analyzePowerDistribution $driverPin_loc $sinksPins_loc $wiresLines 8]
    puts "\nPower Distribution Plan:"
    lassign [dict get $result generator] genPoint genCapacity
    puts "Generator: [format "%.2f %.2f" {*}$genPoint] (Capacity: $genCapacity)"
    
    puts "\nRepeaters:"
    foreach repeater [dict get $result repeaters] {
      lassign $repeater repPoint repCapacity repLoads
      puts "  Repeater: [format "%.2f %.2f" {*}$repPoint] (Capacity: $repCapacity, Loads: [llength $repLoads])"
      puts "    Driven Loads:"
      foreach load $repLoads {
        puts "      - [format "%.2f %.2f" {*}$load]"
      }
    }
    
    puts "\nDirect Loads (generator-driven): [llength [dict get $result directLoads]]"
    foreach load [dict get $result directLoads] {
      lassign $load point capacity
      puts "  - [format "%.2f %.2f" {*}$point] (Capacity: $capacity)"
    }

  }
}
