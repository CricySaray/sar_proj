proc edi_signoff_check_missing_via {{rptNamePrefix edi_signoff_check_missing_via}} {
     ##top
     if {[dbGet top.name] eq "chip_top"} {
         verifyPowerVia -report ${rptNamePrefix}_APM8.rpt -layerRange {AL_RDL ME8} -nonOrthogonalCheck -error 1000000 -checkWirePinOverlap	
     }
     deselectAll
     delete_gui_object -all
     fit
     gui_dim_foreground -lightness_level medium
     setLayerPreference node_route -isVisible 0
     setLayerPreference node_blockage -isVisible 0
     setLayerPreference node_layer -isVisible 1
     setLayerPreference violation -isVisible 1
     ##block
     foreach uplayer {AL_RDL ME8 ME7 ME6 ME5} downLayer {ME8 ME7 ME6 ME5 ME4} {
         clearDrc
         deselectAll
         verifyPowerVia -report ${rptNamePrefix}_${uplayer}${downLayer}.rpt -layerRange [list $uplayer $downLayer] -nonOrthogonalCheck -error 1000000 -checkWirePinOverlap
         deselectAll
	 #gui_dump_picture ${rptNamePrefix}_${uplayer}${downLayer}.gif -format GIF
	 #saveDrc ${rptNamePrefix}_${uplayer}${downLayer}.drc
     }


     if {"sc7mcpp140z_l28hpcp" == [dbGet top.fplan.coreSite.name]} {
 	set pgGap 11.5
     }  else {
	set pgGap 11.5
     }
     clearDrc
     deselectAll
     editSelect -type Special -shape {FOLLOWPIN STRIPE} -layer {ME2 ME5}
     verifyPowerVia -report ${rptNamePrefix}_stackM2M5.rpt -layer_rail ME2 -layer_stripe ME5 -stackedVia -stripe_rule $pgGap -layerRange {ME2 ME5} -selected -error 1000000
     gui_dump_picture ${rptNamePrefix}_stackM2M5.gif -format GIF
     saveDrc ${rptNamePrefix}_stackM2M5.drc
     deselectAll
     }
