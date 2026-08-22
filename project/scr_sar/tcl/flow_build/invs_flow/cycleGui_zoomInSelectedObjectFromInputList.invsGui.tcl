#!/bin/tclsh
# --------------------------
# author    : aiden song
# date      : 2026/06/21 19:20:06 Sunday
# label     : 
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc|snippet|signoff_check|drc_proc|clock_tree_relative_proc)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : Retrieve a list via input procedures. Specify the iteration command and the reset command for clearing iteration state 
#             before each new iteration using parameters. Built-in commands are available to evaluate objects within the list and categorize 
#             them into separate target lists accordingly. This enables fast implementation of review and classification workflows
# return    : 
# ref       : link url
# --------------------------
global _cycleGui_var_inputList
global _cycleGui_var_inputObjectType
global _cycleGui_var_yesList
global _cycleGui_var_noList
global _cycleGui_var_initCmd
global _cycleGui_var_resetCmd
global _cycleGui_iter_num_of_inputList

set _cycleGui_var_inputList [list]
set _cycleGui_var_inputObjectType "inst"
set _cycleGui_var_yesList [list]
set _cycleGui_var_noList [list]
set _cycleGui_var_initCmd "selectPin"
set _cycleGui_var_resetCmd "deselectAll"
set _cycleGui_iter_num_of_inputList 1

alias ssreset cycleGui_resetAllStatus
proc cycleGui_resetAllStatus {} {
  set _cycleGui_var_inputList [list]
  set _cycleGui_var_inputObjectType "inst"
  set _cycleGui_var_yesList [list]
  set _cycleGui_var_noList [list]
  set _cycleGui_var_initCmd "selectPin"
  set _cycleGui_var_resetCmd "deselectAll"
  set _cycleGui_iter_num_of_inputList 1

  eval ${_cycleGui_var_resetCmd}
}
alias ssinit cycleGui_initInputList
proc cycleGui_initInputList {{inputlist {}}} {
  global _cycleGui_var_inputObjectType
  global _cycleGui_var_inputList
  if {${_cycleGui_var_inputObjectType} eq "inst"} {
    set _cycleGui_var_inputList [lmap temp_inputItem ${_cycleGui_var_inputList} {
      if {[dbget top.insts.name $temp_inputItem -e] ne ""} {
        set temp_inputItem
      } else { continue }
    }]
  }
}
alias ssrun cycleGui_runCycleCmd
proc cycleGui_runCycleCmd {} {
  global _cycleGui_var_inputList
  global _cycleGui_iter_num_of_inputList
  global _cycleGui_var_initCmd
  global _cycleGui_var_resetCmd
  set temp_resetcmd "${_cycleGui_var_resetCmd}"
  set temp_initcmd "${_cycleGui_var_initCmd} [lindex ${_cycleGui_var_inputList} ${_cycleGui_iter_num_of_inputList}]"
  eval $temp_resetcmd
  eval $temp_initcmd
  incr _cycleGui_iter_num_of_inputList
}
alias ssy cycleGui_yesStatusAndDumpYesList
proc cycleGui_yesStatusAndDumpYesList {} {
  global _cycleGui_var_inputList
  global _cycleGui_iter_num_of_inputList
  global _cycleGui_var_yesList
  lappend _cycleGui_var_yesList [lindex ${_cycleGui_var_inputList} ${_cycleGui_iter_num_of_inputList}]
}
alias ssn cycleGui_noStatusAndDumpNoList
proc cycleGui_noStatusAndDumpNoList {} {
  global _cycleGui_var_inputList
  global _cycleGui_iter_num_of_inputList
  global _cycleGui_var_noList
  lappend _cycleGui_var_noList [lindex ${_cycleGui_var_inputList} ${_cycleGui_iter_num_of_inputList}]
}
