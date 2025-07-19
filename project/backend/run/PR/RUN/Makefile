SHELL 				= /bin/csh -f
VPATH 				?= ./FLAG
SCRIPTS 			:= ../../SCRIPTS/GLOBAL# now at PR/RUN/WORK
LOG_DIR   		:= ./LOG
WORK_DIR 			:= $(CURDIR)/WORK
LOG_SUFFIX_GUI:= log_suffix
CORE_NUMS 		:= 8
QUEUE					:= backend_mc
INVS_TOOL_DIR := /tools/cadence/ddi/22.13-s094/bin/
INVS_SHELL 		:= \bsub -q $(QUEUE) -n $(CORE_NUMS) -R "select[hname!='tianjin'] span[hosts=1]" -Is ${INVS_TOOL_DIR}/innovus -cpus $(CORE_NUMS)
# now at run/PR/RUN/WORK
MAIN_CMD			= cd $(WORK_DIR) ; \
								source ../../../block_setup.csh ; \
								source ../../../../eco_setup.csh ; \
								setenv currEcoNum 102 ; \
								setenv step $@ ; \
								setenv laststep $(shell echo $< | awk -F "/" '{print $$NF}') ; \
								$(INVS_SHELL) -files $(SCRIPTS)/run_$@.tcl -log $(LOG_DIR)/$@.log
PREFIX 				:= echo "--------------------------------------" ; \
								 echo "Step: $@ started at : `date` by: $(USER)" ; \
								 echo "--------------------------------------"
SUFFIX 				:= echo "step: $@ ended at: `date` "
BODY 					:= $(PREFIX) ; cd $(WORK_DIR) ; mkdir -p WORK LOG DBS RPT FLAG TEMP_TEST ; $(MAIN_CMD) ; $(SUFFIX)
GEN_SUM 			:= setenv step $@ ; cd $(WORK_DIR) ; python3 ../../../ENV/gen_block_summary_to_html.py -loc ../../
build:
	@mkdir -p WORK LOG DBS RPT FLAG TEMP_TEST
	@setenv song "anrui" ; echo $$song
	@export anrui "song" ; echo $$anrui #this can be known make use csh shell
init:
	@$(BODY)
preplace : init
	@$(BODY)
	-$(GEN_SUM)
preplace_drc : preplace
	@$(BODY)
	-$(GEN_SUM)
place : preplace
	@$(BODY)
	-$(GEN_SUM)
cts :place
	@$(BODY)
	-$(GEN_SUM)
route : cts
	@$(BODY)
	-$(GEN_SUM)
postroute : route
	@$(BODY)
	-$(GEN_SUM)
eco :
	@$(BODY)

eco_ver = $(shell ls -1 -d $(WORK_DIR) | grep "_eco"| wc -l)
ifeq ($(eco_ver),0)
chipfinish: postroute
	@$(BODY)
else
chipfinish :eco
	@$(BODY)
endif

gui:
	@$(PREFIX)
	@cd $(WORK_DIR); source ../../block_setup.csh ; $(INVS_SHELL) -files $(SCRIPTS)/run_$@.tcl -log $(LOG_DIR)/$@_$(LOG_SUFFIX_GUI) .log ;
	@$(SUFFIX)

clean:
	@find . -mindepth 1 -name "*" | grep -v Makefile | xargs rm -rf
