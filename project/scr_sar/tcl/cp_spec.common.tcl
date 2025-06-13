#!/bin/tclsh
# from jiangyuan
# ref : https://www.notion.so/copy-cp_spec-tcl-16ba8d0ab3d8806caf43e4581f659365?source=copy_link
set RUN_DIR "/your/path/"    #注意这里的路径需要最后加上斜杠符号，否则后面regsub部分无法正常替换
set all_sums [glob -nocomplain ${RUN_DIR}/*/rpts/special_check/d2d_ss.dual_ports_mem.rpt.gz]
foreach sum $all_sums {
	set view [regsub {\/.*$} [regsub $RUN_DIR $sum ""] ""]
	set base [file tail $sum]
	puts "cp -fp $sum ${view}.${base}"     #这里加上-p这个option是为了方便看到copy的file的时间戳
	exec cp -fp $sum "${view}.${base}"
}
