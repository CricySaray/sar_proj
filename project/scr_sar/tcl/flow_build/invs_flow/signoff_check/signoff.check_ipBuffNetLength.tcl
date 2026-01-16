#!/bin/tclsh
# --------------------------
# author    : clourney semi
# date      : 2026/01/16 16:50:33 Friday
# label     : signoff_check
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc|snippet|signoff_check)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : check ip buffer net length
# return    : output file and format list
# ref       : link url
# --------------------------
source ../../../eco_fix/timing_fix/trans_fix/proc_get_net_lenth.invs.tcl; # get_net_length
source ../../../packages/table_format_with_title.package.tcl; # table_format_with_title
proc check_ipBuffNetLength {args} {
  set memCelltypeExp_toIgnore {^ram_} ; # (using lsearch) if it is empty, it will get all celltype which of subClass is block
  set ipExpOrNameListToMatch {} ; # if it is empty, it will using \$memCelltypeExp_toIgnore
  set lengthThreshold 50
  set rptName "signoff_check_ipBuffNetLength.rpt"
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  set celltypesOfBlockSubClass [dbget [dbget top.insts.cell.subClass block -p].name]
  if {$celltypesOfBlockSubClass eq ""} {
    return [list ipBuffNetLength 0] 
  } else {
    if {$ipExpOrNameListToMatch ne ""} {
      set ipCelltypes [dbget -regexp top.insts.cell.name [join $ipExpOrNameListToMatch "|"]]
    } elseif {$memCelltypeExp_toIgnore eq ""} {
      set ipCelltypes $celltypesOfBlockSubClass 
    } else {
      set ipCelltypes [lsearch -not -regexp -inline -all $celltypesOfBlockSubClass $memCelltypeExp_toIgnore] 
    }
    set ipInsts [dbget [dbget -regexp top.insts.cell.name [join $ipCelltypes "|"] -p2].name]
    set finalList [list]
    foreach temp_ipinst $ipInsts {
      set temp_terms [dbget [dbget top.insts.name $temp_ipinst -p].instTerms.name -e] 
      foreach temp_term $temp_terms {
        set temp_net [dbget [dbget top.insts.instTerms.name $temp_term -p].net.name -e] 
        if {$temp_net ne ""} {
          set temp_length [get_net_length $temp_net] 
          if {$temp_length > $lengthThreshold} {
            lappend finalList [list $temp_length $temp_net $temp_term] 
          }
        }
      }
    }
    set finalList [lsort -decreasing -real -index 0 $finalList]
    set finalList [linsert $finalList 0 [list netLength netName termName]]
    set totalNum [expr [llength $finalList] - 1]
    set fo [open $rptName w]
    puts $fo [join [table_format_with_title $finalList 0 left "" 0] \n]
    puts $fo ""
    puts $fo "TOTALNUM: $totalNum"
    puts $fo "ipBuffNetLength $totalNum"
    close $fo
    return [list ipBuffNetLength $totalNum]
  }
  
}

define_proc_arguments check_ipBuffNetLength \
  -info "check ip buffer net length"\
  -define_args {
    {-memCelltypeExp_toIgnore "specify the mem celltype expression to ignore" AString string optional}
    {-ipExpOrNameListToMatch "specify the list of expressing or name of ip to matching" AList list optional}
    {-lengthThreshold "specify the net length threshold" AFloat float optional}
    {-inst "specify inst to eco when type is add/delete" AString string optional}
  }
