#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/07/08 15:06:52 Tuesday
# label     : dump_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc)
# descrip   : dump FP def only having necessary elements
#             songNOTE: if you defOut in old version of design and defIn at new version of design,
#              which it has more or maybe have some difference, you'd better to use it instead of 
#              using defOut ./filename in old version and defIn ./filename in new version of design
# update    : 2025/09/02 14:55:29 Tuesday
#             (U001) improve small options
# ref       : link url
# --------------------------
proc defout_FP_elements {args} {
  set testOrRun         "test"
  set path              "./"
  set suffix            ""
  set types             {term rblkg pblkg endcap welltap block pad padSpacer cornerBottomRight}
  set netNamesList      {DVSS DVDD_ONO DVDD_AON}
  set objectTypeForNets {Wire Via} ; # Wire|Via
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  if {[llength $netNamesList]} { ; # U001
    foreach tempnet $netNamesList {
      if {[dbget top.nets.name $tempnet -e] == ""} {
        puts "# --- the net($tempnet) is not found!!! please check it." 
      } else {
        editSelect -net $tempnet -object_type $objectTypeForNets
      }
    }
  }
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
  if {$testOrRun == "run"} {
    set lefDefOutVersion 5.8
    set defOutLefNDR 1
    set defOutLefVia 1
    set defLefDefOutVersion 5.8
    set dbgDefOutFixedViasShape 1
    set gdsUnit [dbget head.dbUnits]
    defOut -selected -routing $path/FP_[clock format [clock second] -format "%Y%m%d_%H%M"]_$suffix.def.gz
  } else {
    puts "testing..." 
  }
}
define_proc_arguments defout_FP_elements \
  -info "defOut def file for Floorplan content"\
  -define_args {
    {-testOrRun "test or run" oneOfString one_of_string {required value_type {values {test run}}}}
    {-path "specify path for generated def file (default: ./)" AString string optional}
    {-suffix "specify the suffix name for def file" AString string optional}
    {-types "specify the types of insts" AList list optional}
    {-netNamesList "specify the list of net name" AList list optional}
    {-objectTypeForNets "specify the type for nets" AList list optional}
  }
