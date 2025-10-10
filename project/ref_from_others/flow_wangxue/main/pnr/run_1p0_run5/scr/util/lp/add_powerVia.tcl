editPowerVia -delete_vias 1
setViaGenMode  -reset
#setViaGenMode -allow_via_expansion false 
#deselectAll
#select_obj [dbGet top.nets.swires.layer.name M1 -p2]
#select_obj [dbGet top.nets.swires.layer.name M2 -p2]
#editPowerVia -add_vias 1 -selected_wires 1  -bottom_layer M1 -top_layer M2 -skip_via_on_pin {pad block cover physicalpin}
#editPowerVia -add_vias 1 -selected_wires 1 -bottom_layer M1 -top_layer M2 -orthogonal_only 0
deselectAll
select_obj [dbGet top.nets.swires.layer.name M1 -p2]
select_obj [dbGet top.nets.swires.layer.name M6 -p2]
editPowerVia -add_vias 1 -selected_wires 1  -bottom_layer M4 -top_layer M6 -orthogonal_only 1
editPowerVia -add_vias 1 -between_selected_wires 1 -bottom_layer M1 -top_layer M6 -orthogonal_only 1
deselectAll
select_obj [dbGet top.nets.swires.layer.name M6 -p2]
select_obj [dbGet top.nets.swires.layer.name M7 -p2]
editPowerVia -add_vias 1 -selected_wires  1 -bottom_layer M6 -top_layer M7 -orthogonal_only 0
editPowerVia -add_vias 1 -between_selected_wires  1 -bottom_layer M6 -top_layer M7 -orthogonal_only 1
deselectAll
select_obj [dbGet top.nets.swires.layer.name M7 -p2]
select_obj [dbGet top.nets.swires.layer.name M8 -p2]
editPowerVia -add_vias 1 -between_selected_wires  1 -bottom_layer M7 -top_layer M8 -orthogonal_only 1
deselectAll
select_obj [dbGet top.nets.swires.layer.name M3 -p2]
select_obj [dbGet top.nets.swires.layer.name M7 -p2]
editPowerVia -add_vias 1 -between_selected_wires  1 -bottom_layer M3 -top_layer M7 -orthogonal_only 1
deselectAll
select_obj [dbGet top.nets.swires.layer.name M4 -p2]
select_obj [dbGet top.nets.swires.layer.name M7 -p2]
editPowerVia -add_vias 1 -between_selected_wires  1 -bottom_layer M4 -top_layer M7 -orthogonal_only 1
#deselectAll
#select_obj [dbGet top.nets.swires.layer.name M8 -p2]
#editPowerVia -add_vias 1 -selected_wires  1 -bottom_layer M6 -top_layer M8 -orthogonal_only 0
deselectAll
select_obj [dbGet top.nets.swires.layer.name AP -p2]
select_obj [dbGet top.nets.swires.layer.name M8 -p2]
editPowerVia -add_vias 1 -between_selected_wires  1 -bottom_layer M8 -top_layer AP -orthogonal_only 0
deselectAll

