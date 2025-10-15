if {$vars(dont_use_list) != ""} {
  foreach cell $vars(dont_use_list) {
    if {[dbGet head.libCells.name $cell] != ""} {
      puts "INFO: setDontUse $cell true"
      setDontUse $cell true
    }
  }
}


