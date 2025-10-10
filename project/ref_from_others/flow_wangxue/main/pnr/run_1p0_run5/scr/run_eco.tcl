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

#####eco flow
set prefix [exec date +%m%d%H%M]
setEcoMode -updateTiming false -refinePlace false -prefix xtop_$prefix -honorDontUse false  -honorFixedStatus false
setEcoMode -batchMode true

redirect -tee log {source /home/user3/project/CX200UR1/CX200UR1_SOC_TOP/pnr/run_1p0_run5/work/ecofile}
#source /home/user3/project/CX200UR1/CX200UR1_SOC_TOP/pnr/run_1p0_run5/work/pt_eco1.tcl
#source /home/user3/project/CX200UR1/CX200UR1_SOC_TOP/pnr/run_1p0_run5/work/slk_clk_eco5.tcl
source /home92/user3/project/CX200UR1/CX200UR1_SOC_TOP/xtop/eco_output/08120907/xtop_opt_innovus_all_netlist_CX200UR1_SOC_TOP.txt
source /home92/user3/project/CX200UR1/CX200UR1_SOC_TOP/xtop/eco_output/08120907/xtop_opt_innovus_all_physical_CX200UR1_SOC_TOP.txt

setEcoMode -reset

refinePlace 
checkPlace

setNanoRouteMode -drouteEndIteration 20
ecoRoute
#verify_drc -limit -1

saveDesign $vars(dbs_dir)/$vars(design).$prefix.enc $vars(design)

set vars(out_dir) "../../../dataout/${prefix}"
exec mkdir -p $vars(out_dir)/db $vars(out_dir)/gds $vars(out_dir)/def $vars(out_dir)/ploc $vars(out_dir)/spef $vars(out_dir)/upf $vars(out_dir)/xtop_data $vars(out_dir)/special_check $vars(out_dir)/sdf

defOut -routing -floorplan -netlist $vars(out_dir)/def/$vars(design).pr.def.gz
saveNetlist $vars(out_dir)/netlist/$vars(design).pr.v.gz

saveNetlist -excludeLeafCell -includePowerGround -phys $vars(out_dir)/netlist/$vars(design).pr.pg.v.gz
#####dataout 
deleteDanglingPort
deleteEmptyModule
#update_names -restricted {[ ]} -replace_str "_"
#remove_assigns

source ../scr/util/add_filler.tcl -e -v 
checkFiller


set vars(out_dir) "../../../dataout/${prefix}"
exec mkdir -p $vars(out_dir)/db $vars(out_dir)/gds $vars(out_dir)/def $vars(out_dir)/ploc $vars(out_dir)/spef $vars(out_dir)/upf $vars(out_dir)/xtop_data $vars(out_dir)/special_check $vars(out_dir)/sdf


#############save def
defOut -routing -floorplan -netlist $vars(out_dir)/def/$vars(design).pr.ir.def.gz
defOut -routing -floorplan -netlist $vars(out_dir)/def/$vars(design).pr.def.gz


#############save db
saveDesign $vars(out_dir)/db/$vars(design).$vars(db).enc

#############save netlist

saveNetlist $vars(out_dir)/netlist/$vars(design).pr.v.gz


set signoff 1
if {$signoff} {
set exclude_cell "N28_DMY_TCD_FH BEOL_small_FDM1 BEOL_small_FDM2 BEOL_small_FDM3 BEOL_small_FDM4 BEOL_small_FDM5 BEOL_small_FDM6 BOUNDARY_LEFTBWP7T35P140 BOUNDARY_RIGHTBWP7T35P140 FILL8BWP7T35P140 FILL4BWP7T35P140 FILL3BWP7T35P140 FILL2BWP7T35P140 FILL1BWP7T35P140 FILL8BWP7T35P140HVT FILL4BWP7T35P140HVT FILL3BWP7T35P140HVT FILL2BWP7T35P140HVT PFILLER10  PFILLER1 PFILLER5 PFILLER05 PFILLER0005 PENDCAP PCORNER TAPCELLBWP7T35P140 FILL3BWP7T40P140HVT FILL2BWP7T40P140HVT PRCUT  CX200UR1_SOC_AFE_PAD_TOP"
saveNetlist -flattenBus -phys -excludeLeafCell -excludeCellInst $exclude_cell $vars(out_dir)/netlist/$vars(design).pr.lvs.v.gz
saveNetlist -flattenBus -flat -phys -excludeLeafCell -excludeCellInst $exclude_cell $vars(out_dir)/netlist/$vars(design).pr.lvs.flat.v.gz

saveNetlist -excludeLeafCell -excludeCellInst {N28_DMY_TCD_FH BEOL_small_FDM1 BEOL_small_FDM2 BEOL_small_FDM3 BEOL_small_FDM4 BEOL_small_FDM5 BEOL_small_FDM6 BOUNDARY_LEFTBWP7T35P140 BOUNDARY_RIGHTBWP7T35P140 FILL8BWP7T35P140 FILL4BWP7T35P140 FILL3BWP7T35P140 FILL2BWP7T35P140 FILL1BWP7T35P140 FILL8BWP7T35P140HVT FILL4BWP7T35P140HVT FILL3BWP7T35P140HVT FILL2BWP7T35P140HVT FILL3BWP7T40P140HVT FILL2BWP7T40P140HVT PFILLER10  PFILLER1 PFILLER5 PFILLER05 PFILLER0005 PENDCAP PCORNER TAPCELLBWP7T35P140 PRCUT CX200A_SOC_AFE_PAD_TOP} $vars(out_dir)/netlist/$vars(design).pr.lp_sim.v.gz

saveNetlist -phys -excludeLeafCell -excludeCellInst {N28_DMY_TCD_FH BEOL_small_FDM1 BEOL_small_FDM2 BEOL_small_FDM3 BEOL_small_FDM4 BEOL_small_FDM5 BEOL_small_FDM6 BOUNDARY_LEFTBWP7T35P140 BOUNDARY_RIGHTBWP7T35P140 TAPCELLBWP7T35P140 TEF28HPCPESD_P PFILLER10  PFILLER1 PFILLER5 PFILLER05 PFILLER0005 PENDCAP PCORNER PRCUT GDCAP12BWP7T30P140HVT GDCAP10BWP7T30P140HVT GDCAP4BWP7T30P140HVT GDCAP3BWP7T30P140HVT GDCAP2BWP7T30P140HVT GDCAPBWP7T30P140HVT GFILL12BWP7T30P140HVT GFILL10BWP7T30P140HVT GFILL4BWP7T30P140HVT GFILL3BWP7T30P140HVT GFILL2BWP7T30P140HVT GFILLBWP7T30P140HVT  FILL8BWP7T40P140HVT FILL4BWP7T40P140HVT FILL3BWP7T40P140HVT FILL2BWP7T40P140HVT FILL3BWP7T35P140 FILL2BWP7T35P140 DCAP64BWP7T40P140HVT DCAP32BWP7T40P140HVT DCAP16BWP7T40P140HVT DCAP8BWP7T40P140HVT DCAP4BWP7T40P140HVT CX200UR1_SOC_AFE_PAD_TOP} $vars(out_dir)/netlist/$vars(design).pr.lp_sim.pg.v.gz



#############save gds
set lefDefOutVersion 5.8
setStreamOutMode -textSize 0.1 -pinTextOrientation automatic -virtualConnection false


streamOut $vars(out_dir)/gds/$vars(design).pr.gds.gz \
-mapFile /process/TSMC28/PDK/tn28clpr002e1_1_9_1a/PRTF_EDI_28nm_Cad_V19_1a/PRTF_EDI_28nm_Cad_V19_1a/PR_tech/Cadence/GdsOutMap/gdsout_5X1Z1U.map  \
-merge  $vars(gds) \
-uniquifyCellNames \
-mode ALL \
-units 1000

foreach cell [dbGet top.insts.cell.name -u ] {
	echo "$cell $cell" >> $vars(out_dir)/gds/hcell.list
	}
}
###############for fm
dumpMultiBitFlopMappingFile -output $vars(out_dir)/netlist/
gen_set_user_match -file_name $vars(out_dir)/netlist/multi_bit_pin_mapping -out $vars(out_dir)/netlist


invs_Count_Vt -out $vars(out_dir)/special_check/Count_Vt
exit
