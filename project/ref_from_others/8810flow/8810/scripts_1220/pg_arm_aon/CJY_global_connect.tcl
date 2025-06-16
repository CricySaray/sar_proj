proc global_net_connect {} {
	global vars
	globalNetConnect $vars(gnd_nets) -override -pin VSS -instanceBasename * -type pgpin -verbose
	globalNetConnect $vars(gnd_nets) -override -pin VPW -instanceBasename * -type pgpin -verbose
	globalNetConnect $vars(power_nets) -override -pin VDD -instanceBasename * -type pgpin -verbos
	globalNetConnect $vars(power_nets) -override -pin VNW -instanceBasename * -type pgpin -verbos
	foreach inst [dbGet [dbGet top.insts.cell.name -regexp AU28HPC -p2].name] {
		globalNetConnect $vars(gnd_nets) -override -pin VSSE -singleInstance $inst -type pgpin -verbose
		globalNetConnect $vars(power_nets) -override -pin VDDCE -singleInstance $inst -type pgpin -verbose
		globalNetConnect $vars(power_nets) -override -pin VDDPE -singleInstance $inst -type pgpin -verbose
	}
}
#foreach inst [get_object_name [get_cells -hierarchical -filter  "is_memory_cell == true"]] {
