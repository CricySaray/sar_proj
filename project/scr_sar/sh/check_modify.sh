#!/bin/bash

# Function to display help information
show_help() {
  cat << EOF
Usage: $0 [TARGET_FOLDER] [TIME_LIMIT]
Description: Recursively scan a folder, track symlinks to the real file, list modified files sorted by modify time.

Parameters:
  TARGET_FOLDER    Required. The target folder to scan recursively.
  TIME_LIMIT       Optional. Time range to filter modified files (default: 10min).
                   Use 'nolimit' to show all files without time restriction.
                   Supported units: min (minutes), h (hours), d (days), e.g., 30min, 2h, 1d.

Output:
  Files sorted by modify time (oldest first, newest last).
  Returns "no modified files" if no matched files.
EOF
}

# Check if no arguments provided
if [ $# -eq 0 ]; then
  show_help
  exit 0
fi

# Assign parameters
TARGET_DIR="$1"
TIME_LIMIT="${2:-10min}"

# Check if target directory exists
if [ ! -d "$TARGET_DIR" ]; then
  echo "Error: Directory '$TARGET_DIR' does not exist!"
  exit 1
fi

# Function to get the REAL file (follow symlinks recursively)
get_real_file() {
  local file="$1"
  # Iterate until we get a non-symlink file
  while [ -L "$file" ]; do
    local link_target=$(readlink -e "$file")
    if [ -z "$link_target" ]; then
      return 1
    fi
    file="$link_target"
  done
  echo "$file"
}

# Temporary file to store results
TMP_FILE=$(mktemp)

# Get current timestamp
CURRENT_TS=$(date +%s)

# Recursively scan all files in target directory
find "$TARGET_DIR" -type f -o -type l | while read -r item; do
  # Get the final real file
  real_file=$(get_real_file "$item")
  if [ ! -e "$real_file" ]; then
    continue
  fi

  # Get modify timestamp of real file
  modify_ts=$(stat -c %Y "$real_file")
  # Get formatted modify time (like ls -l output)
  modify_time=$(stat -c "%y" "$real_file" | cut -d. -f1)
  # Calculate time difference (seconds)
  time_diff=$((CURRENT_TS - modify_ts))

  # Check time limit condition
  in_time_range=0
  if [ "$TIME_LIMIT" = "nolimit" ]; then
    in_time_range=1
  else
    # Parse time value and unit
    time_val=$(echo "$TIME_LIMIT" | sed -e 's/[^0-9]//g')
    time_unit=$(echo "$TIME_LIMIT" | sed -e 's/[0-9]//g')

    # Convert to seconds
    case "$time_unit" in
      min) limit_sec=$((time_val * 60)) ;;
      h) limit_sec=$((time_val * 3600)) ;;
      d) limit_sec=$((time_val * 86400)) ;;
      *) limit_sec=$((10 * 60)) ;; # default 10min
    esac

    if [ $time_diff -le $limit_sec ]; then
      in_time_range=1
    fi
  fi

  # Save to temp file if in time range
  if [ $in_time_range -eq 1 ]; then
    echo "$modify_ts|$modify_time|$item" >> "$TMP_FILE"
  fi
done

# Check if any results
if [ ! -s "$TMP_FILE" ]; then
  echo "no modified files"
  rm -f "$TMP_FILE"
  exit 0
fi

# Sort by modify time (oldest first, newest last) and print
sort -n "$TMP_FILE" | cut -d'|' -f2- | awk -F'|' '{printf "%-20s %s\n", $1, $2}'

# Cleanup
rm -f "$TMP_FILE"

exit 0
