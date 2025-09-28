#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/09/28 11:18:19 Sunday
# label     : flow_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|report_proc|cross_lang_proc|misc_proc)
#   perl -> (format_sub|getInfo_sub|perl_task)
# descrip   : Generate the specified report using PT-specific commands, and then execute this proc in PT (where the define_proc_attributes command can only be executed in PT). 
#             Summarize one or several scenarios and create a table, then generate the table into a file for easy reading. It can also be written into the PT flow, generating 
#             a separate table file for each scenario. After all scenarios are executed, use a simple file aggregation to integrate the data from each scenario into a master 
#             table. In this way, data can be saved layer by layer.
# NOTICE    : please generate report file using command: report_constraint -all_violator -path_type end|slack_only -nos -max_delay -min_delay -max_transition -max_capacitance -max_fanout -min_period -min_pulse_width
# return    : csv summary file
# ref       : link url
# --------------------------
source ./common/generate_combinations.common.tcl; # generate_combinations
source ./common/parse_constraint_report.common.tcl; # parse_constraint_report
source ../packages/table_format_with_title.package.tcl; # table_format_with_title
proc runCmd_summarize_pt_rpts {args} {
  set searchDir                   "./"
  set outputFileOfSummary         "$searchDir/<scenario>/sum.csv" ; # if have '<scenario>' in this path, this will write output for every scenario dir
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
  if {$scenarios == "auto"} {
    set optionsOfFormatOfScenarios [list "<mode>" "<type>" "<voltage>" "<rcCorner>" "<temperature>"] ; # you only select options inside these
    set mode $modesOfFormatExp ; set type $typeToCheckOfFormatExp ; set voltage $voltageOfFormatExp ; set rcCorner $rcCornerOfFormatExp ; set temperature $temperatureOfFormatExp
    set allCasesOfScenarios [generate_combinations -connector "_" {*}[lmap temp_var [regsub -all {>|<} $optionsOfFormatOfScenarios ""] { if {![llength [subst \${$temp_var}]]} {error "proc runCmd_summarize_pt_rpts: check your input: the $temp_var is empty!!!"} else {set $temp_var}}]]
  } else {
    set allCasesOfScenarios $scenarios 
  }
  if {![file isdirectory $searchDir]} {
    error "proc runCmd_summarize_pt_rpts: check your input: searchDir($searchDir) does not exist!!!" 
  }
  set allDirNameOnSearchDir [lmap temp_path [glob -nocomplain $searchDir/*] { file tail $temp_path }]
  set scenarioDirs [lmap temp_dirname $allDirNameOnSearchDir { if {$temp_dirname in $allCasesOfScenarios} {set temp_dirname} else {continue} }]
  if {$scenarioDirs == ""} { error "proc runCmd_summarize_pt_rpts: " }
  set allConstraintNameList [list min_delay max_delay max_capacitance max_transition max_fanout min_pulse_width min_period]

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
    set fi_temp [open "$searchDir/$temp_scenario_dir/$globalTimingCsvFileName" r] ; set globalTimingContent [split [read $fi_temp] "\n"]
    set titleList [split [lindex $globalTimingContent 0] ","]
    set valueList [split [lindex $globalTimingContent 1] ","]
    set totalTNS [lindex $valueList [lsearch -exact $titleList "Total_TNS"]]
    set reg2regWNS [lindex $valueList [lsearch -exact $titleList "reg2reg_WNS"]]
    set reg2regTNS [lindex $valueList [lsearch -exact $titleList "reg2reg_TNS"]]
    set reg2regNUM [lindex $valueList [lsearch -exact $titleList "reg2reg_NUM"]]
    if {$typeOfScenario == "setup"} {set wns_type_delay $wns_max_delay ; set num_type_delay $num_max_delay} elseif {$typeOfScenario == "hold"} {set wns_type_delay $wns_max_delay ; set num_type_delay $num_max_delay} else {error "proc runCmd_summarize_pt_rpts: check your formatOfScenarios($formatOfScenarios), not find 'setup' or 'hold' !!!"}
    list $temp_scenario_dir $wns_type_delay $num_type_delay $totalTNS $reg2regWNS $reg2regNUM $reg2regTNS $wns_max_transition $num_max_transition $wns_max_fanout $num_max_fanout $wns_max_capacitance $num_max_capacitance $wns_min_period $num_min_period $wns_min_pulse_width $num_min_pulse_width
  }]
  set infoOfAllScenarios [linsert $infoOfAllScenarios 0 [list scenario wns num tns r2r_w r2r_n r2r_t transW transN maxfanW maxfanN maxCapW maxCapN minPeriodW minPeriodN minPulseW minPulseN]]
  set tableToDisplay [join [table_format_with_title $infoOfAllScenarios 0 center "" 0] \n]
  if {[regexp {<scenario>} $outputFileOfSummary]} { 
    set allOutputFileOfSummary [lmap temp_scenario $allCasesOfScenarios { 
      set temp_output_file_of_summary [string map [list <scenario> $temp_scenario] $outputFileOfSummary]
      if {![file isdirectory [file dirname $temp_output_file_of_summary]]} {
        error "proc runCmd_summarize_pt_rpts: check your input : dir name of outputFileOfSummary($outputFileOfSummary) is not found!!!" 
      } else {
        set temp_output_file_of_summary 
      }
    }]
  } else {
    if {![file isdirectory [file dirname $outputFileOfSummary]]} {
      error "proc runCmd_summarize_pt_rpts: check your input : dir name of outputFileOfSummary($outputFileOfSummary) is not found!!!" 
    }
    set allOutputFileOfSummary $outputFileOfSummary
  }
  foreach temp_file_to_output $allOutputFileOfSummary {
    set fo [open "$temp_file_to_output" w]
    puts $fo $tableToDisplay
    close $fo
  }
}

define_proc_attributes runCmd_summarize_pt_rpts \
  -info "run cmd of summarizing pt rpts"\
  -define_args {
    {-searchDir "specify the dir to search" AString string optional}
    {-outputFileOfSummary "specify the output file of summary" AString string optional}
    {-scenarios "you can specify some scenarios name list or 'auto' that is can match all possible scenarios" AList list optional}
    {-formatOfScenarios "specify the format of scenarios if \$scenarios == 'auto'" AString string optional}
    {-modesOfFormatExp "specify the modes of Format Exp if \$scenarios == 'auto'" AList list optional}
    {-typeToCheckOfFormatExp "specify the type to check of Format Exp if \$scenarios == 'auto'" AList list optional}
    {-voltageOfFormatExp "specify the voltage of Format Exp if \$scenarios == 'auto'" AList list optional}
    {-rcCornerOfFormatExp "spcify the rc corners of Format Exp if \$scenarios == 'auto'" AList list optional}
    {-temperatureOfFormatExp "specify the temperature of Format Exp if \$scenarios == 'auto'" AList list optional}
    {-designName "specify the design name" AString string optional}
    {-reportConstraintFileName "specify the report_constraint file name" AString string optional}
    {-globalTimingCsvFileName "specify the file name of ouput of report_global_timing -format csv" AString string optional}
  }
