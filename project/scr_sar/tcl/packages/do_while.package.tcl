#!/bin/tclsh
# --------------------------
# author    : from tcl manual example
# date      : 2025/08/03 17:43:24 Sunday
# label     : package_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|misc_proc)
# descrip   : do { scripts } while { condition } like c programming language
# ref       : https://www.tcl-lang.org/man/tcl8.6.13/TclCmd/uplevel.htm
# --------------------------
proc do {body while condition} {
	if {$while ne "while"} {
		error "proc do_while: required word(while) missing"
	}
	set conditionCmd [list expr $condition]
	while {1} {
		uplevel 1 $body
		if {![uplevel 1 $conditionCmd]} {
			break
		}
	}
}
