
#hah foreach lib $all_libs  {read_lib $lib}
#hah foreach lib [get_object_name  [get_lib *]]  {write_lib -format db -output $lib.db   $lib}

set all_libs  [glob /eda_files/proj/ict8810/archive/11-ip/pvt_sensor/20240528_028UMC_PVT_01_database_release_v1.0/Abstracts/LIB/{capacitor_instance,UMC028_PVT_01_SU09,UMC028_PVT_01_SU18,UMC028_PVT_01_SU33,UMC028_PVT_01_SU_VBAT}*lib]
foreach lib $all_libs {
	read_lib $lib
	set ip_name [get_object_name  [get_lib *]]
#	regexp ".*LIB/${ip_name}.lib" $lib a corner
	write_lib -format db -output ${ip_name}.db $ip_name 
	remove_lib -all
}
exit
