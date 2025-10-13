namespace eval base {
  set version    20.1.3
  set process    28
  set local_cpus 32
  
  set design_name               "xxxtop"
  set netlist_file              "xx.v"
  set func_sdc_file             ""
  set scan_sdc_file             ""
  set scan_def_file             ""
  set dont_touch_cell_file_list ""
  set dont_use_list_exp         ""
  set fp_file                   ""
  set ieee1801_upf_file         ""
  set def_files_list            ""
  set power_nets_list           ""
  set ground_nets_list          ""
  set tie_cells_exp_list        ""
  set view_defination_file      ""
  set if_enable_ocv             "pre_postcts"
  set if_enable_cppr            "both"
  set if_enable_si_aware        "true"

  set if_use_sdc_uncertainty             "true"
  set clk_uncertainty_setup_prects    0.4
  set clk_uncertainty_hold_prects     0.05
  set clk_uncertainty_setup_postcts   0.35
  set clk_uncertainty_hold_postcts    0.05
  set clk_uncertainty_setup_postroute 0.3
  set clk_uncertainty_hold_postroute  0.05
  set data_slew                       0.25
  set clk_slew                        0.15
  set max_fanout                      25
}
