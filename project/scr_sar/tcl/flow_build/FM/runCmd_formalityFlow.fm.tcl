#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/09/29 19:30:23 Monday
# label     : flow_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|report_proc|cross_lang_proc|misc_proc)
#   perl -> (format_sub|getInfo_sub|perl_task)
# descrip   : simple formal flow
# return    : /
# ref       : link url
# --------------------------
proc runCmd_formalityFlow {args} {
  set designName                 ""
  set dbList                     "" ; # can be any rc corner db list
  set referenceNetlist           ""
  set implementNetlist           ""
  set logFileName                ""
  set failingPointReportFileName ""
  set constantSettingCmdsList    [list]
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  if {![every x [list $referenceNetlist $implementNetlist] {file isfile $x}]} {
    error "proc runCmd_formalityFlow: check your input: referenceNetlist($referenceNetlist) or implementNetlist($implementNetlist) is not found!!!" 
  } else {
    if {$dbList == ""} {
      error "proc runCmd_formalityFlow: check your input: dbList($dbList) is empty!!!" 
    } else {
      if {![file isdirectory [file dirname $logFileName]] || ![file isdirectory [file dirname $failingPointReportFileName]]} {
        error "proc runCmd_formalityFlow: check your input: dirname([file dirname $logFileName]) of logFileName($logFileName) or dirname([file dirname $failingPointReportFileName]) of failingPointReportFileName($failingPointReportFileName) is not a directory!!!"
      } else {
        set hdlin_unresolved_modules black_box
        set hdlin_warn_on_mismatch_message
        set hdlin_warn_on_mismatch_message "FMR_ELAB-147 FMR_ELAB-146" 
        set synopsys_auto_setup true
        set verification_clock_gate_edge_analysis true
        set verification_failing_point_limit 1000
        set_host_options -max_cores 8
        set DESIGN $designName

        # --- Library Variable Setting
        set_app_var search_path ". "
        set link_library $dbList
        read_db $link_library
        read_verilog -r $referenceNetlist
        set_top r:/WORK/$DESIGN
        read_verilog -i $implementNetlist
        set_top i:/WORK/$DESIGN
        if {$constantSettingCmdsList != ""} {
          foreach temp_constant $constantSettingCmdsList {
            eval $temp_constant 
          }
        }
        report_black_boxes -all
        match
        verify
        report_failing_point > $failingPointReportFileName
      }
    }
  }
}

define_proc_arguments runCmd_formalityFlow \
  -info "run cmd of Formality flow"\
  -define_args {
    {-designName "specify the design name" AString string optional}
    {-dbList "specify any rc corner db list" AList list optional}
    {-referenceNetlist "specify reference netlist path" AString string optional}
    {-implementNetlist "specify implement netlist path" AString string optional}
    {-logFileName "specify the log file name" AString string optional}
  }
