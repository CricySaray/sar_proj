foreach clamp [dbGet top.insts.cell.name VESDC09GV -p2] {
    set clampName [dbGet ${clamp}.name]
    set vdd_pin_box [dbTransform -localPt [dbGet [dbGet -p2 [dbGet -p ${clamp}.pgInstTerms.term.name VCC09VESD].pins.allShapes.layer.name ME3].shapes.rect] -inst $clampName]
    scan $vdd_pin_box "{%f %f %f %f}" llx1 lly1 urx1 ury1
    set area [dbShape -output rect "$llx1 $lly1 $urx1 $ury1" SIZE 0.5]
    createRouteBlk -layer {ME1 ME2 ME3} -name clp_vdd -box $area
}
foreach clamp [dbGet -e top.insts.cell.name VESDC09GH -p2] {
    set clampName [dbGet ${clamp}.name]
    set vdd_pin_box [dbTransform -localPt [dbGet [dbGet -p2 [dbGet -p ${clamp}.pgInstTerms.term.name VCC09VESD].pins.allShapes.layer.name ME3].shapes.rect] -inst $clampName]
    scan $vdd_pin_box "{%f %f %f %f}" llx1 lly1 urx1 ury1
    set area [dbShape -output rect "$llx1 $lly1 $urx1 $ury1" SIZE 0.5]
    createRouteBlk -layer {ME1 ME2 ME3} -name clp_vdd -box $area
}
