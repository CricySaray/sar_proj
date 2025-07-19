VPATH 		:= ./FLAG
DESIGN 		:= SC5018_TOP
VERSION 	:= test_flow
NUM_CORE 	:= 8
QUEUE			:= normal
STARRC_TOOL := /cad/EDA/tools/synopsys/starrc-T-2022.03/bin/StarXtract
.ONESHELL:

def_file 	:= 
gds_file 	:= 
gds_layer_map_file 	:= 
mapping_file 				:= 
corner_file					:= 
selected_corners 		:=
run_dir 						:= ./$(VERSION)/
output_dir					:= /simulation/arsong/SC5018/OUTPUT/spef

export: def_file gds_file gds_layer_map_file mapping_file corner_file selected_corners run_dir
.PHONY: def_file gds_file gds_layer_map_file mapping_file corner_file selected_corners run_dir sr starrc_$(VERSION)

# actual working dir : RUN/$(VERSION)/
sr: starrc_$(VERSION)
starrc_$(VERSION):
	mkdir -p $(run_dir)/output
	cd $(run_dir)
	tclsh ../../SCRIPTS/GLOBAL/build_StarRC_cmd.tcl
	bsub -n $(NUM_CORE) -Is -q $(QUEUE) "$(STARRC_TOOL) StarRC.cmd | tee ./StarRC.log"
	mkdir -p $(output_dir)/$(VERSION)
	ln -snf $(output_dir)/$(VERSION) $(output_dir)/ref_spef
	ln -snf /simulation/arsong/SC5018/STARRC/run/$(VERSION)/output/* $(output_dir)/$(VERSION)/
	ln -snf $(output_dir)/ref_spef/* $(output_dir)
