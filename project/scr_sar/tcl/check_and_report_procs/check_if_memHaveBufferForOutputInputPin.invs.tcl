#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/12/05 14:22:12 Friday
# label     : check_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : By default, it will search for all instances of block subclasses. If you only want to check a few of them, you can choose 
#             to match the names of the instances or the names of the celltypes. If it is empty, no filtering will be performed.
# return    : file
# ref       : link url
# --------------------------
source ../packages/table_format_with_title.package.tcl; # table_format_with_title
proc check_if_memHaveBufferForOutputInputPin {args} {
  # if \$memBufferExp_toMatch is empty, it will
  set memBufferExp_toMatch {\yMEM_BUF_} ; # \y : word boundary
  set bufferCelltypeExp {^BUFF.*}
  set memCelltypeExp_toMatch {^ram_} ; # match mem cell
  set memInstExp_toMatch {} ; # If it is empty, no filtering will be performed.
  set directionToCheck "input" ; # input|output|all
  set typeToCheck "clk" ; # clk|data|all
  set outputFilename "./sor_check_memHaveBufferForOutputInputPin.rpt"
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  if {$outputFilename eq ""} {
    error "proc check_if_memHaveBufferForOutputInputPin: check your input: outputFilename is empty!!!" 
  }
  if {$directionToCheck ni "input output all" || $typeToCheck ni "clk data all"} {
    error "proc check_if_memHaveBufferForOutputInputPin: check your input: \$directionToCheck or \$typeToCheck is not valid!!!" 
  }
  set all_meminsts [dbget [dbget top.insts.cells.subClass block -p2].name -e]
  if {$all_meminsts eq ""} {
    error "proc check_if_memHaveBufferForOutputInputPin: check your invs db: have no mems inst!!!" 
  }
  set all_mem_inst_celltype_List [lmap temp_meminst $all_meminsts {
    set temp_celltype [dbget [dbget top.insts.name $temp_meminst -p].cell.name -e] 
    list $temp_meminst $temp_celltype
  }]
  set final_mem_inst_celltype_List [list]
  set notCheckMemInstCelltypeList [list]
  foreach temp_mem_inst_celltype $all_mem_inst_celltype_List {
    lassign $temp_mem_inst_celltype temp_inst temp_celltype
    if {$memCelltypeExp_toMatch ne "" && [regexp $memCelltypeExp_toMatch $temp_celltype]} {
      lappend final_mem_inst_celltype_List $temp_mem_inst_celltype
    } elseif {$memCelltypeExp_toMatch eq ""} {
      lappend final_mem_inst_celltype_List $temp_mem_inst_celltype
    } elseif {$memInstExp_toMatch ne "" && [regexp $memInstExp_toMatch $temp_inst]} {
      lappend final_mem_inst_celltype_List $temp_mem_inst_celltype
    } elseif {$memInstExp_toMatch eq ""} {
      lappend final_mem_inst_celltype_List $temp_mem_inst_celltype
    } else {
      lappend notCheckMemInstCelltypeList $temp_mem_inst_celltype
    }
  }
  set memPinNotConnectToBuffer [list [list type pinName]]
  set memPinHasConnectedToBuffer [list [list type pinName connectedBufferName]]
  foreach temp_final_mem_inst_celltype $final_mem_inst_celltype_List {
    lassign $temp_mem_inst_celltype temp_inst temp_celltype
    set input_pins [dbget [dbget [dbget top.insts.name $temp_inst -p].instTerms.isInput 1 -p].name -e]
    set output_pins [dbget [dbget [dbget top.insts.name $temp_inst -p].instTerms.isOutput 1 -p].name -e]
    if {$directionToCheck eq "input" || $directionToCheck eq "all"} {
      foreach temp_input_pin $input_pins {
        set connectedInstName_forInputPin [dbget [dbget [dbget top.insts.instTerms.name $temp_input_pin -p].net.instTerms.isOutput 1 -p].inst.name -e]
        set connectedCelltype_forInputPin [dbget [dbget top.insts.name $connectedInstName_forInputPin -p].cell.name -e]
        if {[regexp $bufferCelltypeExp $connectedCelltype_forInputPin] && (($memBufferExp_toMatch ne "" && [regexp $memBufferExp_toMatch $connectedInstName_forInputPin) || $memBufferExp_toMatch eq "")]} {
          lappend memPinHasConnectedToBuffer [list "input" $temp_input_pin $connectedCelltype_forInputPin] 
        } else {
          lappend memPinNotConnectToBuffer [list "input" $temp_input_pin]
        }
      }
    }
    if {$directionToCheck eq "output" || $directionToCheck eq "all"} {
      foreach temp_output_pin $output_pins {
        set connectedInstName_forOutputPin [dbget [dbget [dbget top.insts.instTerms.name $temp_output_pin -p].net.instTerms.isInput 1 -p].inst.name -e]
        set connectedCelltype_forOutputPin [dbget [dbget top.insts.name $connectedInstName_forOutputPin -p].cell.name -e]
        if {[regexp $bufferCelltypeExp $connectedCelltype_forOutputPin] && (($memBufferExp_toMatch ne "" && [regexp $memBufferExp_toMatch $connectedInstName_forOutputPin) || $memBufferExp_toMatch eq "")]} {
          lappend memPinHasConnectedToBuffer [list "output" $temp_output_pin $connectedCelltype_forOutputPin] 
        } else {
          lappend memPinNotConnectToBuffer [list "output" $temp_output_pin]
        }
      }
    }
  }
  
}

define_proc_arguments check_if_memHaveBufferForOutputInputPin \
  -info "check if mems have buffers for output pin or input pin"\
  -define_args {
    {-type "specify the type of eco" oneOfString one_of_string {required value_type {values {change add delRepeater delNet move}}}}
    {-inst "specify inst to eco when type is add/delete" AString string require}
    {-distance "specify the distance of movement of inst when type is 'move'" AFloat float optional}
  }
