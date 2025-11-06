#!/usr/bin/env python3
import argparse
import subprocess
import sys
import os
from datetime import datetime
import configparser
import shutil

# ============================== DEFAULT CONFIGURATION ==============================
# User-modifiable default values (auto-synced to help text)
DEFAULT_REPO_ALIASES = {
  "flow": "/eda-tools/gvs/flow/flow_test.git",
  "signoff": "/eda-tools/gvs/signoff/signoff_test.git"
}
DEFAULT_REPO_ALIAS = "flow"
DEFAULT_PROCESS_BRANCH = "smic40ll"
DEFAULT_OUTPUT_DIR = os.path.expanduser("./")
CONFIG_FILE_PATH = os.path.expanduser("~/.gvs.conf")
VALID_SCRIPT_TYPES = ["flow", "signoff"]  # Kept for backward compatibility, not used in validation
DEFAULT_DEBUG_MODE = False
DEFAULT_SHALLOW_CLONE = 0  # Default: pull all version history (0=full, 1=shallow)

# ============================== GLOBAL VARIABLES ==============================
DEBUG_MODE = DEFAULT_DEBUG_MODE
PERSISTENT_ALIASES = {}

# ============================== UTILITY FUNCTIONS ==============================
def debug_log(message):
  if DEBUG_MODE:
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(f"[DEBUG] {timestamp}: {message}", file=sys.stderr)

def load_persistent_config():
  global PERSISTENT_ALIASES
  if os.path.exists(CONFIG_FILE_PATH):
    config = configparser.ConfigParser()
    config.read(CONFIG_FILE_PATH)
    if "RepoAliases" in config.sections():
      PERSISTENT_ALIASES = dict(config["RepoAliases"])
      debug_log(f"Loaded persistent aliases: {PERSISTENT_ALIASES}")
  else:
    debug_log(f"Config file not found at {CONFIG_FILE_PATH}")
  
  merged_aliases = PERSISTENT_ALIASES.copy()
  merged_aliases.update(DEFAULT_REPO_ALIASES)
  return merged_aliases

def save_persistent_config(alias, path):
  config = configparser.ConfigParser()
  if os.path.exists(CONFIG_FILE_PATH):
    config.read(CONFIG_FILE_PATH)
  if "RepoAliases" not in config.sections():
    config.add_section("RepoAliases")
  config["RepoAliases"][alias] = path
  with open(CONFIG_FILE_PATH, "w") as f:
    config.write(f)
  debug_log(f"Saved alias '{alias}' -> '{path}'")

def run_git_command(cmd, cwd=None, check=True):
  debug_log(f"Git cmd: {' '.join(cmd)}")
  try:
    result = subprocess.run(
      cmd,
      cwd=cwd,
      stdout=subprocess.PIPE,
      stderr=subprocess.PIPE,
      text=True,
      check=check,
      shell=False
    )
    if result.stdout:
      debug_log(f"Git stdout: {result.stdout.strip()}")
    if result.stderr:
      debug_log(f"Git stderr: {result.stderr.strip()}")
    return result
  except subprocess.CalledProcessError as e:
    print(f"ERROR: Git command failed: {' '.join(cmd)} - {e.stderr.strip()}", file=sys.stderr)
    return None
  except FileNotFoundError:
    print("ERROR: 'git' not found. Install Git first.", file=sys.stderr)
    sys.exit(1)

def get_repo_url_by_alias(alias):
  merged_aliases = load_persistent_config()
  if alias not in merged_aliases:
    print(f"ERROR: Alias '{alias}' not found. Available aliases:")
    for a, u in merged_aliases.items():
      print(f"  - {a}: {u}")
    sys.exit(1)
  return merged_aliases[alias]

def get_current_remote_url(cwd):
  """Get the remote origin URL of the current Git repository"""
  result = run_git_command(["git", "remote", "get-url", "origin"], cwd=cwd, check=False)
  if result and result.returncode == 0:
    return result.stdout.strip()
  return None

def check_git_repo_clean(cwd):
  """Check if the Git repository has uncommitted changes"""
  result = run_git_command(["git", "status", "--porcelain"], cwd=cwd, check=False)
  if result and result.returncode == 0:
    return len(result.stdout.strip()) == 0
  return False

def list_remote_branches(repo_url):
  debug_log(f"Fetching branches for {repo_url}")
  # Distinguish local and remote repos: read branches directly for local, use ls-remote for remote
  if os.path.isdir(repo_url):
    result = run_git_command(["git", "branch", "--list"], cwd=repo_url)
    if not result:
      debug_log(f"Failed to fetch branches for local repo {repo_url}")
      return []
    branches = [line.strip().lstrip("* ") for line in result.stdout.splitlines()]
  else:
    result = run_git_command(["git", "ls-remote", "--heads", repo_url])
    if not result:
      debug_log(f"Failed to fetch branches for remote repo {repo_url}")
      return []
    branches = [line.split("/")[-1].strip() for line in result.stdout.splitlines()]
  return branches

def list_remote_tags(repo_url):
  debug_log(f"Fetching tags for {repo_url}")
  # Distinguish local and remote repos: read tags directly for local, use ls-remote for remote
  if os.path.isdir(repo_url):
    result = run_git_command(["git", "tag", "--list"], cwd=repo_url)
    if not result:
      debug_log(f"Failed to fetch tags for local repo {repo_url}")
      return []
    tags = [line.strip() for line in result.stdout.splitlines()]
  else:
    result = run_git_command(["git", "ls-remote", "--tags", repo_url], check=False)
    if not result or result.returncode != 0:
      debug_log("Failed to fetch tags (may have none)")
      return []
    tags = [line.split("/")[-1].strip() for line in result.stdout.splitlines()]
    # Filter out lightweight tags (keep annotated tags, remove duplicates)
    unique_tags = list(dict.fromkeys([t for t in tags if t]))
    return unique_tags
  return tags

def validate_process_branch(repo_url, branch):
  branches = list_remote_branches(repo_url)
  if branch not in branches:
    print(f"ERROR: Branch '{branch}' not found in {repo_url}.")
    print("Available branches:")
    for b in branches[:10]:  # Limit output to 10 branches
      print(f"  - {b}")
    if len(branches) > 10:
      print(f"  ... and {len(branches)-10} more")
    sys.exit(1)
  debug_log(f"Valid branch: {branch}")

# ============================== COMMAND HANDLERS ==============================
def handle_config(alias, path, debug):
  global DEBUG_MODE
  DEBUG_MODE = debug
  
  if not alias or not path:
    print("ERROR: -a/--repo-alias and -p/--repo-path must be used together", file=sys.stderr)
    sys.exit(1)
  
  # Validate path: local directory or valid remote URL
  is_local_repo = os.path.isdir(path)
  is_remote_url = path.startswith(("https://", "git@", "ssh://"))
  
  if not (is_local_repo or is_remote_url):
    print(f"ERROR: Invalid repo path '{path}'.", file=sys.stderr)
    print("Use: 1) Local directory path (e.g., /test/path/to/git) 2) Remote URL (https://, git@, ssh://)", file=sys.stderr)
    sys.exit(1)
  
  # Local repo path must exist
  if is_local_repo and not os.path.exists(path):
    print(f"ERROR: Local repo path '{path}' does not exist", file=sys.stderr)
    sys.exit(1)
  
  # Local repo must be a valid Git repository
  if is_local_repo:
    git_dir = os.path.join(path, ".git")
    if not os.path.isdir(git_dir):
      print(f"ERROR: Local path '{path}' is not a valid Git repository (missing .git directory)", file=sys.stderr)
      sys.exit(1)
    debug_log(f"Valid local Git repo: {path}")
  else:
    # Validate connectivity for remote URL
    debug_log(f"Testing remote repo connectivity: {path}")
    test_result = run_git_command(["git", "ls-remote", "--heads", path], check=False)
    if test_result and test_result.returncode != 0:
      print(f"WARNING: Cannot connect to remote repo {path} (check URL/credentials)", file=sys.stderr)
      print("Config will be saved but may fail on download", file=sys.stderr)
      if not input("Continue? (y/N): ").strip().lower() == "y":
        sys.exit(0)
  
  save_persistent_config(alias, path)
  print(f"SUCCESS: Alias '{alias}' -> '{path}'")
  
  if DEBUG_MODE:
    print("\n[DEBUG] Full config (defaults + persistent):")
    for a, p in load_persistent_config().items():
      source = "DEFAULT" if a in DEFAULT_REPO_ALIASES else "PERSISTENT"
      print(f"  {a}: {p} ({source})")

def handle_download(repo_alias, branch, output_dir, shallow_clone, debug):
  global DEBUG_MODE
  DEBUG_MODE = debug
  
  # Validate shallow_clone parameter (only 0 or 1 allowed)
  if shallow_clone not in (0, 1):
    print(f"ERROR: Invalid value for --shallow-clone. Must be 0 (full history) or 1 (latest only)", file=sys.stderr)
    sys.exit(1)
  
  repo_path = get_repo_url_by_alias(repo_alias)
  validate_process_branch(repo_path, branch)
  
  # Resolve absolute output directory path
  output_dir = os.path.abspath(output_dir)
  debug_log(f"Target output directory: {output_dir}")
  debug_log(f"Shallow clone mode: {'Enabled (latest history only)' if shallow_clone == 1 else 'Disabled (full history)'}")
  
  # Create output directory if it doesn't exist
  if not os.path.exists(output_dir):
    debug_log(f"Output directory does not exist, creating: {output_dir}")
    os.makedirs(output_dir, exist_ok=True)
  
  git_dir = os.path.join(output_dir, ".git")
  current_repo_url = get_current_remote_url(output_dir) if os.path.exists(git_dir) else None
  
  # Case 1: Output directory is not a Git repository (no .git folder)
  if not os.path.exists(git_dir):
    print(f"Initializing new Git repository in '{output_dir}'...")
    clone_cmd = ["git", "clone", repo_path, "--branch", branch, "--single-branch"]
    
    # Add shallow clone option if enabled (--depth 1 = only latest commit)
    if shallow_clone == 1:
      clone_cmd.append("--depth")
      clone_cmd.append("1")
      print("(Shallow clone enabled: Only latest version history will be downloaded)")
    
    clone_cmd.append(output_dir)  # Add target directory as last parameter
    clone_result = run_git_command(clone_cmd)
    
    if not clone_result or clone_result.returncode != 0:
      print(f"ERROR: Failed to clone repository {repo_path} to {output_dir}", file=sys.stderr)
      # Clean up incomplete directory if needed
      if os.path.exists(output_dir) and len(os.listdir(output_dir)) == 0:
        os.rmdir(output_dir)
      sys.exit(1)
    print(f"Successfully cloned repository to '{output_dir}'")
  
  # Case 2: Output directory is a Git repository
  else:
    print(f"Found existing Git repository in '{output_dir}'")
    
    # Subcase 2a: Existing repo remote does not match target repo
    if current_repo_url and current_repo_url != repo_path:
      print(f"ERROR: Repository mismatch!", file=sys.stderr)
      print(f"  Existing remote: {current_repo_url}", file=sys.stderr)
      print(f"  Target remote:   {repo_path}", file=sys.stderr)
      print("Please use a different output directory or remove the existing .git folder", file=sys.stderr)
      sys.exit(1)
    
    # Subcase 2b: Check for uncommitted changes
    if not check_git_repo_clean(output_dir):
      print("ERROR: Uncommitted changes detected in the repository!", file=sys.stderr)
      print("Please commit or stash your changes before proceeding", file=sys.stderr)
      sys.exit(1)
    
    # Subcase 2c: Switch to target branch and pull latest changes
    print(f"Switching to branch '{branch}'...")
    checkout_result = run_git_command(["git", "checkout", branch], cwd=output_dir)
    if not checkout_result or checkout_result.returncode != 0:
      # Try to create branch from remote if it doesn't exist locally
      print(f"Branch '{branch}' not found locally, creating from remote...")
      checkout_result = run_git_command(["git", "checkout", "-b", branch, f"origin/{branch}"], cwd=output_dir)
      if not checkout_result or checkout_result.returncode != 0:
        print(f"ERROR: Failed to checkout branch '{branch}'", file=sys.stderr)
        sys.exit(1)
    
    # Fetch latest changes from remote (shallow mode: fetch only latest commit)
    print("Fetching latest changes from remote...")
    fetch_cmd = ["git", "fetch", "origin", branch]
    if shallow_clone == 1:
      fetch_cmd.append("--depth")
      fetch_cmd.append("1")
      print("(Shallow mode enabled: Fetching only latest version history)")
    
    fetch_result = run_git_command(fetch_cmd, cwd=output_dir)
    if not fetch_result or fetch_result.returncode != 0:
      print("ERROR: Failed to fetch remote changes", file=sys.stderr)
      sys.exit(1)
    
    # Pull changes with conflict detection
    print(f"Merging latest changes for branch '{branch}'...")
    pull_result = run_git_command(["git", "pull", "origin", branch], cwd=output_dir)
    if not pull_result or pull_result.returncode != 0:
      print("ERROR: Merge conflict detected!", file=sys.stderr)
      print("Resolution steps:", file=sys.stderr)
      print("  1. Navigate to the output directory: cd", output_dir, file=sys.stderr)
      print("  2. Resolve conflicts manually (edit conflicted files)", file=sys.stderr)
      print("  3. Commit resolved changes: git add . && git commit -m 'Resolve merge conflicts'", file=sys.stderr)
      print("  4. Re-run the download command", file=sys.stderr)
      sys.exit(1)
    
    print("Successfully updated repository with latest changes")
  
  # Final success message (no modification to repo contents/permissions)
  print(f"\nSUCCESS: Repository operation completed successfully")
  print(f"Target directory: {output_dir}")
  print(f"Version history: {'Latest only (shallow mode)' if shallow_clone == 1 else 'Full history'}")
  print(f"\nNext: cd {output_dir} && ./your_script.sh (adjust script name as needed)")

def handle_list(debug):
  global DEBUG_MODE
  DEBUG_MODE = debug
  
  merged_aliases = load_persistent_config()
  if not merged_aliases:
    print("ERROR: No repo aliases configured (use 'config' command first)", file=sys.stderr)
    sys.exit(1)
  
  print(f"Found {len(merged_aliases)} repo(s):\n")
  for alias, repo_path in merged_aliases.items():
    print(f"=== Alias: {alias} ===")
    print(f"Repo Path: {repo_path}")
    print(f"Type: {'Local' if os.path.isdir(repo_path) else 'Remote'}")
    print(f"Source: {'DEFAULT' if alias in DEFAULT_REPO_ALIASES else 'PERSISTENT'}")
    
    # Get branches (with error handling)
    try:
      branches = list_remote_branches(repo_path)
      print(f"Available branches ({len(branches)}):")
      for b in branches[:10]:  # Limit to 10 branches to avoid clutter
        print(f"  - {b}")
      if len(branches) > 10:
        print(f"  ... and {len(branches)-10} more")
    except Exception as e:
      print(f"Warning: Failed to fetch branches - {str(e)}")
    
    # Get tags (no error if none)
    tags = list_remote_tags(repo_path)
    if tags:
      print(f"Latest tags ({len(tags)}):")
      # Show latest 5 tags (sorted by version-like order)
      try:
        # Simple version sorting (handles v1.0, 2.1.3 etc.)
        tags_sorted = sorted(tags, key=lambda x: [int(y) if y.isdigit() else y for y in x.replace("v", "").split(".")], reverse=True)
        for tag in tags_sorted[:5]:
          print(f"  - {tag}")
        if len(tags_sorted) > 5:
          print(f"  ... and {len(tags_sorted)-5} more")
      except:
        # Fallback to raw order if sorting fails
        for tag in tags[:5]:
          print(f"  - {tag}")
    else:
      print("Available tags: None")
    
    print()  # Add blank line between repos

# ============================== MAIN ARGUMENT PARSER ==============================
def main():
  # Top-level parser
  parser = argparse.ArgumentParser(
    description="Script Distributor - Manage/download flow/signoff scripts from Git (local/remote repos)",
    formatter_class=argparse.RawDescriptionHelpFormatter,
    epilog=f"""
IMPORTANT NOTES:
  1. Default values are in script's top section (auto-synced to help)
  2. Default aliases can't be overwritten by 'config'
  3. Persistent config: {CONFIG_FILE_PATH}
  4. Install Git first (required for all operations)
  5. Support both local Git repos (e.g., /test/path/to/git) and remote URLs (https://, git@, ssh://)
  6. Output directory handling:
     - If not a Git repo: Clones target repo directly
     - If existing Git repo: Checks for remote match, clean state, and merges changes
     - Handles conflicts with clear resolution steps
  7. No modification to repo contents: Preserves original file permissions and Git status
  8. Shallow clone option: Use --shallow-clone 1 to download only latest version history (faster, less disk space)
    """
  )
  
  # Global option (all commands)
  parser.add_argument(
    "-d", "--debug",
    action="store_true",
    default=DEFAULT_DEBUG_MODE,
    help=f"Enable debug logs (default: {DEFAULT_DEBUG_MODE})"
  )
  
  # Subparsers with short/long command support
  subparsers = parser.add_subparsers(
    dest="cmd",
    required=True,
    help="Commands (use <cmd> -h for details): c=config, d=download, l=list"
  )
  
  # ------------------------------ Config Command (c/config) ------------------------------
  config_parser = subparsers.add_parser(
    "config",
    aliases=["c"],
    help="Configure persistent repo alias-path pairs (short: c)",
    formatter_class=argparse.RawDescriptionHelpFormatter,
    epilog="""
Examples:
  1. Add local repo alias:
     %(prog)s -a local-dev -p /test/path/to/local-git-repo
  2. Add remote repo alias:
     %(prog)s -a dev -p git@github.com:your-org/dev-scripts.git
  3. Update alias (local/remote):
     %(prog)s -a test -p /new/local/repo/path
  4. Add with debug:
     %(prog)s -a prod -p https://github.com/your-org/prod.git -d
    """
  )
  config_parser.add_argument(
    "-a", "--repo-alias",
    help="Repo alias (e.g., dev, vendor_x) - unique"
  )
  config_parser.add_argument(
    "-p", "--repo-path",
    help="Git repo path: local directory (e.g., /test/path/to/git) or remote URL (https://, git@, ssh://)"
  )
  config_parser.set_defaults(func=lambda args: handle_config(
    args.repo_alias, args.repo_path, args.debug
  ))
  
  # ------------------------------ Download Command (d/download) ------------------------------
  download_parser = subparsers.add_parser(
    "download",
    aliases=["d"],
    help="Download scripts from repo alias + vendor branch (short: d)",
    formatter_class=argparse.RawDescriptionHelpFormatter,
    epilog="""
Examples:
  1. Defaults (full history, alias:{DEFAULT_REPO_ALIAS}, branch:{DEFAULT_PROCESS_BRANCH}, output:{DEFAULT_OUTPUT_DIR}):
     %(prog)s
  2. Shallow clone (latest history only):
     %(prog)s --shallow-clone 1
  3. Custom alias + shallow clone:
     %(prog)s -t dev -b vendor_a -o ~/work/vendor_a_scripts --shallow-clone 1
  4. Full history (explicit):
     %(prog)s -t test -b main -o ./scripts --shallow-clone 0
  5. Debug + shallow clone:
     %(prog)s -t test -b vendor_b -o ./scripts --shallow-clone 1 -d
    """.format(
      DEFAULT_REPO_ALIAS=DEFAULT_REPO_ALIAS,
      DEFAULT_PROCESS_BRANCH=DEFAULT_PROCESS_BRANCH,
      DEFAULT_OUTPUT_DIR=DEFAULT_OUTPUT_DIR
    )
  )
  download_parser.add_argument(
    "-t", "--type",
    default=DEFAULT_REPO_ALIAS,
    help=f"Repo alias (default: {DEFAULT_REPO_ALIAS})"
  )
  download_parser.add_argument(
    "-b", "--branch",
    default=DEFAULT_PROCESS_BRANCH,
    help=f"Vendor branch (default: {DEFAULT_PROCESS_BRANCH})"
  )
  download_parser.add_argument(
    "-o", "--output",
    default=DEFAULT_OUTPUT_DIR,
    help=f"Output directory (default: {DEFAULT_OUTPUT_DIR})"
  )
  download_parser.add_argument(
    "--shallow-clone",
    type=int,
    default=DEFAULT_SHALLOW_CLONE,
    choices=[0, 1],
    help=f"Download only latest version history (1=enable, 0=disable full history) (default: {DEFAULT_SHALLOW_CLONE})"
  )
  download_parser.set_defaults(func=lambda args: handle_download(
    args.type, args.branch, args.output, args.shallow_clone, args.debug
  ))
  
  # ------------------------------ List Command (l/list) ------------------------------
  list_parser = subparsers.add_parser(
    "list",
    aliases=["l"],
    help="List all repos: aliases, type (local/remote), branches, tags (short: l)",
    formatter_class=argparse.RawDescriptionHelpFormatter,
    epilog="""
Examples:
  1. List all repos (basic):
     %(prog)s
  2. List with debug logs:
     %(prog)s -d
    """
  )
  list_parser.set_defaults(func=lambda args: handle_list(args.debug))
  
  # ------------------------------ Parse and Validate ------------------------------
  args = parser.parse_args()
  
  # Validate command-option combinations
  cmd_opts = {
    "c": {"allowed": {"cmd", "debug", "repo_alias", "repo_path"}, "desc": "-a/--repo-alias, -p/--repo-path, -d"},
    "config": {"allowed": {"cmd", "debug", "repo_alias", "repo_path"}, "desc": "-a/--repo-alias, -p/--repo-path, -d"},
    "d": {"allowed": {"cmd", "debug", "type", "branch", "output", "shallow_clone"}, "desc": "-t/--type, -b/--branch, -o/--output, --shallow-clone, -d"},
    "download": {"allowed": {"cmd", "debug", "type", "branch", "output", "shallow_clone"}, "desc": "-t/--type, -b/--branch, -o/--output, --shallow-clone, -d"},
    "l": {"allowed": {"cmd", "debug"}, "desc": "-d/--debug only"},
    "list": {"allowed": {"cmd", "debug"}, "desc": "-d/--debug only"}
  }
  
  provided = set([k for k, v in vars(args).items() if v is not None and k != "func" and k != "cmd"])
  invalid = provided - cmd_opts[args.cmd]["allowed"]
  if invalid:
    print(f"ERROR: Invalid options for '{args.cmd}' command: {', '.join(invalid)}", file=sys.stderr)
    print(f"Allowed options: {cmd_opts[args.cmd]['desc']}", file=sys.stderr)
    sys.exit(1)
  
  # Execute command
  args.func(args)

if __name__ == "__main__":
  main()
