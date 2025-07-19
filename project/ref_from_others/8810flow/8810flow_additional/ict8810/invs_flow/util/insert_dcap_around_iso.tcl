if {"" == [dbGet -e head.allCells.name FILLSGCAP8_A9PP140ZTS_C35]} {
	set insert_decap_around_iso_buffer                   "5:FILLSGCAP8_A7PP140ZTS_C35:1" ; # length:cell:insert_or_not 
} else {
	set insert_decap_around_iso_buffer                   "5:FILLSGCAP8_A9PP140ZTS_C35:1" ; # length:cell:insert_or_not 
}
if {[info exists insert_decap_around_iso_buffer] } {
    set length [lindex [split $insert_decap_around_iso_buffer ":"] 0]
    set cell   [lindex [split $insert_decap_around_iso_buffer ":"] 1]
    set insert [lindex [split $insert_decap_around_iso_buffer ":"] 2]
     
    if {$insert == 1} {
        # expr 0.98 + 1.26 + 1.12
        set top_layer [lindex [get_db [get_db layers -if { .type == routing}] .name] end-1 ]
        foreach bbox [dbShape [dbShape [get_db [get_db port_shapes -if {.name == V* || .layer.name == $top_layer} -invert ] .rect] SIZE $length] and [get_db rows .rect]] {
            set tapcellNum 0
            set tapcellNum [llength  [get_db [get_db [dbQuery -areas $bbox -objType inst ] -if {.base_cell.name == FILLTIE5** }] .name]]
            set xvalue     [expr [lindex $bbox 2] - [lindex $bbox 0]]
            set yvalue     [expr [lindex $bbox 3] - [lindex $bbox 1]]
            #set corebox    [dbShape [dbGet top.fPlan.corebox] SIZEX -1.12]
            set corebox    [dbShape [dbGet top.fPlan.rows.box] SIZE 100 SIZE -100 SIZEX -1.12]
            set fbox [dbShape -output rect $bbox] 
            if {$tapcellNum > 20 && [expr $yvalue - $xvalue] > 10} {set Box [dbShape [dbShape $fbox SIZEX 20 SIZEY 10] AND $corebox]   } else {set Box [dbShape [dbShape $fbox SIZEY 20] AND $corebox] }
            set num  [expr ([lindex [flattenList $Box] 2] - [lindex [flattenList $Box] 0]) / 1.12]
            set tar  [expr floor($num) + 0.51]
            set new_Box  $Box
            #if {$num < $tar} {
            #    set new_num [expr $tar + 1.02]
            #    if {[lindex [flattenList $corebox] 0] == [lindex [flattenList $Box] 0]} {
            #        set new_urx [expr [lindex [flattenList $corebox] 0] + $new_num * 3.36]
            #        set new_Box [list [lindex [flattenList $Box] 0]  [lindex [flattenList $Box] 1] $new_urx [lindex [flattenList $Box] 3]]
            #    }
            #    if {[lindex [flattenList $corebox] 2] == [lindex [flattenList $Box] 2]} {
            #        set new_llx [expr [lindex [flattenList $corebox] 2] - $new_num * 3.36]
            #        set new_Box [list $new_llx  [lindex [flattenList $Box] 1] [lindex [flattenList $Box] 2] [lindex [flattenList $Box] 3]]
            #    }
            #}
            addWellTap -cellInterval 3.36 -cell $cell -prefix [dbGet top.name]_DCAP_for_iso_buff -area $new_Box -checkerBoard
        }
    }
}
###usb {2.8 619.5 22.82 744.1} addWellTap -cellInterval 3.36 -cell FILLSGCAP8_A7PP140ZTS_C35  -prefix [dbGet top.name]_DCAP_for_iso_buff -area {2.8 619.5 22.82 744.1} -checkerBoard
###ddr addWellTap -cellInterval 3.36 -cell FILLSGCAP8_A9PP140ZTS_C35  -prefix [dbGet top.name]_DCAP_for_iso_buff -area {2387.56 2.7 2557.38 22.5} -checkerBoard
###ddr addWellTap -cellInterval 3.36 -cell FILLSGCAP8_A9PP140ZTS_C35  -prefix [dbGet top.name]_DCAP_for_iso_buff -area {1309.56 2.7 1393.42 22.5} -checkerBoard
