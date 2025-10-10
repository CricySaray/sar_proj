DESIGN:=CX200UR1_SOC_TOP
VERSION:=run_1p0_run6
DATAOUT_VERSION:=postroute
WORK_DIR:=$(PWD)
DATE:=$$(date+%F)

################tool
invs:=innovus
pt:=pt_shell

###############work dir
PR_DIR:=${WORK_DIR}/pnr/${VERSION}
STARRC_DIR:=${WORK_DIR}/starrc
PV_DIR:=${WORK_DIR}/pv
FM_DIR:=${WORK_DIR}/fm
STA_DIR:=${WORK_DIR}/sta
CLP_DIR:=${WORK_DIR}/clp
STAFILE_DIR:=${WORK_DIR}/pt2sta_file
XTOP_DIR:=${WORK_DIR}/xtop
FLAG_DIR:=${WORK_DIR}/.flag/${VERSION}

ifeq ($(wildcard ${FLAG_DIR}),)
$(shell mkdir -p ${FLAG_DIR})
endif

#############define targets
init: ${FLAG_DIR}/init
floorplan: ${FLAG_DIR}/floorplan
place: ${FLAG_DIR}/place
cts:${FLAG_DIR}/cts
postcts: ${FLAG_DIR}/postcts
route: ${FLAG_DIR}/route
postroute: ${FLAG_DIR}/postroute
eco: ${FLAG_DIR}/eco
dataout: ${FLAG_DIR}/dataout
starrc: ${FLAG_DIR}/starrc

fm: ${FLAG_DIR}/fm
clp:${FLAG_DIR}/clp

stafile: ${FLAG_DIR}/stafile
pt: ${FLAG_DIR}/pt
pt_1: ${FLAG_DIR}/pt_1
pt_2: ${FLAG_DIR}/pt_2
pt_2p5: ${FLAG_DIR}/pt_2p5
pt_2p5_1: ${FLAG_DIR}/pt_2p5_1
pt_1p8: ${FLAG_DIR}/pt_1p8
pt_1p8_1: ${FLAG_DIR}/pt_1p8_1
pt_0p8: ${FLAG_DIR}/pt_0p8
pt_0p8_1: ${FLAG_DIR}/pt_0p8_1
xtop: ${FLAG_DIR}/xtop

dummy_FEOL: ${FLAG_DIR}/dummy_FEOL
dummy_BEOL: ${FLAG_DIR}/dummy_BEOL
merge_dummy: ${FLAG_DIR}/merge_dummy

v2lvs: ${FLAG_DIR}/v2lvs
ant: ${FLAG_DIR}/ant
drc: ${FLAG_DIR}/drc
lvs: ${FLAG_DIR}/lvs

###########define run
${FLAG_DIR}/init:
	cd ${PR_DIR}/work; \
	${invs} -files ../scr/run_init.tcl -log ../log/init.log -64 -overwrite
	touch $@

${FLAG_DIR}/floorplan:${FLAG_DIR}/init
	cd ${PR_DIR}/work; \
	${invs} -files ../scr/run_floorplan.tcl -log ../log/floorplan.log -64 -overwrite
	touch $@

${FLAG_DIR}/place:${FLAG_DIR}/floorplan
	cd ${PR_DIR}/work; \
	${invs} -files ../scr/run_place.tcl -log ../log/place.log -64 -overwrite
	touch $@

${FLAG_DIR}/cts:${FLAG_DIR}/place
	cd ${PR_DIR}/work; \
	${invs} -files ../scr/run_cts.tcl -log ../log/cts.log -64 -overwrite
	touch $@

${FLAG_DIR}/postcts:${FLAG_DIR}/cts
	cd ${PR_DIR}/work; \
	${invs} -files ../scr/run_postcts.tcl -log ../log/postcts.log -64 -overwrite
	touch $@

${FLAG_DIR}/route:${FLAG_DIR}/postcts
	cd ${PR_DIR}/work; \
	${invs} -files ../scr/run_route.tcl -log ../log/route.log -64 -overwrite
	touch $@

${FLAG_DIR}/postroute:${FLAG_DIR}/route
	cd ${PR_DIR}/work; \
	${invs} -files ../scr/run_postroute.tcl -log ../log/postroute.log -64 -overwrite
	touch $@
	touch ${FLAG_DIR}/eco


${FLAG_DIR}/eco:${FLAG_DIR}/postroute
	cd ${PR_DIR}/work; \
	${invs} -files ../scr/run_eco.tcl -log ../log/eco.log -64
	touch $@


export DATAOUT_VERSION DESIGN
STARRC_WITH_DUMMY = 1
export STARRC_WITH_DUMMY

${FLAG_DIR}/dataout:${FLAG_DIR}/eco
	cd ${PR_DIR}/work; \
	${invs} -files ../scr/run_dataout.tcl -log ../log/dataout.${DATAOUT_VERSION}.log -64
	touch $@
${FLAG_DIR}/dummy_BEOL:${FLAG_DIR}/dataout
	cd ${PV_DIR}; \
	./scr/run_Dummy_Metal.csh
	touch $@
${FLAG_DIR}/dummy_FEOL:${FLAG_DIR}/dataout
	cd ${PV_DIR}; \
	./scr/run_Dummy_DODP.csh
	touch $@
${FLAG_DIR}/merge_dummy:${FLAG_DIR}/dummy_FEOL ${FLAG_DIR}/dummy_BEOL
	cd ${PV_DIR}; \
	./scr/run_mergeDummy.csh
	touch $@
${FLAG_DIR}/drc:${FLAG_DIR}/merge_dummy
	cd ${PV_DIR}; \
	./scr/run_drc.csh
	touch $@
${FLAG_DIR}/ant:${FLAG_DIR}/merge_dummy
	cd ${PV_DIR}; \
	./scr/run_ant.csh
	touch $@
${FLAG_DIR}/v2lvs:${FLAG_DIR}/dataout
	cd ${PV_DIR}; \
	./scr/run_v2lvs.csh
	touch $@
${FLAG_DIR}/lvs:${FLAG_DIR}/v2lvs
	cd ${PV_DIR}; \
	./scr/run_lvs.csh
	touch $@

${FLAG_DIR}/starrc:${FLAG_DIR}/dummy_BEOL
	cd ${STARRC_DIR}; \
	tclsh scr/gen_starrc_script.tcl ;\
	csh run_starrc.csh ;\
	touch $@
${FLAG_DIR}/pt:${FLAG_DIR}/starrc
	cd ${STA_DIR}/rm_pt/run; \
	pt_shell -multi_scenario -f ../../scripts_block/rm_pt_scripts/dmsa.tcl ;\
	touch $@
${FLAG_DIR}/pt_1:${FLAG_DIR}/pt
	cd ${STA_DIR}/rm_pt/run; \
	pt_shell -multi_scenario -f ../../scripts_block/rm_pt_scripts/dmsa_1.tcl ;\
	touch $@
${FLAG_DIR}/pt_2:${FLAG_DIR}/pt_1
	cd ${STA_DIR}/rm_pt/run; \
	pt_shell -multi_scenario -f ../../scripts_block/rm_pt_scripts/dmsa_2.tcl ;\
	touch $@
${FLAG_DIR}/pt_2p5:${FLAG_DIR}/pt_2
	cd ${STA_DIR}/rm_pt/run; \
	pt_shell -multi_scenario -f ../../scripts_block/rm_pt_scripts/dmsa_2p5.tcl ;\
	touch $@
${FLAG_DIR}/pt_2p5_1:${FLAG_DIR}/pt_2p5
	cd ${STA_DIR}/rm_pt/run; \
	pt_shell -multi_scenario -f ../../scripts_block/rm_pt_scripts/dmsa_2p5_1.tcl ;\
	touch $@
${FLAG_DIR}/pt_1p8:${FLAG_DIR}/pt_2p5_1
	cd ${STA_DIR}/rm_pt/run; \
	pt_shell -multi_scenario -f ../../scripts_block/rm_pt_scripts/dmsa_1p8.tcl ;\
	touch $@
${FLAG_DIR}/pt_0p8:${FLAG_DIR}/pt_1p8
	cd ${STA_DIR}/rm_pt/run; \
	pt_shell -multi_scenario -f ../../scripts_block/rm_pt_scripts/dmsa_0p8std.tcl ;\
	touch $@
${FLAG_DIR}/xtop:${FLAG_DIR}/pt_0p8
	cd ${XTOP_DIR} ;\
	xtop -file ./scr/xtop.tcl -log_dir ./log ;\
	touch $@	
${FLAG_DIR}/stafile:${FLAG_DIR}/pt
	cd ${STAFILE_DIR}; \
	pt_shell -f ./scr/ptpx_gen_sta.tcl ;


${FLAG_DIR}/fm:
	cd ${FM_DIR} ;\
	fm_shell -work_path ./work -f ./scr/fm.tcl  |tee ./log/fm.log 
	

