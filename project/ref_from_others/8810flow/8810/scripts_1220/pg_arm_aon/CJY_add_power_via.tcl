proc add_power_via {} {
	global vars
	
	#add power via from AP to M8
	#editPowerVia -add_vias 1 -bottom_layer M8 -orthogonal_only 1 -top_layer AL_RDL

	#add power via from M8 to M7
	#editPowerVia -add_vias 1 -bottom_layer ME7 -orthogonal_only 1 -top_layer ME8

	#add power via from m7 to m6
	editPowerVia -add_vias 1 -bottom_layer ME6 -orthogonal_only 1 -top_layer ME7

	#add power via from m6 to m5
	editPowerVia -add_vias 1 -bottom_layer ME5 -orthogonal_only 1 -top_layer ME6

	#add power via from m5 to m1
  #setViaGenMode -viarule_preference  {VIAGEN12 VIAGEN23}
	editPowerVia -add_vias 1 -bottom_layer M2 -orthogonal_only 1 -top_layer M5
  #editPowerVia -add_vias 1 -bottom_layer M1 -orthogonal_only 0 -top_layer M2
  setViaGenMode -reset
}
