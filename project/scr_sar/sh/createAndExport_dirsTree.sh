#!/usr/bin/env bash
#
# ============================================================================
#  createAndExport_dirsTree_fixed.sh
#
#  A bidirectional, config-file driven directory-tree manager.
#
#    create  - build a complete nested directory structure from an
#              indentation-based config file in a single command.
#    export  - read the folder structure of one or more source directories
#              and generate such a config file, prefixed by a comment header
#              that records the source, the recreate command and basic
#              statistics.
#
#  Author    : Aiden Song
#  Version   : 1.0.1
#  Date      : 2026-09-02
#  License   : MIT
#  Shell     : bash >= 4 (associative arrays required; tested on GNU bash 5.2)
#
#  The script name is taken dynamically from "$0" and shown in every help and
#  summary line, so renaming this file needs no code change.
#
# ---------------------------------------------------------------------------
#  CHANGES SINCE 1.0.0
# ---------------------------------------------------------------------------
#  1.0.1  - FIX export hang: exporting a source path that ends with a slash
#           (e.g. "export son/", which tab-completion appends) could trap the
#           ancestor-propagation loop in pass 3 in an infinite loop, because
#           find(1) strips the trailing slash while the loop compared against
#           the raw "$root". The source root is now normalized (trailing slash
#           stripped, "/" protected), and the propagation loop additionally
#           stops whenever dirname() stops descending (e.g. "." -> "."), so
#           the loop is unconditionally terminating.
#
# ---------------------------------------------------------------------------
#  CONFIG FILE FORMAT
# ---------------------------------------------------------------------------
#  The config file expresses hierarchy by indentation only; each line holds a
#  single directory name, and its parents are implied by the indentation.
#  Empty lines and '#' comment lines (whole-line or trailing) are ignored, and
#  a trailing '/' on a directory name is tolerated.
#
#      chip_top/
#        src/
#          rtl
#          sdc
#        docs
#
# ---------------------------------------------------------------------------
#  MODES
# ---------------------------------------------------------------------------
#  create
#      Read a config file and create the whole tree under a base directory.
#      Indentation width is auto-detected from the first indented line, or
#      can be forced with -w. Supports tabs and any consistent space width.
#
#  export
#      Read one or more source directories and write a config file. Supports:
#        * multiple sources merged into one file
#        * include / exclude filtering by folder-name regex (POSIX ERE)
#        * a depth limit (-d N)
#        * a comment header with source, folder count, max depth and the
#          exact recreate command
#
# ---------------------------------------------------------------------------
#  USAGE
# ---------------------------------------------------------------------------
#    createAndExport_dirsTree.sh create [options] <config_file>
#    createAndExport_dirsTree.sh export [options] <path> [<path> ...]
#
#  create options:
#    -b DIR   base directory where the tree is created (default: current dir)
#    -w N     indentation width in spaces per level (default: auto-detect)
#    -n       dry run: print the paths that would be created, create nothing
#
#  export options:
#    -o FILE  write the generated config to FILE (default: stdout)
#    -i REGEX  keep only folders whose NAME matches REGEX, plus their
#              ancestor folders so the matches stay reachable; folders that
#              do not match and have no matching descendant are skipped
#    -x REGEX  skip folders whose NAME matches REGEX, together with their
#              whole subtree (also applies to the source root itself)
#    -w N     indentation width of the generated config (default: 2)
#    -d N     descend at most N levels below each source root
#    -h       print help (also: create -h / export -h)
#
# ---------------------------------------------------------------------------
#  EXAMPLES
# ---------------------------------------------------------------------------
#    createAndExport_dirsTree.sh create -b out -n dirs.txt     # dry run
#    createAndExport_dirsTree.sh create -b out dirs.txt        # create tree
#    createAndExport_dirsTree.sh export -o dirs.txt /data/proj
#    createAndExport_dirsTree.sh export -i '^(rtl|sdc)$' -x 'tmp' /a /b
#
# ---------------------------------------------------------------------------
#  EXIT STATUS
# ---------------------------------------------------------------------------
#    0  success
#    1  invalid usage / unreadable config / missing source / runtime error
#
# ---------------------------------------------------------------------------
#  DEPENDENCIES
# ---------------------------------------------------------------------------
#    bash >= 4 and the standard GNU/Linux tools:
#    find, sort, mkdir, basename, dirname, awk, mktemp, tr, printf, date
#
# ============================================================================

set -euo pipefail
shopt -s extglob

# Name of this script as invoked; used in every help / summary line so the
# output always matches whatever the user renamed this file to.
PROG=$(basename "$0")

# ---------- shared helpers ----------

die() {
  echo "error: $*" >&2
  exit 1
}

main_usage() {
  cat <<EOF
$PROG - bidirectional directory-tree manager

Usage:
  $PROG create [options] <config_file>
  $PROG export [options] <path> [<path> ...]

Commands:
  create  build nested directory structure from an indentation-based config
  export  read folder structure of source dirs and generate such a config

Run '$PROG <command> -h' for command-specific options.
EOF
}

# indent_level: leading whitespace -> hierarchy level
# (a tab counts as one level; spaces are grouped by CREATE_WIDTH)
indent_level() {
  local line="$1" tabs spaces
  tabs=$(tr -dc '\t' <<<"$line" | wc -c)
  spaces=$(tr -dc ' ' <<<"$line" | wc -c)
  echo $((tabs + spaces / CREATE_WIDTH))
}

# ---------- create mode ----------

create_usage() {
  cat <<EOF
Usage: $PROG create [options] <config_file>
  -b DIR  base directory where the tree is created (default: .)
  -w N    indentation width in spaces per level (default: auto-detect)
  -n      dry run: print paths only, create nothing
  -h      print this help
EOF
}

create_from_config() {
  local config="$1" base="$2" dry="$3"
  if [ "$dry" -eq 0 ]; then
    mkdir -p -- "$base" 2>/dev/null || die "cannot create base directory: $base"
  fi
  local -a path=()
  local line name level full target
  while IFS= read -r raw || [ -n "$raw" ]; do
    line="${raw%%#*}"                      # strip inline comment
    line="${line%%+([[:space:]])}"         # trim trailing whitespace
    [ -z "$line" ] && continue
    name="${line#"${line%%[![:space:]]*}"}" # strip leading whitespace
    name="${name%/}"                        # tolerate trailing '/'
    [ -z "$name" ] && continue
    level=$(indent_level "$line")
    if (( level < ${#path[@]} )); then      # new branch at shallower depth
      path=("${path[@]:0:$level}")
    fi
    path+=("$name")
    full=$(IFS=/; echo "${path[*]}")
    target="$base/$full"
    if [ "$dry" -eq 1 ]; then
      echo "$target"
    else
      mkdir -p -- "$target"
    fi
  done < "$config"
}

create_main() {
  local base="." width="" dry=0 config=""
  OPTIND=1
  while getopts "b:w:nh" opt; do
    case "$opt" in
      b) base="$OPTARG" ;;
      w) width="$OPTARG" ;;
      n) dry=1 ;;
      h) create_usage; exit 0 ;;
      *) create_usage; exit 1 ;;
    esac
  done
  shift $((OPTIND - 1))
  [ "$#" -eq 1 ] || die "create: exactly one config file required"
  config="$1"
  [ -r "$config" ] || die "cannot read config file: $config"

  CREATE_WIDTH="$width"
  if [ -z "$CREATE_WIDTH" ]; then
    CREATE_WIDTH=$(awk '/^[[:space:]]+/ { match($0, /^[[:space:]]+/); print RLENGTH; exit }' "$config")
    [ -n "$CREATE_WIDTH" ] || CREATE_WIDTH=2
  fi
  if ! [ "$CREATE_WIDTH" -ge 1 ] 2>/dev/null; then
    die "invalid indent width: $CREATE_WIDTH"
  fi
  create_from_config "$config" "$base" "$dry"
}

# ---------- export mode ----------

export_usage() {
  cat <<EOF
Usage: $PROG export [options] <path> [<path> ...]
  -o FILE   write the generated config to FILE (default: stdout)
  -i REGEX  keep only folders whose NAME matches REGEX (POSIX ERE), plus
            their ancestor folders so the matches stay reachable; folders
            that do not match and have no matching descendant are skipped
  -x REGEX  skip folders whose NAME matches REGEX, together with their
            whole subtree; also applies to the source root itself
  -w N      indentation width for the generated config (default: 2)
  -d N      descend at most N levels below each source root
  -h        print this help
EOF
}

# globals used by export
OUT_WIDTH=2
INCLUDE_RE=""
EXCLUDE_RE=""
MAXDEPTH_ARG=""
TOTAL_FOLDERS=0
MAX_DEPTH=0
TMPD=""

declare -A EXCLUDED=()
declare -A KEEP=()

# excluded_p <path>: 0 if the path lies inside any excluded subtree
excluded_p() {
  local q="$1" x
  for x in "${!EXCLUDED[@]}"; do
    [ "$q" = "$x" ] && return 0
    case "$q" in
      "$x"/*) return 0 ;;
    esac
  done
  return 1
}

# print_header: emit the comment block that prefixes an exported config.
#   $1: source list (already space-joined)
#   $2: include regex (may be empty)
#   $3: exclude regex (may be empty)
#   $4: indent width used by the export
#   $5: output file name (empty -> placeholder shown in the command line)
print_header() {
  local srcs="$1" inc="$2" exc="$3" w="$4" outf="$5"
  echo "# source: $srcs"
  if [ -n "$inc" ]; then
    echo "# include regex: $inc"
  fi
  if [ -n "$exc" ]; then
    echo "# exclude regex: $exc"
  fi
  echo "# total folders: $TOTAL_FOLDERS (top-level roots included)"
  echo "# max depth: $MAX_DEPTH (levels below the source root)"
  if [ -n "$outf" ]; then
    echo "# command: $PROG create -b . -w $w \"$outf\""
  else
    echo "# command: $PROG create -b . -w $w <config_file>"
  fi
  echo "# generated: $(date '+%Y-%m-%d %H:%M:%S')"
  echo ""
}

# export_tree: emit one source root and its subtree into stdout
export_tree() {
  local root="$1" n="$2"
  local base dirs_file p b rel depth indent_str a na
  # Normalize the source root: strip a single trailing slash so that the
  # paths reported by find(1) and the ancestors produced by dirname(1)
  # compare cleanly against "$root" in the propagation loop below.
  # The filesystem root itself ("/") is protected from being reduced to an
  # empty string.
  if [ "${#root}" -gt 1 ] && [ "${root: -1}" = "/" ]; then
    root="${root%/}"
  fi
  base=$(basename "$root")

  # exclude applies to the root as well: a matching source is dropped entirely.
  if [ -n "$EXCLUDE_RE" ] && [[ "$base" =~ $EXCLUDE_RE ]]; then
    return 0
  fi
  printf '%s/\n' "$base"
  TOTAL_FOLDERS=$((TOTAL_FOLDERS + 1))
  if [ "$MAX_DEPTH" -lt 1 ]; then
    MAX_DEPTH=1
  fi

  # reset per-source state (multi-source invocations share these globals)
  EXCLUDED=()
  KEEP=()
  dirs_file="$TMPD/dirs.$n"
  find "$root" -mindepth 1 -type d 2>/dev/null | sort > "$dirs_file"

  # pass 1: mark excluded subtrees (matching dir and every descendant)
  while IFS= read -r p; do
    b=$(basename "$p")
    if [ -n "$EXCLUDE_RE" ] && [[ "$b" =~ $EXCLUDE_RE ]]; then
      EXCLUDED["$p"]=1
    fi
  done < "$dirs_file"

  # pass 2: mark include matches (all dirs when no include regex given)
  while IFS= read -r p; do
    excluded_p "$p" && continue
    b=$(basename "$p")
    if [ -z "$INCLUDE_RE" ] || [[ "$b" =~ $INCLUDE_RE ]]; then
      KEEP["$p"]=1
    fi
  done < "$dirs_file"

  # pass 3: propagate keep upward so matches stay reachable; guard against
  # walking above the root (dirname() of a root-child is the root itself, and
  # "/" is a hard stop) and against dirname() converging on a fixed value
  # (e.g. "." -> "."), which would otherwise loop forever. With the root
  # normalized above, the chain always reaches the root and terminates.
  for p in "${!KEEP[@]}"; do
    a=$(dirname "$p")
    while [ "$a" != "$root" ] && [ "$a" != "/" ]; do
      KEEP["$a"]=1
      na=$(dirname "$a")
      [ "$na" = "$a" ] && break   # dirname() converged, stop unconditionally
      a="$na"
    done
  done

  # emit in DFS order (sorted path order)
  # depth = number of path segments below the source root, so a root child has
  # depth 1 and gets OUT_WIDTH spaces; every deeper level adds another width.
  while IFS= read -r p; do
    excluded_p "$p" && continue
    [ "${KEEP[$p]+set}" ] || continue
    rel="${p#"$root"/}"
    depth=$(awk -F/ '{print NF}' <<<"$rel")
    if [ -n "$MAXDEPTH_ARG" ] && (( depth > MAXDEPTH_ARG )); then
      continue
    fi
    indent_str=$(printf '%*s' $(( depth * OUT_WIDTH )) '')
    printf '%s%s/\n' "$indent_str" "$(basename "$p")"
    TOTAL_FOLDERS=$((TOTAL_FOLDERS + 1))
    if [ "$depth" -gt "$MAX_DEPTH" ]; then
      MAX_DEPTH=$depth
    fi
  done < "$dirs_file"

  # always return success: a false "if" condition inside the loop must never
  # leak a non-zero status up through the while-loop exit code into the caller
  # where 'set -e' would abort the whole run
  return 0
}

export_main() {
  local out="" width=2 include_re="" exclude_re="" maxdepth=""
  local src n
  OPTIND=1
  while getopts "o:i:x:w:d:h" opt; do
    case "$opt" in
      o) out="$OPTARG" ;;
      i) include_re="$OPTARG" ;;
      x) exclude_re="$OPTARG" ;;
      w) width="$OPTARG" ;;
      d) maxdepth="$OPTARG" ;;
      h) export_usage; exit 0 ;;
      *) export_usage; exit 1 ;;
    esac
  done
  shift $((OPTIND - 1))
  [ "$#" -ge 1 ] || die "export: at least one source path required"
  if ! [ "$width" -ge 1 ] 2>/dev/null; then
    die "invalid indent width: $width"
  fi
  if [ -n "$maxdepth" ] && ! [ "$maxdepth" -ge 1 ] 2>/dev/null; then
    die "invalid max depth: $maxdepth"
  fi

  OUT_WIDTH="$width"
  INCLUDE_RE="$include_re"
  EXCLUDE_RE="$exclude_re"
  MAXDEPTH_ARG="$maxdepth"
  TOTAL_FOLDERS=0
  MAX_DEPTH=0

  TMPD=$(mktemp -d) || die "cannot create temp dir"
  # TMPD is a script-level global so the EXIT trap can still reference it
  # after export_main returns.
  trap 'rm -rf -- "$TMPD"' EXIT

  n=0
  for src in "$@"; do
    [ -d "$src" ] || die "not a directory: $src"
    export_tree "$src" "$n"
    n=$((n + 1))
  done > "$TMPD/body.txt"

  if [ -n "$out" ]; then
    {
      print_header "$*" "$include_re" "$exclude_re" "$width" "$out"
      cat "$TMPD/body.txt"
    } > "$out"
  else
    {
      print_header "$*" "$include_re" "$exclude_re" "$width" ""
      cat "$TMPD/body.txt"
    }
  fi

  trap - EXIT
  rm -rf -- "$TMPD"
}

# ---------- main ----------

case "${1:-}" in
  create) shift; create_main "$@" ;;
  export) shift; export_main "$@" ;;
  -h|--help|help) main_usage; exit 0 ;;
  *) main_usage >&2; exit 1 ;;
esac

exit 0
