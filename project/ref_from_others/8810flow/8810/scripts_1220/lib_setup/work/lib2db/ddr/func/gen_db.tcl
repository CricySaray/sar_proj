
#hah foreach lib $all_libs  {read_lib $lib}
#hah foreach lib [get_object_name  [get_lib *]]  {write_lib -format db -output $lib.db   $lib}

set all_libs  [glob /eda_files/proj/ict8810/archive/11-ip/ddr_phy/INNO_PKG_DDR4_3_3L_COMBO_PHY_PRJ2403CAM1_S2403_V4P1_R20240722/FRONTEND/LIB/func/lib/*lib]
foreach lib $all_libs {
	read_lib $lib
	set ip_name [get_object_name  [get_lib *]]
#	regexp ".*${ip_name}_(.*).lib" $lib a corner
	regexp ".*inno_ddr_phy_(.*).lib" $lib a corner
	write_lib -format db -output ${ip_name}.db $ip_name 
#	close_lib -all
	remove_lib -all
}
#sh rm lc_output.txt
#sh rm lc_command.log
exit
