#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/07/08 15:06:52 Tuesday
# label     : dump_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc)
#   -> atomic_proc : Specially used for calling and information transmission of other procs, 
#                    providing a variety of error prompt codes for easy debugging
#   -> display_proc : Specifically used for convenient access to information in the innovus command line, 
#                    focusing on data display and aesthetics
#   -> gui_proc   : for gui display, or effort can be viewed in invs GUI
#   -> task_proc  : composed of multiple atomic_proc , focus on logical integrity, 
#                   process control, error recovery, and the output of files and reports when solving problems.
#   -> dump_proc  : dump data with specific format from db(invs/pt/starrc/pv...)
# descrip   : dump FP def only having necessary elements
#             songNOTE: if you defOut in old version of design and defIn at new version of design,
#              which it has more or maybe have some difference, you'd better to use it instead of 
#              using defOut ./filename in old version and defIn ./filename in new version of design
# ref       : link url
# --------------------------
proc defout_FP_elements {{ifRun "test"} {path "./"} {suffix ""} {types {term rblkg pblkg endcap welltap block pad padSpacer cornerBottomRight}}} {
  editSelect -net {DVSS DVDD_ONO DVDD_AON}
  if {[lsearch -exact $types "term"] > -1} {
    select_obj [dbget top.terms.]
    set types [lsearch -not -all -inline $types "term"]
  }
  if {[lsearch -exact $types "rblkg"] > -1} {
    select_obj [dbget top.fplan.rblkgs.]
    set types [lsearch -not -all -inline $types "rblkg"]
  }
  if {[lsearch -exact $types "pblkg"] > -1} {
    select_obj [dbget top.fplan.pblkgs.]
    set types [lsearch -not -all -inline $types "pblkg"]
  }
  if {[lsearch -exact $types "endcap"] > -1} {
    select_obj [dbget top.insts.name */ENDCAP* -p]
    select_obj [dbget top.insts.name ENDCAP* -p]
    set types [lsearch -not -all -inline $types "endcap"]
  }
  if {[lsearch -exact $types "welltap"] > -1} {
    select_obj [dbget top.insts.name WELLTAP* -p]
    set types [lsearch -not -all -inline $types "welltap"]
  }
  foreach type $types {
    if {[dbget top.insts.cell.subClass $type -e -u] != ""} {
      select_obj [dbget top.insts.cell.subClass $type -p2]
    } else {
      return "can't find cell.subClass: $type , please check input \$types"
    }
  }
  if {$ifRun == "run"} {
    defOut -selected -routing $path/FP_[clock format [clock second] -format "%Y%m%d_%H%M"]_$suffix.def.gz
  } else {
    puts "testing..." 
  }
}
