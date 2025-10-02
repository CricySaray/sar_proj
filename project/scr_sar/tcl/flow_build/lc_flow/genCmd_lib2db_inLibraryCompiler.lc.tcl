#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/09/18 09:41:18 Thursday
# label     : flow_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|report_proc|misc_proc)
#   perl -> (format_sub)
# descrip   : By providing a list of lib files, generate commands that can be executed by the Library Compiler tool to convert lib files into db files. This script 
#             can also generate files that can be directly executed in the lc shell, and combine these commands into a single list to return as a return value.
# return    : cmd list for generating db from lib file list
# ref       : link url
# --------------------------
proc genCmd_lib2db_inLibraryCompiler {{lib_files_list {}} {dir_gen_db "./"} {lc_script_suffix ""}} {
  if {![llength $lib_files_list]} {
    error "proc genCmd_lib2db_inLibraryCompiler: check your input: lib_files_list($lib_files_list) is empty!!!" 
  } else {
    set cmdsList [list ]
    foreach temp_lib $lib_files_list {
      if {![file isfile $temp_lib]} {
        error "proc genCmd_lib2db_inLibraryCompiler: check your input: lib path($temp_lib) is not found!!!"
      } else {
        set file_tail [file tail $temp_lib] 
        set db_file_name [regsub {\.lib$} $file_tail ".db"]
        set db_name_in_LC "\[lindex \[get_object_name \[get_libs\]\] 0\]"
        lappend cmdsList "read_lib $temp_lib"
        lappend cmdsList "write_lib -format db -output $dir_gen_db/$db_file_name $db_name_in_LC"
        lappend cmdsList "remove_design -all"
      }
    }
    if {$lc_script_suffix == ""} {
      set outputfilename "lc_shell_lib2db_script.tcl" 
    } else {
      set outputfilename "lc_shell_lib2db_script_$lc_script_suffix.tcl" 
    }
    set fi [open $outputfilename w]
    puts $fi [join $cmdsList \n]
    close $fi
    return $cmdsList
  }
}
