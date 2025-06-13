#!/bin/tclsh
#################################
# author :pd_sar
# date   :2024/11/14
# descrip: change link to local file
# ref		 : https://www.notion.so/link2local-tcl-367de07abe8b4936abeb1121a0efb605?source=copy_link
#################################

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

