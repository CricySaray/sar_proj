#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/02 22:16:55 Saturday
# label     : check_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|misc_proc)
# descrip   : check CTS cell type, must be LVT CLK class of cell type
# return    : non-CLK/LVT cell type rpt(output file)
# ref       : link url
# --------------------------
source ../proc_whichProcess_fromStdCellPattern.pt.tcl; # whichProcess_fromStdCellPattern
source ../eco_fix/timing_fix/trans_fix/proc_getDriveCapacity_ofCelltype.pt.tcl; # get_driveCapacity_of_celltype
source ../eco_fix/timing_fix/trans_fix/proc_get_cellDriveLevel_and_VTtype_of_inst.pt.tcl; # get_cellDriveLevel_and_VTtype_of_inst
proc check_CTScelltype {{specify_VT "ULVT"} {promptERROR "songERROR"}} {
  # $specify_VT : ULVT|AR9
  set allCTSinstname_collection [get_clock_network_objects -type cell -include_clock_gating_network]
  set allCTSinstname_collection [filter_collection $allCTSinstname_collection "ref_name !~ ANT~ && is_black_box==false && is_pad_cell==false"]
  # deal with and classify collection
  set process [whichProcess_fromStdCellPattern [lindex [get_attribute $allCTSinstname_collection ref_name] 0]]
  set error_driveCapacity [add_to_collection "" ""]
  set error_VTtype [add_to_collection "" ""]
  set error_CLKcelltype [add_to_collection "" ""]
  if {$process == "TSMC"} {
    set regExp "D(\\d+).*CPD(U?L?H?VT)?"
    set availableVT [list HVT SVT LVT ULVT]
  } elseif {$process == "HH"} {
    set regExp "X(\\d+).*(A\[HRL\]\\d+)$"
    set availableVT [list AH9 AR9 AL9]
  } else {
    error "proc check_CTScelltype: Other process!!! can't match!!!"
  }
  foreach_in_collection instname_itr $allCTSinstname_collection {
    set driveCapacity [get_driveCapacity_of_celltype [get_attribute $instname_itr ref_name] $regExp]
    if {$driveCapacity < 4} {
      set error_driveCapacity [add_to_collection $error_driveCapacity $instname_itr] ; # drive capacity
    }
    if {$specify_VT in $availableVT && [lindex [get_cellDriveLevel_and_VTtype_of_inst [get_object_name $instname_itr] $regExp] end] != $specify_VT} {
      set error_VTtype [add_to_collection $error_VTtype $instname_itr] ; # VT type
    } elseif {$specify_VT ni $availableVT} {
      error "proc check_CTScelltype: \$specify_VT can't in availableVT list from process $process"
    }
    if {[regexp DCCK [get_attribute $instname_itr ref_name]]} {
      set error_CLKcelltype [add_to_collection $error_CLKcelltype $instname_itr] ; # CLK cell type
    }
  }
  # dump to output file
  # have 7 situations
  if {[sizeof_collection $error_driveCapacity]} {
    
  }
}
