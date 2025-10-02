#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/10/02 10:42:29 Thursday
# label     : flow_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|report_proc|cross_lang_proc|misc_proc)
#   perl -> (format_sub|getInfo_sub|perl_task)
# descrip   : Execute the PT DMSA command to fix DRV, setup, and hold violations in STA. Various options can be customized.
# return    : /
# ref       : link url
# --------------------------
proc runCmd_ptDMSA {args} {
  set scenariosToRun                   {}
  set resultDir                        "./"
  set icc2ToInvsEcoScriptFile          "/path/to/icc2ToInvs.eco_script.tcl"
  set dontUseCellsList                 {}
  set defFileWhenPhysicalAware         ""
  set techLefFileWhenPhysicalAware     ""
  set lefFilesWhenPhysicalAware        ""
  set fillerCellsListWhenPhysicalAware {}
  set ifAllowInsertBuffer              1
  set ifAllowFillerCellsAsOpenSites    1
  set ecoReportUnfixedReasonMaxEndpoint 10000
  set multiScenarioMergedErrorLimit    10000
  set multiScenarioMergedErrorLogFile  error_multi_scenario.log
  set reportDefaultSignificantDigits   4
  set hostProcessesNum                 [llength $scenariosToRun] ; # The value of this option must be greater than the number of scenarios, and it is recommended that the two quantities be equal.
  set clockInverterList                {}
  set fixHoldBufferList                {}
  set fixSetupBuffList                 {}
  set fixDrvBufferList                 {}
  set fixDrvHoldMargin                 0.001
  set fixDrvSetupMargin                0.010
  set fixTimingHoldMargin              0.003
  set fixTrmingSetupMargin             0.020
  set pbaMode                          path
  set ecoPhysicalMode                  open_site
  set fixTimingSetupToList             {}
  set fixTimingHoldToList              {}

  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }

}

define_proc_arguments runCmd_ptDMSA \
  -info "run cmd for PT DMSA"\
  -define_args {
    {-type "specify the type of eco" oneOfString one_of_string {required value_type {values {change add delRepeater delNet move}}}}
    {-inst "specify inst to eco when type is add/delete" AString string require}
    {-distance "specify the distance of movement of inst when type is 'move'" AFloat float optional}
  }
