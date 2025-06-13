
#hah foreach lib $all_libs  {read_lib $lib}
#hah foreach lib [get_object_name  [get_lib *]]  {write_lib -format db -output $lib.db   $lib}

#set all_libs  [glob /eda_files/pub/library/umc/umc28hpcplus/tech_file/10-IP_Category/efuse/synopsys/*lib]
set all_libs  [glob /eda_files/pub/library/umc/umc28hpcplus_vct/09-IP_Category/G-9MT-LOGIC_MIXED_MODE28N-HPC+_UM028EFUCP01603218400-MEMORY_TAPE_OUT_KIT-Ver.A02_PB/synopsys/*lib]

foreach lib $all_libs {
	read_lib $lib
	set ip_name [get_object_name  [get_lib *]]
	regexp ".*${ip_name}_(.*).lib" $lib a corner
	write_lib -format db -output ${ip_name}_$corner.db $ip_name 
	close_lib -all
}
#sh rm lc_output.txt
#sh rm lc_command.log
exit
