set current_dir [pwd]
set DESIGN_NAME lb_cpu_top
set mode        scan
set corner      typ_85
set check       setuphold;#setup hold
set VIEW        eco_39
write_sdf -version  3.0 -no_edge -context verilog -significant_digits 5 -compress gzip -include  "SETUPHOLD RECREM" -exclude { no_condelse clock_tree_path_models } -no_negative_values timing_checks  -no_internal_pins    ${current_dir}/../../dsn/sdf/${DESIGN_NAME}.${mode}_${corner}_${check}.${VIEW}.sdf
