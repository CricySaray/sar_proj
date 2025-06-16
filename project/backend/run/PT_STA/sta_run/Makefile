#!/usr/bin/make
############## Project setting ################
SHELL = csh -f
TOOL_VERSION = /tools/synopsys/prime/U-2022.12-SP5/bin/primetime
XTOP_VERSION = /tools/empyrean/xtop/2023.12_20240130/bin/xtop
RUN_PATH  	 = ${shell pwd}
DATE = $(shell echo $(shell date +%m%d_%H%M%S))
STA_DATE 		 = $(shelL echo $(shell date +%m%d%H%M%S))
##############   user setting   ################
QUEUE 			?= normal
NUM_CPU 		?= 4
# 0: no limit | 40G
MEMORY 			?= 0
EXIT 				?= 1
INTERACTIVE ?= 0
# fast | setup_all | hold_all | all | all_wo0c | all_w0c85c | all_w0c85c25c | tt | etm | sdf | twf | zwl | setup_ssgnp0p72v125c_cworstccworstT_125c...
CORNER 			?= all
MODE 				?= funcl shiftl stuckatl
RUN_MODE  	?= hier
CREATE_LINK ?= 1
FORCE_RERUN ?= 1
CELL_H 			?= core6T
LINK_SUM 		?= 1

export SHELL TOOL_VERSION RUN_PATH DATE QUEUE NUM_CPU INTERACTIVE EXIT CORNER MODE CREATE_LINK CLEAN_DATA FORCE_RERUN CELL_H MEMORY RUN_MODE STA_DATE XTOP_VERSION LINK_SUM
.PHONY: sta dmsa_eco leackage_opt hyper sta_sum gui resume xtop_opt
help:
	-@echo "###################################################"
	-@echo "this is the help pager, but now is not important!"
	-@echo "###################################################"

sta:
	@source ../../block_setup.csh ; tclsh SCRIPT/GLOBAL/bsub_sta.tcl ; ./RUN/bsub_cmd/pt.run_all.csh
#zwl:
#	@source ../../block_setup.csh ; sed -i 's/\(set vars(zhbe,setting,pr_stage)\).*/\1 "zwl"/' ./SETUP/common_setup.tcl; tclsh SCRIPT/GLOBAL/bsub_sta.tcl ; ./RUN/bsub_cmd/pt.run_all.csh
dmsa_eco:
	@source ../../block_setup.csh ; tclsh SCRIPT/GLOBAL/bsub_dmsa.tcl ; source ./RUN/bsub_cmd/dmsa_fix_timing_${STA_DATE}.bsub
leackage_opt:
	@source ../../block_setup.csh ; tclsh SCRIPT/GLOBAL/bsub_leackage.tcl
#xtop_opt:
#	@source ../. ./block_setup.csh ; tclsh SCRIPT/GLOBAL/bsub_xtop.tcl ; source ./RUN/bsub_cmd/xtop_opt_${STA_DATE}.bsub
#hyper:
#	@source ../../block_setup.csh ; tclsh SCRIPT/GLOBAL/bsub_hyper.tcl
#merge_etm:
#	@source ../. ./block_setup.csh ; tclsh SCRIPT/GLOBAL/bsub_merge_etm.tcl
resume:
	@source ../../block_setup.csh ; ./SCRIPT/UTILITY/resume_fail_jobs.csh
sum:
	@source ../../block_setup.csh ; tclsh SCRIPT/GLOBAL/bsub_summary.tcl
gui:
	@bsub -Is -q ${QUEUE} -n ${NUM_CPU} -R "rusage[mem=${MEMORY}]" ${TOOL_VERSION} -output_log_file ./RUN/gui_log_${DATE}.log
