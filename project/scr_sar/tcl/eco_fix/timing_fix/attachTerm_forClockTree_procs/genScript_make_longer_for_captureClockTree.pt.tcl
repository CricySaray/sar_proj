#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2026/02/21 14:10:36 Saturday
# label     : clock_tree_relative_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc|snippet|signoff_check|drc_proc|clock_tree_relative_proc)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : 
# return    : 
# ref       : link url
# --------------------------

# source ./insertBuffer_forCaptureClockTree.pt.tcl; # insertBuffer_forCaptureClockTree_pt
# source ./insertBuffer_forCaptureClockTree.invs.tcl; # insertBuffer_forCaptureClockTree_invs
source ../../../flow_build/common/convert_file_to_list.common.tcl; # convert_file_to_list
proc genScript_make_longer_for_captureClockTree {args} {
  set violPinsOrInstsOrFilename           [list]
  set celltypeOfClkBuffer                 "DCCKBD4BWP35P140LVT"
  set suffixForNewCellAndNetAndOutputFile "fix_mem2reg_fromeco18"
  set topHierNeedRemoveAtScript           "U_M3KL_MAIN_SUB_WRAP"
  set delayOfCelltypeOfClockBuffer        0.02 ; # ns
  set minMarginSlackOfNextLevel           0.01 ; # when margin > this slack, it will run fixing
  set multiplierOfviolSlackVsMarginSlack  1.5
  set ifTurnOnSafeMode                    1 ; # safe mode: only process register cp pin, not process mem/ip/... cp/clk pin. not at safe mode: will process all cp/clk pin of provided inst/pins
  set pba_mode                            ex
  set insertBufferProcFilename_pt         "./insertBuffer_forCaptureClockTree.pt.tcl"
  set insertBufferProcFilename_invs       "./insertBuffer_forCaptureClockTree.invs.tcl"
  set outputFileBodyname                  "fix_setup_using_make_longer_for_captureClockTree"
  set output_dir                          "./"
  set ifDumpUnfixPath                     1
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  if {[file exists $violPinsOrInstsOrFilename]} {
    set violPinsOrInstsOrFilename [convert_file_to_list $violPinsOrInstsOrFilename 1 1 0 1]
  } 

  set needProcessedInsts [list]
  foreach temp_pin_or_inst $violPinsOrInstsOrFilename {
    if {[get_pins $temp_pin_or_inst -q] ne ""} {
      lappend needProcessedInsts [get_object_name [get_cells -of [get_pins $temp_pin_or_inst]]]
    } elseif {[get_cells $temp_pin_or_inst -q] ne ""} {
      lappend needProcessedInsts [get_object_name [get_cells $temp_pin_or_inst]]
    }
  }
  set needProcessedInsts [lsort -u $needProcessedInsts]
  if {$ifTurnOnSafeMode} {
    set needProcessedInsts [lmap temp_inst $needProcessedInsts {
      if {[get_attribute [get_cells $temp_inst] is_sequential]} {
        set temp_inst
      } else {
        continue
      }
    }]
  }  

  suppress_message UITE-479
  suppress_message UITE-416

  set totalInstNum [llength $needProcessedInsts]
  if {$ifTurnOnSafeMode} { puts "at safe mode: only process register inst/pin" }
  puts "total $totalInstNum inst to processing..."
  puts " ------ "
  set finalCmdsList_invs [list]
  set numOfFixedInst 0
  set numOfUnfixedInst 0
  set numOfMeetInst 0
  set finalCmdsList_pt [list]
  set unfixInst [list]
  set i 0
  foreach temp_inst $needProcessedInsts {
    incr i
    puts -nonewline "$i "
    flush stdout
    set margin_next_level [get_attribute [get_timing_paths -pba_mode $pba_mode -from [get_pins -of [get_cells $temp_inst] -filter "direction==out"]] slack]
    set viol_slack [get_attribute [get_timing_paths -pba_mode $pba_mode -to [get_pins -of [get_cells $temp_inst] -filter "direction==in"]] slack]
    if {$viol_slack >= 0.00000} {
      set ifCanFix " meet"
    } elseif {$viol_slack < 0.00000 && $margin_next_level >= $minMarginSlackOfNextLevel && $margin_next_level > [expr {abs($viol_slack * $multiplierOfviolSlackVsMarginSlack)}]} {
      set ifCanFix "  ok "
    } else {
      set ifCanFix "unfix"
    }
    set clockPinOfInst [get_object_name [get_pins -of [get_cells $temp_inst] -filter "is_clock_pin"]]
    if {[lsearch -exact -index 0 $finalCmdsList_invs $clockPinOfInst] != -1} {
      continue
    } else {
      lappend finalCmdsList_invs "# $ifCanFix , marginSlack:$margin_next_level , violSlack:$viol_slack , clockPin:$clockPinOfInst"
      lappend finalCmdsList_pt   "# $ifCanFix , marginSlack:$margin_next_level , violSlack:$viol_slack , clockPin:$clockPinOfInst"
      if {$viol_slack >= "-$delayOfCelltypeOfClockBuffer"} {
        set num_buffer 1
      } elseif {$viol_slack >= [expr {$delayOfCelltypeOfClockBuffer * -2}]} {
        set num_buffer 2
      } elseif {$viol_slack >= [expr {$delayOfCelltypeOfClockBuffer * -3}]} {
        set num_buffer 3
      } else {
        set num_buffer 4
      }
      if {$ifCanFix   ne "unfix"} {
        if {$ifCanFix eq "  ok "} {
          incr numOfFixedInst
          lappend finalCmdsList_invs [list $clockPinOfInst "insertBuffer_forCaptureClockTree_invs -ifDryRun 0 -suffixForEco $suffixForNewCellAndNetAndOutputFile -celltypeOfBufferToInsert $celltypeOfClkBuffer -numOfInsert $num_buffer -terms $clockPinOfInst"]
          lappend finalCmdsList_pt [list $clockPinOfInst "insertBuffer_forCaptureClockTree_pt -ifDryRun 0 -suffixForEco $suffixForNewCellAndNetAndOutputFile -celltypeOfBufferToInsert $celltypeOfClkBuffer -numOfInsert $num_buffer -terms $clockPinOfInst"]
        } elseif {$ifCanFix eq " meet"} {
          incr numOfMeetInst
          lappend finalCmdsList_invs [list $clockPinOfInst "### MEET ###"]
          lappend finalCmdsList_pt [list $clockPinOfInst "### MEET ###"]
        }
      } else {
        incr numOfUnfixedInst
        lappend unfixInst $temp_inst
        lappend finalCmdsList_invs [list $clockPinOfInst "### UNFIX ###"]
        lappend finalCmdsList_pt [list $clockPinOfInst "### UNFIX ###"]
      }
    }
  }
  set outputfilename_invs "$output_dir/$outputFileBodyname.$suffixForNewCellAndNetAndOutputFile.invs.tcl"
  set outputfilename_pt "$output_dir/$outputFileBodyname.$suffixForNewCellAndNetAndOutputFile.pt.tcl"
  set fo_invs [open $outputfilename_invs w] ; set fo_pt [open $outputfilename_pt w]
  puts $fo_invs "source $insertBufferProcFilename_invs"
  puts $fo_invs "setEcoMode -reset"
  puts $fo_invs "setEcoMode -batchMode true -updateTiming false -refinePlace false -honorDontTouch false -honorDontUse false -honorFixedNetWire false -honorFixedStatus false"

  puts $fo_pt "source $insertBufferProcFilename_pt"
  puts $fo_pt "setEcoMode -reset"
  puts $fo_pt "setEcoMode -batchMode true -updateTiming false -refinePlace false -honorDontTouch false -honorDontUse false -honorFixedNetWire false -honorFixedStatus false"
  foreach temp_invs $finalCmdsList_invs temp_pt $finalCmdsList_pt {
    if {[regexp {^#} $temp_invs]} {
      puts $fo_invs $temp_invs
    } elseif {![regexp {^#} $temp_invs]} {
      puts $fo_invs [regsub [subst {$topHierNeedRemoveAtScript/}] [lindex $temp_invs 1] ""]
    }
    if {[regexp {^#} $temp_pt]} {
      puts $fo_pt $temp_pt
    } elseif {![regexp {^#} $temp_pt]} {
      puts $fo_pt [lindex $temp_pt 1]
    }
  }
  puts $fo_invs "setEcoMode -reset"
  puts $fo_pt "setEcoMode -reset"
  close $fo_invs ; close $fo_pt

  puts ""
  puts " ------ "
  puts "total processed $totalInstNum inst."
  puts "fixed $numOfFixedInst inst."
  puts "have $numOfUnfixedInst inst that is unfixed."
  puts "have $numOfMeetInst inst that is meet originally."
  puts "output file invs: $outputfilename_invs"
  puts "output file pt  : $outputfilename_pt"

  if {$ifDumpUnfixPath} {
    puts " ------ "
    puts "have turn on switch of dumping unfixed path."
    puts "now dumping unfixed path ..."
    set outputfile_unfixpath "$output_dir/$outputFileBodyname.$suffixForNewCellAndNetAndOutputFile.unfix_path.rpt"
    if {[file exists $outputfile_unfixpath]} {
      file delete $outputfile_unfixpath
    }
    set j 0
    foreach temp_unfixinst $unfixInst {
      incr j
      puts -nonewline "$j "
      flush stdout
      redirect -append $outputfile_unfixpath {report_timing -pba_mode $pba_mode -to [get_pins -of [get_cells $temp_unfixinst] -filter "direction==in"] -nos -delay max -input_pins -trans -derate -cap -sort_by slack -crosstalk_delta -slack_lesser_than 9999 -nets -max_paths 1 -nworst 1}
      flush stdout
    }
    puts ""
    puts "have dump all unfixed path to $outputfile_unfixpath"
  }
}
define_proc_attributes genScript_make_longer_for_captureClockTree \
  -info "gen script to make longer for capture clock tree"\
  -define_args {
    {-violPinsOrInstsOrFilename "specify the viol pins or insts or input filename" AString string optional}
    {-celltypeOfClkBuffer "specify the celltype of clock buffer, such as DCCKBD4BWP30P140LVT" AString string optional}
    {-suffixForNewCellAndNetAndOutputFile "specify the suffix name of new cell name, new net name and output file" AString string optional}
    {-topHierNeedRemoveAtScript "specify the top hier name that need remove at script. you can keep empty if no need" AString string optional}
    {-delayOfCelltypeOfClockBuffer "specify the delay value of celltype of clock buffer" AFloat float optional}
    {-minMarginSlackOfNextLevel "specify the min margin slack of next level" AFloat float optional}
    {-multiplierOfviolSlackVsMarginSlack "specify the multiplier of viol slack Vs margin slack" AFloat float optional}
    {-ifTurnOnSafeMode "if turn on safe mode" oneOfString one_of_string {optional value_help {values {0 1}}}}
    {-pba_mode "specify the pba mode" oneOfString one_of_string {optional value_help {values {exhaustive none path}}}}
    {-insertBufferProcFilename_pt "specify the file name of insertBuffer for pt" AString string optional}
    {-insertBufferProcFilename_invs "specify the file name of insertBuffer for invs" AString string optional}
    {-outputFileBodyname "specify the output file body name" AString string optional}
    {-output_dir "specify the output dir" AString string optional}
    {-ifDumpUnfixPath "if dump unfixed path to output file" oneOfString one_of_string {optional value_help {values {0 1}}}}
  }
