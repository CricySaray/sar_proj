#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2024/11/14
# label     : misc_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc)
#   -> atomic_proc : Specially used for calling and information transmission of other procs, 
#                    providing a variety of error prompt codes for easy debugging
#   -> display_proc : Specifically used for convenient access to information in the innovus command line, 
#                    focusing on data display and aesthetics
#   -> gui_proc   : for gui display, or effort can be viewed in invs GUI
#   -> task_proc  : composed of multiple atomic_proc , focus on logical integrity, 
#                   process control, error recovery, and the output of files and reports when solving problems.
#   -> dump_proc  : dump data with specific format from db(invs/pt/starrc/pv...)
# descrip   : convert links to localfiles
# ref       : https://www.notion.so/link2local-tcl-367de07abe8b4936abeb1121a0efb605?source=copy_link
# --------------------------

set have [catch {glob INPUT}]
if {$have == 0} {
	cd ./INPUT
	set links [exec find ./ -maxdepth 1 -type l]
	foreach link $links {
		if {$link != ""} {
			set local [exec readlink $link]
			set ifexist [catch {glob $local}]
			if {$ifexist == 0} {
				puts $link
				set localAbs [file normalize $local]
				set rmif [catch {exec rm $link} rmError]
				if {$rmif == 0} {puts "exec rm $link  : ok!"} else {puts "exec rm $link  : Error! \n Detail: $rmError"}
				set cpif [catch {exec cp -p $localAbs ./} cpError]
				if {$cpif == 0} {puts "cp -p $localAbs ./ : ok!"} else {puts "cp -p $localAbs ./ : Error! \n Detail: $cpError"}
			}
		}
	}
	cd ..
} else {
	puts "Error: no INPUT dir!"
}
