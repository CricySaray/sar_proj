#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/09/28 11:18:19 Sunday
# label     : flow_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|report_proc|cross_lang_proc|misc_proc)
#   perl -> (format_sub|getInfo_sub|perl_task)
# descrip   : 
# NOTICE    : please generate report file using command: report_constraint -all_violator -path_type end|slack_only -nos -max_delay -min_delay -max_transition -max_capacitance -max_fanout -min_period -min_pulse_width
# return    : 
# ref       : link url
# --------------------------
source ./common/generate_combinations.common.tcl; # generate_combinations
source ./common/parse_constraint_report.common.tcl; # parse_constraint_report
proc runCmd_summarize_pt_rpts {args} {
  set searchDir                   "./"
  set scenarios                   "auto" ; # auto (will search ) or [list ...]
  set formatOfScenarios           "<mode>_<type>_<voltage>_<rcCorner>_<temperature>" ; # func_setup_0p99v_rcworst_m40c
  set modesOfFormatExp            {func scan}
  set typeToCheckOfFormatExp      {setup hold}
  set voltageOfFormatExp          {0p99v 1p1v 1p21v}
  set rcCornerOfFormatExp         {cworst cbest rcworst rcbest typical}
  set temperatureOfFormatExp      {25c m40c 125c}
  set designName                  "SC5019_TOP" ; # only consisted of reportConstraintFileName
  set reportConstraintFileName    "report_constraint_$designName.rpt"
  set globalTimingCsvFileName     "${designName}.global_timing.csv" ; # please using command: report_global_timing -format csv -ouput .../$designName.global_timing.csv
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  set optionsOfFormatOfScenarios [list "<mode>" "<type>" "<voltage>" "<rcCorner>" "<temperature>"] ; # you only select options inside these
  set mode $modesOfFormatExp ; set type $typeToCheckOfFormatExp ; set voltage $voltageOfFormatExp ; set rcCorner $rcCornerOfFormatExp ; set temperature $temperatureOfFormatExp
  set allCasesOfScenarios [generate_combinations -connector "_" {*}[lmap temp_var [regsub {>|<} $optionsOfFormatOfScenarios ""] { if {![llength [subst \${$temp_var}]]} {error "proc runCmd_summarize_pt_rpts: check your input: the $temp_var is empty!!!"} else {set $temp_var}}]]
  if {![file isdirectory $searchDir]} {
    error "proc runCmd_summarize_pt_rpts: check your input: searchDir($searchDir) does not exist!!!" 
  }
  set allDirNameOnSearchDir [lmap temp_path [glob -nocomplaion $searchDir/*] { file tail $temp_path }]
  set scenarioDirs [lmap temp_dirname $allDirNameOnSearchDir { if {$temp_dirname in $allCasesOfScenarios} {set temp_dirname} else {continue} }]
  set allConstraintNameList [list min_delay max_daley max_capacitance max_transition max_fanout min_pulse_width min_period]

  set infoOfAllScenarios [lmap temp_scenario_dir $scenarioDirs {
    set splitedOptionOfScenario [regsub {>|<} [regexp -all {<.*>} $formatOfScenarios] ""]
    if {[lsearch -exact $splitedOptionOfScenario "setup"]} { set typeOfScenario setup } elseif {[lsearch -exact $splitedOptionOfScenario "hold"]} { set typeOfScenario hold }
    set constraintNameWnsNumLists [parse_constraint_report "$searchDir/$temp_scenario_dir/$reportConstraintFileName" 0] ; # have item include "NA" like {max_delay NA NA}, you can add other actions for it NOTICE
    foreach temp_constaint_wns_num $constraintNameWnsNumLists {
      lassign $temp_constaint_wns_num temp_const temp_wns temp_num
      if {$temp_const in $allConstraintNameList} {
        set wns_$temp_const $temp_wns
        set num_$temp_const $temp_num
      }
    }
    set fi_temp [open "$searchDir/$temp_scenario_dir/$globalTimingFileName" r] ; set globalTimingContent [split [read $fi] "\n"]
    set titleList [split [lindex $globalTimingContent 0] ","]
    set valueList [split [lindex $globalTimingContent 1] ","]
    set totalTNS [lindex $valueList [lsearch -exact $titleList "Total_TNS"]]
    set reg2regTNS [lindex $valueList [lsearch -exact $titleList "reg2reg_TNS"]]
    set reg2regNUM [lindex $valueList [lsearch -exact $titleList "reg2reg_NUM"]]
    if {$typeOfScenario == "setup"} {set wns_type_delay $wns_max_delay ; set num_type_delay $num_max_delay} elseif {$typeOfScenario == "hold"} {set wns_type_delay $wns_max_delay ; set num_type_delay $num_max_delay} else {error "proc runCmd_summarize_pt_rpts: check your formatOfScenarios($formatOfScenarios), not find 'setup' or 'hold' !!!"}
    list $wns_type_delay
  }]
}

define_proc_arguments runCmd_summarize_pt_rpts \
  -info "run cmd of summarizing pt rpts"\
  -define_args {
    {-type "specify the type of eco" oneOfString one_of_string {required value_type {values {change add delRepeater delNet move}}}}
    {-inst "specify inst to eco when type is add/delete" AString string require}
    {-distance "specify the distance of movement of inst when type is 'move'" AFloat float optional}
  }
