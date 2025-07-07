#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : Mon Jul  7 12:31:39 CST 2025
# label     : gui_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc)
#   -> atomic_proc : Specially used for calling and information transmission of other procs, 
#                    providing a variety of error prompt codes for easy debugging
#   -> display_proc : Specifically used for convenient access to information in the innovus command line, 
#                    focusing on data display and aesthetics
#   -> gui_proc   : for gui display, or effort can be viewed in invs GUI
#   -> task_proc  : composed of multiple atomic_proc , focus on logical integrity, 
#                   process control, error recovery, and the output of files and reports when solving problems.
# descrip   : can select_obj insts from filename(can have other misc info), 
#             only select the first that is searchable, as one after it will be ignored
# ref       : link url
# --------------------------
# example : one line of file:
#   violvalue celltype      pinname
#   -0.1      AOI22B2X1AR9 u_ana_smux/U709/O
# inst(u_ana_smux/U709) and pin(u_ana_smux/U709/O) will be selected

proc select_insts_of_object_from_file {{filename ""}} {
  set promptError "songERROR:"
  if {$filename == "" || [glob -nocomplain $filename] == ""} {
    return "0x0:1" ; # check your filename and type 
  } else {
    set fi [open $filename r]
    while {[gets $fi line] > -1} {
      set getFlag 0
      foreach item $line {
        if {[regexp -expanded -- "^-" $item]} {continue}; # $item with "-" will affect on judgement
        set inst [dbget top.insts.name $item -e]
        set pin  [dbget top.insts.instTerms.name $item -e]
        if {$inst == "" && $pin == ""} {
          continue
        } else {
          set getFlag 1
          if {$inst == "" && $pin != ""} {
            select_obj $pin
            set inst [get_object_name [get_cells -of_objects $item]]
            select_obj $inst
          } else {
            select_obj [get_object_name $inst]
          }
          break 
        }
      }
      if {!$getFlag} {
        puts "$promptError can't find selectable obj in line:\n $line"
      }
    }
  }
  close $fi
}

