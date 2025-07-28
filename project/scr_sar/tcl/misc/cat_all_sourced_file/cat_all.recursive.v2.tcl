#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/07/24
# label     : misc_proc
# descrip   : Merge sourced files with improved comment stripping (fixed inline comments)
# update    : 2025/07/25 修复行内注释去除逻辑，处理括号内注释和分号后空白
#             2025/07/27 增加自动切换文件所在目录功能，修复相对路径解析问题
# --------------------------
namespace eval CatAll {
  variable state
  array set state {
    processed_files {}  ;# 记录已处理的文件
    recursion_depth {}  ;# 记录递归深度
    original_dir ""     ;# 原始工作目录
    target_dir ""       ;# 目标文件所在目录
  }
  proc init_state {original working} {
    variable state
    array unset state
    set state(processed_files) [dict create]
    set state(recursion_depth) [dict create]
    set state(original_dir) $original
    set state(target_dir) $working
  }
  proc is_file_processed {file} {variable state; return [dict exists $state(processed_files) $file]}
  proc mark_file_processed {file} {variable state; dict set state(processed_files) $file 1}
  proc set_recursion_depth {file depth} {variable state; dict set state(recursion_depth) $file $depth}
  proc get_recursion_depth {file} {variable state; return [dict get $state(recursion_depth) $file 0]}
  proc get_target_dir {} {variable state; return $state(target_dir)}
  proc restore_original_dir {} {variable state; catch {cd $state(original_dir)}}
  proc process_file {filename fo depth opts} {
    set max_depth [dict get $opts -max_depth]
    if {$depth > $max_depth} {
      set msg "Maximum recursion depth ($max_depth) reached for $filename"
      puts $fo "# WARNING: $msg"
      if {[dict get $opts -verbose]} {puts "Warning: $msg"}
      return
    }
    set current_dir [pwd]
    set abs_path [file normalize [file join $current_dir $filename]]
    if {[is_file_processed $abs_path]} {
      set msg "Skipping already processed file: $filename"
      puts $fo "# $msg"
      if {[dict get $opts -verbose]} {puts $msg}
      return
    }
    mark_file_processed $abs_path
    set_recursion_depth $abs_path $depth
    set exclude [dict get $opts -exclude]
    if {$exclude ne "" && [string match $exclude $abs_path]} {
      set msg "Excluded by pattern: $filename"
      puts $fo "# $msg"
      if {[dict get $opts -verbose]} {puts $msg}
      return
    }
    if {![file exists $filename]} {
      set msg "File not found: $filename (resolved to $abs_path)"
      puts $fo "# ERROR: $msg"
      if {[dict get $opts -verbose]} {puts "Error: $msg"}
      return
    }
    if {[catch {set fi [open $filename r]} err]} {
      set msg "Failed to open file $filename: $err"
      puts $fo "# ERROR: $msg"
      if {[dict get $opts -verbose]} {puts "Error: $msg"}
      return
    }
    fconfigure $fi -encoding utf-8

    # 新增：切换到当前文件所在目录
    set file_dir [file dirname $abs_path]
    set original_processing_dir [pwd]
    cd $file_dir

    set lang [dict get $opts -lang]
    set strip_mode [dict get $opts -strip_comments]
    set comment_state [CommentState new $lang]
    if {[dict get $opts -include_comments]} {
      puts $fo "\n#"
      puts $fo "# START OF FILE: $filename (depth $depth)"
      puts $fo "# Resolved path: $abs_path"
      puts $fo "#"
    }
    set source_lines [list]
    set regular_lines [list]
    while {[gets $fi line] >= 0} {
      if {[regexp {^\s*source\s+(\S+)(.*)$} $line -> filename_part remainder]} {
        if {[string index $filename_part 0] eq "\""} {
          if {[regexp {^"([^"]*)"(.*)$} $filename_part -> clean_file rest]} {
            lappend source_lines [list $clean_file $line]
            continue
          }
        } elseif {[string index $filename_part 0] eq "'"} {
          if {[regexp {^'([^']*)'(.*)$} $filename_part -> clean_file rest]} {
            lappend source_lines [list $clean_file $line]
            continue
          }
        }
        set clean_file [string map {";" ""} $filename_part]
        set clean_file [string trimright $clean_file " \t;"]
        if {[string first "#" $clean_file] >= 0} {
          set clean_file [string range $clean_file 0 [expr {[string first "#" $clean_file] - 1}]]
          set clean_file [string trimright $clean_file " \t"]
        }
        lappend source_lines [list $clean_file $line]
      } else {
        lappend regular_lines $line
      }
    }
    close $fi

    foreach line $regular_lines {
      set processed_line [process_comments $line $comment_state $strip_mode]
      if {$processed_line ne ""} {
        puts $fo $processed_line
      }
    }
    if {[dict get $opts -preserve_order]} {
      foreach item $source_lines {
        lassign $item src_file orig_line
        process_source_line $src_file $orig_line $fo [expr {$depth + 1}] $opts
      }
    } else {
      foreach item [lsort -index 0 $source_lines] {
        lassign $item src_file orig_line
        process_source_line $src_file $orig_line $fo [expr {$depth + 1}] $opts
      }
    }
    if {[dict get $opts -include_comments]} {
      puts $fo "\n#"
      puts $fo "# END OF FILE: $filename (depth $depth)"
      puts $fo "#"
    }
    $comment_state destroy

    # 新增：恢复到处理该文件前的目录
    cd $original_processing_dir
  }
  proc process_source_line {src_file orig_line fo depth opts} {
    if {[dict get $opts -include_comments]} {
      puts $fo "\n# SOURCE COMMAND: $orig_line"
      puts $fo "# Resolving: $src_file (from current working directory)"
    }
    process_file $src_file $fo $depth $opts
  }
  oo::class create CommentState {
    variable lang       ;# 语言类型(tcl/perl)
    variable brace_depth ;# 括号嵌套深度
    variable in_quote   ;# 引号状态(0:无, "':双引号, ':单引号)
    variable in_comment ;# 是否在注释中(perl多行注释用)
    constructor {language} {
      set lang $language
      set brace_depth 0
      set in_quote 0
      set in_comment 0
    }
    method cget {-lang} {return $lang}
    method update_brace {char} {
      if {$in_quote == 0 && $in_comment == 0} {
        switch $char {
          "{" { incr brace_depth }
          "}" { if {$brace_depth > 0} { incr brace_depth -1 } }
        }
      }
      return $brace_depth
    }
    method update_quote {char prev_char} {
      if {$in_comment == 0} {
        if {$in_quote == 0} {
          if {$char in {"\"" "'"}} {
            set in_quote $char
          }
        } else {
          if {$char eq $in_quote} {
            set escape_count 0
            set p $prev_char
            while {$p eq "\\"} {
              incr escape_count
              set p [string index [my get_prev_prev] end]
            }
            if {$escape_count % 2 == 0} {
              set in_quote 0
            }
          }
        }
      }
      return $in_quote
    }
    method get_prev_prev {} {return ""}
    method set_in_comment {val} {set in_comment $val}
    method get_state {} {return [list $brace_depth $in_quote $in_comment]}
    method set_state {state} {
      lassign $state brace_depth in_quote in_comment
      set brace_depth $brace_depth
      set in_quote $in_quote
      set in_comment $in_comment
    }
  }
  proc process_comments {line state_obj strip_mode} {
    set lang [$state_obj cget -lang]
    set current_state [$state_obj get_state]
    $state_obj set_state $current_state
    set result ""
    set len [string length $line]
    set prev_char ""
    set i 0
    while {$i < $len} {
      set char [string index $line $i]
      $state_obj update_brace $char
      $state_obj update_quote $char $prev_char
      lassign [$state_obj get_state] brace_depth in_quote in_comment
      if {$in_comment} {
        if {$lang eq "perl" && $char eq "/" && $prev_char eq "*"} {
          $state_obj set_in_comment 0
          incr i
          set prev_char ""
          continue
        }
        if {![expr {$strip_mode & 1}]} {
          append result $char
        }
        set prev_char $char
        incr i
        continue
      }
      if {$lang eq "tcl" && ($strip_mode & 2) && $char eq ";" && $in_quote == 0} {
        append result $char
        set prev_char $char
        incr i
        set found_comment 0
        while {$i < $len} {
          set c [string index $line $i]
          if {[string trim $c] eq ""} {
            append result $c
            set prev_char $c
            incr i
          } elseif {$c eq "#"} {
            set found_comment 1
            break
          } else {
            append result $c
            set prev_char $c
            incr i
          }
        }
        if {$found_comment} {
          break
        }
        continue
      }
      if {$lang eq "tcl" && ($strip_mode & 1) && $char eq "#" && $in_quote == 0} {
        set prefix [string range $line 0 [expr {$i-1}]]
        if {[string trim $prefix] eq ""} {
          break
        }
      }
      if {$lang eq "perl" && ($strip_mode & 2) && $char eq "#" && $in_quote == 0 && $brace_depth == 0} {
        break
      }
      if {$lang eq "perl" && ($strip_mode & 2) && $char eq "*" && $prev_char eq "/" && $in_quote == 0 && $brace_depth == 0} {
        $state_obj set_in_comment 1
        set result [string range $result 0 end-1]
        set prev_char $char
        incr i
        continue
      }
      append result $char
      set prev_char $char
      incr i
    }
    $state_obj set_state [$state_obj get_state]
    return [string trimright $result]
  }
}
proc cat_all {filename {output ""} {verbose 0} {max_depth 10} {exclude ""} {include_comments 1} {preserve_order 1} {strip_comments 0} {lang "tcl"}} {
  set original_dir [file normalize [pwd]]
  set target_file_abs [file normalize $filename]
  if {![file exists $target_file_abs]} {
    puts "Error: Target file not found - $filename"
    return 1
  }
  set target_dir [file dirname $target_file_abs]
  set target_file [file tail $target_file_abs]
  CatAll::init_state $original_dir $target_dir
  if {[catch {cd $target_dir} err]} {
    puts "Error: Failed to change to target directory ($target_dir): $err"
    return 1
  }
  if {$output eq ""} {
    set output "all_$target_file"
    set output_path [file join $original_dir $output]
  } else {
    set output_path [file normalize [file join $original_dir $output]]
  }
  set opts [dict create \
    -verbose $verbose \
    -max_depth $max_depth \
    -exclude $exclude \
    -include_comments $include_comments \
    -preserve_order $preserve_order \
    -output $output_path \
    -strip_comments $strip_comments \
    -lang $lang]
  if {[catch {set fo [open $output_path w]} err]} {
    puts "Error: Failed to open output file ($output_path): $err"
    CatAll::restore_original_dir
    return 1
  }
  fconfigure $fo -encoding utf-8
  if {[catch {
    CatAll::process_file $target_file $fo 0 $opts
  } err]} {
    puts "Error during processing: $err"
  }
  close $fo
  CatAll::restore_original_dir
  if {[dict get $opts -verbose]} {
    puts "Merged file created: $output_path"
  }
  return 0
}
if {$argc > 0} {
  set filename [lindex $argv 0]
  set options [lrange $argv 1 end]
  set output ""; set verbose 0; set max_depth 10; set exclude ""
  set include_comments 0; set preserve_order 1; set strip_comments 3; set lang "tcl"
  for {set i 0} {$i < [llength $options]} {incr i} {
    set opt [lindex $options $i]
    switch -- $opt {
      "-output" {incr i; set output [lindex $options $i]}
      "-verbose" {incr i; set verbose [lindex $options $i]}
      "-max_depth" {incr i; set max_depth [lindex $options $i]}
      "-exclude" {incr i; set exclude [lindex $options $i]}
      "-include_comments" {incr i; set include_comments [lindex $options $i]}
      "-preserve_order" {incr i; set preserve_order [lindex $options $i]}
      "-strip_comments" {incr i; set strip_comments [lindex $options $i]}
      "-lang" {incr i; set lang [lindex $options $i]}
      default {
        puts "Unknown option: $opt"
        exit 1
      }
    }
  }
  cat_all $filename $output $verbose $max_depth $exclude $include_comments $preserve_order $strip_comments $lang
} else {
  puts "Usage: $argv0 filename ?options?"
  puts "Options:"
  puts "  -output outfile      输出文件路径"
  puts "  -verbose 0|1         显示详细信息"
  puts "  -max_depth n         最大递归深度"
  puts "  -exclude pattern     排除文件模式"
  puts "  -include_comments 0|1 保留合并标记"
  puts "  -preserve_order 0|1  保留原顺序"
  puts "  -strip_comments mode 注释处理模式(0-3)"
  puts "  -lang tcl|perl       语言类型"
}
