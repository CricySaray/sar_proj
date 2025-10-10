deleteFiller -prefix ENDCAP
deleteFiller -prefix WELLTAP_
setEndCapMode -reset
set_well_tap_mode -reset
foreach i [dbGet [dbGet top.pds.isPowerDomainMacroOnly 0 -p].name] {
set vars(endCap_cell) "FILL3BWP7T40P140HVT FILL2BWP7T40P140HVT"
set vars(tap_cell) TAPCELLBWP7T35P140
setEndCapMode -prefix ENDCAP \
              -topEdge $vars(endCap_cell) \
              -bottomEdge $vars(endCap_cell) \
              -leftEdge BOUNDARY_RIGHTBWP7T35P140 \
              -rightEdge BOUNDARY_LEFTBWP7T35P140 \
              -leftBottomEdge BOUNDARY_RIGHTBWP7T35P140 \
              -leftBottomCorner BOUNDARY_RIGHTBWP7T35P140 \
              -leftTopEdge BOUNDARY_RIGHTBWP7T35P140 \
              -leftTopCorner BOUNDARY_RIGHTBWP7T35P140 \
              -rightBottomEdge BOUNDARY_LEFTBWP7T35P140 \
              -rightBottomCorner BOUNDARY_LEFTBWP7T35P140 \
              -rightTopEdge BOUNDARY_LEFTBWP7T35P140 \
              -rightTopCorner BOUNDARY_LEFTBWP7T35P140 \
              -boundary_tap true 
set_well_tap_mode -bottom_tap_cell $vars(tap_cell)  -top_tap_cell $vars(tap_cell) -rule 116
addEndCap -prefix ENDCAP -powerDomain $i
}

