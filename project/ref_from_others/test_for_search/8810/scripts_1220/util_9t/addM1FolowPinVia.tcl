setViaGenMode -reset
setSnapGrid -pitch 0.002 0.002
editSelect -net VDD -layer M1 -shape FOLLOWPIN
editSelect -net VDD -layer M2 -shape FOLLOWPIN
editSelect -net VSS -layer M1 -shape FOLLOWPIN
editSelect -net VSS -layer M2 -shape FOLLOWPIN

setViaGenMode -optimize_cross_via true -ignore_drc true
setViaGenMode -keep_existing_via 1 -respect_signal_routes 2 -respect_stdcell_cut true
editPowerVia -add_vias 1 -top_layer M2 -bottom_layer M1 -orthogonal_only 0 -split_vias 1 -between_selected_wires 1
deselectAll
fixVia -cutSacing -shape FOLLOWPIN -layer {V12}

setViaGenMode -reset
