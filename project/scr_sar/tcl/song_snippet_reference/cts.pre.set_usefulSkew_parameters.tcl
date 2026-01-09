#!/bin/tclsh
# --------------------------
# author    : yuan wenchao
# date      : 2026/01/09 15:13:23 Friday
# label     : snippet
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc|snippet)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : Set a maximum of 200ps for usefulSkew to borrow; it seems the tool's default is 1ns that can be borrowed.
# ref       : link url
# --------------------------

set_ccopt_property max_fanout 16
set_ccopt_property target_skew 0.08
set_ccopt_property update_io_latency true
set_ccopt_property ccopt_auto_limit_insertion_delay_factor 1.2
set_ccopt_mode     -ccopt_auto_limit_insertion_delay_factor 1.2
set_ccopt_property useful_skew_max_delta 0.2
setUesfulSkewMode -maxAllowedDelay 0.2
set_ccopt_property auto_limit_insertion_delay_factor 1.2
