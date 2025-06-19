SHELL 		= /bin/csh -f
VPATH 		?= ./FLAG
SCRIPTS 	:= .. /SCRIPTS/GLOBAL
LOG 			:= ./LOG
PWD 			:= $(shell dirname $(shell pwd)/$(lastword $(MAKEFILE_LIST)))
log 			:= log
cpu 			:= 8
q 				:= backend_mc
inn_dir 	:= /tools/cadence/ddi/22.13-s094/bin/
INN_SHELL := \bsub -q $(q) -n $(cpu) -R "select[hname!='tianjin'] span[hosts=1]" -Is ${inn_dir}/innovus -cpus $(cpu)
cmd				= cd $(PWD) ; source ../../block_setup.csh ; source ../../../eco_setup.csh ; setenv currEcoNum 102 ; setenv step $@ ; setenv laststep $(shell echo $< | awk-F "/" '{print $$NF}') ; $(INN_SHELL) -files $(SCRIPTS)/run_$@.tcl -log $(LOG)/$@.log
init:
	@echo "--------------------------------------"
	@echo"Step: $@ started at : `date` by: $(USER)"
	@echo "--------------------------------------"
	@cd $(PWD); mkdir -p LOG DBS RPT FLAG
	@$(cmd)
	@echo "step: $@ ended at: `date` "
preplace : init
	@echo "--------------------------------------"
	@echo "Step: $@ started at : `date` by: $(USER)"
	@echo "--------------------------------------"
	@$(cmd)
	@echo "step: $@ ended at: `date` "
	-setenv step $@ ; cd $(PWD) ; python3 ../../ENV/gen_block_summary_to_html.py -loc ../../
preplace_drc : preplace
	@echo "--------------------------------------"
	@echo "Step: $@ started at : `date` by: $(USER)"
	@echo "--------------------------------------"
	@$(cmd)
	@echo "step: $@ ended at: `date` "
	-setenv step $@ ; cd $(PWD) ; python3 ../../ENV/gen_block_summary_to_html.py -loc ../../
mixplace : preplace
	@echo "--------------------------------------"
	@echo "Step: $@ started at : `date` by: $(USER)"
	@echo "--------------------------------------"
	@$(cmd)
	@echo "step: $@ ended at: `date` "
	-setenv step $@ ; cd $(PWD) ; python3 ../../ENV/gen_block_summary_to_html.py -loc ../../
place : preplace
	@echo "--------------------------------------"
	@echo "Step: $@ started at : `date` by: $(USER)"
	@echo "--------------------------------------"
	@$(cmd)
	@echo "step: $@ ended at: `date` "
	-setenv step $@ ; cd $(PWD) ; python3 ../../ENv/gen_block_summary_to_html.py -loc ../..
cts :place
	@echo "--------------------------------------"
	@echo "Step: $@ started at : `date` by: $(USER)"
	@echo "--------------------------------------"
	@$(cmd)
	@echo "Step: $@ ended at: `date`
	-setenv step $@ ; cd $(PWD) ; python3 ../../ENv/gen_block_summary_to_html.py -loc ../../
route : cts
	@echo "--------------------------------------"
	@echo "Step: $@ started at : `date` by: $(USER)"
	@echo "--------------------------------------"
	@$(cmd)
	@echo "step: $@ ended at: `date`
	-setenv step $@ ; cd $(PWD) ; python3 ../../ENV/gen_block_summary_to_html.py -loc ../../
postroute : route
	@echo "--------------------------------------"
	@echo "Step: $@ started at : `date` by: $(USER)"
	@echo "--------------------------------------"
	@$(cmd)
	@echo "Step: $@ ended at:`date` "
	-setenv step $@ ; cd $(PWD) ; python3 ../../ENV/gen_block_summary_to_html.py -loc ../../
eco :
	@echo "--------------------------------------"
	@echo "Step: $@ started at : `date` by: $(USER)"
	@echo "--------------------------------------"
	@$(cmd)
	@echo "Step: $@ ended at: `date` "

eco_ver = $(shell PWD I grep "_eco"| wc -l)
ifeq ($(eco_ver),0)
chipfinish: postroute
	@echo "--------------------------------------"
	@echo "Step: $@ started at :`date` by: $(USER)"
	@echo "--------------------------------------"
	@$(cmd)
	@echo "step: $@ ended at: `date`"
else
chipfinish :eco
	@echo "--------------------------------------"
	@echo "Step: $@ started at : `date` by: $(USER)"
	@echo "--------------------------------------"
	@$(cmd)
	@echo "Step: $@ ended at: `date`"
endif
###
gui:
	@echo "--------------------------------------"
	@echo "Step: $@ started at :`date` by: $(USER)"
	@echo "--------------------------------------"
	@cd $(PWD); source ../../block_setup.csh ; $(INN_SHELL) -files $(SCRIPTS)/run_$@.tcl -log $(LOG)/$@_$(log) .log ;
	@echo "step: $@ ended at: `date`"
clean:
	@find . -mindepth 1 -name "*" |grep -v Makefile | xargs rm -rf
