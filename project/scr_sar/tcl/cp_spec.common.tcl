#!/bin/tclsh
# --------------------------
# from      : jiangyuan
# date      : 2025/07/08 12:26:55 Tuesday
# label     : misc_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|misc_proc)
#   -> atomic_proc : Specially used for calling and information transmission of other procs, 
#                    providing a variety of error prompt codes for easy debugging
#   -> display_proc : Specifically used for convenient access to information in the innovus command line, 
#                    focusing on data display and aesthetics
#   -> gui_proc   : for gui display, or effort can be viewed in invs GUI
#   -> task_proc  : composed of multiple atomic_proc , focus on logical integrity, 
#                   process control, error recovery, and the output of files and reports when solving problems.
#   -> misc_proc  : some other uses of procs
# descrip   : Collect files of the same type from different directories into the same folder 
#             and change the file names according to the different directories they are in.
# ref       : https://www.notion.so/copy-cp_spec-tcl-16ba8d0ab3d8806caf43e4581f659365?source=copy_link
# --------------------------
set RUN_DIR "/your/path/"    #注意这里的路径需要最后加上斜杠符号，否则后面regsub部分无法正常替换
set all_sums [glob -nocomplain ${RUN_DIR}/*/rpts/special_check/d2d_ss.dual_ports_mem.rpt.gz]
foreach sum $all_sums {
	set view [regsub {\/.*$} [regsub $RUN_DIR $sum ""] ""]
	set base [file tail $sum]
	puts "cp -fp $sum ${view}.${base}"     #这里加上-p这个option是为了方便看到copy的file的时间戳
	exec cp -fp $sum "${view}.${base}"
}
