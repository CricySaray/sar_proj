########################################
# author: Leon Sun
# Date: 2024/05/24 18:04:55
# Version: 1.0
# for valid/ready handshake 
########################################

set handshake_ports [get_ports "*valid* *vld* *ready* *rdy*" -filter "direction==out" -quiet]
if { $handshake_ports != "" } {
    set sinks [get_object_name [filter_collection [all_fanin -to $handshake_ports -startpoint -view func_wcl_cworst_t] name=~CK*]]
    if { $sinks != "" } {
        echo "INFO: for handshake signals"
        foreach i $sinks {
            echo "INFO: set_ccopt_property insertion_delay 0.2 -pin $i"
            set_ccopt_property insertion_delay 0.2 -pin $i
        }
        group_path -name  to_handshake -from [all_registers] -to [get_cells -of [get_pins $sinks]]
        setPathGroupOptions to_handshake -effortLevel high -weight 2
    }
}
