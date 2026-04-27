#!/bin/tclsh
# --------------------------
# author    : aiden song
# date      : 2026/02/20 22:08:19 Friday
# label     : clock_tree_relative_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc|snippet|signoff_check|drc_proc|clock_tree_relative_proc)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : This is set to facilitate the insertion of multiple repeaters, and can automatically increment the iterative number in the suffix of the cell name.
# return    : run eco cmd
# ref       : link url
# --------------------------
proc insertBuffer_forCaptureClockTree_invs {args} {
  set suffixForEco                "fix_mem2reg"
  set numOfInsert                 1
  set celltypeOfBufferToInsert    DCCKBD4BWP35P140LVT
  set terms                       {}
  set location                    {}
  set ifDryRun                    1
  set ifResetIterationCounter     0
  set initIndexOfIterationCounter 1 ; # nornally is 0/1, you can set other number as the initial number of iteration counter
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  global song_eco_counter
  if {$ifResetIterationCounter} {
    if {![array exists song_eco_counter]} {
      puts "proc insertBuffer_forCaptureClockTree_invs: not need reset, cuz it have been reset."
    } elseif {![catch {array unset song_eco_counter}]} {
      puts "proc insertBuffer_forCaptureClockTree_invs: reset iteration counter SUCCESS!!!"
      return [list]
    } else {
      error "proc insertBuffer_forCaptureClockTree_invs: error when unset array song_eco_counter!!! check your code"
    }
  }

  if {![array exists song_eco_counter]} {
    set song_eco_counter(eco_num) [expr {$initIndexOfIterationCounter - 1}]
  } else {
    # incr song_eco_counter(eco_num)
  }
  if {$terms eq ""} {
    error "proc insertBuffer_forCaptureClockTree_invs: check your input , terms is empty!!!"
  } else {
    foreach temp_term $terms {
      if {[dbget top.insts.instTerms.name $temp_term -e] eq ""} {
        error "proc insertBuffer_forCaptureClockTree_invs: not found term name ($temp_term)"
      }
    }
    if {[dbget head.libCells.name $celltypeOfBufferToInsert -e] eq ""} {
      error "proc insertBuffer_forCaptureClockTree_invs: check your input : not found celltype of buffer/inverter($celltypeOfBufferToInsert) in invs library."
    }
    set finalCmdsList [list]
    for {set i 1} {$i <= $numOfInsert} {incr i} {
      if {$location eq ""} {
        incr song_eco_counter(eco_num)
        set temp_cmd "ecoAddRepeater -name ${suffixForEco}_${song_eco_counter(eco_num)} -cell $celltypeOfBufferToInsert -term \{$terms\}"
        lappend finalCmdsList $temp_cmd
      } else {
        incr song_eco_counter(eco_num)
        set temp_cmd "ecoAddRepeater -name ${suffixForEco}_${song_eco_counter(eco_num)} -cell $celltypeOfBufferToInsert -term \{$terms\} -loc \{$location\}"
        lappend finalCmdsList $temp_cmd
      }
    }
    if {$ifDryRun} {
      foreach temp_final_cmd $finalCmdsList {
        puts "dry run cmd: $temp_final_cmd"
      }
    } else {
      puts [join $finalCmdsList \n]
      foreach temp_final_cmd $finalCmdsList {
        puts "actually run cmd: $temp_final_cmd"
        eval $temp_final_cmd
      }
    }
  }
}
define_proc_arguments insertBuffer_forCaptureClockTree_invs \
  -info "insert buffer for capture clock tree"\
  -define_args {
    {-ifDryRun "if only print cmd but not run actually" oneOfString one_of_string {optional value_type {values {0 1}}}}
    {-suffixForEco "specify the eco suffix name" AString string optional}
    {-numOfInsert "specify the num of buffer to insert" AInt int optional}
    {-celltypeOfBufferToInsert "celltype of buffer to insert" AString string optional}
    {-terms "specify the term(s) to run ecoAddRepeater" AList list optional}
    {-location "specify the location of new repeater" AList list optional}
    {-ifResetIterationCounter "if reset iteration counter" oneOfString one_of_string {optional value_type {values {0 1}}}}
    {-initIndexOfIterationCounter "specify the initial index of iteration counter" AInt int optional}
  }
