####################################################################
# Innovus Foundation Flow Code Generator, Sun Jun 11 00:07:17 CST 2023
# Version : 19.11-s001_1
####################################################################
#set vars(pre_db) dataout_1106
set vars(db) $env(DATAOUT_VERSION)
set vars(dataout,start_time) [clock seconds]
source ../scr/setup.tcl -e -v

set vars(rpt_dir) "$vars(rpt_dir)/dataout/$vars(db)"
exec mkdir -p $vars(rpt_dir)

set restore_db_file_check 0
restoreDesign $vars(dbs_dir)/$vars(design).$vars(db).enc.dat $vars(design)

source ../scr/util/ech_aon_domain_cell.tcl -e -v

foreach inst [dbGet top.insts.name u_aon_top/*] {
	globalNetConnect DVDD0P9_AON_SLP -pin VDD -singleInstance $inst -type pgpin -override -verbose 
	}
foreach inst [dbGet top.insts.name u_aon_top/u_pd_aon_top/*] {
	globalNetConnect DVDD0P9_AON -pin VDD -singleInstance $inst -type pgpin -override -verbose 
	}
foreach inst [dbGet top.insts.name u_aon_top/u_pd_aon_top/u_pd_aon_pad_top/*] {
	globalNetConnect DVDD0P9_AON_IO -pin VDD -singleInstance $inst -type pgpin -override -verbose 
	}

deleteDanglingPort
deleteEmptyModule

source ../scr/util/add_filler.tcl -e -v 
checkFiller

globalNetConnect DVDD0P9_AON_SLP -pin VDD -region [join [dbGet [dbGet top.pds.name PD_AON_SLP -p].group.boxes]] -type pgpin -override -verbose
globalNetConnect DVDD0P9_AON     -pin VDD -region [join [dbGet [dbGet top.pds.name PD_AON -p].group.boxes]] -type pgpin -override -verbose

set vars(out_dir) "../../../dataout/$vars(db)"
exec mkdir -p $vars(out_dir)/db $vars(out_dir)/gds $vars(out_dir)/def $vars(out_dir)/ploc $vars(out_dir)/spef $vars(out_dir)/upf $vars(out_dir)/xtop_data $vars(out_dir)/special_check $vars(out_dir)/sdf


#############save def
defOut -routing -floorplan -netlist $vars(out_dir)/def/$vars(design).pr.ir.def.gz
defOut -routing -floorplan -netlist $vars(out_dir)/def/$vars(design).pr.def.gz


#############save db
saveDesign $vars(out_dir)/db/$vars(design).$vars(db).enc

#############save netlist
redirect -tee write_upf.log {write_power_intent -1801 $vars(out_dir)/upf/$vars(design).pr.upf}
saveNetlist $vars(out_dir)/netlist/$vars(design).pr.v.gz

saveNetlist -excludeLeafCell -includePowerGround $vars(out_dir)/netlist/$vars(design).pr.clp.v.gz

set exclude_cell "N28_DMY_TCD_FH BEOL_small_FDM1 BEOL_small_FDM2 BEOL_small_FDM3 BEOL_small_FDM4 BEOL_small_FDM5 BEOL_small_FDM6 BOUNDARY_LEFTBWP7T35P140 BOUNDARY_RIGHTBWP7T35P140 FILL8BWP7T35P140 FILL4BWP7T35P140 FILL3BWP7T35P140 FILL2BWP7T35P140 FILL1BWP7T35P140 FILL8BWP7T40P140HVT FILL4BWP7T40P140HVT FILL3BWP7T40P140HVT FILL2BWP7T40P140HVT PFILLER10  PFILLER1 PFILLER5 PFILLER05 PFILLER0005 PENDCAP PCORNER TAPCELLBWP7T35P140 PRCUT  CX200A_SOC_AFE_PAD_TOP CX100B_SOC_AFE"
saveNetlist -flattenBus -phys -excludeLeafCell -excludeCellInst $exclude_cell $vars(out_dir)/netlist/$vars(design).pr.noafe.lvs.v.gz
set exclude_cell "N28_DMY_TCD_FH BEOL_small_FDM1 BEOL_small_FDM2 BEOL_small_FDM3 BEOL_small_FDM4 BEOL_small_FDM5 BEOL_small_FDM6 BOUNDARY_LEFTBWP7T35P140 BOUNDARY_RIGHTBWP7T35P140 FILL8BWP7T35P140 FILL4BWP7T35P140 FILL3BWP7T35P140 FILL2BWP7T35P140 FILL1BWP7T35P140 FILL8BWP7T40P140HVT FILL4BWP7T40P140HVT FILL3BWP7T40P140HVT FILL2BWP7T40P140HVT PFILLER10  PFILLER1 PFILLER5 PFILLER05 PFILLER0005 PENDCAP PCORNER TAPCELLBWP7T35P140 PRCUT  CX200A_SOC_AFE_PAD_TOP"
saveNetlist -flattenBus -phys -excludeLeafCell -excludeCellInst $exclude_cell $vars(out_dir)/netlist/$vars(design).pr.afe.lvs.v.gz

saveNetlist -excludeLeafCell -excludeCellInst {N28_DMY_TCD_FH BEOL_small_FDM1 BEOL_small_FDM2 BEOL_small_FDM3 BEOL_small_FDM4 BEOL_small_FDM5 BEOL_small_FDM6 BOUNDARY_LEFTBWP7T35P140 BOUNDARY_RIGHTBWP7T35P140 FILL8BWP7T35P140 FILL4BWP7T35P140 FILL3BWP7T35P140 FILL2BWP7T35P140 FILL1BWP7T35P140 FILL8BWP7T40P140HVT FILL4BWP7T40P140HVT FILL3BWP7T40P140HVT FILL2BWP7T40P140HVT PFILLER10  PFILLER1 PFILLER5 PFILLER05 PFILLER0005 PENDCAP PCORNER TAPCELLBWP7T35P140 PRCUT CX200UR1_SOC_AFE_PAD_TOP} $vars(out_dir)/netlist/$vars(design).pr.lp_sim.v.gz

saveNetlist -phys -excludeLeafCell -excludeCellInst {N28_DMY_TCD_FH BEOL_small_FDM1 BEOL_small_FDM2 BEOL_small_FDM3 BEOL_small_FDM4 BEOL_small_FDM5 BEOL_small_FDM6 BOUNDARY_LEFTBWP7T35P140 BOUNDARY_RIGHTBWP7T35P140 TAPCELLBWP7T35P140 TEF28HPCPESD_P PFILLER10  PFILLER1 PFILLER5 PFILLER05 PFILLER0005 PENDCAP PCORNER PRCUT GDCAP12BWP7T30P140HVT GDCAP10BWP7T30P140HVT GDCAP4BWP7T30P140HVT GDCAP3BWP7T30P140HVT GDCAP2BWP7T30P140HVT GDCAPBWP7T30P140HVT GFILL12BWP7T30P140HVT GFILL10BWP7T30P140HVT GFILL4BWP7T30P140HVT GFILL3BWP7T30P140HVT GFILL2BWP7T30P140HVT GFILLBWP7T30P140HVT  FILL8BWP7T40P140HVT FILL4BWP7T40P140HVT FILL3BWP7T40P140HVT FILL2BWP7T40P140HVT FILL3BWP7T35P140 FILL2BWP7T35P140 DCAP64BWP7T40P140HVT DCAP32BWP7T40P140HVT DCAP16BWP7T40P140HVT DCAP8BWP7T40P140HVT DCAP4BWP7T40P140HVT CX200A_SOC_AFE_PAD_TOP} $vars(out_dir)/netlist/$vars(design).pr.lp_sim.pg.v.gz



#############save gds
addInst -cell CX200UR1_SOC_AFE_PAD_TOP -inst CX200UR1_SOC_AFE_PAD_TOP -physical -loc {0 0}
set lefDefOutVersion 5.8
setStreamOutMode -textSize 0.1 -pinTextOrientation automatic -virtualConnection false

#streamOut $vars(out_dir)/gds/$vars(design).pr.noafe.notext.gds.gz \
#-mapFile /local_disk/home/user2/project/CX100_B_R1/pnr/100p/run_0315/scripts/gdsout_5X1Z1U.map  \
#-merge  $vars(gds_afe) \
#-uniquifyCellNames \
#-mode ALL \
#-units 1000

streamOut $vars(out_dir)/gds/$vars(design).pr.noafe.text.gds.gz \
-mapFile /process/TSMC28/PDK/tn28clpr002e1_1_9_1a/PRTF_EDI_28nm_Cad_V19_1a/PRTF_EDI_28nm_Cad_V19_1a/PR_tech/Cadence/GdsOutMap/gdsout_5X1Z1U.map  \
-merge  $vars(gds_noafe) \
-uniquifyCellNames \
-mode ALL \
-units 1000

streamOut $vars(out_dir)/gds/$vars(design).pr.afe.text.gds.gz \
-mapFile /process/TSMC28/PDK/tn28clpr002e1_1_9_1a/PRTF_EDI_28nm_Cad_V19_1a/PRTF_EDI_28nm_Cad_V19_1a/PR_tech/Cadence/GdsOutMap/gdsout_5X1Z1U.map  \
-merge  $vars(gds_afe) \
-uniquifyCellNames \
-mode ALL \
-units 1000

streamOut $vars(out_dir)/gds/$vars(design).pr.noafe.text.no_ap.gds.gz \
-mapFile /process/TSMC28/PDK/tn28clpr002e1_1_9_1a/PRTF_EDI_28nm_Cad_V19_1a/PRTF_EDI_28nm_Cad_V19_1a/PR_tech/Cadence/GdsOutMap/gdsout_5X1Z1U.map  \
-merge  $vars(gds_afe_no_ap) \
-uniquifyCellNames \
-mode ALL \
-units 1000

foreach cell [dbGet top.insts.cell.name -u ] {
	echo "$cell $cell" >> $vars(out_dir)/gds/hcell.list
	}

###############for fm
dumpMultiBitFlopMappingFile -output $vars(out_dir)/netlist/
gen_set_user_match -file_name $vars(out_dir)/netlist/multi_bit_pin_mapping -out $vars(out_dir)/netlist


set list "*PD_AON_SLP* *PD_AON_IO* *PD_DBB* *PD_CORE*"
set cell_name_list "FILL* DCAP* GDCAP* GFILL*"
foreach i $list {
        foreach a $cell_name_list {
                set cell_list [dbGet [dbGet top.insts.name $i -p].cell.name $a -u] 
                foreach b   $cell_list {
                set num [llength [dbGet [dbGet top.insts.name $i -p].cell.name $b -p2]]
                echo "$i $b $num" >> $vars(out_dir)/special_check/decap_count
                }
        }
}

foreach a $cell_name_list {
        set cell_list [dbGet [dbGet [dbGet top.insts.name *PD_AON* -p].name -v -regexp {PD_AON_SLP|PD_AON_IO} -p].cell.name $a -u] 
        foreach b   $cell_list {
        set num [llength [dbGet [dbGet [dbGet top.insts.name *PD_AON* -p].name -v -regexp {PD_AON_SLP|PD_AON_IO} -p].cell.name $b -p2]]
        echo "*PD_AON* $b $num" >> $vars(out_dir)/special_check/decap_count
        }
}

invs_Count_Vt -out $vars(out_dir)/special_check/Count_Vt
exit

