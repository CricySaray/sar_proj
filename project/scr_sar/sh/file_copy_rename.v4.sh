#!/bin/bash

# Enhanced File Copy Script - Handles current directory and multi-level subfolders
# Usage: ./file_copy_rename.sh [options]

# Default parameters
DRY_RUN=0
FILE_PATTERN=".*"        # Match filenames against this regex
PATH_PATTERN=""          # Match original folder names against this regex
NAME_TEMPLATE="{dir}_{subdir}_{file}"  # Naming template with full subdir hierarchy
FILE_PREFIX=""           # Prefix for output filenames
FILE_SUFFIX=""           # Suffix for output filenames
OVERWRITE=0              # Overwrite existing files (0=no, 1=yes)
RECURSIVE=1              # Process subfolders in original folders (0=no, 1=yes)
RECURSE_DIR_CHECK=0      # Check subfolders of source dir for original folders (0=no, 1=yes)
SOURCES=("./")           # Default source directory: current directory
TARGET_DIR="colsong"     # Default target directory
LOG_SUCCESS=()           # Log of successfully copied files
LOG_SKIPPED=()           # Log of files not matching patterns
LOG_OVERWRITTEN=()       # Log of overwritten files
LOG_DUPLICATES=()        # Log of files skipped due to duplicates

# Get relative path from full path and base directory
function get_relative_path {
  local full_path="$1"
  local base_dir="$2"
  # Handle current directory case (avoid leading "./")
  if [[ "$base_dir" == "." ]]; then
    echo "${full_path#./}"
  else
    echo "${full_path#$base_dir/}"
  fi
}

# Get directory name from path (last segment)
function get_dir_name {
  local path="$1"
  echo "$(basename "$path")"
}

# Show help information
function show_help {
  echo "Usage: $0 [options]"
  echo "Options:"
  echo "  -s, --sources        Source directories (default: './')"
  echo "  -t, --target         Target directory (default: 'colsong')"
  echo "  -f, --file-pattern   Regex for filenames (default: '.*')"
  echo "  -p, --path-pattern   Regex for original folder NAMES (default: empty=all)"
  echo "  -n, --name-template  Output filename template (default: '{dir}_{subdir}_{file}')"
  echo "  --prefix             Prefix for output filenames (default: '')"
  echo "  --suffix             Suffix for output filenames (default: '')"
  echo "  -o, --overwrite      Overwrite existing files (default: no)"
  echo "  -r, --no-recursive   Do not process subfolders in original folders"
  echo "  --recurse-dir-check  Check source dir's subfolders for original folders"
  echo "  -d, --dry-run        Dry run (show operations only)"
  echo "  -h, --help           Show this help message"
  exit 1
}

# Regular expression matching function
function matches_regex {
  local string="$1"
  local pattern="$2"
  
  # Empty pattern matches everything
  if [[ -z "$pattern" ]]; then
    return 0
  fi
  
  if [[ "$string" =~ $pattern ]]; then
    return 0  # Match success
  else
    return 1  # Match failed
  fi
}

# Replace template variables
function replace_template {
  local template="$1"
  local original_dir="$2"  # Name of original folder (matched by path-pattern)
  local subdir="$3"        # Multi-level subdirs (with . as separator)
  local file="$4"
  
  # Replace template variables
  template="${template//\{dir\}/$original_dir}"
  template="${template//\{subdir\}/$subdir}"
  template="${template//\{file\}/$file}"
  
  echo "$template"
}

# Generate final filename (including prefix and suffix)
function generate_final_filename {
  local base_name="$1"
  echo "${FILE_PREFIX}${base_name}${FILE_SUFFIX}"
}

# Process a single file
function process_file {
  local source_file="$1"
  local source_dir="$2"
  local original_dir="$3"  # Original folder name (matched by path-pattern)
  
  # Get relative path from source_dir
  rel_path=$(get_relative_path "$source_file" "$source_dir")
  
  # Get filename
  filename=$(basename "$source_file")
  
  # Apply file pattern filter
  if ! matches_regex "$filename" "$FILE_PATTERN"; then
    LOG_SKIPPED+=("File pattern not matched: $rel_path")
    return
  fi
  
  # Extract subdirectory part (relative to original_dir)
  # Original dir path: $source_dir/[...]/$original_dir
  # File path: $source_dir/[...]/$original_dir/subdir1/subdir2/file
  # => subdir should be "subdir1.subdir2"
  local original_dir_path=$(find "$source_dir" -type d -name "$original_dir" -print -quit 2>/dev/null)
  local rel_to_original=$(get_relative_path "$source_file" "$original_dir_path")
  local sub_dir=$(dirname "$rel_to_original")
  
  # Handle root of original dir (no subdirs)
  if [[ "$sub_dir" == "." ]]; then
    sub_dir=""
  else
    # Replace / with . for multi-level subdirs
    sub_dir="${sub_dir//\//.}"
  fi
  
  # Generate new filename
  new_base_filename=$(replace_template "$NAME_TEMPLATE" "$original_dir" "$sub_dir" "$filename")
  new_filename=$(generate_final_filename "$new_base_filename")
  
  # Construct target file path
  target_file="$TARGET_DIR/$new_filename"
  
  # Check if file exists
  if [[ -e "$target_file" ]]; then
    if [[ $OVERWRITE -eq 1 ]]; then
      LOG_OVERWRITTEN+=("Overwritten: $source_file -> $target_file")
    else
      LOG_DUPLICATES+=("Already exists (not overwritten): $source_file -> $target_file")
      return
    fi
  fi
  
  # Show operation
  if [[ $DRY_RUN -eq 1 ]]; then
    echo "Would copy (dry run): $source_file -> $target_file"
  else
    echo "Copying: $source_file -> $target_file"
    cp -f "$source_file" "$target_file" || { 
      echo "Error: Failed to copy $source_file"
      return
    }
  fi
  
  # Record successfully copied file
  LOG_SUCCESS+=("$source_file -> $target_file")
}

# Show processing report
function show_report {
  echo
  echo "========== Processing Report =========="
  
  echo
  echo "Successfully copied files ($((${#LOG_SUCCESS[@]}))):"
  for file in "${LOG_SUCCESS[@]}"; do
    echo "  - $file"
  done
  
  if [[ ${#LOG_OVERWRITTEN[@]} -gt 0 ]]; then
    echo
    echo "Overwritten files ($((${#LOG_OVERWRITTEN[@]}))):"
    for file in "${LOG_OVERWRITTEN[@]}"; do
      echo "  - $file"
    done
  fi
  
  if [[ ${#LOG_DUPLICATES[@]} -gt 0 ]]; then
    echo
    echo "Skipped due to duplicates ($((${#LOG_DUPLICATES[@]}))):"
    for file in "${LOG_DUPLICATES[@]}"; do
      echo "  - $file"
    done
  fi
  
  if [[ ${#LOG_SKIPPED[@]} -gt 0 ]]; then
    echo
    echo "Files not processed ($((${#LOG_SKIPPED[@]}))):"
    for file in "${LOG_SKIPPED[@]}"; do
      echo "  - $file"
    done
  fi
  
  echo
  echo "Operation completed"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -s|--sources)
      shift
      SOURCES=()
      while [[ $# -gt 0 && ! "$1" =~ ^- ]]; do
        SOURCES+=("$1")
        shift
      done
      ;;
    -t|--target)
      TARGET_DIR="$2"
      shift 2
      ;;
    -f|--file-pattern)
      FILE_PATTERN="$2"
      shift 2
      ;;
    -p|--path-pattern)
      PATH_PATTERN="$2"
      shift 2
      ;;
    -n|--name-template)
      NAME_TEMPLATE="$2"
      shift 2
      ;;
    --prefix)
      FILE_PREFIX="$2"
      shift 2
      ;;
    --suffix)
      FILE_SUFFIX="$2"
      shift 2
      ;;
    -o|--overwrite)
      OVERWRITE=1
      shift
      ;;
    -r|--no-recursive)
      RECURSIVE=0
      shift
      ;;
    --recurse-dir-check)
      RECURSE_DIR_CHECK=1
      shift
      ;;
    -d|--dry-run)
      DRY_RUN=1
      shift
      ;;
    -h|--help)
      show_help
      ;;
    *)
      echo "Unknown parameter: $1"
      show_help
      ;;
  esac
done

# Create target directory if needed
if [[ $DRY_RUN -eq 0 && ! -d "$TARGET_DIR" ]]; then
  mkdir -p "$TARGET_DIR" || { echo "Error: Failed to create target directory $TARGET_DIR"; exit 1; }
fi

# Process each source directory
for source_dir in "${SOURCES[@]}"; do
  # Normalize source directory path
  source_dir=$(realpath "$source_dir" 2>/dev/null || echo "$source_dir")
  
  if [[ ! -d "$source_dir" ]]; then
    echo "Warning: Source directory '$source_dir' does not exist, skipping"
    continue
  fi
  
  # Step 1: Identify "original folders" (source_dir下符合path-pattern的文件夹)
  original_folders=()
  
  # Define scope for searching original folders
  if [[ $RECURSE_DIR_CHECK -eq 0 ]]; then
    # Search only 1st-level subfolders of source_dir
    find "$source_dir" -maxdepth 1 -type d ! -path "$source_dir" -print0 | while IFS= read -r -d '' dir; do
      dir_name=$(get_dir_name "$dir")
      if matches_regex "$dir_name" "$PATH_PATTERN"; then
        original_folders+=("$dir")
      fi
    done
  else
    # Search all subfolders of source_dir recursively
    find "$source_dir" -type d ! -path "$source_dir" -print0 | while IFS= read -r -d '' dir; do
      dir_name=$(get_dir_name "$dir")
      if matches_regex "$dir_name" "$PATH_PATTERN"; then
        original_folders+=("$dir")
      fi
    done
  fi
  
  # Handle special case: if no original folders found and path-pattern is empty, treat source_dir as original folder
  if [[ ${#original_folders[@]} -eq 0 && -z "$PATH_PATTERN" ]]; then
    original_folders+=("$source_dir")
  fi
  
  # Step 2: Process files in each original folder
  for orig_folder in "${original_folders[@]}"; do
    orig_folder_name=$(get_dir_name "$orig_folder")
    
    # Define file search scope in original folder
    if [[ $RECURSIVE -eq 1 ]]; then
      # Include all subfolders of original folder
      find "$orig_folder" -type f -print0 | while IFS= read -r -d '' source_file; do
        process_file "$source_file" "$source_dir" "$orig_folder_name"
      done
    else
      # Only files directly in original folder (no subfolders)
      find "$orig_folder" -maxdepth 1 -type f -print0 | while IFS= read -r -d '' source_file; do
        process_file "$source_file" "$source_dir" "$orig_folder_name"
      done
    fi
  done
done

# Show processing report
show_report

exit 0
