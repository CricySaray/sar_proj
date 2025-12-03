#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/12/02 15:34:39 Tuesday
# label     : 
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : Obtain the mem buffer inst, then calculate the Manhattan distance between the inputTerm or outputTerm of the inst and 
#             the connected mem pin, and sort them according to the distance to form a table.
# return    : output file
# ref       : link url
# --------------------------
source ../packages/table_format_with_title.package.tcl; # table_format_with_title
proc check_manhattanDistance_ofMemBufferToMem {args} {
  set instExp    {MEM_BUF_} ; # specify the mem buffer key work expression
  set outputFile "./mem_to_buffer_manhattanDistance.rpt"
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  set insts_core_ptr [dbget -regexp [dbget -regexp top.insts.pstatus {placed|fixed} -p].name $instExp -p]
  set inst_toInst_manhattanDistance_LIST [list]
  set mem_celltype [dbget [dbget head.libCells.subClass block -p].name -e]
  if {$mem_celltype eq ""} {
    error "proc check_manhattanDistance_ofMemBufferToMem: check your invs db, there is no mem/block subClass celltype!!!" 
  }
  foreach temp_inst_ptr $insts_core_ptr {
    set celltypeToInputTerm [dbget [dbget [dbget $temp_inst_ptr.instTerms.isInput 1 -p].net.instTerms.isOutput 1 -p].inst.cell.name -e]
    set celltypeToOutputTerm [dbget [dbget [dbget $temp_inst_ptr.instTerms.isOutput 1 -p].net.instTerms.isInput 1 -p].inst.cell.name -e]
    if {$celltypeToInputTerm in $mem_celltype && $celltypeToOutputTerm ni $mem_celltype} {
      set inputTerm [dbget [dbget $temp_inst_ptr.instTerms.isInput 1 -p].name -e]
      set termConnectToInputTerm [lindex [dbget [dbget [dbget $temp_inst_ptr.instTerms.isInput 1 -p].net.instTerms.isOutput 1 -p].name -e] 0]
      set ptOfInputTerm {*}[dbget [dbget top.insts.instTerms.name $inputTerm -p].pt -e]
      set ptOfTermConnectToInput {*}[dbget [dbget top.insts.instTerms.name $termConnectToInputTerm -p].pt -e]
      set manhattanDistance_toInput [expr {abs([lindex $ptOfInputTerm 0] - [lindex $ptOfTermConnectToInput 0]) + abs([lindex $ptOfInputTerm 1] - [lindex $ptOfTermConnectToInput 1])}]
      lappend inst_toInst_manhattanDistance_LIST [list $manhattanDistance_toInput [dbget $temp_inst_ptr.name -e] $termConnectToInputTerm]
    } elseif {$celltypeToInputTerm ni $mem_celltype && $celltypeToOutputTerm in $mem_celltype} {
      set outputTerm [dbget [dbget $temp_inst_ptr.instTerms.isInput 1 -p].name -e]
      set termConnectToOutputTerm [lindex [dbget [dbget [dbget $temp_inst_ptr.instTerms.isOutput 1 -p].net.instTerms.isOutput 1 -p].name -e] 0]
      set ptOfOutputTerm {*}[dbget [dbget top.insts.instTerms.name $outputTerm -p].pt -e]
      set ptOfTermConnectToOutput {*}[dbget [dbget top.insts.instTerms.name $termConnectToOutputTerm -p].pt -e]
      set manhattanDistance_toOutput [expr {abs([lindex $ptOfOutputTerm 0] - [lindex $ptOfTermConnectToOutput 0]) + abs([lindex $ptOfOutputTerm 1] - [lindex $ptOfTermConnectToOutput 1])}]
      lappend inst_toInst_manhattanDistance_LIST [list $manhattanDistance_toOutput [dbget $temp_inst_ptr.name -e] $termConnectToOutputTerm]
    } else {
      error "proc: check_manhattanDistance_ofMemBufferToMem: inst($temp_inst_ptr) is not connected to mem or ip!!! please modify instExp to match correct inst name."
    }
  }
  set inst_toInst_manhattanDistance_LIST [lsort -real -decreasing -index 0 $inst_toInst_manhattanDistance_LIST]
  set inst_toInst_manhattanDistance_LIST [linsert $inst_toInst_manhattanDistance_LIST 0 [list manhattanDistance inst toMem]]
  set fo_temp [open $outputFile w]
  puts $fo_temp [join [table_format_with_title $inst_toInst_manhattanDistance_LIST 0 left "" 0] \n]
  close $fo_temp
}
define_proc_arguments check_manhattanDistance_ofMemBufferToMem \
  -info "check manhattan distance of mem buffer to mem"\
  -define_args {
    {-instExp "specify the expression of inst" AString string optional}
    {-outputFile "specify the output file name" AString string optional}
  }
