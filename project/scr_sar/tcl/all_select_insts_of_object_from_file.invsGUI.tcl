#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : Mon Jul  7 12:31:39 CST 2025
# label     : gui_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc)
# descrip   : can select_obj insts from filename(can have other misc info), 
#             only select the first that is searchable, as one after it will be ignored
# ref       : link url
# --------------------------
# example : one line of file:
#   violvalue celltype      pinname
#   -0.1      AOI22B2X1AR9 u_ana_smux/U709/O
# inst(u_ana_smux/U709) and pin(u_ana_smux/U709/O) will be selected

proc select_insts_of_object_from_file {{filename ""} {selectDriveOrLoadInst all}} {
  # $selectDriveOrLoadInst : drive|load|all
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
            if {[dbget [dbget top.insts.instTerms.name $pin -p].isOutput] && $selectDriveOrLoadInst == "drive"} {
              select_obj $pin
              set inst [get_object_name [get_cells -of_objects $pin]]
              select_obj $inst
            } elseif {[dbget [dbget top.insts.instTerms.name $pin -p].isInput] && $selectDriveOrLoadInst == "load"} {
              select_obj $pin
              set inst [get_object_name [get_cells -of_objects $pin]]
              select_obj $inst
            } elseif {$selectDriveOrLoadInst == "all"} {
              if {[dbget [dbget top.insts.instTerms.name $pin -p].isInput]} {

                select_obj $pin; # load pin
                set loadInst [get_object_name [get_cells -of_objects $pin]]
                select_obj $loadInst
                set drivePin [lindex [get_object_name [all_fanin -to $pin -pin_levels 1]] 1]
                select_obj $drivePin
                set driveInst [get_object_name [get_cells -of_objects $drivePin]]
                select_obj $driveInst

              } elseif {[dbget [dbget top.insts.instTerms.name $pin -p].isOutput]} {

                select_obj $pin; # drive pin
                set driveInst [get_object_name [get_cells -of_objects $pin]]
                select_obj $driveInst
                #set loadPin [dbget [dbget [dbget top.insts.instTerms.name $pin -p].net.instTerms.isInput 1 -p].name ]
                #select_obj $loadPin
                #set loadInst [get_object_name [get_cells -of_objects $drivePin]]
                #select_obj $loadInst

              }
            }
          } elseif {$inst != "" && $pin == ""} {
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

# source -v ./eco_fix/proc_get_fanoutNum_and_inputTermsName_of_pin.invs.tcl; # get_drivePin
#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : Wed Jul  2 20:38:55 CST 2025
# label     : atomic_proc
#   -> (atomic_proc|display_proc)
# descrip   : get number of fanout and name of input terms of a pin. ONLY one pin!!! this pin is output
# ref       : link url
# --------------------------
proc get_fanoutNum_and_inputTermsName_of_pin {{pin ""}} {
  # this pin must be output pin
  if {$pin == "" || $pin == "0x0" || [dbget top.insts.instTerms.name $pin -e] == ""} {
    return "0x0:1"
  } else {
    set netOfPinPtr  [dbget [dbget top.insts.instTerms.name $pin -p].net.]
    set netNameOfPin [dbget $netOfPinPtr.name]
    set fanoutNum    [dbget $netOfPinPtr.numInputTerms]
    set allinstTerms [dbget $netOfPinPtr.instTerms.name]
    #set inputTermsName "[lreplace $allinstTerms [lsearch $allinstTerms $pin] [lsearch $allinstTerms $pin]]"
    set inputTermsName "[lsearch -all -inline -not -exact $allinstTerms $pin]"
    #puts "$fanoutNum"
    #puts "$inputTermsName"
    set numToInputTermName [list ]
    lappend numToInputTermName $fanoutNum
    lappend numToInputTermName $inputTermsName
    return $numToInputTermName
  }
}
proc get_driverPin {{pin ""}} {
  if {$pin == "" || [dbget top.insts.instTerms.name $pin -e] == ""} {
    return "0x0:1"; # no pin
  } else {
    set driver [lindex [dbget [dbget [dbget top.insts.instTerms.name $pin -p].net.instTerms.isOutput 1 -p].name ] 0]
    return $driver
  }
}

