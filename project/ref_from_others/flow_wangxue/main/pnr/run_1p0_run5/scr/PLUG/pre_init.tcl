####################################################################################
#                           PRE-INIT PLUG-IN
####################################################################################
#
# This plug-in script is called before initializing the design database from the
# run_init.tcl flow script.
#
####################################################################################
#
# Ex: Below command used for inserting buffers on tie-high/tie-low assign statements
#
#-----------------------------------------------------------------------------------
#
#setImportMode -bufferTieAssign $vars(buffer_tie_assign)

#set_message -id IMPVL-346 -severity error ;#missing lef
#set_message -id IMPDB-2163 -severity warn ;#lib/lef bus not match
#set_message -id IMPVL-902 -severity warn ;#lib/lef bus not match
#set_message -id IMPDB-2160 -severity warn ;

set init_no_new_assigns 1
set init_remove_assigns 1
setDoAssign on -buffer BUFFD4BWP7T35P140  -prefix assign_fix_ 


