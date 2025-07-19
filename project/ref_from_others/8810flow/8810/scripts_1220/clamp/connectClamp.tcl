addHaloToBlock 10 10 10 10 -cell VESDC09GV
dbSet [dbGet -p2 top.insts.cell.name VESDC09G*].pstatus fixed

foreach clamp [dbGet top.insts.cell.name VESDC09GV -p2] {
    set clampName [dbGet ${clamp}.name]
    if { [dbGet top.pgNets.name vdd_inner] == "0x0" } {
        addNet vdd_inner -physical -power
        addNet vss_inner -physical -ground
    }
    globalNetConnect vdd_inner -singleInstance $clampName -pin VCC09VESD
    globalNetConnect vss_inner -singleInstance $clampName -pin GNDVESD
    
    set vdd_pin_box [dbTransform -localPt [dbGet [dbGet -p2 [dbGet -p ${clamp}.pgInstTerms.term.name VCC09VESD].pins.allShapes.layer.name ME3].shapes.rect] -inst $clampName]
    set gnd_pin_box [dbTransform -localPt [dbGet [dbGet -p2 [dbGet -p ${clamp}.pgInstTerms.term.name   GNDVESD].pins.allShapes.layer.name ME3].shapes.rect] -inst $clampName]
    scan $vdd_pin_box "{%f %f %f %f}" llx1 lly1 urx1 ury1
    scan $gnd_pin_box "{%f %f %f %f}" llx2 lly2 urx2 ury2
    set width 1
    set spacing 0.29
    set length 6
    #M2
    setAddStripeMode -skip_via_on_pin {pad cover standardcell physicalpin block} -skip_via_on_wire_shape {stripe}
    addStripe -nets vss_inner -start_offset 0 -width $width -spacing $spacing -set_to_set_distance [expr $width+$spacing] -uda clamp_pg -layer ME2 -area "$llx2 $lly2 $urx2 [expr $lly2+$length]" -start_from left
    addStripe -nets vdd_inner -start_offset 0 -width $width -spacing $spacing -set_to_set_distance [expr $width+$spacing] -uda clamp_pg -layer ME2 -area "$llx1 [expr $ury1-$length] $urx1 $ury1" -start_from left
    #M3
    addStripe -nets vss_inner -start_offset 0 -width $width -spacing $spacing -set_to_set_distance [expr $width+$spacing] -uda clamp_pg -layer ME3 -area "$llx2 $lly2 $urx2 [expr $lly2+$length]" -start_from left
    addStripe -nets vdd_inner -start_offset 0 -width $width -spacing $spacing -set_to_set_distance [expr $width+$spacing] -uda clamp_pg -layer ME3 -area "$llx1 [expr $ury1-$length] $urx1 $ury1" -start_from left
    #M4
    addStripe -nets vss_inner -start_offset 0 -width 2.2 -spacing 1 -set_to_set_distance 3.3 -uda clamp_pg -layer ME4 -direction horizontal -area "[expr $llx2-5] $lly2 [expr $urx2+5] [expr $lly2+$length]" -start_from bottom
    addStripe -nets vdd_inner -start_offset 0 -width 2 -spacing 1.3 -set_to_set_distance 3.3 -uda clamp_pg -layer ME4 -direction horizontal -area "[expr $llx1-5] [expr $ury1-$length] [expr $urx1+5] $ury1" -start_from top
    #M5
    addStripe -nets "vss_inner vdd_inner" -start_offset 0 -width 4 -spacing 1 -set_to_set_distance 10 -uda clamp_pg -layer ME5 -direction vertical -area "[expr $llx1-5] [expr $ury1-$length] [expr $urx1+5] [expr $lly2+$length]" -start_from left
    #M6
    addStripe -nets "vss_inner vdd_inner" -start_offset 0 -width 4 -spacing 1 -set_to_set_distance 10 -uda clamp_pg -layer ME6 -direction horizontal -area "[expr $llx1-5] [expr $ury1-$length] [expr $urx1+5] [expr $lly2+$length]" -start_from bottom
    #M7
    addStripe -nets "vss_inner vdd_inner" -start_offset 1 -width 10 -spacing 2 -set_to_set_distance 24 -uda clamp_pg -layer ME7 -direction vertical -area "[expr $llx1-5] [expr $ury1-$length] [expr $urx1+5] [expr $lly2+$length]" -start_from left
}


#Via
editPowerVia -nets "vss_inner vdd_inner" -add_vias 1 -bottom_layer ME3 -top_layer ME4  -orthogonal_only 0
editPowerVia -nets "vss_inner vdd_inner" -add_vias 1 -bottom_layer ME2 -top_layer ME4
editPowerVia -nets "vss_inner vdd_inner" -add_vias 1 -bottom_layer ME4 -top_layer ME5
editPowerVia -nets "vss_inner vdd_inner" -add_vias 1 -bottom_layer ME5 -top_layer ME6
editPowerVia -nets "vss_inner vdd_inner" -add_vias 1 -bottom_layer ME6 -top_layer ME7


#for dp
foreach clamp [dbGet -e top.insts.cell.name VESDC09GH -p2] {
    addHaloToBlock 10 10 10 10 -cell VESDC09GH
    set clampName [dbGet ${clamp}.name]
    if { [dbGet top.pgNets.name vdd_inner] == "0x0" } {
        addNet vdd_inner -physical -power
        addNet vss_inner -physical -ground
    }
    globalNetConnect vdd_inner -singleInstance $clampName -pin VCC09VESD
    globalNetConnect vss_inner -singleInstance $clampName -pin GNDVESD

    set vdd_pin_box [dbTransform -localPt [dbGet [dbGet -p2 [dbGet -p ${clamp}.pgInstTerms.term.name VCC09VESD].pins.allShapes.layer.name ME3].shapes.rect] -inst $clampName]
    set gnd_pin_box [dbTransform -localPt [dbGet [dbGet -p2 [dbGet -p ${clamp}.pgInstTerms.term.name   GNDVESD].pins.allShapes.layer.name ME3].shapes.rect] -inst $clampName]
    scan $vdd_pin_box "{%f %f %f %f}" llx1 lly1 urx1 ury1
    scan $gnd_pin_box "{%f %f %f %f}" llx2 lly2 urx2 ury2
    set width 1
    set spacing 0.29
    set length 6
    #M2
    setAddStripeMode -skip_via_on_pin {pad cover standardcell physicalpin block} -skip_via_on_wire_shape {stripe}
    addStripe -nets vss_inner -start_offset 0 -width $width -spacing $spacing -set_to_set_distance [expr $width+$spacing] -uda clamp_pg -layer ME2 -direction horizontal -area "[expr $urx2-$length] $lly2 $urx2 $ury2" -start_from bottom
    addStripe -nets vdd_inner -start_offset 0 -width $width -spacing $spacing -set_to_set_distance [expr $width+$spacing] -uda clamp_pg -layer ME2 -direction horizontal -area "$llx1 $lly1 [expr $llx1+$length] $ury1" -start_from bottom
    #M3
    addStripe -nets vss_inner -start_offset 0 -width $width -spacing $spacing -set_to_set_distance [expr $width+$spacing] -uda clamp_pg -layer ME3 -direction horizontal -area "[expr $urx2-$length] $lly2 $urx2 $ury2" -start_from bottom
    addStripe -nets vdd_inner -start_offset 0 -width $width -spacing $spacing -set_to_set_distance [expr $width+$spacing] -uda clamp_pg -layer ME3 -direction horizontal -area "$llx1 $lly1 [expr $llx1+$length] $ury1" -start_from bottom
    #M4
    addStripe -nets vss_inner -start_offset 0 -width $width -spacing $spacing -set_to_set_distance [expr $width+$spacing] -uda clamp_pg -layer ME4 -direction horizontal -area "[expr $urx2-$length] $lly2 $urx2 $ury2" -start_from bottom
    addStripe -nets vdd_inner -start_offset 0 -width $width -spacing $spacing -set_to_set_distance [expr $width+$spacing] -uda clamp_pg -layer ME4 -direction horizontal -area "$llx1 $lly1 [expr $llx1+$length] $ury1" -start_from bottom
    #M5
    addStripe -nets vss_inner -start_offset 0 -width 2.2 -spacing 1 -set_to_set_distance 3.3 -uda clamp_pg -layer ME5 -direction vertical -area "[expr $urx2-$length] [expr $lly2-5] $urx2 [expr $ury2+5]" -start_from right
    addStripe -nets vdd_inner -start_offset 0 -width 2 -spacing 1.3 -set_to_set_distance 3.3 -uda clamp_pg -layer ME5 -direction vertical -area "$llx1 [expr $lly1-5] [expr $llx1+$length] [expr $ury1+5]" -start_from left
    #M6
    addStripe -nets "vss_inner vdd_inner" -start_offset 0 -width 4 -spacing 1 -set_to_set_distance 10 -uda clamp_pg -layer ME6 -direction horizontal -area "[expr $urx2-$length] [expr $lly2-5] [expr $llx1+$length] [expr $ury1+5]" -start_from bottom
    #M7
    addStripe -nets "vss_inner vdd_inner" -start_offset 1 -width 10 -spacing 2 -set_to_set_distance 24 -uda clamp_pg -layer ME7 -direction vertical -area "[expr $urx2-$length] [expr $lly2-5] [expr $llx1+$length] [expr $ury1+5]" -start_from left

    #Via
    editPowerVia -nets "vss_inner vdd_inner" -add_vias 1 -bottom_layer ME2 -top_layer ME3 -orthogonal_only 0
    editPowerVia -nets "vss_inner vdd_inner" -add_vias 1 -bottom_layer ME3 -top_layer ME4 -orthogonal_only 0
    editPowerVia -nets "vss_inner vdd_inner" -add_vias 1 -bottom_layer ME4 -top_layer ME5
    editPowerVia -nets "vss_inner vdd_inner" -add_vias 1 -bottom_layer ME5 -top_layer ME6
    editPowerVia -nets "vss_inner vdd_inner" -add_vias 1 -bottom_layer ME6 -top_layer ME7
}

