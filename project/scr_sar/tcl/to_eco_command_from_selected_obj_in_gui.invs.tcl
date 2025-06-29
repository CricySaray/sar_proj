proc to_eco_command_from_selected_obj_in_gui {{objs ""}} {
  if {$objs == ""} { 
    set objs [dbget selected.name -e]
    if {$objs == ""} {puts "error: no selected and no inputs!!!"; break}
  }
  set insts ""
  set terms ""
  foreach obj $objs {
    set inst [dbget top.insts.name $obj -e]
    if {$inst != ""} {lappend insts $inst}
    set term [dbget top.insts.instTerms.name $obj -e]
    if {$term != ""} {lappend terms $term}
  }
  if {$insts != ""} {
    foreach i $insts { puts "ecoChangeCell -cell [dbget [dbget top.insts.name $i -p].cell.name] -inst $i" } 
  }
  if {$terms != ""} {
    foreach t $terms { puts "ecoAddRepeater -name sar_fix_what -cell what -term {$t} -loc { }"} 
  }
}
alias toeco "to_eco_command_from_selected_obj_in_gui"
# 后面还得加一下假如是inst，那么需要看一下head.libCells.name 中还有什么其他驱动的同类型cell，可以用来替换的
