#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/09/29 15:30:48 Monday
# label     : flow_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|report_proc|cross_lang_proc|misc_proc)
#   perl -> (format_sub|getInfo_sub|perl_task)
# descrip   : Obtain the shape of the physical pin, calculate its center point, and generate the corresponding edtext. The prerequisite is that only the 
#             part of your physical pin that needs to have edtext exported is included. Otherwise, the command will select the part of the physical pin 
#             for which edtext should not be exported.
# return    : edtext file
# ref       : link url
# --------------------------
alias degui "delete_all_gui_object_and_highlight"
proc delete_all_gui_object_and_highlight {} {
  delete_gui_object -all
  dehighlight -all
}
# small proc for converting selected physical pin shape to edtext
proc genFile_edTextForLVS_forSelectedPhysicalPin {args} {
  set outputFileName             "edText.autoGen"
  set testFileNameForVerify      "verifyEdTextCmds.tcl"
  set suffixOfOutputFileName     "eco1_selected"
  set layerNumOnCalibre          "94 60"
  set colorOfMarkerForVerify     "wheat" ; # red blue green yellow magenta cyan pink orange brown purple violet teal olive gold maroon wheat
  set typeOfMarkerForVerify      "STAR" ; # X|TICK|STAR
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  set physicalPinPtr [dbget selected.]
  if {![llength $physicalPinPtr]} {
    error "proc genFile_edTextForLVS_forSelectedPhysicalPin: not selected physical pin!!!" 
  }
  set physicalPinName [dbget $physicalPinPtr.name]
  set physicalPinBox  [dbget $physicalPinPtr.box]
  set pin_centerPt_List [lmap pin $physicalPinName box $physicalPinBox {
    set center_of_box [db_rect -center $box]
    set temp [list $pin $center_of_box]
  }]
  set contentOfEdText [lmap temp_pin_centerpt $pin_centerPt_List {
    lassign $temp_pin_centerpt temp_pin temp_centerpt
    set temp "LAYOUT TEXT \"$temp_pin\" $temp_centerpt $layerNumOnCalibre" 
  }]
  set testToVerifyCmdsList [lmap temp_pin_centerpt $pin_centerPt_List {
    lassign $temp_pin_centerpt temp_pin temp_centerpt
    set temp_cmd "add_gui_marker -color $colorOfMarkerForVerify -type $typeOfMarkerForVerify -name edText_autoGen_forVerify_$temp_pin -pt \{$temp_centerpt\}"
  }]
  set fo [open $outputFileName w]
  puts $fo [join $contentOfEdText \n]
  close $fo
  set fo_verify [open $testFileNameForVerify w] 
  puts $fo_verify [join $testToVerifyCmdsList \n]
  close $fo_verify
  puts "proc genFile_edTextForLVS: INFO: total generate [llength $contentOfEdText] text line."
  puts "proc genFile_edTextForLVS: INFO: edtext file name: $outputFileName"
  puts "proc genFile_edTextForLVS: INFO: test file name to verify: $testFileNameForVerify"
  
}
define_proc_arguments genFile_edTextForLVS_forSelectedPhysicalPin \
  -info "gen file edtext file for lvs for selected physical pin"\
  -define_args {
    {-outputFileName "specify the output file name to generate edText" AString string optional}
    {-testFileNameForVerify "specify the test file name for verifying if it is correct on invs GUI when generating edText" AString string optional}
    {-suffixOfOutputFileName "specify the suffix of output file name" AString string optional}
    {-layerNumOnCalibre "specify the layer num on Calibre, like '94 0'" AString string optional}
    {-colorOfMarkerForVerify "specify the color of marker for verifying if it is correct" oneOfString one_of_string {optional value_type {values {red blue green yellow magenta cyan pink orange brown purple violet teal olive gold maroon wheat}}}}
    {-typeOfMarkerForVerify "specify teh type of marker for verifying if it is correct" oneOfString one_of_string {optional value_type {values {X STAR TICK}}}}
  }
proc genFile_edTextForLVS {args} {
  set outputFileName             "edText.autoGen"
  set testFileNameForVerify      "verifyEdTextCmds.tcl"
  set suffixOfOutputFileName     "eco1"
  set layerNumOnCalibre          "94 60"
  set colorOfMarkerForVerify     "wheat" ; # red blue green yellow magenta cyan pink orange brown purple violet teal olive gold maroon wheat
  set typeOfMarkerForVerify      "STAR" ; # X|TICK|STAR
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  if {$suffixOfOutputFileName != ""} {
    set outputFileName "[file rootname [lindex [file split $outputFileName] end]]_$suffixOfOutputFileName[file extension $outputFileName]"
    set testFileNameForVerify "[file rootname [lindex [file split $testFileNameForVerify] end]]_$suffixOfOutputFileName[file extension $testFileNameForVerify]"
  }
  puts "proc genFile_edTextForLVS: INFO: select all physical pins shape... (Notice: Only keep the physical pins that need edtext exported.)"
  deselectAll
  editSelect -physical_pin_only
  set physicalPinPtr [dbget selected.]
  if {![llength $physicalPinPtr]} {
    error "proc genFile_edTextForLVS_forSelectedPhysicalPin: not selected physical pin!!!" 
  }
  set physicalPinName [dbget $physicalPinPtr.name]
  set physicalPinBox  [dbget $physicalPinPtr.box]
  set pin_centerPt_List [lmap pin $physicalPinName box $physicalPinBox {
    set center_of_box [db_rect -center $box]
    set temp [list $pin $center_of_box]
  }]
  set contentOfEdText [lmap temp_pin_centerpt $pin_centerPt_List {
    lassign $temp_pin_centerpt temp_pin temp_centerpt
    set temp "LAYOUT TEXT \"$temp_pin\" $temp_centerpt $layerNumOnCalibre" 
  }]
  set testToVerifyCmdsList [lmap temp_pin_centerpt $pin_centerPt_List {
    lassign $temp_pin_centerpt temp_pin temp_centerpt
    set temp_cmd "add_gui_marker -color $colorOfMarkerForVerify -type $typeOfMarkerForVerify -name edText_autoGen_forVerify_$temp_pin -pt \{$temp_centerpt\}"
  }]
  set fo [open $outputFileName w]
  puts $fo [join $contentOfEdText \n]
  close $fo
  set fo_verify [open $testFileNameForVerify w] 
  puts $fo_verify [join $testToVerifyCmdsList \n]
  close $fo_verify
  puts "proc genFile_edTextForLVS: INFO: total generate [llength $contentOfEdText] text line."
  puts "proc genFile_edTextForLVS: INFO: edtext file name: $outputFileName"
  puts "proc genFile_edTextForLVS: INFO: test file name to verify: $testFileNameForVerify"
}

define_proc_arguments genFile_edTextForLVS \
  -info "gen file of edText for LVS"\
  -define_args {
    {-outputFileName "specify the output file name to generate edText" AString string optional}
    {-testFileNameForVerify "specify the test file name for verifying if it is correct on invs GUI when generating edText" AString string optional}
    {-suffixOfOutputFileName "specify the suffix of output file name" AString string optional}
    {-layerNumOnCalibre "specify the layer num on Calibre, like '94 0'" AString string optional}
    {-colorOfMarkerForVerify "specify the color of marker for verifying if it is correct" oneOfString one_of_string {optional value_type {values {red blue green yellow magenta cyan pink orange brown purple violet teal olive gold maroon wheat}}}}
    {-typeOfMarkerForVerify "specify teh type of marker for verifying if it is correct" oneOfString one_of_string {optional value_type {values {X STAR TICK}}}}
  }
