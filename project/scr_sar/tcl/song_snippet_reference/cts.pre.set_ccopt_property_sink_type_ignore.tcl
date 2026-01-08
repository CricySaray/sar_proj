#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2026/01/08 14:00:53 Thursday
# label     : snippet
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc|snippet)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : Before performing Clock Tree Synthesis (CTS), use the set_ccopt_property command to set the ignore attribute for the CP 
#             pins of all registers whose names contain specific characters. This way, clock balancing will not be performed during CTS.
#           在做cts之前使用set_ccopt_property来给名字中具有特定字符的所有寄存器的CP端设置ignore，在CTS的时候就不会做balance了
# ref       : link url
# --------------------------
foreach keyword [list FT_CRG FT_BUS FT_MISC SUB_CRG CP_CRG edt_i Wrapper_inst] {
  set temp_pins [dbget [dbget top.insts.cell.name *DF* -p2].instTerms.name *$keyword*/CP* -e]
  if {$temp_pins ne ""} {
    puts "debug_song_STA_demand_to_set_ignore_for_CP_pin: have keyword pins : $keyword, len [llength $temp_pins]" 
    foreach temp_pin $temp_pins { set_ccopt_property sink_type ignore -pin $temp_pin }
  }
}
