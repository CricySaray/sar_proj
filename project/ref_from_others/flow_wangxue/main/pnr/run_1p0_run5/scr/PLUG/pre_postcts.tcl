##################################################################################
#                           PRE-POST_CTS PLUG-IN 
##################################################################################
#
# This plug-in script is called before optDesign -postCTS fixing from the
# run_postcts.tcl flow script.
#
##################################################################################
setOptMode -addInstancePrefix POSTCTS_HOLD_ 
setOptMode -fixHoldAllowSetupTnsDegrade TRUE
setOptMode -ignorePathGroupsForHold {default}    
setOptMode -holdTargetSlack 0 -setupTargetSlack 0.2
#setOptMode -holdFixingCells 

