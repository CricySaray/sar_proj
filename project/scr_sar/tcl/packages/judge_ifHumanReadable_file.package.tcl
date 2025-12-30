#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/12/30 16:56:57 Tuesday
# label     : package_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : This TCL procedure determines if a file is human-readable (readable via Vim without binary garble) by first detecting 
#             compressed formats and then validating ASCII-only content.
#             Abnormal scenarios (e.g., non-existent files, non-regular files) throw specific error messages instead of returning 0/1.
# return    : It returns 1 for human-readable files (non-compressed + ASCII-only) and 0 for non-readable files (compressed/non-ASCII binary content).
# ref       : link url
# --------------------------
proc is_human_readable_file {file_path {debug 0}} {
  # Define compression detection constants (no global variables)
  set compress_extensions {
    .zip .gz .gzip .bz2 .bzip2 .7z .rar .xz .lzma 
    .tar .tgz .tar.gz .tbz2 .tar.bz2 .txz .tar.xz 
    .z .lz4 .zstd .sz .tar.lz4 .tar.zstd
  }
  set compress_magic {
    {zip        {80 75 3 4} {80 75 5 6} {80 75 7 8}}
    {gzip       {31 139 8}}
    {bzip2      {66 90 104}}
    {7z         {55 122 188 175 39 28}}
    {rar        {82 97 114 33 26 7} {82 97 114 33 26 7 1 0}}
    {xz         {253 55 122 88 90 0}}
    {lzma       {93 0 0}}
    {tar        {117 115 116 97 114} {112 97 120 32} {99 112 105 111}}
    {lz4        {4 34 77 24}}
    {zstd       {40 181 47 253}}
    {compress   {31 157}}
  }

  # Debug print initial info
  if {$debug} {
    puts "\n=== Debug Mode: Checking file '$file_path' (human-readable status) ==="
  }

  # Step 1: Resolve real path (handle symbolic links)
  set path_result [_resolve_real_path $file_path]
  if {[lindex $path_result 0] ne "success"} {
    set err_msg [lindex $path_result 1]
    if {$debug} {
      puts "Debug Error: $err_msg"
    }
    error $err_msg
  }
  set real_path [lindex $path_result 1]
  if {$debug} {
    puts "Debug: Resolved real path - '$real_path'"
  }
  
  # Step 2: First check if file is compressed (compressed = non-readable)
  # 2.1 Check by extension
  set ext_result [_check_compress_by_ext $real_path $compress_extensions]
  if {[lindex $ext_result 0] eq "success"} {
    set format [lindex $ext_result 1]
    if {$debug} {
      puts "Debug: File is compressed (Format: $format, Method: extension) → NON-READABLE"
    }
    return 0
  }
  # 2.2 Fallback to magic number check if extension check fails
  set magic_result [_check_compress_by_magic $real_path $compress_magic]
  if {[lindex $magic_result 0] eq "error"} {
    set err_msg [lindex $magic_result 1]
    if {$debug} {
      puts "Debug Error: $err_msg"
    }
    error $err_msg
  }
  if {[lindex $magic_result 0] eq "success"} {
    set format [lindex $magic_result 1]
    if {$debug} {
      puts "Debug: File is compressed (Format: $format, Method: magic number) → NON-READABLE"
    }
    return 0
  }
  if {$debug} {
    puts "Debug: File is not compressed (neither extension nor magic number matched)"
  }
  
  # Step 3: Check if non-compressed file is ASCII-only (human-readable)
  # 3.1 Read sample bytes (10KB for performance)
  set sample_result [_read_file_sample_bytes $real_path 10240]
  if {[lindex $sample_result 0] eq "error"} {
    set err_msg [lindex $sample_result 1]
    if {$debug} {
      puts "Debug Error: $err_msg"
    }
    error $err_msg
  }
  set file_bytes [lindex $sample_result 1]
  
  # 3.2 Validate ASCII characters
  set ascii_check [_is_ascii_only $file_bytes]
  if {$ascii_check} {
    if {$debug} {
      puts "Debug: File is human-readable (ASCII-only, non-compressed)"
    }
    return 1
  } else {
    if {$debug} {
      puts "Debug: File is NON-READABLE (non-ASCII characters found)"
    }
    return 0
  }
}

# Resolve real file path (follow symbolic links recursively)
proc _resolve_real_path {file_path} {
  if {![file exists $file_path]} {
    return [list "error" "File does not exist: $file_path"]
  }
  
  set current_path $file_path
  # Follow symbolic links until non-link is found
  while {[string equal [file type $current_path] "link"]} {
    try {
      set link_target [file readlink $current_path]
      # Convert relative link to absolute path
      if {![file isabsolute $link_target]} {
        set link_target [file join [file dirname $current_path] $link_target]
      }
      set current_path $link_target
      # Check if link target exists
      if {![file exists $current_path]} {
        return [list "error" "Symbolic link target does not exist: $current_path"]
      }
    } on error {e} {
      return [list "error" "Failed to resolve symbolic link '$file_path': $e"]
    }
  }
  
  # Verify final path is a regular file
  if {![file isfile $current_path]} {
    return [list "error" "Path '$current_path' is not a regular file (directory/special file)"]
  }
  
  return [list "success" $current_path]
}

# Read first N bytes of file (return as decimal byte list)
proc _read_file_magic_bytes {file_path max_bytes} {
  # Validate input
  if {$max_bytes <= 0} {
    return [list "error" "Invalid max bytes: $max_bytes"]
  }
  
  # Open file in binary mode with read permission
  try {
    set fd [open $file_path rb]
  } on error {e} {
    return [list "error" "Failed to open file '$file_path': $e (permission denied or invalid file)"]
  }
  
  # Read bytes with cleanup
  try {
    set raw_data [read $fd $max_bytes]
    set byte_list {}
    binary scan $raw_data c* byte_list
    # Convert negative bytes (signed char) to unsigned decimal
    set unsigned_bytes {}
    foreach b $byte_list {
      lappend unsigned_bytes [expr {$b & 0xFF}]
    }
    return [list "success" $unsigned_bytes]
  } on error {e} {
    return [list "error" "Failed to read file '$file_path': $e"]
  } finally {
    catch {close $fd}
  }
}

# Read sample bytes for human-readable check (reuse magic byte read logic)
proc _read_file_sample_bytes {file_path sample_size} {
  return [_read_file_magic_bytes $file_path $sample_size]
}

# Check if byte list contains only human-readable ASCII characters
# Allowed range:
# - Printable ASCII: 0x20 (space) - 0x7E (~)
# - Common control chars: 0x09 (Tab), 0x0A (Newline), 0x0D (CR), 0x07 (Bell), 0x08 (Backspace)
proc _is_ascii_only {byte_list} {
  set allowed_control_chars {9 10 13 7 8}
  foreach byte $byte_list {
    # Reject non-ASCII bytes (> 127)
    if {$byte > 127} {
      return 0
    }
    # Reject control chars (0-31) not in allowed list
    if {$byte < 32 && [lsearch -exact $allowed_control_chars $byte] == -1} {
      return 0
    }
  }
  return 1
}

# Check compression by file extension (case-insensitive)
# Arguments:
#   file_path - Real path of the file to check
#   extensions - List of compression extensions to match
proc _check_compress_by_ext {file_path extensions} {
  # Get lowercase path (case-insensitive check)
  set lower_path [string tolower $file_path]
  foreach ext $extensions {
    set ext_length [string length $ext]
    # Skip if extension is longer than path
    if {$ext_length > [string length $lower_path]} {
      continue
    }
    # Calculate start index (fix: end only supports single number)
    set start_idx [expr {[string length $lower_path] - $ext_length}]
    set path_suffix [string range $lower_path $start_idx end]
    if {[string equal $path_suffix $ext]} {
      return [list "success" [string trimleft $ext .]]
    }
  }
  return [list "not_found" "No compression extension matched"]
}

# Check compression by magic number (most reliable method)
# Arguments:
#   file_path - Real path of the file to check
#   magic_map - Mapping of compression format to magic number lists
proc _check_compress_by_magic {file_path magic_map} {
  # Get max magic bytes length to read
  set max_magic_len 0
  foreach {format magic_list} $magic_map {
    foreach magic $magic_list {
      set len [llength $magic]
      if {$len > $max_magic_len} {
        set max_magic_len $len
      }
    }
  }
  
  # Read magic bytes from file
  set magic_result [_read_file_magic_bytes $file_path $max_magic_len]
  if {[lindex $magic_result 0] ne "success"} {
    return $magic_result
  }
  set file_bytes [lindex $magic_result 1]
  
  # Match magic numbers (decimal byte comparison, case-insensitive by nature)
  foreach {format magic_list} $magic_map {
    foreach magic $magic_list {
      set magic_len [llength $magic]
      # Skip if file has fewer bytes than magic number
      if {[llength $file_bytes] < $magic_len} {
        continue
      }
      # Extract file header bytes to match
      set file_header [lrange $file_bytes 0 [expr {$magic_len - 1}]]
      if {$file_header eq $magic} {
        return [list "success" $format]
      }
    }
  }
  
  return [list "not_found" "No compression magic number matched"]
}

# Test function: batch verify human-readable detection
proc _test_human_readable_detection {test_files} {
  puts "=== Human-Readable Detection Test ==="
  foreach file $test_files {
    puts "\nChecking file: $file"
    try {
      set result [is_human_readable_file $file 1]
      if {$result == 1} {
        puts "  Result: HUMAN-READABLE (return value: 1)"
      } else {
        puts "  Result: NON-READABLE (return value: 0)"
      }
    } on error {e} {
      puts "  Result: ERROR - $e"
    }
  }
}

# Test files (replace with your actual paths)
set test_files {
  "/tmp/test.txt"
  "/tmp/data.tar.gz"
  "/tmp/archive.7z"
  "/tmp/backup.lz4"
  "/tmp/symlink_to_zip"
  "/tmp/non_exist.file"
  "/tmp/test_dir"
  "/tmp/temp" 
  "/tmp/image.png" 
  "/tmp/script.sh"
}

# Run test (comment out if not needed)
# _test_human_readable_detection $test_files
