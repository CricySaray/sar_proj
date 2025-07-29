#!/bin/bash

# Enhanced File Copy Script - Matches directory names only, not full paths
# Usage: ./file_copy_rename.sh [options]

# Default parameters
DRY_RUN=0
SOURCES=("./")           # Default source directory: current directory
TARGET_DIR="colsong"     # Default target directory
FILE_PATTERN=".*"        # Default: match all files
PATH_PATTERN="test.*"          # Default: empty path pattern (match all directories)
NAME_TEMPLATE="{dir}.{subdir}{file}"  # Default naming template
FILE_PREFIX=""           # Default no prefix
FILE_SUFFIX=""           # Default no suffix
OVERWRITE=0              # Default do not overwrite existing files
RECURSIVE=0              # Process matched directories recursively
RECURSE_DIR_CHECK=0      # Recursively check all directory names

LOG_SUCCESS=()           # Store successfully copied files
LOG_SKIPPED=()           # Store files not matching patterns
LOG_OVERWRITTEN=()       # Store overwritten files
LOG_DUPLICATES=()        # Store files skipped due to duplicates

# Get relative path from full path and base directory
function get_relative_path {
  local full_path="$1"
  local base_dir="$2"
  echo "${full_path#$base_dir/}"
}

# Get directory name from path
function get_dir_name {
  local path="$1"
  echo "$(basename "$path")"
}

# Show help information
function show_help {
  echo "Usage: $0 [options]"
  echo "Options:"
  echo "  -s, --sources        List of source directories (default: './')"
  echo "  -t, --target         Target directory (default: 'colsong')"
  echo "  -f, --file-pattern   Regular expression for filenames (default: '.*')"
  echo "  -p, --path-pattern   Regular expression for directory NAMES (default: empty)"
  echo "  -n, --name-template  Output filename template (default: '{dir}_{file}')"
  echo "  --prefix             Prefix for output filenames (default: '')"
  echo "  --suffix             Suffix for output filenames (default: '')"
  echo "  -o, --overwrite      Overwrite existing files (default: no)"
  echo "  -r, --no-recursive   Do not process subfolders in matched directories"
  echo "  --recurse-dir-check  Recursively check all directory NAMES (not just first level)"
  echo "  -d, --dry-run        Perform dry run (show operations without copying)"
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
  local dir="$2"
  local subdir="$3"
  local file="$4"
  
  # Replace template variables
  template="${template//\{dir\}/$dir}"
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
  local dir_basename="$3"
  
  # Get relative path
  rel_path=$(get_relative_path "$source_file" "$source_dir")
  
  # Get filename
  filename=$(basename "$source_file")
  
  # Apply file pattern filter
  if ! matches_regex "$filename" "$FILE_PATTERN"; then
    LOG_SKIPPED+=("File pattern not matched: $rel_path")
    return
  fi
  
  # Extract subdirectory part
  sub_dir=$(dirname "$rel_path")
  if [[ "$sub_dir" == "." ]]; then
    sub_dir=""
  else
    # Replace path separators with underscores
    sub_dir="${sub_dir//\//_}"
  fi
  
  # Generate new filename
  new_base_filename=$(replace_template "$NAME_TEMPLATE" "$dir_basename" "$sub_dir" "$filename")
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

# Check if target directory exists, create if not
if [[ $DRY_RUN -eq 0 && ! -d "$TARGET_DIR" ]]; then
  mkdir -p "$TARGET_DIR" || { echo "Error: Failed to create target directory $TARGET_DIR"; exit 1; }
fi

# Process each source directory
for source_dir in "${SOURCES[@]}"; do
  # Normalize path
  source_dir=$(realpath "$source_dir")
  
  if [[ ! -d "$source_dir" ]]; then
    echo "Warning: Source directory '$source_dir' does not exist, skipping"
    continue
  fi
  
  # Get base name of source directory
  dir_basename=$(basename "$source_dir")
  
  # Collect directories to process
  if [[ -z "$PATH_PATTERN" ]]; then
    # Empty path pattern: process all files in base directory and subdirectories
    if [[ $RECURSIVE -eq 1 ]]; then
      find "$source_dir" -type f -print0 | while IFS= read -r -d '' source_file; do
        process_file "$source_file" "$source_dir" "$dir_basename"
      done
    else
      find "$source_dir" -maxdepth 1 -type f -print0 | while IFS= read -r -d '' source_file; do
        process_file "$source_file" "$source_dir" "$dir_basename"
      done
    fi
  else
    # Non-empty path pattern: check directory names against pattern
    
    # 1. Collect directories to check
    if [[ $RECURSE_DIR_CHECK -eq 0 ]]; then
      # Check only first-level directories
      dirs_to_check=()
      while IFS= read -r -d '' dir; do
        dirs_to_check+=("$dir")
      done < <(find "$source_dir" -maxdepth 1 -type d ! -name "." -print0)
    else
      # Check all directories recursively
      dirs_to_check=()
      while IFS= read -r -d '' dir; do
        dirs_to_check+=("$dir")
      done < <(find "$source_dir" -type d ! -path "$source_dir" -print0)
    fi
    
    # 2. Check each directory name against path pattern
    matched_dirs=()
    for dir in "${dirs_to_check[@]}"; do
echo "dir name : $dir_name"
      dir_name=$(get_dir_name "$dir")
      if matches_regex "$dir_name" "$PATH_PATTERN"; then
        matched_dirs+=("$dir")
      fi
    done
    
    # 3. Process files in matched directories
    for dir in "${matched_dirs[@]}"; do
      if [[ $RECURSIVE -eq 1 ]]; then
        # Process all files in subfolders
        find "$dir" -type f -print0 | while IFS= read -r -d '' source_file; do
          process_file "$source_file" "$source_dir" "$dir_basename"
        done
      else
        # Process only files in current directory
        find "$dir" -maxdepth 1 -type f -print0 | while IFS= read -r -d '' source_file; do
          process_file "$source_file" "$source_dir" "$dir_basename"
        done
      fi
    done
    
    # 4. Process files in base directory (base directory name is not checked)
    find "$source_dir" -maxdepth 1 -type f -print0 | while IFS= read -r -d '' source_file; do
      process_file "$source_file" "$source_dir" "$dir_basename"
    done
  fi
done

# Show processing report
show_report

exit 0
