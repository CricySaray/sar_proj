SHELL 				= /bin/csh -f
VPATH 				?= ./flag
SCRIPTS 			:= ./SCR
LOG_DIR   		:= ./LOG
RUN_DIR 			:= ./RUN
LOG_SUFFIX_GUI:= log_suffix
CORE_NUMS 		:= 8
QUEUE					:= backend_mc
INVS_TOOL_DIR := /tools/cadence/ddi/22.13-s094/bin/
INVS_SHELL 		:= \bsub -q $(QUEUE) -n $(CORE_NUMS) -R "select[hname!='tianjin'] span[hosts=1]" -Is ${INVS_TOOL_DIR}/innovus -cpus $(CORE_NUMS)
# now at run/PR/RUN/WORK
MAIN_CMD			= cd $(RUN_DIR) ; \
								source ../../../block_setup.csh ; \
								source ../../../../eco_setup.csh ; \
								setenv currEcoNum 102 ; \
								setenv step $@ ; \
								setenv laststep $(shell echo $< | awk -F "/" '{print $$NF}') ; \
								$(INVS_SHELL) -files $(SCRIPTS)/run_$@.tcl -log $(LOG_DIR)/$@.log
PREFIX_CMD 		:= echo "--------------------------------------" ; \
								 echo "Step: $@ started at : `date` by: $(USER)" ; \
								 echo "--------------------------------------"
SUFFIX 				:= echo "step: $@ ended at: `date` "
BODY 					:= $(PREFIX_CMD) ; cd $(RUN_DIR) ; mkdir -p RUN WORK LOG DB RPT flag ; $(MAIN_CMD) ; $(SUFFIX)
GEN_SUM 			:= setenv step $@ ; cd $(RUN_DIR) ; python3 ../../../ENV/gen_block_summary_to_html.py -loc ../../
build:
	@mkdir -p WORK LOG DB RPT FLAG 
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

eco_ver = $(shell ls -1 -d $(RUN_DIR) | grep "_eco"| wc -l)
ifeq ($(eco_ver),0)
chipfinish: postroute
	@$(BODY)
else
chipfinish :eco
	@$(BODY)
endif

gui:
	@$(PREFIX_CMD)
	@cd $(RUN_DIR); source ../../block_setup.csh ; $(INVS_SHELL) -files $(SCRIPTS)/run_$@.tcl -log $(LOG_DIR)/$@_$(LOG_SUFFIX_GUI) .log ;
	@$(SUFFIX)

clean:
	@find . -mindepth 1 -name "*" | grep -v Makefile | xargs rm -rf
