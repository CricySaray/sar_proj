#proc min {a b} {
#    if {$a < $b} {
#        return $a
#    } else {
#        return $b
#    }
#}
#catch { unset clk_arr}
#
#proc set_max_data_transition {MAX_DATA_SLEW} {
#    foreach_in_collection clk [all_clocks] {
#       set clk_name [get_attribute $clk full_name]
#       set clk_period [get_attribute $clk period -quiet]
#          if { $clk_period != "" } {
#              set clk_arr($clk_name) $clk_period
#          }
#       }
#         foreach {name period} [lsort -stride 2 -index 1 -real -decreasing [array get clk_arr]] {  
#         set max_slew [expr (ceil ($period / 3.000 * 1000))/1000]
#         set min_slew [min $max_slew $MAX_DATA_SLEW]
#         set min_min_slew [expr $min_slew - 0.010]
#         echo "set_max_transition $min_min_slew -data_path $name"
#         set_max_transition $min_min_slew -data_path [get_clocks $name] 
#     }
#    }
#
#catch { unset clk_arr}
#proc set_max_clk_transition {MAX_CLK_SLEW} {
#       foreach_in_collection clk [all_clocks] {
#          set clk_name [get_attribute $clk full_name]
#          set clk_period [get_attribute $clk period -quiet]
#              if { $clk_period != "" } {
#                 set clk_arr($clk_name) $clk_period
#               }
#            }
#            foreach {name period} [lsort -stride 2 -index 1 -real -decreasing [array get clk_arr]] {
#                   set max_slew [expr (ceil ($period / 6.000 * 1000))/1000]
#               set min_slew [min $max_slew $MAX_CLK_SLEW]
#               set min_min_slew [expr $min_slew - 0.008]
#               echo "set_max_transition $min_min_slew -clock_path $name"
#               set_max_transition $min_min_slew -clock_path [get_clocks $name ]
#         }
#}

#set MAX_DATA_SLEW 0.450; 
#set MAX_CLK_SLEW 0.250;
#set_max_transition 0.450 [current_design] 

#set_max_data_transition $MAX_DATA_SLEW
#set_max_clk_transition $MAX_CLK_SLEW 

####
# 20250122  update  
# data  : 450ps
# clock : 250ps
set tran_data 0.450
set tran_clk  0.250
set_interactive_constraint_modes [all_constraint_modes ]
set_max_transition 0.450 [current_design] 
foreach_in_collection clk [all_clocks] {
    set name [get_attribute $clk full_name]
    # data
    echo "set_max_transition $tran_data -data_path $name"
    set_max_transition $tran_data -data_path [get_clocks $name]
    # clk
    echo "set_max_transition $tran_clk -clock_path $name"
    set_max_transition $tran_clk -clock_path [get_clocks $name]
}
