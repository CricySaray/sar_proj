#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/09/08 17:47:04 Monday
# label     : check_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|misc_proc)
#   perl -> (format_sub)
# descrip   : check if the globalNetConnect of inst is empty 
# return    : output file
# ref       : link url
# --------------------------
source ../packages/table_format_with_title.package.tcl; # table_format_with_title
source ../packages/pw_puts_message_to_file_and_window.package.tcl; # pw
proc check_if_empty_of_globalNetConnect {args} {
  set insts_toCheck        {}
  set outputfilename       "checkGNC.rpt"
  set ignorePin_signalOrPg {PO RTO SNS Y}
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  if {[llength $insts_toCheck] && [any x $insts_toCheck { expr {[dbget top.insts.name $x -e] == ""} }]} {
    error "proc check_if_empty_of_globalNetConnect: check your input: insts_toCheck($insts_toCheck) has inst that not found!!!"
  } elseif {[llength $insts_toCheck]} {
    set inst_signal_pg_emptyList [list ]
    foreach inst [lsort -unique $insts_toCheck] {
      set inst_ptr [dbget top.insts.name $inst -p]
      set signalPins_ofInst [dbget $inst_ptr.instTerms. -e]
      set temp_signalPin_empty [list]
      if {$signalPins_ofInst != ""} {
        foreach temp_signalpin $signalPins_ofInst {
          set signal_net [dbget $temp_signalpin.net.name -e]
          if {$signal_net == ""} {
            lappend temp_signalPin_empty [lindex [split [dbget $temp_signalpin.name] "/"] end]
          } 
        }
      }
      set pgPins_ofInst [dbget $inst_ptr.pgInstTerms. -e]
      set temp_pgPins_empty [list] 
      if {$pgPins_ofInst != ""} {
        foreach temp_pgpin $pgPins_ofInst {
          set pg_net [dbget $temp_pgpin.net.name -e]
          if {$pg_net == ""} {
            lappend temp_pgPins_empty [dbget $temp_pgpin.name] 
          } 
        }
      }
      foreach x $ignorePin_signalOrPg {
        set temp_signalPin_empty [lsearch -not -exact -all -inline $temp_signalPin_empty $x]
        set temp_pgPins_empty [lsearch -not -exact -all -inline $temp_pgPins_empty $x]
      }
      if {[llength $temp_signalPin_empty] || [llength $temp_pgPins_empty]} {
        if {![llength $temp_signalPin_empty]} { set temp_signalPin_empty "/" }
        if {![llength $temp_pgPins_empty]} { set temp_pgPins_empty "/" }
        lappend inst_signal_pg_emptyList [list $inst $temp_signalPin_empty $temp_pgPins_empty]
      }
    }
    set inst_signal_pg_emptyList [linsert $inst_signal_pg_emptyList 0 [list instname signalPin pgPin]]
    set tabled_content [table_format_with_title $inst_signal_pg_emptyList 0 "Specified insts globalNetConnect checking result"]
    set fi [open $outputfilename w]
    pw $fi $tabled_content
    close $fi
  } else {
    set all_cellSubClass [dbget top.insts.cell.subClass -u -e]
    if {$all_cellSubClass == ""} {
      error "proc check_if_empty_of_globalNetConnect: check your design([dbget top.name]) is not found any insts!!!"
    } else {
      set all_cellSubClass [lsort -command {
        apply {{a b} {
          set a_len [llength [dbget top.insts.cell.subClass $a]]
          set b_len [llength [dbget top.insts.cell.subClass $b]]
          if {$a_len < $b_len} { return -1 }
          if {$a_len > $b_len} { return 1 } else { return 0 }
        }} 
      } $all_cellSubClass]
#set all_cellSubClass [lrange $all_cellSubClass 0 end-1]
puts $all_cellSubClass
      foreach temp_subclass $all_cellSubClass {
        puts "# - scanning subClass: $temp_subclass ..."
        set all_insts_of_this_subclass_ptr [dbget top.insts.cell.subClass $temp_subclass -p2]
        set empty_signal "" ; set have_signal "" ; set empty_pg "" ; set have_pg ""
        foreach inst_of_this_subclass_ptr $all_insts_of_this_subclass_ptr {
          set signalPins_ofInstCell [dbget $inst_of_this_subclass_ptr.cell.terms. -e]
          if {$signalPins_ofInstCell != ""} {
            foreach signalpin $signalPins_ofInstCell {
              set signal_net [dbget $signalpin.net.name -e] 
              if {$signal_net == ""} {
                lappend empty_signal "[dbget $inst_of_this_subclass_ptr.name]/[dbget $signalpin.name]"
              } else {
                lappend have_signal "[dbget $inst_of_this_subclass_ptr.name]/[dbget $signalpin.name]"
              }
            }
          }
          set pgPins_ofInstCell [dbget $inst_of_this_subclass_ptr.cell.pgTerms. -e]
          if {$pgPins_ofInstCell != ""} {
            foreach pgpin $pgPins_ofInstCell {
              set pg_net [dbget $pgpin.net.name -e]
              if {$pg_net == ""} {
                lappend empty_pg "[dbget $inst_of_this_subclass_ptr.name]/[dbget $pgpin.name]"
              } else {
                lappend have_pg "[dbget $inst_of_this_subclass_ptr.name]/[dbget $pgpin.name]"
              }
            }
          }
        }
        set empty_signal [lsearch -not -all -inline $empty_signal ""]
        set empty_pg [lsearch -not -all -inline $empty_pg ""]
        set have_signal [lsearch -not -all -inline $have_signal ""]
        set have_pg [lsearch -not -all -inline $have_pg ""]
        if {[llength $empty_signal]} { lappend empty_$temp_subclass signal $empty_signal }
        if {[llength $empty_pg]} { lappend empty_$temp_subclass pg $empty_pg }
        if {[llength $have_signal]} { lappend have_$temp_subclass signal $have_signal }
        if {[llength $have_pg]} { lappend have_$temp_subclass pg $have_pg }
        unset empty_signal ; unset empty_pg ; unset have_signal ; unset have_pg
        if {[info exists empty_$temp_subclass]} { lappend empty_all_class_pins $temp_subclass [subst \${empty_$temp_subclass}] }
        if {[info exists have_$temp_subclass]} { lappend have_all_class_pins $temp_subclass [subst \${have_$temp_subclass}] }
      }
      if {[info exists empty_all_class_pins]} { set emptyGlobalNetConnect_List [dict create {*}$empty_all_class_pins] }
      if {[info exists have_all_class_pins]} { set haveGlobalNetConnect_List [dict create {*}$have_all_class_pins] }
#puts [join [join [join [dict get $emptyGlobalNetConnect_List] \n] \n] \n]
      dict for {class type} $emptyGlobalNetConnect_List {
        set signal_pins [dict get $type signal]
        set pg_pins [dict get $type pg]
        set signal_insts [lsort -unique [lmap temp_signal_pin $signal_pins {
          set temp_signal_inst [join [lrange [split $temp_signal_pin "/"] 0 end-1] "/"]
        }]]
        set signal_singlePinname [lsort -unique [lmap temp_signal_pin $signal_pins {
          set temp_signal_singlePinname [lindex [split $temp_signal_pin "/"] end] 
        }]]
        set pg_insts [lsort -unique [lmap temp_pg_pin $pg_pins {
          set temp_pg_inst [join [lrange [split $temp_pg_pin "/"] 0 end-1] "/"] 
        }]]
        set pg_singlePinname [lsort -unique [lmap temp_pg_pin $pg_pins {
          set temp_pg_singlePinname [lindex [split $temp_pg_pin "/"] end] 
        }]]
        set signal_size [if {[dict exists $type signal]} {set temp [llength [dict get $type signal]]} else {set temp 0} ]
        set pg_size [if {[dict exists $type pg]} {set temp [llength [dict get $type pg]]} else {set temp 0} ]
        puts "# --------------------------------------------------"
        puts "# - $class : signal : $signal_size | pg : $pg_size "
        puts "# -- $class : signal single pin name :\n$signal_singlePinname"
        puts "# -- $class : pg single pin name :\n$pg_singlePinname"
        #puts "# - $class : signal : [if {[dict exists $type signal] && [dict get $type signal] != ""} {set temp [dict size [dict get $type signal]]} else {set temp 0}] | pg : [if {[dict exists $type pg] && [dict get $type pg] != ""} {set temp [dict size [dict get $type pg]]} else {set temp 0}]"
      }
    }
  }
}

define_proc_arguments check_if_empty_of_globalNetConnect \
  -info "check if the globalNetConnect(GNC) of every inst is empty, you can specify insts or check all inst of invs db."\
  -define_args {
    {-insts_toCheck "specify insts that need to check GNC" AList list optional}
    {-outputfilename "specify file name to output" AString string require}
    {-ignorePin_signalOrPg "specify the pins list to ignore, which is not check" AList list optional}
  }
