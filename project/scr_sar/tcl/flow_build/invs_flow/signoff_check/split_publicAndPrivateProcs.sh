#!/bin/bash
# --------------------------
# author    : sar song
# date      : 2026/01/20 16:35:07 Tuesday
# label     : sh
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc|snippet|signoff_check)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : split public and private procs
# return    : two file of public and private procs
# ref       : link url
# --------------------------
grep -n "^source" ./signoff.* > .private_procs.tcl
sed -i -e 's/.*source/source/' .private_procs.tcl
tclsh ~/project/scr_sar/tcl/misc/cat_all_sourced_file/cat_all.recursive.tcl .private_procs.tcl -output private_procs.tcl -verbose 1
rm -f .private_procs.tcl
cat signoff.*.tcl > .public_procs.tcl
sed -i -e '/^source/d' .public_procs.tcl
tclsh ~/project/scr_sar/tcl/misc/cat_all_sourced_file/cat_all.recursive.tcl .public_procs.tcl -output public_procs.tcl -verbose 1
rm -f .public_procs.tcl
