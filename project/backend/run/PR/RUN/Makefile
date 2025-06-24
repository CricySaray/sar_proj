SHELL 		= /bin/csh -f
VPATH 		?= ./FLAG
SCRIPTS 	:= .. /SCRIPTS/GLOBAL
LOG 			:= ./LOG
PWD 			:= $(shell dirname $(CURDIR)/$(lastword $(MAKEFILE_LIST)))# this can adapt different makefile in several dir
log 			:= log
cpu 			:= 8
q 				:= backend_mc
inn_dir 	:= /tools/cadence/ddi/22.13-s094/bin/
INN_SHELL := \bsub -q $(q) -n $(cpu) -R "select[hname!='tianjin'] span[hosts=1]" -Is ${inn_dir}/innovus -cpus $(cpu)
cmd				= cd $(PWD) ; source ../../block_setup.csh ; source ../../../eco_setup.csh ; setenv currEcoNum 102 ; setenv step $@ ; setenv laststep $(shell echo $< | awk-F "/" '{print $$NF}') ; $(INN_SHELL) -files $(SCRIPTS)/run_$@.tcl -log $(LOG)/$@.log
PREFIX 		:= echo "--------------------------------------" ; \
						 echo"Step: $@ started at : `date` by: $(USER)" ; \
						 echo "--------------------------------------"
SUFFIX 		:= echo "step: $@ ended at: `date` "
BODY 			:= $(PREFIX) ; cd $(PWD) ; mkdir -p LOG DBS RPT FLAG ; $(cmd) ; $(SUFFIX)
GEN_HTML 	:= setenv step $@ ; cd $(PWD) ; python3 ../../ENV/gen_block_summary_to_html.py -loc ../../
init:
	@$(BODY)
preplace : init
	@$(BODY)
	-$(GEN_HTML)
preplace_drc : preplace
	@$(BODY)
	-$(GEN_HTML)
mixplace : preplace
	@$(BODY)
	-$(GEN_HTML)
place : preplace
	@$(BODY)
	-$(GEN_HTML)
cts :place
	@$(BODY)
	-$(GEN_HTML)
route : cts
	@$(BODY)
	-$(GEN_HTML)
postroute : route
	@$(BODY)
	-$(GEN_HTML)
eco :
	@$(BODY)

eco_ver = $(shell PWD I grep "_eco"| wc -l)
ifeq ($(eco_ver),0)
chipfinish: postroute
	@$(BODY)
else
chipfinish :eco
	@$(BODY)
endif

gui:
	@$(PREFIX)
	@cd $(PWD); source ../../block_setup.csh ; $(INN_SHELL) -files $(SCRIPTS)/run_$@.tcl -log $(LOG)/$@_$(log) .log ;
	@$(SUFFIX)

clean:
	@find . -mindepth 1 -name "*" |grep -v Makefile | xargs rm -rf
