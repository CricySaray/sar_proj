#!user/bin/tclsh
#############################################
## author: spark
## Date: 2024/01/29
## Version: 1.0
## gen gsr & rhkw
#############################################


############################################
## user defind vars 
###########################################
set TECHNOLOGY "28"
set LIBSET "tt85"
set RC_TYPE ""
set TEMPERATURE "85"
set SIGNAL_RATE "0.2"
set CLOCK_RATE "2"
set FREQUENCY "200"
set VDD_NETS "DVDD0P9_CORE 0.9 DVDD0P9_DBB 0.9 DVDD0P9_AON 0.9 DVDD0P9_PSW 0.9 VQPS 1.8 DVDDIO 3.3 DVDDIO_PSW 3.3"
set GND_NETS "VSS_CORE 0 VSS_IO 0"
set CHIP_NAME "CX200UR1_SOC_TOP"
set BLOCK_NAME ""
set VERSION "final"
set PLOC_FILE "/Data83/home/user2/project/cx200/dataout/final_0212/ploc/PG.ploc"
set FUNC_STA_FILE "/Data83/home/user2/project/cx200/dataout/final_0212/STA_file/CX200A_SOC_TOP_func_tt_85.irdrop.gz"
set SCAN_STA_FILE "/Data83/home/user2/project/cx200/dataout/final_0212/STA_file/CX200A_SOC_TOP_scan_tt_85.irdrop.gz"
set RC_FILE "/Data83/home/user2/project/cx200/dataout/final_0212/spef/CX200A_SOC_TOP.spef.tt_85.gz"
set DEF_FILE "/Data83/home/user2/project/cx200/dataout/final_0212/def/CX200A_SOC_TOP.pr.ir.def.gz"
set coremark_FSDB "/local_disk/share/CX200_A/wave_for_irdrop/ECO4/coremark_with_flash_fft_netlist3.0_eco4_tt_extract_0213.fsdb"
set aon_psw_FSDB "/local_disk/share/CX200_A/wave_for_irdrop/3.0/0116/aon_irdrop_netlist3.0_eco_tt_extract.fsdb"
set dbb_trx_FSDB "/local_disk/share/CX200_A/wave_for_irdrop/ECO4/ir_drop_dbb_trx_20us_net0211.fsdb"
set mbist_fsdb "/local_disk/home/user3/project/cx200a/release_to_pr/3.0/1223/FSDB_eco4/MemoryBist_for_pa.fsdb"
set ac_fsdb "/local_disk/home/user3/project/cx200a/release_to_pr/3.0/1223/FSDB_eco4/ac_ser_for_pa.fsdb"
set sa_fsdb "/local_disk/home/user3/project/cx200a/release_to_pr/3.0/1223/FSDB_eco4/sa_ser_for_pa.fsdb"
set FSDB_TIMING "1"
set SCOPE "harness/u_cx200a_chip"
set SWITCH_MODEL_FILE "/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp7t40p140cghvt_160a/redhawk/tcbn28hpcplusbwp7t40p140cghvttt0p9v85c/APLSW/aplsw_header.out"

set TECH_FILE "/local_disk/home/user10/work/PA/PA_flow/tsmcn28_8lm5X1Z1URDL.redhawk.typical.tech"
set TECH_LEF "/local_disk/home/user2/project/CX200/lib_conf/tlef/tsmcn28_8lm5X1Z1URDL.tlef"

set APL_FILE "/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp35p140_110c/redhawk/tcbn28hpcplusbwp35p140tt0p9v85c/CAP/tcbn28hpcplusbwp35p140tt0p9v85c_cap.cdev \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp35p140hvt_110c/redhawk/tcbn28hpcplusbwp35p140hvttt0p9v85c/CAP/tcbn28hpcplusbwp35p140hvttt0p9v85c_cap.cdev \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp35p140lvt_110c/redhawk/tcbn28hpcplusbwp35p140lvttt0p9v85c/CAP/tcbn28hpcplusbwp35p140lvttt0p9v85c_cap.cdev \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp35p140mb_170a/redhawk/tcbn28hpcplusbwp35p140mbtt0p9v85c/CAP/tcbn28hpcplusbwp35p140mbtt0p9v85c_cap.cdev \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp35p140mbhvt_170a/redhawk/tcbn28hpcplusbwp35p140mbhvttt0p9v85c/CAP/tcbn28hpcplusbwp35p140mbhvttt0p9v85c_cap.cdev \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp35p140mblvt_170a/redhawk/tcbn28hpcplusbwp35p140mblvttt0p9v85c/CAP/tcbn28hpcplusbwp35p140mblvttt0p9v85c_cap.cdev \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp7t35p140_130c/redhawk/tcbn28hpcplusbwp7t35p140tt0p9v85c/CAP/tcbn28hpcplusbwp7t35p140tt0p9v85c_cap.cdev \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp7t35p140cg_160a/redhawk/tcbn28hpcplusbwp7t35p140cgtt0p9v85c/CAP/tcbn28hpcplusbwp7t35p140cgtt0p9v85c_cap.cdev \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp7t35p140cghvt_160a/redhawk/tcbn28hpcplusbwp7t35p140cghvttt0p9v85c/CAP/tcbn28hpcplusbwp7t35p140cghvttt0p9v85c_cap.cdev \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp7t35p140cglvt_160a/redhawk/tcbn28hpcplusbwp7t35p140cglvttt0p9v85c/CAP/tcbn28hpcplusbwp7t35p140cglvttt0p9v85c_cap.cdev \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp7t35p140cguhvt_160a/redhawk/tcbn28hpcplusbwp7t35p140cguhvttt0p9v85c/CAP/tcbn28hpcplusbwp7t35p140cguhvttt0p9v85c_cap.cdev \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp7t35p140hvt_130c/redhawk/tcbn28hpcplusbwp7t35p140hvttt0p9v85c/CAP/tcbn28hpcplusbwp7t35p140hvttt0p9v85c_cap.cdev \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp7t35p140lvt_130c/redhawk/tcbn28hpcplusbwp7t35p140lvttt0p9v85c/CAP/tcbn28hpcplusbwp7t35p140lvttt0p9v85c_cap.cdev \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp7t35p140mb_150a/redhawk/tcbn28hpcplusbwp7t35p140mbtt0p9v85c/CAP/tcbn28hpcplusbwp7t35p140mbtt0p9v85c_cap.cdev \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp7t35p140mbhvt_150a/redhawk/tcbn28hpcplusbwp7t35p140mbhvttt0p9v85c/CAP/tcbn28hpcplusbwp7t35p140mbhvttt0p9v85c_cap.cdev \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp7t35p140mblvt_170a/redhawk/tcbn28hpcplusbwp7t35p140mblvttt0p9v85c/CAP/tcbn28hpcplusbwp7t35p140mblvttt0p9v85c_cap.cdev \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp7t35p140mbuhvt_150a/redhawk/tcbn28hpcplusbwp7t35p140mbuhvttt0p9v85c/CAP/tcbn28hpcplusbwp7t35p140mbuhvttt0p9v85c_cap.cdev \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp7t35p140opp_130c/redhawk/tcbn28hpcplusbwp7t35p140opptt0p9v85c/CAP/tcbn28hpcplusbwp7t35p140opptt0p9v85c_cap.cdev \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp7t35p140opphvt_130c/redhawk/tcbn28hpcplusbwp7t35p140opphvttt0p9v85c/CAP/tcbn28hpcplusbwp7t35p140opphvttt0p9v85c_cap.cdev \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp7t35p140opplvt_130c/redhawk/tcbn28hpcplusbwp7t35p140opplvttt0p9v85c/CAP/tcbn28hpcplusbwp7t35p140opplvttt0p9v85c_cap.cdev \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp7t40p140cghvt_160a/redhawk/tcbn28hpcplusbwp7t40p140cghvttt0p9v85c/CAP/tcbn28hpcplusbwp7t40p140cghvttt0p9v85c_cap.cdev \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp7t40p140ehvt_170a/redhawk/tcbn28hpcplusbwp7t40p140ehvttt0p9v85c/CAP/tcbn28hpcplusbwp7t40p140ehvttt0p9v85c_cap.cdev \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp7t40p140hvt_130c/redhawk/tcbn28hpcplusbwp7t40p140hvttt0p9v85c/CAP/tcbn28hpcplusbwp7t40p140hvttt0p9v85c_cap.cdev \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp7t40p140mb_150a/redhawk/tcbn28hpcplusbwp7t40p140mbtt0p9v85c/CAP/tcbn28hpcplusbwp7t40p140mbtt0p9v85c_cap.cdev \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp7t40p140mbhvt_150a/redhawk/tcbn28hpcplusbwp7t40p140mbhvttt0p9v85c/CAP/tcbn28hpcplusbwp7t40p140mbhvttt0p9v85c_cap.cdev \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp7t40p140mblvt_170a/redhawk/tcbn28hpcplusbwp7t40p140mblvttt0p9v85c/CAP/tcbn28hpcplusbwp7t40p140mblvttt0p9v85c_cap.cdev \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp7t40p140mbuhvt_150a/redhawk/tcbn28hpcplusbwp7t40p140mbuhvttt0p9v85c/CAP/tcbn28hpcplusbwp7t40p140mbuhvttt0p9v85c_cap.cdev \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp7t40p140opphvt_130c/redhawk/tcbn28hpcplusbwp7t40p140opphvttt0p9v85c/CAP/tcbn28hpcplusbwp7t40p140opphvttt0p9v85c_cap.cdev \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp7t40p140uhvt_140a/redhawk/tcbn28hpcplusbwp7t40p140uhvttt0p9v85c/CAP/tcbn28hpcplusbwp7t40p140uhvttt0p9v85c_cap.cdev  \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp35p140_110c/redhawk/tcbn28hpcplusbwp35p140tt0p9v85c/CURRENT/tcbn28hpcplusbwp35p140tt0p9v85c_current.spiprof \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp35p140hvt_110c/redhawk/tcbn28hpcplusbwp35p140hvttt0p9v85c/CURRENT/tcbn28hpcplusbwp35p140hvttt0p9v85c_current.spiprof \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp35p140lvt_110c/redhawk/tcbn28hpcplusbwp35p140lvttt0p9v85c/CURRENT/tcbn28hpcplusbwp35p140lvttt0p9v85c_current.spiprof \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp35p140mb_170a/redhawk/tcbn28hpcplusbwp35p140mbtt0p9v85c/CURRENT/tcbn28hpcplusbwp35p140mbtt0p9v85c_current.spiprof \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp35p140mbhvt_170a/redhawk/tcbn28hpcplusbwp35p140mbhvttt0p9v85c/CURRENT/tcbn28hpcplusbwp35p140mbhvttt0p9v85c_current.spiprof \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp35p140mblvt_170a/redhawk/tcbn28hpcplusbwp35p140mblvttt0p9v85c/CURRENT/tcbn28hpcplusbwp35p140mblvttt0p9v85c_current.spiprof \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp7t35p140_130c/redhawk/tcbn28hpcplusbwp7t35p140tt0p9v85c/CURRENT/tcbn28hpcplusbwp7t35p140tt0p9v85c_current.spiprof \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp7t35p140cg_160a/redhawk/tcbn28hpcplusbwp7t35p140cgtt0p9v85c/CURRENT/tcbn28hpcplusbwp7t35p140cgtt0p9v85c_current.spiprof \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp7t35p140cghvt_160a/redhawk/tcbn28hpcplusbwp7t35p140cghvttt0p9v85c/CURRENT/tcbn28hpcplusbwp7t35p140cghvttt0p9v85c_current.spiprof \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp7t35p140cglvt_160a/redhawk/tcbn28hpcplusbwp7t35p140cglvttt0p9v85c/CURRENT/tcbn28hpcplusbwp7t35p140cglvttt0p9v85c_current.spiprof \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp7t35p140cguhvt_160a/redhawk/tcbn28hpcplusbwp7t35p140cguhvttt0p9v85c/CURRENT/tcbn28hpcplusbwp7t35p140cguhvttt0p9v85c_current.spiprof \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp7t35p140hvt_130c/redhawk/tcbn28hpcplusbwp7t35p140hvttt0p9v85c/CURRENT/tcbn28hpcplusbwp7t35p140hvttt0p9v85c_current.spiprof \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp7t35p140lvt_130c/redhawk/tcbn28hpcplusbwp7t35p140lvttt0p9v85c/CURRENT/tcbn28hpcplusbwp7t35p140lvttt0p9v85c_current.spiprof \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp7t35p140mb_150a/redhawk/tcbn28hpcplusbwp7t35p140mbtt0p9v85c/CURRENT/tcbn28hpcplusbwp7t35p140mbtt0p9v85c_current.spiprof \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp7t35p140mbhvt_150a/redhawk/tcbn28hpcplusbwp7t35p140mbhvttt0p9v85c/CURRENT/tcbn28hpcplusbwp7t35p140mbhvttt0p9v85c_current.spiprof \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp7t35p140mblvt_170a/redhawk/tcbn28hpcplusbwp7t35p140mblvttt0p9v85c/CURRENT/tcbn28hpcplusbwp7t35p140mblvttt0p9v85c_current.spiprof \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp7t35p140mbuhvt_150a/redhawk/tcbn28hpcplusbwp7t35p140mbuhvttt0p9v85c/CURRENT/tcbn28hpcplusbwp7t35p140mbuhvttt0p9v85c_current.spiprof \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp7t35p140mbulvt_170a/redhawk/tcbn28hpcplusbwp7t35p140mbulvttt0p9v85c/CURRENT/tcbn28hpcplusbwp7t35p140mbulvttt0p9v85c_current.spiprof \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp7t35p140opp_130c/redhawk/tcbn28hpcplusbwp7t35p140opptt0p9v85c/CURRENT/tcbn28hpcplusbwp7t35p140opptt0p9v85c_current.spiprof \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp7t35p140opphvt_130c/redhawk/tcbn28hpcplusbwp7t35p140opphvttt0p9v85c/CURRENT/tcbn28hpcplusbwp7t35p140opphvttt0p9v85c_current.spiprof \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp7t35p140opplvt_130c/redhawk/tcbn28hpcplusbwp7t35p140opplvttt0p9v85c/CURRENT/tcbn28hpcplusbwp7t35p140opplvttt0p9v85c_current.spiprof \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp7t40p140cghvt_160a/redhawk/tcbn28hpcplusbwp7t40p140cghvttt0p9v85c/CURRENT/tcbn28hpcplusbwp7t40p140cghvttt0p9v85c_current.spiprof \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp7t40p140ehvt_170a/redhawk/tcbn28hpcplusbwp7t40p140ehvttt0p9v85c/CURRENT/tcbn28hpcplusbwp7t40p140ehvttt0p9v85c_current.spiprof \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp7t40p140hvt_130c/redhawk/tcbn28hpcplusbwp7t40p140hvttt0p9v85c/CURRENT/tcbn28hpcplusbwp7t40p140hvttt0p9v85c_current.spiprof \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp7t40p140mb_150a/redhawk/tcbn28hpcplusbwp7t40p140mbtt0p9v85c/CURRENT/tcbn28hpcplusbwp7t40p140mbtt0p9v85c_current.spiprof \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp7t40p140mbhvt_150a/redhawk/tcbn28hpcplusbwp7t40p140mbhvttt0p9v85c/CURRENT/tcbn28hpcplusbwp7t40p140mbhvttt0p9v85c_current.spiprof \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp7t40p140mblvt_170a/redhawk/tcbn28hpcplusbwp7t40p140mblvttt0p9v85c/CURRENT/tcbn28hpcplusbwp7t40p140mblvttt0p9v85c_current.spiprof \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp7t40p140mbuhvt_150a/redhawk/tcbn28hpcplusbwp7t40p140mbuhvttt0p9v85c/CURRENT/tcbn28hpcplusbwp7t40p140mbuhvttt0p9v85c_current.spiprof \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp7t40p140opphvt_130c/redhawk/tcbn28hpcplusbwp7t40p140opphvttt0p9v85c/CURRENT/tcbn28hpcplusbwp7t40p140opphvttt0p9v85c_current.spiprof \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp7t40p140uhvt_140a/redhawk/tcbn28hpcplusbwp7t40p140uhvttt0p9v85c/CURRENT/tcbn28hpcplusbwp7t40p140uhvttt0p9v85c_current.spiprof \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp35p140_110c/redhawk/tcbn28hpcplusbwp35p140tt0p9v85c/PWC/tcbn28hpcplusbwp35p140tt0p9v85c_pwc.pwcdev \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp35p140hvt_110c/redhawk/tcbn28hpcplusbwp35p140hvttt0p9v85c/PWC/tcbn28hpcplusbwp35p140hvttt0p9v85c_pwc.pwcdev \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp35p140lvt_110c/redhawk/tcbn28hpcplusbwp35p140lvttt0p9v85c/PWC/tcbn28hpcplusbwp35p140lvttt0p9v85c_pwc.pwcdev \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp35p140mb_170a/redhawk/tcbn28hpcplusbwp35p140mbtt0p9v85c/PWC/tcbn28hpcplusbwp35p140mbtt0p9v85c_pwc.pwcdev \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp35p140mbhvt_170a/redhawk/tcbn28hpcplusbwp35p140mbhvttt0p9v85c/PWC/tcbn28hpcplusbwp35p140mbhvttt0p9v85c_pwc.pwcdev \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp35p140mblvt_170a/redhawk/tcbn28hpcplusbwp35p140mblvttt0p9v85c/PWC/tcbn28hpcplusbwp35p140mblvttt0p9v85c_pwc.pwcdev \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp7t35p140_130c/redhawk/tcbn28hpcplusbwp7t35p140tt0p9v85c/PWC/tcbn28hpcplusbwp7t35p140tt0p9v85c_pwc.pwcdev \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp7t35p140cg_160a/redhawk/tcbn28hpcplusbwp7t35p140cgtt0p9v85c/PWC/tcbn28hpcplusbwp7t35p140cgtt0p9v85c_pwc.pwcdev \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp7t35p140cghvt_160a/redhawk/tcbn28hpcplusbwp7t35p140cghvttt0p9v85c/PWC/tcbn28hpcplusbwp7t35p140cghvttt0p9v85c_pwc.pwcdev \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp7t35p140cglvt_160a/redhawk/tcbn28hpcplusbwp7t35p140cglvttt0p9v85c/PWC/tcbn28hpcplusbwp7t35p140cglvttt0p9v85c_pwc.pwcdev \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp7t35p140cguhvt_160a/redhawk/tcbn28hpcplusbwp7t35p140cguhvttt0p9v85c/PWC/tcbn28hpcplusbwp7t35p140cguhvttt0p9v85c_pwc.pwcdev \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp7t35p140hvt_130c/redhawk/tcbn28hpcplusbwp7t35p140hvttt0p9v85c/PWC/tcbn28hpcplusbwp7t35p140hvttt0p9v85c_pwc.pwcdev \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp7t35p140lvt_130c/redhawk/tcbn28hpcplusbwp7t35p140lvttt0p9v85c/PWC/tcbn28hpcplusbwp7t35p140lvttt0p9v85c_pwc.pwcdev \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp7t35p140mb_150a/redhawk/tcbn28hpcplusbwp7t35p140mbtt0p9v85c/PWC/tcbn28hpcplusbwp7t35p140mbtt0p9v85c_pwc.pwcdev \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp7t35p140mbhvt_150a/redhawk/tcbn28hpcplusbwp7t35p140mbhvttt0p9v85c/PWC/tcbn28hpcplusbwp7t35p140mbhvttt0p9v85c_pwc.pwcdev \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp7t35p140mblvt_170a/redhawk/tcbn28hpcplusbwp7t35p140mblvttt0p9v85c/PWC/tcbn28hpcplusbwp7t35p140mblvttt0p9v85c_pwc.pwcdev \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp7t35p140mbuhvt_150a/redhawk/tcbn28hpcplusbwp7t35p140mbuhvttt0p9v85c/PWC/tcbn28hpcplusbwp7t35p140mbuhvttt0p9v85c_pwc.pwcdev \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp7t35p140mbulvt_170a/redhawk/tcbn28hpcplusbwp7t35p140mbulvttt0p9v85c/PWC/tcbn28hpcplusbwp7t35p140mbulvttt0p9v85c_pwc.pwcdev \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp7t35p140opp_130c/redhawk/tcbn28hpcplusbwp7t35p140opptt0p9v85c/PWC/tcbn28hpcplusbwp7t35p140opptt0p9v85c_pwc.pwcdev \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp7t35p140opphvt_130c/redhawk/tcbn28hpcplusbwp7t35p140opphvttt0p9v85c/PWC/tcbn28hpcplusbwp7t35p140opphvttt0p9v85c_pwc.pwcdev \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp7t35p140opplvt_130c/redhawk/tcbn28hpcplusbwp7t35p140opplvttt0p9v85c/PWC/tcbn28hpcplusbwp7t35p140opplvttt0p9v85c_pwc.pwcdev \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp7t40p140cghvt_160a/redhawk/tcbn28hpcplusbwp7t40p140cghvttt0p9v85c/PWC/tcbn28hpcplusbwp7t40p140cghvttt0p9v85c_pwc.pwcdev \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp7t40p140ehvt_170a/redhawk/tcbn28hpcplusbwp7t40p140ehvttt0p9v85c/PWC/tcbn28hpcplusbwp7t40p140ehvttt0p9v85c_pwc.pwcdev \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp7t40p140hvt_130c/redhawk/tcbn28hpcplusbwp7t40p140hvttt0p9v85c/PWC/tcbn28hpcplusbwp7t40p140hvttt0p9v85c_pwc.pwcdev \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp7t40p140mb_150a/redhawk/tcbn28hpcplusbwp7t40p140mbtt0p9v85c/PWC/tcbn28hpcplusbwp7t40p140mbtt0p9v85c_pwc.pwcdev \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp7t40p140mbhvt_150a/redhawk/tcbn28hpcplusbwp7t40p140mbhvttt0p9v85c/PWC/tcbn28hpcplusbwp7t40p140mbhvttt0p9v85c_pwc.pwcdev \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp7t40p140mblvt_170a/redhawk/tcbn28hpcplusbwp7t40p140mblvttt0p9v85c/PWC/tcbn28hpcplusbwp7t40p140mblvttt0p9v85c_pwc.pwcdev \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp7t40p140mbuhvt_150a/redhawk/tcbn28hpcplusbwp7t40p140mbuhvttt0p9v85c/PWC/tcbn28hpcplusbwp7t40p140mbuhvttt0p9v85c_pwc.pwcdev \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp7t40p140opphvt_130c/redhawk/tcbn28hpcplusbwp7t40p140opphvttt0p9v85c/PWC/tcbn28hpcplusbwp7t40p140opphvttt0p9v85c_pwc.pwcdev \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/redhawk/tcbn28hpcplusbwp7t40p140uhvt_140a/redhawk/tcbn28hpcplusbwp7t40p140uhvttt0p9v85c/PWC/tcbn28hpcplusbwp7t40p140uhvttt0p9v85c_pwc.pwcdev \
"


set LIB_FILE " \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Front_End/timing_power_noise/CCS/tcbn28hpcplusbwp7t35p140_180a/tcbn28hpcplusbwp7t35p140tt0p9v85c_ccs.lib \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Front_End/timing_power_noise/CCS/tcbn28hpcplusbwp7t35p140_180a/tcbn28hpcplusbwp7t35p140tt0p9v0p9v85c_ccs.lib \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Front_End/timing_power_noise/CCS/tcbn28hpcplusbwp7t40p140hvt_180a/tcbn28hpcplusbwp7t40p140hvttt0p9v0p9v85c_ccs.lib \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Front_End/timing_power_noise/CCS/tcbn28hpcplusbwp7t40p140cghvt_160a/tcbn28hpcplusbwp7t40p140cghvttt0p9v85c_ccs.lib \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Front_End/timing_power_noise/CCS/tcbn28hpcplusbwp7t35p140lvt_180a/tcbn28hpcplusbwp7t35p140lvttt0p9v85c_ccs.lib \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Front_End/timing_power_noise/CCS/tcbn28hpcplusbwp7t40p140hvt_180a/tcbn28hpcplusbwp7t40p140hvttt0p9v85c_ccs.lib \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Front_End/timing_power_noise/CCS/tcbn28hpcplusbwp7t35p140cg_160a/tcbn28hpcplusbwp7t35p140cgtt0p9v85c_ccs.lib \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Front_End/timing_power_noise/CCS/tcbn28hpcplusbwp7t35p140mb_170a/tcbn28hpcplusbwp7t35p140mbtt0p9v85c_ccs.lib \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Front_End/timing_power_noise/CCS/tcbn28hpcplusbwp7t35p140mblvt_170a/tcbn28hpcplusbwp7t35p140mblvttt0p9v85c_ccs.lib \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Front_End/timing_power_noise/CCS/tcbn28hpcplusbwp7t40p140mbhvt_170a/tcbn28hpcplusbwp7t40p140mbhvttt0p9v85c_ccs.lib \
/process/TSMC28/projects/CX200_A/frontend/memory/lib/sp128x12m2_tt_ctypical_0p90v_0p90v_85c.lib \
/process/TSMC28/projects/CX200_A/frontend/memory/lib/sp128x21m4_tt_ctypical_0p90v_0p90v_85c.lib \
/process/TSMC28/projects/CX200_A/frontend/memory/lib/sp8192x52bm16b2_tt_ctypical_0p90v_0p90v_85c.lib \
/process/TSMC28/projects/CX200_A/frontend/memory/lib/sp2048x32bm4b2_tt_ctypical_0p90v_0p90v_85c.lib \
/process/TSMC28/projects/CX200_A/frontend/memory/lib/sp64x32m2_tt_ctypical_0p90v_0p90v_85c.lib \
/process/TSMC28/projects/CX200_A/frontend/memory/lib/sp64x24m2_tt_ctypical_0p90v_0p90v_85c.lib \
/process/TSMC28/projects/CX200_A/frontend/memory/lib/sp8192x32bm16b2_tt_ctypical_0p90v_0p90v_85c.lib \
/process/TSMC28/projects/CX200_A/frontend/memory/lib/sp768x64bm4_tt_ctypical_0p90v_0p90v_85c.lib \
/process/TSMC28/projects/CX200_A/frontend/memory/lib/rom1024x13m8_tt_ctypical_0p90v_0p90v_85c.lib \
/process/TSMC28/projects/CX200_A/frontend/memory/lib/dp8x144m1_tt_ctypical_0p90v_0p90v_85c.lib \
/process/TSMC28/projects/CX200_A/frontend/memory/lib/sp1024x32m4_tt_ctypical_0p90v_0p90v_85c.lib \
/process/TSMC28/projects/CX200_A/frontend/memory/lib/sp256x32m4_tt_ctypical_0p90v_0p90v_85c.lib \
/process/TSMC28/projects/CX200_A/frontend/memory/lib/sp64x4bm4_tt_ctypical_0p90v_0p90v_85c.lib \
/process/TSMC28/projects/CX200_A/frontend/memory/lib/sp256x24m2_tt_ctypical_0p90v_0p90v_85c.lib \
/process/TSMC28/projects/CX200_A/frontend/memory/lib/sp64x26m2_tt_ctypical_0p90v_0p90v_85c.lib \
/process/TSMC28/projects/CX200_A/frontend/memory/lib/sp256x16m2_tt_ctypical_0p90v_0p90v_85c.lib \
/process/TSMC28/projects/CX200_A/frontend/memory/lib/dp32x144m1_tt_ctypical_0p90v_0p90v_85c.lib \
/process/TSMC28/projects/CX200_A/frontend/memory/lib/dp128x80m1_tt_ctypical_0p90v_0p90v_85c.lib \
/process/TSMC28/projects/CX200_A/frontend/memory/lib/rom10240x32m16_tt_ctypical_0p90v_0p90v_85c.lib \
/process/TSMC28/projects/CX200_A/frontend/memory/lib/sp512x32bm4_tt_ctypical_0p90v_0p90v_85c.lib \
/process/TSMC28/projects/CX200_A/frontend/memory/lib/sp2048x40m8_tt_ctypical_0p90v_0p90v_85c.lib \
/process/TSMC28/projects/CX200_A/frontend/memory/lib/dp256x40m1_tt_ctypical_0p90v_0p90v_85c.lib \
/process/TSMC28/projects/CX200_A/frontend/memory/lib/sp4096x32bm8b2_tt_ctypical_0p90v_0p90v_85c.lib \
/process/TSMC28/projects/CX200_A/frontend/memory/lib/dp32x32m1_tt_ctypical_0p90v_0p90v_85c.lib \
/process/TSMC28/projects/CX200_A/frontend/memory/lib/sp64x30m2_tt_ctypical_0p90v_0p90v_85c.lib \
/process/TSMC28/projects/CX200_A/frontend/memory/lib/dp256x32m4_tt_ctypical_0p90v_0p90v_85c.lib \
/process/TSMC28/projects/CX200_A/frontend/memory/lib/sp256x28m2_tt_ctypical_0p90v_0p90v_85c.lib \
/process/TSMC28/projects/CX200_A/frontend/memory/lib/sp64x22m2_tt_ctypical_0p90v_0p90v_85c.lib \
/process/TSMC28/projects/CX200_A/frontend/memory/lib/sp256x12m2_tt_ctypical_0p90v_0p90v_85c.lib \
/process/TSMC28/projects/CX200_A/frontend/memory/lib/sp256x36m2_tt_ctypical_0p90v_0p90v_85c.lib \
/process/TSMC28/projects/CX200_A/frontend/memory/lib/sp256x40m2_tt_ctypical_0p90v_0p90v_85c.lib \
/process/TSMC28/projects/CX200_A/frontend/memory/lib/rom4096x32m16_tt_ctypical_0p90v_0p90v_85c.lib \
/process/TSMC28/projects/CX200_A/frontend/memory/lib/rf2p32x128m1_tt_ctypical_0p90v_0p90v_85c.lib \
/process/TSMC28/projects/CX200_A/frontend/memory/lib/rf2p128x30m1_tt_ctypical_0p90v_0p90v_85c.lib \
/process/TSMC28/projects/CX200_A/frontend/memory/lib/rf2p128x32m1_tt_ctypical_0p90v_0p90v_85c.lib \
/process/TSMC28/projects/CX200_A/frontend/memory/lib/rf2p128x24m1_tt_ctypical_0p90v_0p90v_85c.lib \
/process/TSMC28/projects/CX200_A/frontend/memory/lib/rf2p128x26m1_tt_ctypical_0p90v_0p90v_85c.lib \
/process/TSMC28/projects/CX200_A/frontend/memory/lib/rf2p256x12m1_tt_ctypical_0p90v_0p90v_85c.lib \
/process/TSMC28/projects/CX200_A/frontend/memory/lib/rf2p128x22m1_tt_ctypical_0p90v_0p90v_85c.lib \
/process/TSMC28/projects/CX200_A/frontend/memory/lib/ts3n28hpcpa32x128m8fs_130a_tt0p9v85c.lib \
/process/TSMC28/projects/CX200_A/frontend/memory/lib/ts3n28hpcpa32x126m8fs_130a_tt0p9v85c.lib \
/process/TSMC28/IO/TSMCHOME/digital/Front_End/timing_power_noise/NLDM/tphn28hpcpgv2od3_210a/tphn28hpcpgv2od3tt0p9v3p3v85c.lib \
/process/TSMC28/MEM/efuse/0105876_tef28hpcp64x32hd18_phrm_140a_20221115/tef28hpcp64x32hd18_phrm_140a_nldm/TSMCHOME/efuse/Front_End/timing_power_noise/NLDM/tef28hpcp64x32hd18_phrm_140a/tef28hpcp64x32hd18_phrm_140a_tt0p9v1p8v85c.lib \
"

set LEF_FILE " \
/local_disk/home/user2/project/CX200/lib_conf/tlef/tsmcn28_8lm5X1Z1URDL.tlef \
/process/TSMC28/IO/TSMCHOME/digital/Back_End/lef/tphn28hpcpgv18_110a/mt_2/8lm/lef/tphn28hpcpgv18_8lm.lef \
/process/TSMC28/IO/TSMCHOME/digital/Back_End/lef/tphn28hpcpgv2od3_210a/mt_2/8m/8M_5X2Z/lef/tphn28hpcpgv2od3_8lm.lef \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/lef/tcbn28hpcplusbwp7t35p140_110a/lef/tcbn28hpcplusbwp7t35p140.lef \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/lef/tcbn28hpcplusbwp7t40p140hvt_110a/lef/tcbn28hpcplusbwp7t40p140hvt.lef \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/lef/tcbn28hpcplusbwp7t40p140cghvt_160a/lef/tcbn28hpcplusbwp7t40p140cghvt.lef \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/lef/tcbn28hpcplusbwp7t35p140lvt_110a/lef/tcbn28hpcplusbwp7t35p140lvt.lef \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/lef/tcbn28hpcplusbwp7t35p140cg_160a/lef/tcbn28hpcplusbwp7t35p140cg.lef \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/lef/tcbn28hpcplusbwp7t35p140mb_150a/lef/tcbn28hpcplusbwp7t35p140mb.lef \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/lef/tcbn28hpcplusbwp7t35p140mblvt_150a/lef/tcbn28hpcplusbwp7t35p140mblvt.lef \
/process/TSMC28/STD/tcbn28hpc/TSMCHOME/digital/Back_End/lef/tcbn28hpcplusbwp7t40p140mbhvt_150a/lef/tcbn28hpcplusbwp7t40p140mbhvt.lef \
/process/TSMC28/projects/CX200_A/frontend/memory/lef/sp2048x32bm4b2.lef \
/process/TSMC28/projects/CX200_A/frontend/memory/lef/ts3n28hpcpa32x126m8fs_130a.lef \
/process/TSMC28/projects/CX200_A/frontend/memory/lef/sp64x30m2.lef \
/process/TSMC28/projects/CX200_A/frontend/memory/lef/sp1024x32m4.lef \
/process/TSMC28/projects/CX200_A/frontend/memory/lef/dp32x144m1.lef \
/process/TSMC28/projects/CX200_A/frontend/memory/lef/sp64x22m2.lef \
/process/TSMC28/projects/CX200_A/frontend/memory/lef/ts3n28hpcpa32x128m8fs_130a.lef \
/process/TSMC28/projects/CX200_A/frontend/memory/lef/sp64x32m2.lef \
/process/TSMC28/projects/CX200_A/frontend/memory/lef/sp64x24m2.lef \
/process/TSMC28/projects/CX200_A/frontend/memory/lef/dp256x40m1.lef \
/process/TSMC28/projects/CX200_A/frontend/memory/lef/sp64x26m2.lef \
/process/TSMC28/projects/CX200_A/frontend/memory/lef/dp128x80m1.lef \
/process/TSMC28/projects/CX200_A/frontend/memory/lef/sp768x64bm4.lef \
/process/TSMC28/projects/CX200_A/frontend/memory/lef/sp4096x32bm8b2.lef \
/process/TSMC28/projects/CX200_A/frontend/memory/lef/dp256x32m4.lef \
/process/TSMC28/projects/CX200_A/frontend/memory/lef/sp2048x40m8.lef \
/process/TSMC28/projects/CX200_A/frontend/memory/lef/dp32x32m1.lef \
/process/TSMC28/projects/CX200_A/frontend/memory/lef/rom10240x32m16.lef \
/process/TSMC28/projects/CX200_A/frontend/memory/lef/rom1024x13m8.lef \
/process/TSMC28/projects/CX200_A/frontend/memory/lef/sp128x12m2.lef \
/process/TSMC28/projects/CX200_A/frontend/memory/lef/sp128x21m4.lef \
/process/TSMC28/projects/CX200_A/frontend/memory/lef/sp256x12m2.lef \
/process/TSMC28/projects/CX200_A/frontend/memory/lef/sp512x32bm4.lef \
/process/TSMC28/projects/CX200_A/frontend/memory/lef/dp8x144m1.lef \
/process/TSMC28/projects/CX200_A/frontend/memory/lef/sp64x4bm4.lef \
/process/TSMC28/projects/CX200_A/frontend/memory/lef/sp256x24m2.lef \
/process/TSMC28/projects/CX200_A/frontend/memory/lef/sp8192x32bm16b2.lef \
/process/TSMC28/projects/CX200_A/frontend/memory/lef/sp256x32m4.lef \
/process/TSMC28/projects/CX200_A/frontend/memory/lef/sp256x16m2.lef \
/process/TSMC28/projects/CX200_A/frontend/memory/lef/sp8192x52bm16b2.lef \
/process/TSMC28/projects/CX200_A/frontend/memory/lef/sp256x28m2.lef \
/process/TSMC28/projects/CX200_A/frontend/memory/lef/sp256x36m2.lef \
/process/TSMC28/projects/CX200_A/frontend/memory/lef/sp256x40m2.lef \
/process/TSMC28/projects/CX200_A/frontend/memory/lef/rom4096x32m16.lef \
/process/TSMC28/projects/CX200_A/frontend/memory/lef/rf2p32x128m1.lef \
/process/TSMC28/projects/CX200_A/frontend/memory/lef/rf2p128x30m1.lef \
/process/TSMC28/projects/CX200_A/frontend/memory/lef/rf2p128x32m1.lef \
/process/TSMC28/projects/CX200_A/frontend/memory/lef/rf2p128x22m1.lef \
/process/TSMC28/projects/CX200_A/frontend/memory/lef/rf2p256x12m1.lef \
/process/TSMC28/projects/CX200_A/frontend/memory/lef/rf2p128x24m1.lef \
/process/TSMC28/projects/CX200_A/frontend/memory/lef/rf2p128x26m1.lef \
/process/TSMC28/PDK/tn28cldr002_2_1/N28_TCD_library_kits_20110323/N28_TCD_library_kits_20110323/lef/FEOL/N28_DMY_TCD_FH_20100614.lef \
/process/TSMC28/PDK/tn28cldr002_2_1/N28_TCD_library_kits_20110323/N28_TCD_library_kits_20110323/lef/BEOL_MX_5X/BEOL_small_FDM6_20110323.lef \
/process/TSMC28/PDK/tn28cldr002_2_1/N28_TCD_library_kits_20110323/N28_TCD_library_kits_20110323/lef/BEOL_MX_5X/BEOL_small_FDM5_20110323.lef \
/process/TSMC28/PDK/tn28cldr002_2_1/N28_TCD_library_kits_20110323/N28_TCD_library_kits_20110323/lef/BEOL_MX_5X/BEOL_small_FDM4_20110323.lef \
/process/TSMC28/PDK/tn28cldr002_2_1/N28_TCD_library_kits_20110323/N28_TCD_library_kits_20110323/lef/BEOL_MX_5X/BEOL_small_FDM3_20110323.lef \
/process/TSMC28/PDK/tn28cldr002_2_1/N28_TCD_library_kits_20110323/N28_TCD_library_kits_20110323/lef/BEOL_MX_5X/BEOL_small_FDM2_20110323.lef \
/process/TSMC28/PDK/tn28cldr002_2_1/N28_TCD_library_kits_20110323/N28_TCD_library_kits_20110323/lef/BEOL_MX_5X/BEOL_small_FDM1_20110323.lef \
/process/TSMC28/MEM/efuse/0105876_tef28hpcpesd_p_130c_20221115/tef28hpcpesd_p_130c_sef/TSMCHOME/efuse/Back_End/lef/tef28hpcpesd_p_130c/lef/tef28hpcpesd_p_130c_4lm.lef \
/process/TSMC28/MEM/efuse/0105876_tef28hpcp64x32hd18_phrm_140a_20221115/tef28hpcp64x32hd18_phrm_120a_sef/TSMCHOME/efuse/Back_End/lef/tef28hpcp64x32hd18_phrm_120a/lef/tef28hpcp64x32hd18_phrm_120a_5lm.lef \
"


### mkdir pa dir ##############################
exec mkdir -p ./PA_$VERSION/Dynamic
exec mkdir -p ./PA_$VERSION/Dynamic_vcd_coremark
exec mkdir -p ./PA_$VERSION/Dynamic_vcd_aon_psw
exec mkdir -p ./PA_$VERSION/Dynamic_vcd_dbb_trx
exec mkdir -p ./PA_$VERSION/Dynamic_vcd_mbist
exec mkdir -p ./PA_$VERSION/Dynamic_vcd_sa
exec mkdir -p ./PA_$VERSION/Dynamic_vcd_ac
exec mkdir -p ./PA_$VERSION/Static
exec mkdir -p ./PA_$VERSION/gridcheck
exec mkdir -p ./PA_$VERSION/SignalEM
exec mkdir -p ./PA_$VERSION/scr

###mkdir pa csh ##############################
set  OP_static_csh        [open  ./PA_$VERSION/Static/do_static.csh                 w]
set  OP_dynamic_csh       [open  ./PA_$VERSION/Dynamic/do_Dynamic.csh               w]
set  OP_vcd_coremark_csh  [open  ./PA_$VERSION/Dynamic_vcd_coremark/do_Dynamic.csh  w]
set  OP_vcd_dbb_trx_csh   [open  ./PA_$VERSION/Dynamic_vcd_dbb_trx/do_Dynamic.csh   w]
set  OP_vcd_aon_psw_csh   [open  ./PA_$VERSION/Dynamic_vcd_aon_psw/do_Dynamic.csh   w]
set  OP_vcd_mbist_csh     [open  ./PA_$VERSION/Dynamic_vcd_mbist/do_Dynamic.csh     w]
set  OP_vcd_sa_csh        [open  ./PA_$VERSION/Dynamic_vcd_sa/do_Dynamic.csh        w]
set  OP_vcd_ac_csh        [open  ./PA_$VERSION/Dynamic_vcd_ac/do_Dynamic.csh        w]
set  OP_signalEM_csh      [open  ./PA_$VERSION/SignalEM/do_SignalEM.csh             w]

###create pa csh ##############################
puts  $OP_static_csh        "redhawk  -f  ../scr/do_Static.rhwk"
puts  $OP_dynamic_csh       "redhawk  -f  ../scr/do_Dynamic.rhwk"
puts  $OP_vcd_coremark_csh  "redhawk  -f  ../scr/do_Dynamic_vcd_coremark.rhwk"
puts  $OP_vcd_dbb_trx_csh   "redhawk  -f  ../scr/do_Dynamic_vcd_dbb_trx.rhwk"
puts  $OP_vcd_aon_psw_csh   "redhawk  -f  ../scr/do_Dynamic_vcd_aon_psw.rhwk"
puts  $OP_vcd_mbist_csh     "redhawk  -f  ../scr/do_Dynamic_vcd_mbist.rhwk"
puts  $OP_vcd_sa_csh        "redhawk  -f  ../scr/do_Dynamic_vcd_sa.rhwk"
puts  $OP_vcd_ac_csh        "redhawk  -f  ../scr/do_Dynamic_vcd_ac.rhwk"
puts  $OP_signalEM_csh      "redhawk  -f  ../scr/do_Signal_EM.rhwk"

### mkdir pa file 
set  OP_dvd_gsr               [open  ./PA_$VERSION/scr/do_Dynamic.gsr                w]
set  OP_dvd_rh                [open  ./PA_$VERSION/scr/do_Dynamic.rhwk               w]
set  OP_dvd_vcd_coremark_gsr  [open  ./PA_$VERSION/scr/do_Dynamic_vcd_coremark.gsr   w]
set  OP_dvd_vcd_aon_psw_gsr   [open  ./PA_$VERSION/scr/do_Dynamic_vcd_aon_psw.gsr    w]
set  OP_dvd_vcd_dbb_trx_gsr   [open  ./PA_$VERSION/scr/do_Dynamic_vcd_dbb_trx.gsr    w]
set  OP_dvd_vcd_mbist_gsr     [open  ./PA_$VERSION/scr/do_Dynamic_vcd_mbist.gsr      w]
set  OP_dvd_vcd_sa_gsr        [open  ./PA_$VERSION/scr/do_Dynamic_vcd_sa.gsr         w]
set  OP_dvd_vcd_ac_gsr        [open  ./PA_$VERSION/scr/do_Dynamic_vcd_ac.gsr         w]
set  OP_dvd_vcd_coremark_rh   [open  ./PA_$VERSION/scr/do_Dynamic_vcd_coremark.rhwk  w]
set  OP_dvd_vcd_aon_psw_rh    [open  ./PA_$VERSION/scr/do_Dynamic_vcd_aon_psw.rhwk   w]
set  OP_dvd_vcd_dbb_trx_rh    [open  ./PA_$VERSION/scr/do_Dynamic_vcd_dbb_trx.rhwk   w]
set  OP_dvd_vcd_mbist_rh      [open  ./PA_$VERSION/scr/do_Dynamic_vcd_mbist.rhwk     w]
set  OP_dvd_vcd_sa_rh         [open  ./PA_$VERSION/scr/do_Dynamic_vcd_sa.rhwk        w]
set  OP_dvd_vcd_ac_rh         [open  ./PA_$VERSION/scr/do_Dynamic_vcd_ac.rhwk        w]
set  OP_Static_gsr            [open  ./PA_$VERSION/scr/do_Static.gsr                 w]
set  OP_Static_rh             [open  ./PA_$VERSION/scr/do_Static.rhwk                w]
set  OP_gridcheck_gsr         [open  ./PA_$VERSION/scr/do_Gridcheck.gsr              w]
set  OP_gridcheck_rh          [open  ./PA_$VERSION/scr/do_Gridcheck.rhwk             w]
set  OP_Signal_EM_gsr         [open  ./PA_$VERSION/scr/do_Signal_EM.gsr              w]
set  OP_Signal_EM_rh          [open  ./PA_$VERSION/scr/do_Signal_EM.rhwk             w]

### out gsr proc ##################################
proc out_gsr {var} {
	global OP_dvd_gsr
	global OP_dvd_vcd_coremark_gsr
	global OP_dvd_vcd_aon_psw_gsr
	global OP_dvd_vcd_dbb_trx_gsr
	global OP_dvd_vcd_mbist_gsr
	global OP_dvd_vcd_sa_gsr
	global OP_dvd_vcd_ac_gsr
	global OP_Static_gsr
	global OP_gridcheck_gsr
	global OP_Signal_EM_gsr
	puts $OP_dvd_gsr $var
	puts $OP_dvd_vcd_coremark_gsr $var
	puts $OP_dvd_vcd_aon_psw_gsr $var
	puts $OP_dvd_vcd_dbb_trx_gsr $var
	puts $OP_dvd_vcd_mbist_gsr $var
	puts $OP_dvd_vcd_sa_gsr $var
	puts $OP_dvd_vcd_ac_gsr $var
	puts $OP_Static_gsr $var
	puts $OP_gridcheck_gsr $var
	puts $OP_Signal_EM_gsr $var
}

#### create rhwk ####################################
#### create Dynamic rhwk ###########################
puts $OP_dvd_rh "setup analysis_mode dynamic"
puts $OP_dvd_rh "import gsr ../scr/do_Dynamic.gsr"
puts $OP_dvd_rh "setup design"
puts $OP_dvd_rh "\n"
puts $OP_dvd_rh "perform pwrcalc"
puts $OP_dvd_rh "perform extraction -power -ground -l -c"
puts $OP_dvd_rh "perform analysis -vectorless"
puts $OP_dvd_rh "perform emcheck -mode avg"
puts $OP_dvd_rh "explore design"
puts $OP_dvd_rh "export db Dynamic_design.db"

### create Dynamic VCD rhwk #######################
puts $OP_dvd_vcd_coremark_rh "setup analysis_mode dynamic"
puts $OP_dvd_vcd_coremark_rh "import gsr ../scr/do_Dynamic_vcd_coremark.gsr"
puts $OP_dvd_vcd_coremark_rh "setup design"
puts $OP_dvd_vcd_coremark_rh "\n"
puts $OP_dvd_vcd_coremark_rh "perform pwrcalc"
puts $OP_dvd_vcd_coremark_rh "perform extraction -power -ground -l -c"
puts $OP_dvd_vcd_coremark_rh "perform analysis -vcd"
puts $OP_dvd_vcd_coremark_rh "perform emcheck -mode avg"
puts $OP_dvd_vcd_coremark_rh "explore design"
puts $OP_dvd_vcd_coremark_rh "export db Dynamic_design.db"

### create Dynamic VCD rhwk #######################
puts $OP_dvd_vcd_aon_psw_rh "setup analysis_mode dynamic"
puts $OP_dvd_vcd_aon_psw_rh "import gsr ../scr/do_Dynamic_vcd_aon_psw.gsr"
puts $OP_dvd_vcd_aon_psw_rh "setup design"
puts $OP_dvd_vcd_aon_psw_rh "\n"
puts $OP_dvd_vcd_aon_psw_rh "perform pwrcalc"
puts $OP_dvd_vcd_aon_psw_rh "perform extraction -power -ground -l -c"
puts $OP_dvd_vcd_aon_psw_rh "perform analysis -vcd"
puts $OP_dvd_vcd_aon_psw_rh "perform emcheck -mode avg"
puts $OP_dvd_vcd_aon_psw_rh "explore design"
puts $OP_dvd_vcd_aon_psw_rh "export db Dynamic_design.db"

### create Dynamic VCD rhwk #######################
puts $OP_dvd_vcd_dbb_trx_rh "setup analysis_mode dynamic"
puts $OP_dvd_vcd_dbb_trx_rh "import gsr ../scr/do_Dynamic_vcd_dbb_trx.gsr"
puts $OP_dvd_vcd_dbb_trx_rh "setup design"
puts $OP_dvd_vcd_dbb_trx_rh "\n"
puts $OP_dvd_vcd_dbb_trx_rh "perform pwrcalc"
puts $OP_dvd_vcd_dbb_trx_rh "perform extraction -power -ground -l -c"
puts $OP_dvd_vcd_dbb_trx_rh "perform analysis -vcd"
puts $OP_dvd_vcd_dbb_trx_rh "perform emcheck -mode avg"
puts $OP_dvd_vcd_dbb_trx_rh "explore design"
puts $OP_dvd_vcd_dbb_trx_rh "export db Dynamic_design.db"

### create Dynamic VCD rhwk #######################
puts $OP_dvd_vcd_mbist_rh "setup analysis_mode dynamic"
puts $OP_dvd_vcd_mbist_rh "import gsr ../scr/do_Dynamic_vcd_mbist.gsr"
puts $OP_dvd_vcd_mbist_rh "setup design"
puts $OP_dvd_vcd_mbist_rh "\n"
puts $OP_dvd_vcd_mbist_rh "perform pwrcalc"
puts $OP_dvd_vcd_mbist_rh "perform extraction -power -ground -l -c"
puts $OP_dvd_vcd_mbist_rh "perform analysis -vcd"
puts $OP_dvd_vcd_mbist_rh "perform emcheck -mode avg"
puts $OP_dvd_vcd_mbist_rh "explore design"
puts $OP_dvd_vcd_mbist_rh "export db Dynamic_design.db"

### create Dynamic VCD rhwk #######################
puts $OP_dvd_vcd_sa_rh "setup analysis_mode dynamic"
puts $OP_dvd_vcd_sa_rh "import gsr ../scr/do_Dynamic_vcd_sa.gsr"
puts $OP_dvd_vcd_sa_rh "setup design"
puts $OP_dvd_vcd_sa_rh "\n"
puts $OP_dvd_vcd_sa_rh "perform pwrcalc"
puts $OP_dvd_vcd_sa_rh "perform extraction -power -ground -l -c"
puts $OP_dvd_vcd_sa_rh "perform analysis -vcd"
puts $OP_dvd_vcd_sa_rh "perform emcheck -mode avg"
puts $OP_dvd_vcd_sa_rh "explore design"
puts $OP_dvd_vcd_sa_rh "export db Dynamic_design.db"

### create Dynamic VCD rhwk #######################
puts $OP_dvd_vcd_ac_rh "setup analysis_mode dynamic"
puts $OP_dvd_vcd_ac_rh "import gsr ../scr/do_Dynamic_vcd_ac.gsr"
puts $OP_dvd_vcd_ac_rh "setup design"
puts $OP_dvd_vcd_ac_rh "\n"
puts $OP_dvd_vcd_ac_rh "perform pwrcalc"
puts $OP_dvd_vcd_ac_rh "perform extraction -power -ground -l -c"
puts $OP_dvd_vcd_ac_rh "perform analysis -vcd"
puts $OP_dvd_vcd_ac_rh "perform emcheck -mode avg"
puts $OP_dvd_vcd_ac_rh "explore design"
puts $OP_dvd_vcd_ac_rh "export db Dynamic_design.db"

### create Static rhwk ########################### 
puts $OP_Static_rh "setup analysis_mode static"
puts $OP_Static_rh "import gsr ../scr/do_Static.gsr"
puts $OP_Static_rh "setup design"
puts $OP_Static_rh "\n"
puts $OP_Static_rh "perform pwrcalc"
puts $OP_Static_rh "perform extraction -power -ground"
puts $OP_Static_rh "perform analysis -static"
puts $OP_Static_rh "perform emcheck -mode avg"
puts $OP_Static_rh "explore design"
puts $OP_Static_rh "export db Static_design.db"

### create gridcheck rhwk ########################
puts $OP_gridcheck_rh "setup analysis_mode static"
puts $OP_gridcheck_rh "import gsr ../scr/do_gridcheck.gsr"
puts $OP_gridcheck_rh "setup design"
puts $OP_gridcheck_rh "\n"
puts $OP_gridcheck_rh "perform pwrcalc"
puts $OP_gridcheck_rh "perform extraction -power -ground -l -c"
puts $OP_gridcheck_rh "perform gridcheck -limit 10000000 -stdcell min -macro none -allPintype -excludeDecap -o grid_check.rpt"
puts $OP_gridcheck_rh "perform emcheck -mode avg"
puts $OP_gridcheck_rh "explore design"
puts $OP_gridcheck_rh "export db gridcheck_design.db"

### create SignalEM rhwk ##########################
puts $OP_Signal_EM_rh "setup analysis_mode signalEM"
puts $OP_Signal_EM_rh "import gsr ../scr/do_Signal_EM.gsr"
puts $OP_Signal_EM_rh "setup design"
puts $OP_Signal_EM_rh "\n"
puts $OP_Signal_EM_rh "perform pwrcalc"
puts $OP_Signal_EM_rh "perform extraction -signal"
puts $OP_Signal_EM_rh "perform analysis -signalEM"
puts $OP_Signal_EM_rh "perform emcheck"
puts $OP_Signal_EM_rh "explore design"
puts $OP_Signal_EM_rh "export db SignalEM_design.db"


############################################################
#### user Defines common setting varibale ##################
###########################################################
out_gsr "###define process"
out_gsr "TECHNOLOGY 	$TECHNOLOGY"
out_gsr "\n"
out_gsr "FREQ		${FREQUENCY}e6"
out_gsr "DYNAMIC_SIMULATION_TIME 8.0e-9"
out_gsr "DYNAMIC_TIME_STEP 20e-12"
out_gsr "DYNAMIC_SAVE_WAVEFORM 2"
out_gsr "#Defines the default goggle rate of the nets on the chip"
out_gsr "\n"
out_gsr "TOGGLE_RATE $SIGNAL_RATE $CLOCK_RATE"
out_gsr "\n"
out_gsr "TEMPERATURE $TEMPERATURE"
out_gsr "TEMPERATURE_EM 110"
out_gsr "USE_DEF_VIARULE 1"
out_gsr "EXTRACT_INTERNAL_NET 1"
out_gsr "REXTRACTION_DETAIL_LEVEL 1"
out_gsr "VIA_COMPRESS 0"
out_gsr "IGNORE_LEF_DEF_MISMATCH 1"
out_gsr "IGNORE_DEF_ERROR 1"
out_gsr "IGNORE_PGARC_ERROR 1"
out_gsr "LIB2AVM 1"
out_gsr "\n"

out_gsr "#### EM setting #################################"
out_gsr "EM_LENGTH_USE_MAX_LENGTH 1"
out_gsr "USE_DRAWN_WIDTH_FOR_EM 1"
out_gsr "USE_DRAWN_WIDTH_FOR_EM_LOOKUP 1"
out_gsr "EM_MODE avg"
out_gsr "EM_REPORT_LINE_NUMBER -1 "
out_gsr "EM_REPORT_PERCENTAGE 100"

out_gsr "\n"
out_gsr "DELTA_T_RMS_EM 5"
out_gsr "POWER_MODE APL"
out_gsr "SCALE_CLOCK_POWER 0"
out_gsr "ITR_OVERRIDE_BPFS 1"
out_gsr "APL_MODE 4"
out_gsr "APL_INTERPOLATION_METHOD 4"
out_gsr "\n"
out_gsr "### GDS2DEF"
out_gsr "IGNORE_UNDEFINED_LAYER 1"
out_gsr "GDS_CELLS {"
out_gsr "PVDD2DGZ_V /home/user2/project/cx200/pa/gds2def/def"
out_gsr "PVSS1DGZ_V /home/user2/project/cx200/pa/gds2def/def"
out_gsr "PVDD1DGZ_V /home/user2/project/cx200/pa/gds2def/def"
out_gsr "PVSS2DGZ_V /home/user2/project/cx200/pa/gds2def/def"
out_gsr "PENDCAP /home/user2/project/cx200/pa/gds2def/def"
out_gsr "PVDD2DGZ_H /home/user2/project/cx200/pa/gds2def/def"
out_gsr "PVSS1DGZ_H /home/user2/project/cx200/pa/gds2def/def"
out_gsr "PVDD1DGZ_H /home/user2/project/cx200/pa/gds2def/def"
out_gsr "PVSS2DGZ_H /home/user2/project/cx200/pa/gds2def/def"
out_gsr "PVDD2POC_H /home/user2/project/cx200/pa/gds2def/def"
out_gsr "PFILLER10 /home/user2/project/cx200/pa/gds2def/def"
out_gsr "PDDW08DGZ_H /home/user2/project/cx200/pa/gds2def/def"
out_gsr "PDDW16DGZ_H /home/user2/project/cx200/pa/gds2def/def"
out_gsr "PDDW08DGZ_V /home/user2/project/cx200/pa/gds2def/def"
out_gsr "PDDW08SDGZ_V /home/user2/project/cx200/pa/gds2def/def"
out_gsr "PDUW04SDGZ_H /home/user2/project/cx200/pa/gds2def/def"
out_gsr "PDDW04SDGZ_H /home/user2/project/cx200/pa/gds2def/def"
out_gsr "}"
out_gsr "\n"


##### VCD file #############
if {$coremark_FSDB != ""} {
	puts $OP_dvd_vcd_coremark_gsr "VCD_FILE {"
        puts $OP_dvd_vcd_coremark_gsr "$CHIP_NAME $coremark_FSDB"
        puts $OP_dvd_vcd_coremark_gsr "FILE_TYPE FSDB"
        puts $OP_dvd_vcd_coremark_gsr "FRONT_PATH $SCOPE"
        puts $OP_dvd_vcd_coremark_gsr "SELECT_TYPE WORST_POWER_CYCLE"
        puts $OP_dvd_vcd_coremark_gsr "SELECT_RANGE -1 -1"
        puts $OP_dvd_vcd_coremark_gsr "TRUE_TIME $FSDB_TIMING"
	puts $OP_dvd_vcd_coremark_gsr "}"
}

if {$aon_psw_FSDB != ""} {
	puts $OP_dvd_vcd_aon_psw_gsr "VCD_FILE {"
        puts $OP_dvd_vcd_aon_psw_gsr "$CHIP_NAME $aon_psw_FSDB"
        puts $OP_dvd_vcd_aon_psw_gsr "FILE_TYPE FSDB"
        puts $OP_dvd_vcd_aon_psw_gsr "FRONT_PATH $SCOPE"
        puts $OP_dvd_vcd_aon_psw_gsr "SELECT_TYPE WORST_POWER_CYCLE"
        puts $OP_dvd_vcd_aon_psw_gsr "SELECT_RANGE -1 -1"
        puts $OP_dvd_vcd_aon_psw_gsr "TRUE_TIME $FSDB_TIMING"
	puts $OP_dvd_vcd_aon_psw_gsr "}"
}

if {$dbb_trx_FSDB != ""} {
	puts $OP_dvd_vcd_dbb_trx_gsr "VCD_FILE {"
        puts $OP_dvd_vcd_dbb_trx_gsr "$CHIP_NAME $dbb_trx_FSDB"
        puts $OP_dvd_vcd_dbb_trx_gsr "FILE_TYPE FSDB"
        puts $OP_dvd_vcd_dbb_trx_gsr "FRONT_PATH $SCOPE"
        puts $OP_dvd_vcd_dbb_trx_gsr "SELECT_TYPE WORST_POWER_CYCLE"
        puts $OP_dvd_vcd_dbb_trx_gsr "SELECT_RANGE -1 -1"
        puts $OP_dvd_vcd_dbb_trx_gsr "TRUE_TIME $FSDB_TIMING"
	puts $OP_dvd_vcd_dbb_trx_gsr "}"
}

if {$mbist_fsdb != ""} {
	puts $OP_dvd_vcd_mbist_gsr "VCD_FILE {"
        puts $OP_dvd_vcd_mbist_gsr "$CHIP_NAME $mbist_fsdb"
        puts $OP_dvd_vcd_mbist_gsr "FILE_TYPE FSDB"
        puts $OP_dvd_vcd_mbist_gsr "FRONT_PATH TB/DUT_inst"
        puts $OP_dvd_vcd_mbist_gsr "SELECT_TYPE WORST_POWER_CYCLE"
        puts $OP_dvd_vcd_mbist_gsr "SELECT_RANGE -1 -1"
        puts $OP_dvd_vcd_mbist_gsr "TRUE_TIME $FSDB_TIMING"
	puts $OP_dvd_vcd_mbist_gsr "}"
}

if {$ac_fsdb != ""} {
	puts $OP_dvd_vcd_ac_gsr "VCD_FILE {"
        puts $OP_dvd_vcd_ac_gsr "$CHIP_NAME $ac_fsdb"
        puts $OP_dvd_vcd_ac_gsr "FILE_TYPE FSDB"
        puts $OP_dvd_vcd_ac_gsr "FRONT_PATH tb/U_dut"
        puts $OP_dvd_vcd_ac_gsr "SELECT_TYPE WORST_POWER_CYCLE"
        puts $OP_dvd_vcd_ac_gsr "SELECT_RANGE -1 -1"
        puts $OP_dvd_vcd_ac_gsr "TRUE_TIME $FSDB_TIMING"
	puts $OP_dvd_vcd_ac_gsr "}"
}

if {$sa_fsdb != ""} {
	puts $OP_dvd_vcd_sa_gsr "VCD_FILE {"
        puts $OP_dvd_vcd_sa_gsr "$CHIP_NAME $sa_fsdb"
        puts $OP_dvd_vcd_sa_gsr "FILE_TYPE FSDB"
        puts $OP_dvd_vcd_sa_gsr "FRONT_PATH tb/U_dut"
        puts $OP_dvd_vcd_sa_gsr "SELECT_TYPE WORST_POWER_CYCLE"
        puts $OP_dvd_vcd_sa_gsr "SELECT_RANGE -1 -1"
        puts $OP_dvd_vcd_sa_gsr "TRUE_TIME $FSDB_TIMING"
	puts $OP_dvd_vcd_sa_gsr "}"
}
out_gsr "\n"

##### STA file #######################
if {$FUNC_STA_FILE != ""} {
	puts $OP_dvd_vcd_coremark_gsr  "###### STA file #####################"
	puts $OP_dvd_vcd_coremark_gsr  "BLOCK_STA_FILE {"
	puts $OP_dvd_vcd_coremark_gsr  "$CHIP_NAME $FUNC_STA_FILE"
	puts $OP_dvd_vcd_coremark_gsr  "}"
}

if {$FUNC_STA_FILE != ""} {
	puts $OP_dvd_vcd_aon_psw_gsr  "###### STA file #####################"
	puts $OP_dvd_vcd_aon_psw_gsr  "BLOCK_STA_FILE {"
	puts $OP_dvd_vcd_aon_psw_gsr  "$CHIP_NAME $FUNC_STA_FILE"
	puts $OP_dvd_vcd_aon_psw_gsr  "}"
}

if {$FUNC_STA_FILE != ""} {
	puts $OP_dvd_vcd_dbb_trx_gsr  "###### STA file #####################"
	puts $OP_dvd_vcd_dbb_trx_gsr  "BLOCK_STA_FILE {"
	puts $OP_dvd_vcd_dbb_trx_gsr  "$CHIP_NAME $FUNC_STA_FILE"
	puts $OP_dvd_vcd_dbb_trx_gsr  "}"
}
if {$FUNC_STA_FILE != ""} {
	puts $OP_Signal_EM_gsr  "###### STA file #####################"
	puts $OP_Signal_EM_gsr  "BLOCK_STA_FILE {"
	puts $OP_Signal_EM_gsr  "$CHIP_NAME $FUNC_STA_FILE"
	puts $OP_Signal_EM_gsr  "}"
}
if {$FUNC_STA_FILE != ""} {
	puts $OP_dvd_gsr  "###### STA file #####################"
	puts $OP_dvd_gsr  "BLOCK_STA_FILE {"
	puts $OP_dvd_gsr  "$CHIP_NAME $FUNC_STA_FILE"
	puts $OP_dvd_gsr  "}"
}
if {$FUNC_STA_FILE != ""} {
	puts $OP_Static_gsr  "###### STA file #####################"
	puts $OP_Static_gsr  "BLOCK_STA_FILE {"
	puts $OP_Static_gsr  "$CHIP_NAME $FUNC_STA_FILE"
	puts $OP_Static_gsr  "}"
}
if {$SCAN_STA_FILE != ""} {
	puts $OP_dvd_vcd_mbist_gsr  "###### STA file #####################"
	puts $OP_dvd_vcd_mbist_gsr  "BLOCK_STA_FILE {"
	puts $OP_dvd_vcd_mbist_gsr  "$CHIP_NAME $SCAN_STA_FILE"
	puts $OP_dvd_vcd_mbist_gsr  "}"
}

if {$SCAN_STA_FILE != ""} {
	puts $OP_dvd_vcd_sa_gsr  "###### STA file #####################"
	puts $OP_dvd_vcd_sa_gsr  "BLOCK_STA_FILE {"
	puts $OP_dvd_vcd_sa_gsr  "$CHIP_NAME $SCAN_STA_FILE"
	puts $OP_dvd_vcd_sa_gsr  "}"
}

if {$SCAN_STA_FILE != ""} {
	puts $OP_dvd_vcd_ac_gsr  "###### STA file #####################"
	puts $OP_dvd_vcd_ac_gsr  "BLOCK_STA_FILE {"
	puts $OP_dvd_vcd_ac_gsr  "$CHIP_NAME $SCAN_STA_FILE"
	puts $OP_dvd_vcd_ac_gsr  "}"
}
out_gsr "######## CLK GAT OPT #####################"
out_gsr "STATE_PROPAGATION {"
out_gsr "PROPAGATION_MODE probability"
out_gsr "CLOCK_GATE_ENABLE_RATIO 0.5"
out_gsr "ENABLE_CASCADED_CLOCK_GATING 1"
out_gsr "}"

out_gsr "\n"
out_gsr "######################## ploc file ########################"
out_gsr "PAD_FILE {"
out_gsr "$PLOC_FILE "
out_gsr "}"

out_gsr "\n"
out_gsr "######################## ploc file ########################"
out_gsr "SWITCH_MODEL_FILE {"
out_gsr "$SWITCH_MODEL_FILE "
out_gsr "}"

out_gsr "########################PG name  ##########################"
out_gsr	"#########################PG name #########################"
out_gsr	"VDD_NETS {"
foreach {power_name voltage} $VDD_NETS {
	out_gsr "$power_name $voltage"
}
out_gsr "}"

out_gsr "\n"
out_gsr "GND_NETS {"
foreach {ground_name v} $GND_NETS {
	out_gsr "$ground_name $v"
}

out_gsr "}"

out_gsr "\n"
out_gsr "DECAP_CELL {"
out_gsr "DCAP*"
out_gsr "GDCAP*"
out_gsr "}"

out_gsr "\n"
out_gsr "IGNORE_CELLS {"
out_gsr "FILL*"
out_gsr "GFILL*"
out_gsr "PFILL*"
out_gsr "TAPCELL*"
out_gsr "ENDCAP*"
out_gsr "}"

out_gsr "\n"
##### PA tech file ########
out_gsr "######## PA tech file #####################"
out_gsr "TECH_FILE {"
out_gsr "$TECH_FILE"
out_gsr "}"

#out_gsr "\n"
###### STA file #######################
#out_gsr "###### STA file #####################"
#out_gsr "BLOCK_STA_FILE {"
#out_gsr "$CHIP_NAME $FUNC_STA_FILE"
#out_gsr "}"

out_gsr "\n"
#### DEF file ########################
out_gsr "\n"
out_gsr "######### DEF file ################"
out_gsr "DEF_FILES {"
out_gsr "$DEF_FILE top"
out_gsr "}"

out_gsr "\n"
##### CELL_RC_FILE #######################
out_gsr "################CELL_RC_FILE #############"
out_gsr "CELL_RC_FILE {"
out_gsr "$CHIP_NAME $RC_FILE"
out_gsr "}"

out_gsr "\n"
########### LEF FILE #############################
out_gsr "##### LEF FILE ####################"
out_gsr "LEF_FILE {"
foreach lef $LEF_FILE {
	out_gsr "$lef"
}
out_gsr "}"


####### LIB FILE #############################
out_gsr "#### LIB FILE ######################"
out_gsr "LIB_FILE {"
foreach lib $LIB_FILE {
	out_gsr "$lib"
}
out_gsr "}"

out_gsr "\n"

######### APL FILE ########################
out_gsr "#### APL FILE #########################"
out_gsr "APL_FILES {"
foreach apl $APL_FILE {
	if {[regexp {\.cdev} "$apl"]} {
		out_gsr "$apl cap"
	} elseif {[regexp {\_current} "$apl"]} {
		out_gsr "$apl current"
	} elseif {[regexp {\.pwcdev} "$apl"]} {
		out_gsr "$apl pwc "
	}
}

out_gsr "}"

close $OP_dvd_gsr
close $OP_dvd_vcd_coremark_gsr
close $OP_dvd_vcd_aon_psw_gsr
close $OP_dvd_vcd_dbb_trx_gsr
close $OP_dvd_vcd_mbist_gsr
close $OP_dvd_vcd_ac_gsr
close $OP_dvd_vcd_sa_gsr
close $OP_dvd_rh
close $OP_dvd_vcd_coremark_rh
close $OP_dvd_vcd_aon_psw_rh
close $OP_dvd_vcd_dbb_trx_rh
close $OP_dvd_vcd_mbist_rh
close $OP_dvd_vcd_ac_rh
close $OP_dvd_vcd_sa_rh
close $OP_Static_gsr
close $OP_Static_rh
close $OP_gridcheck_gsr
close $OP_gridcheck_rh
close $OP_Signal_EM_gsr
close $OP_Signal_EM_rh


