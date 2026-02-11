#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2026/02/11 16:02:18 Wednesday
# label     : package_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc|snippet|signoff_check|drc_proc)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : Get the chain of instance names from one inst or pin to another inst or pin, including the instance names of from and to, 
#             sorted in the order of signal propagation.
# NOTICE    : If there are multiple branched paths between two cells that eventually converge to the **to pin**, all instances in the 
#             middle branches will be captured.
# return    : list of insts chain
# ref       : link url
# --------------------------
alias gc "getchain_ofInsts"
proc getchain_ofInsts {from to} {
  if {[dbget top.insts.name $from -e] ne ""} {
    set from_pins [get_pins -of $from]
    if {[dbget top.insts.name $to -e] ne ""} {
      set to_pins [get_pins -of $to]
    } elseif {[dbget top.insts.instTerms.name $to -e] ne ""} {
      if {[dbget [dbget top.insts.instTerms.name $to -p].isInput]} {
        set to_pins $to 
      } else {
        error "proc getchain_ofInsts: AT1 check your input: \$to is not inputPin: ($to)" 
      }
    } else {
      error "proc getchain_ofInsts: AT1 check your input: \$to is not valid pin or inst name: ($to)" 
    }
  } elseif {[dbget top.insts.instTerms.name $from -e] ne ""} {
    set from_pins $from ; # \$from can be input pin or output pin
    if {[dbget top.insts.name $to -e] ne ""} {
      set to_pins [get_pins -of $to]
    } elseif {[dbget top.insts.instTerms.name $to -e] ne ""} {
      if {[dbget [dbget top.insts.instTerms.name $to -p].isInput]} {
        set to_pins $to 
      } else {
        error "proc getchain_ofInsts: AT2 check your input: \$to is not inputPin: ($to)" 
      }
    } else {
      error "proc getchain_ofInsts: AT2 check your input: \$to is not valid pin or inst name: ($to)" 
    }
  } else {
    error "proc getchain_ofInsts: check your input: \$from is not valid pin or inst name: ($from)" 
  }

  set chain_col [all_fanin -from $from_pins -to $to_pins -only_cells]
  if {![sizeof_collection $chain_col]} { 
    puts "proc getchain_ofInsts: not found the insts chain from $from to $to"
    return [list]
  } else {
    return [lreverse [get_object_name $chain_col]] 
  }
}

