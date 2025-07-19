##########################################################################################################################
#set dir
set dir "/eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/backend/be8803/scripts/pg_arm_aon"

#add soft blockage between mem
source ${dir}/CJY_add_sblk_mem.tcl

#global connect
source ${dir}/CJY_global_connect.tcl

#pg global setting
source ${dir}/CJY_pg_global_setting.tcl

#add sroute m1
source ${dir}/CJY_add_m1.tcl

#add m2
source ${dir}/CJY_add_m2.tcl

#add m5m6
source ${dir}/CJY_add_m5m6.tcl

#add enhance mem m5
source ${dir}/CJY_enhence_m5_pg.tcl

#add enhance mem m5
source ${dir}/CJY_enhence_m6_pg.tcl

#add m7
source ${dir}/CJY_add_m7.tcl

#add m8
source ${dir}/CJY_add_m8.tcl

#add ap
source ${dir}/CJY_add_ap.tcl

#add power via
source ${dir}/CJY_add_power_via.tcl

#check mem m5
source ${dir}/CJY_check_mem_pg.tcl

##########################################################################################################################
#global connect
#global_net_connect

source /eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/backend/be8801/david/flow/ict8810/common_script/Global_Net_Connection.tcl

#add_sblk_mem
add_m2

#add m5m6
add_m5m6 -type all -size 10

#enhence memory m5 pg
enhence_m5_pg

#enhence memory m5 pg
enhence_m6_pg

#add m7 pg
add_m7

#add m8 pg
#add_m8

#add ap pg
#add_ap

#add power via
add_power_via

#check mem m5
check_mem_pg -layer ME5
