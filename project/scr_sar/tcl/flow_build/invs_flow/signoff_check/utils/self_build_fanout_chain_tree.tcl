proc test_chain {{inputList ""}} {
  if {![llength $inputList]} {
    error "proc test_chain: check your input: empty!!!" 
  } else {
    set chainsDict [dict create]
    set processList $inputList
    foreach temp_cell $processList {
      set temp_fanout_cells [lsearch -not -all -inline -exact [all_fanout -from -only_cells [get_pins -of $temp_cell -filter "direction==out"]] $temp_cell] 
      set temp_driver_cells [dbget [dbget [dbget [dbget top.insts.name $temp_cell -p].instTerms.isInput 1 -p].net.instTerms.isOutput 1 -p].inst.name]
      foreach temp_fanout_cell $temp_fanout_cells {
        if {$temp_fanout_cell in $processList} {
          dict set chainsDict $temp_cell [list $temp_fanout_cell {}]
          set processList [lsearch -not -all -inline $processList $temp_fanout_cell]
        } 
      }
      foreach temp_driver_cell $temp_driver_cells {
        if {$temp_driver_cell in $processList} {
          set temp_branch_of_chain [dict get $chainsDict $temp_cell]
          catch {dict unset $chainsDict $temp_cell}
          dict set chainsDict $temp_driver_cell $temp_cell
          set processList [lsearch -not -all -inline $processList $temp_driver_cell]
        } 
      }
    } 
  }
}
