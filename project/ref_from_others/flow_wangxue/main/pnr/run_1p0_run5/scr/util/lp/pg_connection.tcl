set power_nets {POC_CORE POC_DBB VIN_PVPP VIN VBAT AVDD1P2_VFB AVDD0P9_TX_RF AVDD1P2_XO AVDD1P2_TX_RF AVDD1P2_TX_ABB AVDD1P2_RX1 AVDD1P2_RX0 AVDD1P2_RFPLL_DIG AVDD1P2_RFPLL_ANA AVDD1P2_BBPLL_DCO AVDD1P2_BBPLL_ANA AVDD1P2_RXADC DVDD1P2 DVDDIO_FLASH DVDD_EFUSE DVDDIO DVDDIO_AON_PSW DVDD0P9_DBB DVDD0P9_CORE DVDD0P9_RAM VQPS DVDDIO_PSW DVDD0P9_AON DVDD0P9_AON_SLP DVDD0P9_AON_IO}
foreach net $power_nets {
	set yesor [dbGet top.insts.pgInstTerms.net.name $net -u]
	if {$yesor == "0x0"} {
		addNet  $net -power  -physical
	}
}

set ground_nets {VSS_IO VSS_CORE VSS_ANA VSS_3P3 GND_MESH PGND AVSS_BBPLL AVSS_TX}
foreach gnd_net $ground_nets {
deleteNet $gnd_net
}
foreach net $ground_nets {
        set yesor [dbGet top.insts.pgInstTerms.net.name $net -u]
        if {$yesor == "0x0"} {
                addNet  $net -ground  -physical
        }
}
######connect io pg
foreach i [dbGet [dbGet top.insts.cell.baseClass pad -p2 ].name] {
	globalNetConnect  DVDDIO_PSW    -pin  VDDPST  -singleInstance  $i  -type  pgpin  -override
	globalNetConnect  VSS_IO        -pin  VSSPST  -singleInstance  $i  -type  pgpin  -override
	globalNetConnect  POC_CORE      -pin  POC     -singleInstance  $i  -type  pgpin  -override
	globalNetConnect  DVDD0P9_CORE  -pin  VDD     -singleInstance  $i  -type  pgpin  -override
	globalNetConnect  VSS_CORE      -pin  VSS     -singleInstance  $i  -type  pgpin  -override
	}

lassign [join [dbGet [dbGet top.insts.name PRCUT_A -p].box]] llx lly urx ury

globalNetConnect  DVDDIO_AON_PSW  -pin  VDDPST  -type  pgpin  -override -region $llx $lly 110 3300
globalNetConnect  VSS_IO          -pin  VSSPST  -type  pgpin  -override -region $llx $lly 110 3300
globalNetConnect  POC_AON         -pin  POC     -type  pgpin  -override -region $llx $lly 110 3300
globalNetConnect  DVDD0P9_AON_IO  -pin  VDD     -type  pgpin  -override -region $llx $lly 110 3300
globalNetConnect  VSS_CORE        -pin  VSS     -type  pgpin  -override -region $llx $lly 110 3300

globalNetConnect  DVDDIO          -pin  VDDPST  -type  pgpin  -override -region 0 3190  3250 3300
globalNetConnect  VSS_IO          -pin  VSSPST  -type  pgpin  -override -region 0 3190  3250 3300
globalNetConnect  POC_AON         -pin  POC     -type  pgpin  -override -region 0 3190  3250 3300
globalNetConnect  DVDD0P9_AON_IO  -pin  VDD     -type  pgpin  -override -region 0 3190  3250 3300
globalNetConnect  VSS_CORE        -pin  VSS     -type  pgpin  -override -region 0 3190  3250 3300

globalNetConnect  DVDDIO_PSW    -pin  VDDPST  -singleInstance  PCORNER_2  -type  pgpin  -override
globalNetConnect  VSS_IO        -pin  VSSPST  -singleInstance  PCORNER_2  -type  pgpin  -override
globalNetConnect  POC_CORE      -pin  POC     -singleInstance  PCORNER_2  -type  pgpin  -override
globalNetConnect  DVDD0P9_CORE  -pin  VDD     -singleInstance  PCORNER_2  -type  pgpin  -override
globalNetConnect  VSS_CORE      -pin  VSS     -singleInstance  PCORNER_2  -type  pgpin  -override

lassign [join [dbGet [dbGet top.insts.name PRCUT_V_82 -p].box]] llx lly urx ury

globalNetConnect  DVDDIO_PSW   -pin  VDDPST  -type  pgpin  -override  -region  $llx  $lly  3250  110
globalNetConnect  VSS_IO       -pin  VSSPST  -type  pgpin  -override  -region  $llx  $lly  3250  110
globalNetConnect  POC_DBB      -pin  POC     -type  pgpin  -override  -region  $llx  $lly  3250  110
globalNetConnect  DVDD0P9_DBB  -pin  VDD     -type  pgpin  -override  -region  $llx  $lly  3250  110
globalNetConnect  VSS_CORE     -pin  VSS     -type  pgpin  -override  -region  $llx  $lly  3250  110

######connect VQPS pin
globalNetConnect  VQPS -pin  VQPS -inst * -type  pgpin  -override

#####connect afe pin
foreach term [dbGet [dbGet top.insts.name u_afe_core -p].pgInstTerms.name] {
	globalNetConnect  $term -pin  $term -singleInstance  u_afe_core -type  pgpin  -override
	echo "globalNetConnect  $term -pin  $term -singleInstance  u_afe_core -type  pgpin  -override"
	}

#####connect esd
set esd_list {esd_b esd_a}
foreach inst $esd_list {
	globalNetConnect  VSS_CORE -pin  VSS -singleInstance  $inst -type  pgpin  -override
}

set core_retention_memorys {u_core_top/u_sram_ctrl_wrapper/u_soc_sram0/u_sram_ctrl_ecc/sram_instance_0__u_mem/u_mem u_core_top/u_sram_share_wrapper/u_ram1_32KB_cp_itcm_dedicated/u_mem u_core_top/u_sram_share_wrapper/u_ram6_32KB/u_mem u_core_top/u_sram_share_wrapper/u_ram0_32KB_cp_itcm_dedicated/u_mem u_core_top/u_sram_share_wrapper/u_ram2_32KB_ap_itcm_dedicated/u_mem u_core_top/u_sram_share_wrapper/u_ram3_32KB/u_mem u_core_top/u_sram_share_wrapper/u_ram4_32KB/u_mem u_core_top/u_sram_share_wrapper/u_ram5_32KB/u_mem u_core_top/u_sram_share_wrapper/u_ram8_16KB/u_mem u_core_top/u_sram_share_wrapper/u_ram10_16KB/u_mem u_core_top/u_sram_share_wrapper/u_ram9_16KB/u_mem u_core_top/u_sram_share_wrapper/u_ram7_16KB/u_mem}
set dbb_retention_memorys {u_dbe_top/u_dbb_top/u_data_capture_top/u_data_capture_ctrl/mem_num_5__u_2048x32_wrapper/u_mem u_dbe_top/u_dbb_top/u_data_capture_top/u_data_capture_ctrl/mem_num_7__u_2048x32_wrapper/u_mem u_dbe_top/u_dbb_top/u_data_capture_top/u_data_capture_ctrl/mem_num_6__u_2048x32_wrapper/u_mem u_dbe_top/u_dbb_top/u_data_capture_top/u_data_capture_ctrl/mem_num_0__u_2048x32_wrapper/u_mem u_dbe_top/u_dbb_top/u_data_capture_top/u_data_capture_ctrl/mem_num_4__u_2048x32_wrapper/u_mem u_dbe_top/u_dbb_top/u_data_capture_top/u_data_capture_ctrl/mem_num_2__u_2048x32_wrapper/u_mem u_dbe_top/u_dbb_top/u_data_capture_top/u_data_capture_ctrl/mem_num_1__u_2048x32_wrapper/u_mem u_dbe_top/u_dbb_top/u_data_capture_top/u_data_capture_ctrl/mem_num_3__u_2048x32_wrapper/u_mem}
foreach memory $core_retention_memorys {
	globalNetConnect DVDD0P9_RAM -singleInstance $memory -pin VDDCE -type pgpin -override -verbose 
}
foreach memory $dbb_retention_memorys {
	globalNetConnect DVDD0P9_RAM -singleInstance $memory -pin VDDCE -type pgpin -override -verbose 
}
foreach inst [dbGet top.insts.name u_aon_top/*] {
	globalNetConnect DVDD0P9_AON_SLP -pin VDD -singleInstance $inst -type pgpin -override -verbose 
	}
foreach inst [dbGet top.insts.name u_aon_top/u_pd_aon_top/*] {
	globalNetConnect DVDD0P9_AON -pin VDD -singleInstance $inst -type pgpin -override -verbose 
	}
foreach inst [dbGet top.insts.name u_aon_top/u_pd_aon_top/u_pd_aon_pad_top/*] {
	globalNetConnect DVDD0P9_AON_IO -pin VDD -singleInstance $inst -type pgpin -override -verbose 
	}


