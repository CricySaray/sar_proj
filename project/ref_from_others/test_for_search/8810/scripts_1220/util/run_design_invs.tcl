###cutRow
set cut_boxes ""
foreach b [dbGet [dbget top.insts.cell.baseClass block -p2].pHaloBox]  {lappend cut_boxes $b}
set bondary [dbShape [dbGet top.fplan.box] ANDNOT [dbGet top.fPlan.rows.box]]
if {![regexp init $vars(step) ] && "" == [dbShape [lindex $cut_boxes 0] INSIDE $bondary] } {
	puts "start cutRow" 
	foreach c $cut_boxes {cutRow -area $c }
} else {puts "already exists cutRow"}



###run
redirect -file $vars(rpt_dir)/report_utilization.rpt {design::reportUtilization}
set process 28
if {[regexp A7 $vars(cts_driver_cells)]} {
	set vt_groups "HVT *A7*P*TH* SVT *A7*P*TS* LVT *A7*P*TL* uLVT *A7*P*TUL*"
} else {
	set vt_groups "HVT *A9*P*TH* SVT *A9*P*TS* LVT *A9*P*TL* uLVT *A9*P*TUL*"
}
design::report_vt_usage -file $vars(rpt_dir)/report_vt_usage.rpt


