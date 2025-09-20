#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/07/24
# label     : misc_proc
# descrip   : Merge sourced files with improved comment stripping; supports auto lang detection
# update    : 2025/08/08 修复TCL行内注释处理导致的代码重复问题
# --------------------------
namespace eval CatAll {
  variable state
  array set state {
    processed_files {}  ;# Record processed files
    recursion_depth {}  ;# Record recursion depth
    original_dir ""     ;# Original working directory
    target_dir ""       ;# Target file directory
  }

  proc init_state {original working} {
    variable state
    array unset state
    set state(processed_files) [dict create]
    set state(recursion_depth) [dict create]
    set state(original_dir) $original
    set state(target_dir) $working
  }

  proc is_file_processed {file} {
    variable state
    return [dict exists $state(processed_files) $file]
  }

  proc mark_file_processed {file} {
    variable state
    dict set state(processed_files) $file 1
  }

  proc set_recursion_depth {file depth} {
    variable state
    dict set state(recursion_depth) $file $depth
  }

  proc get_recursion_depth {file} {
    variable state
    return [dict get $state(recursion_depth) $file 0]
  }

  proc get_target_dir {} {
    variable state
    return $state(target_dir)
  }

  proc restore_original_dir {} {
    variable state
    catch {cd $state(original_dir)}
  }

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

    # Switch to the directory of current file
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
      set is_source_cmd 0
      set filename_part ""
      set remainder ""

      # Branch by language to detect include commands (source for TCL, require for Perl)
      if {$lang eq "tcl"} {
        if {[regexp {^\s*source\s+(\S+)(.*)$} $line -> fp rem]} {
          set is_source_cmd 1
          set filename_part $fp
          set remainder $rem
        }
      } elseif {$lang eq "perl"} {
        # Match Perl's require command (supports quoted and unquoted syntax)
        if {
          [regexp {^\s*require\s+(['"])(.*?)\1\s*;?\s*(.*)$} $line -> quote fp rem] ||
          [regexp {^\s*require\s+(\S+)\s*;?\s*(.*)$} $line -> fp rem]
        } {
          set is_source_cmd 1
          set filename_part $fp
          set remainder $rem

          # Clean up filename (remove semicolons, comments, etc.)
          set filename_part [string map {";" ""} $filename_part]
          set filename_part [string trimright $filename_part " \t;"]
          if {[string first "#" $filename_part] >= 0} {
            set filename_part [string range $filename_part 0 [expr {[string first "#" $filename_part] - 1}]]
            set filename_part [string trimright $filename_part " \t"]
          }
        }
      }

      if {$is_source_cmd} {
        if {$lang eq "tcl"} {
          # Handle TCL's quoted filename syntax
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
          # Clean up TCL filename
          set clean_file [string map {";" ""} $filename_part]
          set clean_file [string trimright $clean_file " \t;"]
          if {[string first "#" $clean_file] >= 0} {
            set clean_file [string range $clean_file 0 [expr {[string first "#" $clean_file] - 1}]]
            set clean_file [string trimright $clean_file " \t"]
          }
          lappend source_lines [list $clean_file $line]
        } else {
          # Directly use cleaned filename for Perl
          lappend source_lines [list $filename_part $line]
        }
      } else {
        lappend regular_lines $line
      }
    }
    close $fi

    # Process regular lines (strip comments if needed)
    foreach line $regular_lines {
      set processed_line [process_comments $line $comment_state $strip_mode]
      if {$processed_line ne ""} {
        puts $fo $processed_line
      }
    }

    # Process source lines (preserve order or sort)
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
    # Restore original directory before processing this file
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
    variable lang       ;# Language type (tcl/perl)
    variable brace_depth ;# Brace nesting depth
    variable in_quote   ;# Quote state (0: none, "': double quote, ': single quote)
    variable in_comment ;# In multi-line comment (for Perl)
    variable line_brace_depth ;# 单行内的括号深度变化
    variable line_in_quote   ;# 单行内的引号状态

    constructor {language} {
      set lang $language
      set brace_depth 0
      set in_quote 0
      set in_comment 0
      set line_brace_depth 0
      set line_in_quote 0
    }

    method cget {-lang} {
      return $lang
    }

    method update_brace {char} {
      # 同时更新全局括号深度和单行括号深度
      if {$in_quote == 0 && $in_comment == 0} {
        switch $char {
          "{" { 
            incr brace_depth 
            incr line_brace_depth
          }
          "}" { 
            if {$brace_depth > 0} { 
              incr brace_depth -1 
              incr line_brace_depth -1
            }
          }
        }
      }
      return $brace_depth
    }

    method update_quote {char prev_char} {
      # 同时更新全局引号状态和单行引号状态
      if {$in_comment == 0} {
        if {$in_quote == 0} {
          if {$char in {"\"" "'"}} {
            set in_quote $char
            set line_in_quote $char
          }
        } else {
          if {$char eq $in_quote} {
            set escape_count 0
            set p $prev_char
            # Check escape characters (e.g., \", \')
            while {$p eq "\\"} {
              incr escape_count
              set p [string index [my get_prev_prev] end]
            }
            # Only exit quote if even number of escapes
            if {$escape_count % 2 == 0} {
              set in_quote 0
              set line_in_quote 0
            }
          }
        }
      }
      return $in_quote
    }

    method get_prev_prev {} {
      return ""
    }

    method set_in_comment {val} {
      set in_comment $val
    }

    method get_state {} {
      return [list $brace_depth $in_quote $in_comment]
    }

    method set_state {state} {
      lassign $state brace_depth in_quote in_comment
      set brace_depth $brace_depth
      set in_quote $in_quote
      set in_comment $in_comment
      # 重置单行状态
      set line_brace_depth 0
      set line_in_quote 0
    }

    # 获取单行内的括号深度变化
    method get_line_brace_depth {} {
      return $line_brace_depth
    }

    # 获取单行内的引号状态
    method get_line_in_quote {} {
      return $line_in_quote
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
      lassign [$state_obj get_state] global_brace_depth global_in_quote global_in_comment
      set line_brace_depth [$state_obj get_line_brace_depth]
      set line_in_quote [$state_obj get_line_in_quote]

      # Handle multi-line comment continuation
      if {$global_in_comment} {
        if {$lang eq "perl" && $char eq "/" && $prev_char eq "*"} {
          $state_obj set_in_comment 0
          incr i
          set prev_char ""
          continue
        }
        # Keep comment if strip_mode doesn't include comment stripping (bit 1)
        if {![expr {$strip_mode & 1}]} {
          append result $char
        }
        set prev_char $char
        incr i
        continue
      }

      # Handle TCL's semicolon-followed comments (bit 2 in strip_mode)
      if {$lang eq "tcl" && ($strip_mode & 2) && $char eq "#" && $global_in_quote == 0} {
        # 提取当前位置前的内容
        set current_content [string range $line 0 [expr {$i-1}]]
        
        # 查找分号后跟随任意空格再跟#的模式
        if {[regexp {^(.*;)\s*#} $current_content$char -> code_part]} {
          # 只保留分号及前面的内容，不重复添加
          set result [string trimright $code_part]
          break
        }
      }

      # Handle TCL's standalone # comments (bit 1 in strip_mode)
      if {$lang eq "tcl" && ($strip_mode & 1) && $char eq "#" && $global_in_quote == 0} {
        set prefix [string range $line 0 [expr {$i-1}]]
        # 检查是否是行首注释（没有分号前置）
        if {![regexp {;} $prefix] && [string trim $prefix] eq ""} {
          break
        }
      }

      # Handle Perl's # comments 
      if {$lang eq "perl" && $char eq "#"} {
        # 特殊情况处理：排除$#变量格式
        if {$prev_char eq "$"} {
          # 这是Perl的$#特殊变量，不作为注释处理
          append result $char
          set prev_char $char
          incr i
          continue
        }
        
        # 检查是否需要处理行首注释 (strip_mode 1 或 3)
        set handle_line_comments [expr {$strip_mode & 1}]
        # 检查是否需要处理行内注释 (strip_mode 2 或 3)
        set handle_inline_comments [expr {$strip_mode & 2}]
        
        # 获取#号前的内容
        set prefix [string range $result 0 end]
        
        # 检查是否在当前行的引号内（跨多行的引号视为不在内）
        set in_current_line_quote [expr {$line_in_quote != 0}]
        # 检查是否在当前行的括号内（跨多行的括号视为不在内）
        set in_current_line_brace [expr {$line_brace_depth != 0}]
        
        if {!$in_current_line_quote} {
          # 判断是否为行首注释
          set is_line_comment [expr {[string trim $prefix] eq ""}]
          
          # 判断是否为行内注释：不在当前行的括号内且有有效代码
          set is_inline_comment [expr {![expr {[string trim $prefix] eq ""}] && !$in_current_line_brace}]
          
          # 根据模式处理注释
          if {($is_line_comment && $handle_line_comments) || 
              ($is_inline_comment && $handle_inline_comments)} {
            break  # 截断注释部分
          }
        }
        # 如果不满足上述条件，#号将被视为普通字符保留
      }

      # Handle Perl's multi-line comment start (/* ... */)
      if {$lang eq "perl" && ($strip_mode & 2) && $char eq "*" && $prev_char eq "/" && $global_in_quote == 0 && $global_brace_depth == 0} {
        $state_obj set_in_comment 1
        # Remove the leading "/" from result
        set result [string range $result 0 end-1]
        set prev_char $char
        incr i
        continue
      }

      # Add valid character to result
      append result $char
      set prev_char $char
      incr i
    }

    $state_obj set_state [$state_obj get_state]
    # Trim trailing whitespace but keep leading/trailing non-whitespace
    return [string trimright $result]
  }
}

proc cat_all {filename {output ""} {verbose 0} {max_depth 10} {exclude ""} {include_comments 1} {preserve_order 1} {strip_comments 0} {lang "auto"}} {
  # Auto-detect language based on file extension if lang is "auto"
  if {$lang eq "auto"} {
    set file_ext [string tolower [file extension $filename]]
    switch $file_ext {
      ".tcl" { set lang "tcl" }
      ".pl"  { set lang "perl" }
      default {
        puts "Error: Auto language detection failed. Unsupported file extension '$file_ext'. Use .tcl or .pl"
        return 1
      }
    }
    if {$verbose} {puts "Auto-detected language: $lang (from file extension $file_ext)"}
  }

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

  # Set default output file if not specified
  if {$output eq ""} {
    set output "all_$target_file"
    set output_path [file join $original_dir $output]
  } else {
    set output_path [file normalize [file join $original_dir $output]]
  }

  # Prepare options dictionary
  set opts [dict create \
    -verbose $verbose \
    -max_depth $max_depth \
    -exclude $exclude \
    -include_comments $include_comments \
    -preserve_order $preserve_order \
    -output $output_path \
    -strip_comments $strip_comments \
    -lang $lang]

  # Open output file
  if {[catch {set fo [open $output_path w]} err]} {
    puts "Error: Failed to open output file ($output_path): $err"
    CatAll::restore_original_dir
    return 1
  }
  fconfigure $fo -encoding utf-8

  # Process main file
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

# Command line execution
if {$argc > 0} {
  set filename [lindex $argv 0]
  set options [lrange $argv 1 end]
  # Default values
  set output ""; set verbose 1; set max_depth 10; set exclude ""
  set include_comments 0; set preserve_order 1; set strip_comments 3; set lang "auto"

  # Parse command line options
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

  # Execute main function
  cat_all $filename $output $verbose $max_depth $exclude $include_comments $preserve_order $strip_comments $lang
} else {
  # Usage help (Chinese explanation for options)
  puts "Usage: $argv0 filename ?options?"
  puts "功能：合并脚本文件中通过 source (TCL) 或 require (Perl) 引用的所有文件"
  puts "\n选项说明："
  puts "  -output outfile      指定输出文件路径（默认：当前目录下 all_原文件名）"
  puts "  -verbose 0|1         是否显示详细处理过程（0=不显示，1=显示，默认：1）"
  puts "  -max_depth n         最大递归深度（防止无限递归，默认：10）"
  puts "  -exclude pattern     排除符合模式的文件（支持通配符，如 *.tmp）"
  puts "  -include_comments 0|1 是否保留合并标记注释（0=不保留，1=保留，默认：0）"
  puts "  -preserve_order 0|1  是否保留原文件引用顺序（0=按文件名排序，1=保留原顺序，默认：1）"
  puts "  -strip_comments mode 注释处理模式（0=保留所有注释，1=移除行首注释，2=移除行内注释，3=移除所有注释，默认：3）"
  puts "  -lang tcl|perl|auto  指定脚本语言（auto=通过文件后缀自动识别，.tcl→tcl，.pl→perl，默认：auto）"
  puts "\n注释处理说明："
  puts "  TCL: 行内注释需以分号(;)开头，可跟空格，再跟#号，如: set var 1 ;# 这是注释"
  puts "  Perl: 仅当#不在同一行的引号/括号内，且不是$#变量格式时视为注释"
  puts "\n示例："
  puts "  $argv0 main.tcl"
  puts "  $argv0 app.pl -output merged_app.pl -lang perl"
}

