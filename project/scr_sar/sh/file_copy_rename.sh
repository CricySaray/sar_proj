#!/bin/bash

# 增强版文件复制脚本 - 支持正则表达式和自定义命名
# Usage: ./file_copy_rename.sh -s source1 source2 -t target [options]

# Default parameters
DRY_RUN=0
FILE_PATTERN=".*"  # 默认匹配所有文件
PATH_PATTERN=".*"  # 默认匹配所有路径
NAME_TEMPLATE="{dir}_{file}"  # 默认命名模板

# Show help information
function show_help {
	echo "Usage: $0 -s source_dir1 [source_dir2 ...] -t target_dir [options]"
	echo "Options:"
	echo "  -s, --sources     List of source directories (required)"
	echo "  -t, --target      Target directory (required)"
	echo "  -f, --file-pattern  Regular expression for filenames (default: '.*')"
	echo "  -p, --path-pattern  Regular expression for source paths (default: '.*')"
	echo "  -n, --name-template  Output filename template (default: '{dir}_{file}')"
	echo "  -d, --dry-run     Perform dry run (show operations without copying)"
	echo "  -h, --help        Show this help message"
	exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
	case "$1" in
		-s|--sources)
			shift ; # remove args !!!
			SOURCES=()
			while [[ $# -gt 0 && ! "$1" =~ ^- ]]; do
				SOURCES+=("$1") ; # define array
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

# Validate required parameters
if [[ -z "${SOURCES[*]}" || -z "$TARGET_DIR" ]]; then
	echo "Error: Source (-s) and target (-t) directories are required"
	show_help
fi

# Check if target directory exists, create if not
if [[ $DRY_RUN -eq 0 && ! -d "$TARGET_DIR" ]]; then
	mkdir -p "$TARGET_DIR" || { echo "Error: Failed to create target directory $TARGET_DIR"; exit 1; }
fi

# Regular expression matching function
function matches_regex {
	local string="$1"
	local pattern="$2"

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

		# Traverse all files in the source directory
		find "$source_dir" -type f | while read -r source_file; do
		# Apply path pattern filter
		if [[ ! $(matches_regex "$source_file" "$PATH_PATTERN") ]]; then
			continue
		fi

				# Get filename
				filename=$(basename "$source_file")

				# Apply file pattern filter
				if [[ ! $(matches_regex "$filename" "$FILE_PATTERN") ]]; then
					continue
				fi

				# Calculate relative path (relative to source directory)
				rel_path="${source_file#$source_dir/}"

				# Extract subdirectory part
				sub_dir=$(dirname "$rel_path")
				if [[ "$sub_dir" == "." ]]; then
					sub_dir=""
				else
					# Replace path separators with underscores
					sub_dir="${sub_dir//\//_}"
				fi

				# Generate new filename
				new_filename=$(replace_template "$NAME_TEMPLATE" "$dir_basename" "$sub_dir" "$filename")

				# Construct target file path
				target_file="$TARGET_DIR/$new_filename"

				# Show operation
				if [[ $DRY_RUN -eq 1 ]]; then
					echo "Would copy (dry run): $source_file -> $target_file"
				else
					echo "Copying: $source_file -> $target_file"
					cp -f "$source_file" "$target_file" || echo "Error: Failed to copy $source_file"
				fi
			done
		done

		echo "Operation completed"
		exit 0
