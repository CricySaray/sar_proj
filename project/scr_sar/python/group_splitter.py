#!/usr/bin/env python3
# --------------------------
# author    : sar song
# date      : 2025/08/29 17:27:42 Friday
# label     : misc_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|misc_proc)
# descrip   : This Python script splits content from an input file into separate files based on group headers formatted as "======= Group Name =======", 
#             extracting each group's content and saving it to a file named with the group name (customizable with prefixes, suffixes, and extensions).  
#             It includes features like overwrite protection, error handling, and detailed processing summaries, making it useful for organizing 
#             structured content into categorized files.
#           you can get help info using "python3.6 [this script name] -h"
# related   : this script can use combined with script: ./file_categorizer.py
#             NOTICE: Use ./file_categorizer.py to write the generated content into the "outputfile", which then serves as the "inputfile" for this script; 
#             the regular expression for capturing group names can remain default and will work properly.
# return    : several output files that is grouped by input file content
# ref       : link url
# --------------------------
import os
import re
import argparse
import sys
from typing import List, Tuple, Optional


# --------------------------
# Configuration - Modify defaults here
# --------------------------
# Regex pattern to match group header lines (format: "======= Group Name =======")
GROUP_HEADER_PATTERN = re.compile(r'^===== (.*) =====$')

# Default values for command-line arguments
DEFAULT_INPUT = "cates_mem_lib.list"                # Default input file path (empty = require user input)
DEFAULT_PREFIX = ""               # Output filename prefix
DEFAULT_SUFFIX = ".lib_setup"               # Output filename suffix
DEFAULT_EXTENSION = "list"         # Output file extension
DEFAULT_OVERWRITE = 1             # Allow overwriting existing files (0=disallow, 1=allow)
DEFAULT_OUTPUT_DIR = ""           # Default output directory (empty = current directory)
MAX_PREVIEW_LINES = 5             # Max lines to preview for ungrouped content
PROGRESS_UPDATE_INTERVAL = 5      # Progress update interval (groups)


# --------------------------
# Data Structures
# --------------------------
class ProcessingStats:
  """Class to track and manage processing statistics"""
  def __init__(self):
    self.total_groups = 0          # Total valid groups detected
    self.successful_writes = 0     # Groups successfully written to files
    self.overwritten_files = []    # List of overwritten filenames
    self.skipped_groups = []       # Skipped groups (name, reason)
    self.ungrouped_lines = []      # Lines not belonging to any group
    self.failed_writes = []        # Failed writes (group name, filename, error)


# --------------------------
# Core Functions
# --------------------------
def parse_command_line_args() -> argparse.Namespace:
  """Parse and validate command-line arguments, return validated namespace"""
  parser = argparse.ArgumentParser(
    description="""Split grouped content into separate files based on group headers.
    
This script processes files containing grouped content, where each group is marked with a header line
in the format "======= Group Name =======". It extracts content from each group and writes it to
individual files, with configurable naming options.

Default values can be permanently set in the Configuration section at the top of this script.

The input file should follow this structure:
  ======= Group 1 =======
  Content line 1
  Content line 2
  
  ======= Group 2 =======
  Another content line
  ...
""",
    formatter_class=argparse.RawTextHelpFormatter
  )

  # Input file (with default from config)
  parser.add_argument(
    "--input", "-i",
    default=DEFAULT_INPUT,
    help=f"Path to input file containing grouped content\n"
         f"Must be properly formatted with group headers\n"
         f"Example: --input grouped_content.txt\n"
         f"Default: {'(configured in script)' if DEFAULT_INPUT else 'none - required'}"
  )

  # Optional filename customization
  parser.add_argument(
    "--prefix", "-p",
    default=DEFAULT_PREFIX,
    help=f"Prefix to add before the group name in output filenames\n"
         f"Example: --prefix 'data_' → 'data_Group1.txt'\n"
         f"Default: '{DEFAULT_PREFIX}'"
  )
  parser.add_argument(
    "--suffix", "-s",
    default=DEFAULT_SUFFIX,
    help=f"Suffix to add after the group name in output filenames\n"
         f"Example: --suffix '_2023' → 'Group1_2023.txt'\n"
         f"Default: '{DEFAULT_SUFFIX}'"
  )
  parser.add_argument(
    "--ext", "-e",
    default=DEFAULT_EXTENSION,
    help=f"File extension for output files (without leading dot)\n"
         f"Example: --ext 'log' → 'Group1.log'\n"
         f"Default: '{DEFAULT_EXTENSION}'"
  )

  # File write control
  parser.add_argument(
    "--overwrite", "-o",
    type=int,
    choices=[0, 1],
    default=DEFAULT_OVERWRITE,
    help=f"Allow overwriting existing files\n"
         f"0 = Do not overwrite (skip existing files)\n"
         f"1 = Overwrite existing files\n"
         f"Default: {DEFAULT_OVERWRITE}"
  )
  parser.add_argument(
    "--output-dir", "-d",
    default=DEFAULT_OUTPUT_DIR,
    help=f"Directory where output files will be saved\n"
         f"Will be created if it doesn't exist\n"
         f"Example: --output-dir ./output_files\n"
         f"Default: {'(configured in script)' if DEFAULT_OUTPUT_DIR else 'current directory'}"
  )

  args = parser.parse_args()

  # Validate input file is provided (either via CLI or config)
  if not args.input:
    parser.error("Error: Input file is required. Provide it with --input or set DEFAULT_INPUT in the script.")

  # Validate input file exists and is readable
  if not os.path.isfile(args.input):
    parser.error(f"Error: Input file '{args.input}' does not exist or is not a file")
  if not os.access(args.input, os.R_OK):
    parser.error(f"Error: Permission denied - Cannot read input file '{args.input}'")

  # Set default output directory if not configured
  if not args.output_dir:
    args.output_dir = "."

  # Validate and prepare output directory
  try:
    os.makedirs(args.output_dir, exist_ok=True)  # Create if missing
    if not os.access(args.output_dir, os.W_OK):
      parser.error(f"Error: Permission denied - Cannot write to output directory '{args.output_dir}'")
  except Exception as e:
    parser.error(f"Error: Failed to prepare output directory '{args.output_dir}': {str(e)}")

  # Clean up file extension (remove possible leading dot)
  args.ext = args.ext.lstrip('.')

  return args


def extract_groups_from_input(input_path: str, stats: ProcessingStats) -> List[Tuple[str, List[str]]]:
  """
  Extract groups (name + content) from input file
  Preserves original line breaks and skips empty groups
  Updates statistics including ungrouped lines and skipped empty groups
  """
  groups = []
  current_group_name: Optional[str] = None
  current_group_content: List[str] = []  # Stores lines with original newlines

  try:
    with open(input_path, 'r', encoding='utf-8') as f:
      for line_num, raw_line in enumerate(f, 1):
        # Check if line matches group header pattern
        header_match = GROUP_HEADER_PATTERN.match(raw_line.strip())
        if header_match:
          # Process previous group if it exists before starting new one
          if current_group_name is not None:
            # Check if group has non-empty content (ignore all whitespace lines)
            has_valid_content = any(not line.strip() == "" for line in current_group_content)
            if has_valid_content:
              groups.append((current_group_name, current_group_content))
              stats.total_groups += 1
            else:
              stats.skipped_groups.append(
                (current_group_name, f"Empty group (line {line_num})")
              )

          # Initialize new group
          new_group_name = header_match.group(1).strip()
          # Skip empty group names (invalid)
          if not new_group_name:
            stats.skipped_groups.append(
              ("[Empty Group Name]", f"Invalid empty group name (line {line_num})")
            )
            current_group_name = None
            current_group_content = []
          else:
            current_group_name = new_group_name
            current_group_content = []

        else:
          # Add line to current group if active
          if current_group_name is not None:
            current_group_content.append(raw_line)
          else:
            # Collect lines that don't belong to any group
            stats.ungrouped_lines.append(raw_line)

      # Process last group after reaching end of file
      if current_group_name is not None:
        has_valid_content = any(not line.strip() == "" for line in current_group_content)
        if has_valid_content:
          groups.append((current_group_name, current_group_content))
          stats.total_groups += 1
        else:
          stats.skipped_groups.append(
            (current_group_name, "Empty group (end of file)")
          )

  except Exception as e:
    raise RuntimeError(f"Failed to read input file: {str(e)}")

  return groups


def generate_valid_filename(
  group_name: str,
  prefix: str,
  suffix: str,
  ext: str,
  output_dir: str
) -> str:
  """
  Generate valid, sanitized filename for a group:
  1. Replace spaces and path separators with underscores (avoids invalid characters)
  2. Combine prefix → sanitized group name → suffix
  3. Add file extension if provided
  4. Resolve to absolute path in output directory
  """
  # Sanitize group name (replace invalid filename characters)
  sanitized_group = (
    group_name.replace(' ', '_')
    .replace('/', '_')
    .replace('\\', '_')
    .replace(':', '_')
    .replace('*', '_')
    .replace('?', '_')
    .replace('"', '_')
    .replace('<', '_')
    .replace('>', '_')
    .replace('|', '_')
  )

  # Build base filename (skip empty parts to avoid double underscores)
  filename_parts = []
  if prefix.strip():
    filename_parts.append(prefix.strip())
  if sanitized_group:
    filename_parts.append(sanitized_group)
  if suffix.strip():
    filename_parts.append(suffix.strip())
  
  base_filename = "".join(filename_parts) if filename_parts else "untitled_group"

  # Add file extension if specified
  full_filename = f"{base_filename}.{ext}" if ext else base_filename

  # Resolve to absolute path in output directory
  return os.path.abspath(os.path.join(output_dir, full_filename))


def write_group_content(
  group_name: str,
  group_content: List[str],
  filename: str,
  allow_overwrite: int,
  stats: ProcessingStats
) -> None:
  """
  Write group content to file with overwrite protection and error handling
  Updates statistics with write results
  """
  # Check if file exists (skip if overwrite disabled)
  if os.path.isfile(filename):
    if not allow_overwrite:
      stats.skipped_groups.append(
        (group_name, f"File '{os.path.basename(filename)}' exists (overwrite disabled)")
      )
      return
    else:
      # Track files that will be overwritten
      stats.overwritten_files.append(os.path.basename(filename))

  try:
    # Write content to file (overwrites if allowed)
    with open(filename, 'w', encoding='utf-8') as f:
      f.writelines(group_content)
    
    stats.successful_writes += 1

  except PermissionError:
    stats.failed_writes.append(
      (group_name, os.path.basename(filename), "Permission denied (cannot write file)")
    )
  except OSError as e:
    stats.failed_writes.append(
      (group_name, os.path.basename(filename), f"OS error: {str(e)}")
    )
  except Exception as e:
    stats.failed_writes.append(
      (group_name, os.path.basename(filename), f"Unexpected error: {str(e)}")
    )


def print_processing_summary(stats: ProcessingStats, args: argparse.Namespace) -> None:
  """
  Print detailed summary of processing results
  Includes success counts, skipped groups, overwritten files, and ungrouped lines
  """
  print("\n" + "="*60)
  print("                    Processing Summary")
  print("="*60)

  # 1. Basic metrics
  print(f"\n[1] Basic Metrics:")
  print(f"    Total groups detected:    {stats.total_groups}")
  print(f"    Successfully written:     {stats.successful_writes}")
  print(f"    Overwritten files:        {len(stats.overwritten_files)}")
  print(f"    Skipped groups:           {len(stats.skipped_groups)}")
  print(f"    Ungrouped lines:          {len(stats.ungrouped_lines)}")

  # 2. Overwritten files (if any)
  if stats.overwritten_files:
    print(f"\n[2] Overwritten Files (--overwrite=1 enabled):")
    for filename in stats.overwritten_files:
      print(f"    - {filename}")

  # 3. Skipped groups (if any)
  if stats.skipped_groups:
    print(f"\n[3] Skipped Groups:")
    for group_name, reason in stats.skipped_groups:
      print(f"    - Group: '{group_name}' → Reason: {reason}")

  # 4. Failed writes (if any)
  if stats.failed_writes:
    print(f"\n[4] Failed Writes (check permissions/OS errors):")
    for group_name, filename, error in stats.failed_writes:
      print(f"    - Group: '{group_name}' → File: '{filename}' → Error: {error}")

  # 5. Ungrouped lines (if any)
  if stats.ungrouped_lines:
    ungrouped_count = len(stats.ungrouped_lines)
    print(f"\n[5] Ungrouped Lines (not part of any group):")
    print(f"    Total ungrouped lines: {ungrouped_count}")
    print(f"    First {MAX_PREVIEW_LINES} ungrouped lines (preview):")
    for i, line in enumerate(stats.ungrouped_lines[:MAX_PREVIEW_LINES]):
      print(f"      Line {i+1}: {line.strip() or '[Empty line]'}")
    if ungrouped_count > MAX_PREVIEW_LINES:
      print(f"      ... and {ungrouped_count - MAX_PREVIEW_LINES} more lines")

  # 6. Output directory location
  print(f"\n[6] Output Directory:")
  print(f"    All successfully written files saved to: {os.path.abspath(args.output_dir)}")
  print("\n" + "="*60)


# --------------------------
# Main Execution Flow
# --------------------------
def main():
  try:
    # Step 1: Parse and validate command-line arguments
    args = parse_command_line_args()
    print(f"Starting group splitter with input file: {os.path.abspath(args.input)}")

    # Step 2: Initialize processing statistics
    stats = ProcessingStats()

    # Step 3: Extract groups from input file
    print(f"\nExtracting groups from input file...")
    groups = extract_groups_from_input(args.input, stats)
    print(f"Extracted {len(groups)} valid groups (total detected: {stats.total_groups})")

    # Step 4: Process each group (generate filename + write to file)
    if groups:
      print(f"\nProcessing {len(groups)} groups (output directory: {args.output_dir})...")
      for idx, (group_name, group_content) in enumerate(groups, 1):
        # Generate valid filename
        filename = generate_valid_filename(
          group_name=group_name,
          prefix=args.prefix,
          suffix=args.suffix,
          ext=args.ext,
          output_dir=args.output_dir
        )
        # Write group content to file
        write_group_content(
          group_name=group_name,
          group_content=group_content,
          filename=filename,
          allow_overwrite=args.overwrite,
          stats=stats
        )
        # Print progress (every PROGRESS_UPDATE_INTERVAL groups or last group)
        if idx % PROGRESS_UPDATE_INTERVAL == 0 or idx == len(groups):
          print(f"  Processed {idx}/{len(groups)} groups")
    else:
      print("\nNo valid groups found in input file")

    # Step 5: Print detailed summary
    print_processing_summary(stats, args)

    # Exit with success code if no critical errors
    sys.exit(0)

  except KeyboardInterrupt:
    print(f"\n\nProcess interrupted by user (Ctrl+C)")
    sys.exit(1)
  except RuntimeError as e:
    print(f"\nError: {str(e)}")
    sys.exit(1)
  except Exception as e:
    print(f"\nUnexpected error: {str(e)}")
    sys.exit(1)


if __name__ == "__main__":
  main()
  
