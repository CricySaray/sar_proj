###################################block user just need configure it ##################################################################################
##normal fix it 
set  VIEW = eco_39 
set  Quen = I8810_STA
set  top_name = lb_cpu_top 
echo 'set sdc_func "/eda_files/proj/ict8810/archive/chip_top_fdp/dsn/fe_release/FDP_240526/netlist/lb_cpu_top/sdc/lb_cpu_top.func.pt_write.sdc" ' >>  scr/common_setup.tcl
echo 'set sdc_scan "/eda_files/proj/ict8810/archive/chip_top_fdp/dsn/fe_release/FDP_240526/netlist/lb_cpu_top/sdc/lb_cpu_top.scan.pt_write.sdc" ' >>  scr/common_setup.tcl
echo 'set sdc_cdc  "/eda_files/proj/ict8810/archive/chip_top_fdp/dsn/fe_release/FDP_240526/netlist/lb_cpu_top/sdc/lb_cpu_top.async.func.sdc" ' >>  scr/common_setup.tcl
##spicial module 
## func=(std0.9v,pad1.8v) func1=(std0.9v,pad3.3v) func2=(std1.0v,pad1.8v) func3=(std1.0v,pad3.3v) 
echo 'set sdc_func1 ""  ' >>  scr/common_setup.tcl
echo 'set sdc_func2 ""  ' >>  scr/common_setup.tcl
echo 'set sdc_func3 ""  ' >>  scr/common_setup.tcl
echo 'set full_chip 0 ' >>  scr/common_setup.tcl
echo 'set all_blocks "" ' >>  scr/common_setup.tcl
echo "set  DESIGN_NAME $top_name" >>  scr/common_setup.tcl
echo "set  Quen I8810_STA" >>  scr/common_setup.tcl
#####################################################################################################################
#### gen link data
#tclsh collect_data.tcl $VIEW

### wait spef

##sleep  2h



### run  arm 6.5t  func func1 scan mode
if (1) then
#set pt_cmd_var = "set cdc_run 0; set VIEW $VIEW; set RUN_ONECORNE 1;set mode "" ;set Quen $Quen"
#bsub -Ip -q $Quen  pt_shell -multi -x "$pt_cmd_var" -f scr/pt.tcl |& tee log/runlog
#pt_shell -multi -x "$pt_cmd_var" -f scr/pt_1015.tcl |& tee log/runlog


#### run func_1.8vpad 0.9std typic85
#set pt_cmd_var = "set cdc_run 0;set mode func ; set corner typ_85 ;set check setup; set VIEW $VIEW; set RUN_ONECORNE 1;set Quen $Quen"
#bsub -Ip -q $Quen  pt_shell -multi -x "$pt_cmd_var" -f scr/pt.tcl
set pt_cmd_var = "set cdc_run 0; set VIEW $VIEW; set RUN_ONECORNE 0;set mode "" ;set Quen $Quen"
pt_shell -multi -x "$pt_cmd_var" -f scr/pt_1015.tcl |& tee log/runlog

#set pt_cmd_var = "set cdc_run 0;set mode scan ; set corner typ_85 ;set check setup; set VIEW $VIEW; set RUN_ONECORNE 1;set Quen $Quen"
#bsub -Ip -q $Quen  pt_shell -multi -x "$pt_cmd_var" -f scr/pt.tcl
#
#
### run cdc mode 
#set pt_cmd_var = "set cdc_run 1;set VIEW $VIEW; set RUN_ONECORNE 0;set mode "";set Quen $Quen"
#bsub -Ip -q $Quen  pt_shell -multi -x "$pt_cmd_var" -f scr/pt.tcl |& tee log/runlog

#
##### run  func2=(std1.0v,pad1.8v) 312 ty modem 
#set pt_cmd_var = "set cdc_run 0;set mode func2 ; set corner typ_85 ;set check setup; set VIEW $VIEW; set RUN_ONECORNE 1;set Quen $Quen"
#bsub -Ip -q $Quen  pt_shell -multi -x "$pt_cmd_var" -f scr/pt.tcl
#set pt_cmd_var = "set cdc_run 0;set mode func2 ; set corner typ_85 ;set check hold; set VIEW $VIEW; set RUN_ONECORNE 1;set Quen $Quen"
#bsub -Ip -q $Quen  pt_shell -multi -x "$pt_cmd_var" -f scr/pt.tcl
##### run func3=(std1.0v,pad3.3v)  312 ty modem 
#set pt_cmd_var = "set cdc_run 0;set mode func3 ; set corner typ_85 ;set check setup; set VIEW $VIEW; set RUN_ONECORNE 1;set Quen $Quen"
#bsub -Ip -q $Quen  pt_shell -multi -x "$pt_cmd_var" -f scr/pt.tcl
#set pt_cmd_var = "set cdc_run 0;set mode func3 ; set corner typ_85 ;set check hold; set VIEW $VIEW; set RUN_ONECORNE 1;set Quen $Quen"
#bsub -Ip -q $Quen  pt_shell -multi -x "$pt_cmd_var" -f scr/pt.tcl

# source day.csh  $VIEW $top_name



endif

#find ./$VIEW/rpt/ -type f -name "*vio_summary*" -exec cat {} \; >> ./$VIEW/vio_summary.rpt
