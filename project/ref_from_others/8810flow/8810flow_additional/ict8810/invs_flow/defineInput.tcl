###environment variable transformations
set vars(design)                          $env(design)
set vars(top_or_block)                    $env(top_or_block)
set vars(timing_cri_mode)                 $env(timing_cri_mode)
set vars(cong_cri_mode)                   $env(cong_cri_mode)
set vars(scan_reoder_mode)                $env(scan_reoder_mode)
set vars(cellPad_mode)                    $env(cellPad_mode)
set vars(simplify_mode)                   $env(simplify_mode)
set vars(userfulSkew_mode)                $env(userfulSkew_mode)
set vars(cts_swap_ff_mode)                $env(cts_swap_ff_mode)
set vars(leakage_opt_mode)                $env(leakage_opt_mode)
set vars(cts_hold_fix_mode)               $env(cts_hold_fix_mode)
set vars(merge_ffs)                       $env(merge_ffs)
set vars(ccopt_shiled_mode)               $env(ccopt_shiled_mode)
set vars(feed_through)                    $env(feed_through)
set vars(use_lvt)                         $env(use_lvt) 
 
set vars(netlist)                         $env(netlist)
set vars(sdc_func)                        $env(sdc_func)
set vars(sdc_funcasyn)                    $env(sdc_funcasyn)
set vars(sdc_scan)                        $env(sdc_scan)
set vars(func_dontch_list)                $env(func_dontch_list)
set vars(scan_def)                        $env(scan_def)
set vars(fp_def)                          $env(fp_def)

if { $vars(use_lvt) == "true" } {
set vars(dont_use_cells)       "INV*SGCAP* BUF*SGCAP* FRICG* DFF*QL_* DFF*QNL_* SDFF*QL_* SDFF*QNL_* SDFFQH* SDFFQNH* SDFFRPQH* SDFFRPQNH* SDFFSQH* SDFFSQNH* SDFFSRPQH* SDFFY* *DRFF* HEAD* FOOT* *X0* *DLY* SDFFX* XOR3* XNOR3* *ECO*  *ZTEH* *ZTUH* *ZTUL* *ISO* *LVL* *G33* ANTENNA* *AND*_X11* *AND*_X8* *AO21A1AI2_X8* *AOI21B_X8* *AOI21_X11* *AOI21_X8* *AOI22BB_X8* *AOI22_X11* *AOI22_X8* *AOI2XB1_X8* *AOI31_X8* *ENDCAP FILL* GP* MXGL* OA*_X8* OR*_X11* NOR*_X11* OR*_X8* NOR*_X8* *_X20* *QN* ICT_CDMSTD" 
}
