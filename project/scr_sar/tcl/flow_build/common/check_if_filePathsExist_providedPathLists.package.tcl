#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/09/18 09:45:17 Thursday
# label     : package_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|report_proc|misc_proc)
#   perl -> (format_sub)
# descrip   : A Tcl proc that checks a list of absolute file paths to identify valid existing files, distinguishing them from non-existent paths and existing directories, 
#             featuring a debug option, printing categorized summaries, and returning results in a specified nested list format.
# return    : list: {{exist {/path/exists.list ...}} {notFound {/path/does/not/exist.list ...}}}
# related   : You can use the script ./convert_file_to_list.common.tcl to convert the file path list into a list data in Tcl, and then input it into this proc for detection.
# ref       : link url
# --------------------------
proc check_if_filePathsExist_providedPathLists { fileList { debug 0 } } {
  # 初始化三个列表用于存储不同类型的路径
  set existsFiles [list]
  set notFound [list]
  set folderPaths [list]
  # 检查输入是否为有效的列表
  if { ![llength $fileList] } {
    error "Invalid input: expected a list of file paths"
  }
  # 遍历每个文件路径
  foreach filePath $fileList {
    # 确保路径是字符串类型
    if { ![string is ascii $filePath] } {
      if { $debug } {
        puts "Skipping invalid path entry: $filePath (not a string)"
      }
      lappend notFound $filePath
      continue
    }
    if { $debug } {
      puts "Checking path: $filePath"
    }
    # 检查路径是否存在
    if { [file exists $filePath] } {
      # 检查是否为文件
      if { [file isfile $filePath] } {
        lappend existsFiles $filePath
        if { $debug } {
          puts "  - Found as valid file"
        }
      } else {
        # 存在但不是文件（可能是文件夹）
        lappend folderPaths $filePath
        lappend notFound $filePath
        if { $debug } {
          puts "  - Exists but is not a file (likely a directory)"
        }
      }
    } else {
      # 路径不存在
      lappend notFound $filePath
      if { $debug } {
        puts "  - Path not found"
      }
    }
  }
  if {$debug} {
    # 打印总结信息
    puts "\nSummary:"
    puts "  Valid files: [llength $existsFiles]"
    foreach f $existsFiles {
      puts "    - $f"
    }
    puts "\n  Existing folders (not counted as files): [llength $folderPaths]"
    foreach f $folderPaths {
      puts "    - $f"
    }
    puts "\n  Not found or invalid: [llength $notFound] (includes folders above)"
    foreach f $notFound {
      puts "    - $f"
    }
    puts ""
  }
  # 返回指定格式的嵌套列表
  return [list \
    [list exists $existsFiles] \
    [list notFound $notFound] \
  ]
}
if {0} {
  # 测试路径列表
  set testPaths {
    "/valid/file.txt"
    "/existing/folder"
    "/non/existent/path.txt"
    "/another/valid.doc"
  }
  # 调用过程（开启debug模式）
  set result [check_if_filePathsExist_providedPathLists $testPaths 0]
  # 查看返回结果
  puts "Returned result:"
  puts $result
}
