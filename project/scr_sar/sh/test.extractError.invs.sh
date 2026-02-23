#!/bin/csh
# --------------------------
# author    : sar song
# date      : 2025/07/21 15:47:41 Monday
# label     : sum_csh
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|misc_proc)
# descrip   : Check if there are ERRORs in specified files and output results to screen and summary file
# ref       : link url
# --------------------------
# Enable error trapping
set noclobber
set errexit

# Define variables
set file_pattern = "$1"
set target_dir = "$2"
set summary_file = "summary.txt"
set error_count = 0

# Function: Display usage information and exit
# Usage: usage <exit_code>
function usage
  echo "Usage: $0 <file_pattern> <target_directory>"
  echo "Example: $0 \"*log*\" /var/log"
  exit $1
end

# Function: Check if a directory exists
# Usage: check_directory <directory_path>
function check_directory
  if (! -d "$1") then
    echo "Error: Directory $1 does not exist!"
    exit 1
  endif
end

# Function: Initialize summary file
# Usage: init_summary
function init_summary
  if (-e "$summary_file") then
    \rm -f "$summary_file"
  endif
  touch "$summary_file"
  
  echo "Check Time: `date`" > "$summary_file"
  echo "Target Directory: $target_dir" >> "$summary_file"
  echo "File Pattern: $file_pattern" >> "$summary_file"
  echo "----------------------------------------" >> "$summary_file"
end

# Function: Process a single file
# Usage: process_file <file_path>
function process_file
  set file = "$1"
  echo "Checking file: $file"
  
  # Check if file is readable
  if (! -r "$file") then
    echo "Warning: File $file is not readable, skipping check"
    echo "Warning: File $file is not readable" >> "$summary_file"
    return
  endif
  
  # Find ERRORs
  set errors = `grep -i "ERROR" "$file" 2>/dev/null`
  
  if ($status == 0) then
    @ error_count++
    echo "Errors found in file $file:"
    echo "$errors"
    echo "----------------------------------------"
    echo "File: $file" >> "$summary_file"
    echo "$errors" >> "$summary_file"
    echo "----------------------------------------" >> "$summary_file"
  endif
end

# Function: Display final results
# Usage: display_results
function display_results
  echo "----------------------------------------"
  echo "Check completed!"
  
  if ($error_count > 0) then
    echo "$error_count files with errors found"
    echo "See $summary_file for details"
  else
    echo "congratulations!!!  no ERROR!"
    echo "congratulations!!!  no ERROR!" >> "$summary_file"
  endif
end

# ---- Main Script ----

# Validate arguments
if ($#argv != 2) then
  usage 1
endif

# Check target directory
check_directory "$target_dir"

# Initialize summary file
init_summary

# Find and process files
echo "Checking files in directory $target_dir..."

foreach file (`find "$target_dir" -type f -name "$file_pattern" 2>/dev/null`)
  process_file "$file"
end

# Display results
display_results

# Exit
exit 0    
