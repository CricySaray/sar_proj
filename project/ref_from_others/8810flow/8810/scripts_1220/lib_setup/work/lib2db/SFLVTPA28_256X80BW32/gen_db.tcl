
#hah foreach lib $all_libs  {read_lib $lib}
#hah foreach lib [get_object_name  [get_lib *]]  {write_lib -format db -output $lib.db   $lib}

set all_libs  [glob /eda_files/proj/ict8810/archive/11-ip/tcam/SFLVTPA28_256X80BW32/*.pglib]
foreach lib $all_libs {
	read_lib $lib
	set ip_name [get_object_name  [get_lib *]]
#	regexp ".*${ip_name}_(.*).lib" $lib a corner
#	regexp ".*SFLVTPA28_256X80BW32_(.*).pglib" $lib a corner
	write_lib -format db -output ${ip_name}.pgdb $ip_name 
#	close_lib -all
	remove_lib -all
}
#sh rm lc_output.txt
#sh rm lc_command.log
exit
