#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2026/03/02 16:46:31 Monday
# label     : clock_tree_relative_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc|snippet|signoff_check|drc_proc|clock_tree_relative_proc)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : Given a list of pins or instances, it uses `all_fanin` or `all_fanout` to obtain all startpoints or endpoints. It automatically 
#             filters out endpoints where the input pins or instances lie on the common clock path, retaining only those endpoints belonging to 
#             the capture or launch tree. The specific paths are then output sorted by slack value.
# return    : output file and summary table
# ref       : link url
# --------------------------
source ../../../packages/table_format_with_title.package.tcl; # table_format_with_title
source ../../../packages/pw_puts_message_to_file_and_window.package.tcl; # pw
proc getInfoOfValidEndpointsOrStartpointsPathUsingAllfanoutOrAllfanin {args} {
  set inputPinsOrInsts             [list]
  set orderTypeForSlackOfEndpoint  increasing ; # increasing|decreasing
  set delayType                    max ; # max|min
  set typeOfEndpointsOrStartpoints "endpoints" ; # endpoints|startpoints
  set ifDumpPathsOfEndpoints       1
  set ifShowRemovedEndpoints       1
  set pba_mode                     ex
  set outputFileBodyName           "validEndpointsOrStartpointsPathsUsingAllFanoutOrAllFanin"
  set output_dir                   "./"
  set suffixOfOutputFile           "test1"
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  suppress_message SEL-003
  suppress_message UITE-479
  suppress_message UITE-416
  if {$inputPinsOrInsts eq ""} {
    error "proc getInfoOfValidEndpointsOrStartpointsPathUsingAllfanoutOrAllfanin: error input: empty!!!" 
  }
  set needProcessType_inputItem [list]
  foreach temp_pinOrinst $inputPinsOrInsts {
    if {[get_pins -q $temp_pinOrinst] ne ""} {
      lappend needProcessType_inputItem [list pin $temp_pinOrinst]
    } elseif {[get_cells -q $temp_pinOrinst] ne ""} {
      lappend needProcessType_inputItem [list inst $temp_pinOrinst] 
    } else {
      error "proc getInfoOfValidEndpointsOrStartpointsPathUsingAllfanoutOrAllfanin: error input, is not pin or inst name: $temp_pinOrinst" 
    }
  }
  set numOfNeedProcessItem [llength $needProcessType_inputItem]
  puts "total $numOfNeedProcessItem need process ..."
  set finalResultList [list]
  foreach temp_type_item $needProcessType_inputItem {
    lassign $temp_type_item temp_type temp_item 
    puts " ------ "
    puts "start to analyzing $temp_type: $temp_item"
    if {$temp_type eq "inst"} {
      puts "below is all pins of this inst:"
      puts [join [get_object_name [get_pins -of [get_cells $temp_item]]] \n]
      if {$typeOfEndpointsOrStartpoints eq "endpoints"} {
        set temp_all_endpoints [list] ; set temp_length_of_endpoints 0
        set temp_all_endpoints [get_object_name [all_fanout -only_cells -endpoints_only -flat -from [get_pins -of [get_cells $temp_item]]]]
        set temp_length_of_endpoints [llength $temp_all_endpoints]
      } elseif {$typeOfEndpointsOrStartpoints eq "startpoints"} {
        set temp_all_startpoints [list] ; set temp_length_of_startpoints 0
        set temp_all_startpoints [get_object_name [all_fanin -only_cells -startpoints_only -flat -to [get_pins -of [get_cells $temp_item]]]]
        set temp_length_of_startpoints [llength $temp_all_startpoints]
      }
    } elseif {$temp_type eq "pin"} {
      if {$typeOfEndpointsOrStartpoints eq "endpoints"} {
        set temp_all_endpoints [list] ; set temp_length_of_endpoints 0
        set temp_all_endpoints [get_object_name [all_fanout -only_cells -endpoints_only -flat -from [get_pins $temp_item]]]
        set temp_length_of_endpoints [llength $temp_all_endpoints]
      } elseif {$typeOfEndpointsOrStartpoints eq "startpoints"} {
        set temp_all_startpoints [list] ; set temp_length_of_startpoints 0
        set temp_all_startpoints [get_object_name [all_fanin -only_cells -startpoints_only -flat -to [get_pins $temp_item]]]
        set temp_length_of_startpoints [llength $temp_all_startpoints]
      }
    } else {
      error "proc getInfoOfValidEndpointsOrStartpointsPathUsingAllfanoutOrAllfanin: error processing: invalid temp_type: $temp_type" 
    }
    puts " --- "
    puts "total find $temp_length_of_endpoints endpoints to filter and dump out to file."
    set existsEitherLaunchOrCaptureTree [list]
    set i 0
    set numOfSaveEndpoints 0
    set numOfRemoveEndpoints 0
    set removedEndpoints [list]
    foreach temp_endpoint $temp_all_endpoints {
      incr i
      puts -nonewline "$i "
      flush stdout
      set temp_worst_path_to_endpoint [get_timing_paths -slack_lesser_than 9999 -delay_type $delayType -pba_mode $pba_mode -path_type full_clock_expanded -to $temp_endpoint]
      set temp_worst_slack [get_attribute $temp_worst_path_to_endpoint slack]
      set temp_crpr_common_point [get_object_name [get_attribute $temp_worst_path_to_endpoint crpr_common_point]]
      set temp_launch_tree_points [get_object_name [get_attribute [get_attribute [get_attribute $temp_worst_path_to_endpoint launch_clock_paths] points] object]]
      set temp_capture_tree_points [get_object_name [get_attribute [get_attribute [get_attribute $temp_worst_path_to_endpoint capture_clock_paths] points] object]]
      # set temp_launch_tree_points_remove_common_path [lrange $temp_launch_tree_points [expr {[lsearch -exact $temp_launch_tree_points $temp_crpr_common_point] + 1}] end]
      # set temp_capture_tree_points_remove_common_path [lrange $temp_capture_tree_points [expr {[lsearch -exact $temp_capture_tree_points $temp_crpr_common_point] + 1}] end]
      if {[lsearch -inline -regexp $temp_launch_tree_points $temp_item] ne "" && [lsearch -inline -regexp $temp_capture_tree_points $temp_item] eq ""} {
        incr numOfSaveEndpoints
        lappend existsEitherLaunchOrCaptureTree [list atLaunch $temp_worst_slack $temp_endpoint]
      } elseif {[lsearch -inline -regexp $temp_launch_tree_points $temp_item] eq "" && [lsearch -inline -regexp $temp_capture_tree_points $temp_item] ne ""} {
        incr numOfSaveEndpoints
        lappend existsEitherLaunchOrCaptureTree [list atCapture $temp_worst_slack $temp_endpoint]
      } else { 
        incr numOfRemoveEndpoints 
        if {[lsearch -inline -regexp $temp_launch_tree_points $temp_item] eq "" && [lsearch -inline -regexp $temp_capture_tree_points $temp_item] eq ""} {
          set removedReason "existsBothCaptureAndLaunch"
        } elseif {[lsearch -inline -regexp $temp_launch_tree_points $temp_item] ne "" && [lsearch -inline -regexp $temp_capture_tree_points $temp_item] ne ""} {
          set removedReason "notExistsBothCaptureAndLaunch"
        } else {
          set removedReason "NA" 
        }
        lappend removedEndpoints [list $removedReason $temp_worst_slack $temp_endpoint]
      }
    }
    if {$orderTypeForSlackOfEndpoint eq "increasing"} {
      set existsEitherLaunchOrCaptureTree [lsort -index 1 -real -increasing $existsEitherLaunchOrCaptureTree]
      set removedEndpoints [lsort -index 1 -real -increasing $removedEndpoints]
    } elseif {$orderTypeForSlackOfEndpoint eq "decreasing"} {
      set existsEitherLaunchOrCaptureTree [lsort -index 1 -real -decreasing $existsEitherLaunchOrCaptureTree]
      set removedEndpoints [lsort -index 1 -real -decreasing $removedEndpoints]
    }
    lappend finalResultList [list $temp_type $temp_item $existsEitherLaunchOrCaptureTree $removedEndpoints]
    set existsEitherLaunchOrCaptureTree [list]
    puts ""
    puts "have $numOfSaveEndpoints saved endpoints."
    puts "have $numOfRemoveEndpoints removed endpoints."
    set numOfSaveEndpoints 0 ; set numOfRemoveEndpoints 0 ; set removedEndpoints [list]
  }
  puts ""
  set outputfilename "$output_dir/$outputFileBodyName.$suffixOfOutputFile.rpt"
  set outputfilename_dumpPaths "$output_dir/$outputFileBodyName.$suffixOfOutputFile.paths.rpt"
  if {[file exists $outputfilename_dumpPaths]} {
    file delete $outputfilename_dumpPaths 
    exec touch $outputfilename_dumpPaths
  }
  set fo [open $outputfilename w]
  pw $fo " ------ ------ ------"
  pw $fo "Begin Dump Summary and Paths to output files."
  foreach temp_result $finalResultList {
    lassign $temp_result temp_type temp_item temp_result_body temp_removed_endpoints
    pw $fo " ------ "
    pw $fo "for $temp_type: $temp_item"
    pw $fo "have [llength $temp_result_body] valid $typeOfEndpointsOrStartpoints in order by slack ${orderTypeForSlackOfEndpoint}ly:"
    pw $fo [join [table_format_with_title $temp_result_body 0 left "" 0] \n]
    pw $fo ""
    if {$ifShowRemovedEndpoints} {
      pw $fo "removed endpoints in order by slack ${orderTypeForSlackOfEndpoint}ly:" 
      pw $fo [join [table_format_with_title $temp_removed_endpoints 0 left "" 0] \n]
      pw $fo ""
    }
    if {$ifDumpPathsOfEndpoints} {
      puts "user turn on the switch of dumpPathsOfEndpoints: dumping ..."
      puts "SONG_BLOCK: all valid endpoints paths in order by slack(worstest: first) for $temp_type : $temp_item"
      exec echo "SONG_BLOCK: all valid endpoints paths in order by slack(worstest: first) for $temp_type : $temp_item" >> $outputfilename_dumpPaths
      set j 0
      if {$orderTypeForSlackOfEndpoint eq "decreasing"} { set temp_result_body [lreverse $temp_result_body] }
      foreach temp_type_slack_endpoint $temp_result_body {
        incr j
        puts -nonewline "$j "
        flush stdout
        redirect -append $outputfilename_dumpPaths {report_timing -significant_digits 4 -delay_type $delayType -pba_mode $pba_mode -to [get_pins -of [get_cells [lindex $temp_type_slack_endpoint end]] -filter "direction==in"] -nos -input_pins -trans -derate -cap -sort_by slack -crosstalk_delta -slack_lesser_than 9999 -nets -max_paths 1 -nworst 1}
      }
      puts ""
    }
  }
  close $fo
}

define_proc_attributes getInfoOfValidEndpointsOrStartpointsPathUsingAllfanoutOrAllfanin \
  -info "get info of valid endpoints or startpoints path using all_fanout or all_fanin cmd"\
  -define_args {
    {-inputPinsOrInsts "specify input pins or insts " AString string optional}
    {-orderTypeForSlackOfEndpoint "specify the order type of slack of endpoints" oneOfString one_of_string {optional value_help {values {increasing decreasing}}}}
    {-delayType "specify the delay type to specify check setup or hold" oneOfString one_of_string {optional value_help {values {min max}}}}
    {-typeOfEndpointsOrStartpoints "specify the type of endpoints or startpoints" oneOfString one_of_string {optional value_help {values {endpoints startpoints}}}}
    {-ifDumpPathsOfEndpoints "if dump paths of endpoints" oneOfString one_of_string {optional value_help {values {0 1}}}}
    {-ifShowRemovedEndpoints "if show removed endpoints" oneOfString one_of_string {optional value_help {values {0 1}}}}
    {-pba_mode "specify the pba mode" oneOfString one_of_string {optional value_help {values {ex none path}}}}
    {-outputFileBodyName "specify the output file body name" AString string optional}
    {-output_dir "specify the output dir" AString string optional}
    {-suffixOfOutputFile "specify the suffix of output file" AString string optional}
  }
