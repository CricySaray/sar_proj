#left
editPin -start  "20 0" -side left  -spreadType start -layer M4  -pin [get_property [get_ports * ] hierarchical_name ]-fixedPin  -pinWidth 0.07 -pinDepth 0.6 -spacing 2 -snap TRACK -unit TRACK -honorConstraint 1 -fixOverlap 1
#top
#editPin -start  "0 20" -side top -layer M5  -pin * -fixedPin  -pinWidth 0.07 -pinDepth 0.6 -spacing 2 -snap TRACK -unit TRACK -honorConstraint 1 -fixOverlap 1
