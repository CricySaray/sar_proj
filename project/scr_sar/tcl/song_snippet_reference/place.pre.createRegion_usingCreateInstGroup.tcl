#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2026/01/12 17:39:56 Monday
# label     : snippet
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc|snippet)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : When creating a region for the crg module, it needs to be used in conjunction with "ignore" to prevent balancing during cts.
#             Below is a setting template.
#             在给crg module创建region的时候，需要和ignore搭配使用，防止在cts的时候进行balance，下面是一个设置的模板
#             设置ignore的是寄存器DF的CP端，其他的pin无需设置
# --------------------------
createInstGroup n900_5g_crg -region {100 100 1000 1000}
addInstToInstGroup n900_5g_crg [dbget top.insts.name U_MAIN_SUB/U_MAIN_CRG/u_main_crg/u_main_wpu_root_clk_crg/*_wpu_5g_*]
set n900crgs [dbget top.insts.name U_MAIN_SUB/U_MAIN_CRG/u_main_crg/u_main_wpu_root_clk_crg/*_wpu_5g_*]
foreach temp_crg $n900crgs {
  set temp_pins [dbget [dbget top.insts.cell.name *DF* -p2].instTerms.name $temp_crg*/CP* -e]
  if {$temp_pins ne ""} {
    puts "debug_song_n900_crg: have crg pins : $temp_crg, len [llength $temp_pins]" 
    foreach temp_pin $temp_pins { set_ccopt_property sink_type ignore -pin $temp_pin }
  }
}
