#!/usr/bin/env python3
# --------------------------
# author    : sar song
# date      : 2025/11/11 12:37:12 Tuesday
# label     : python
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : This Python script serves as a script distributor to manage, download, and execute flow/signoff scripts from local or 
#			  remote Git repositories (supports both non-bare and bare repos) with alias management, permission control, regex-based 
#             repo search, and pre-defined command execution. It features multi-level security (user managers and permission-based access), 
#             persistent config storage, and cross-platform compatibility for streamlined script distribution workflows.
# return    : downloaded files or dirs
# ref       : link url
# --------------------------
import argparse
import subprocess
import sys
import os
import re
from datetime import datetime
import configparser
import shutil
import textwrap  # Added for help text line wrapping
import pwd  # For validating system username existence

# ============================== DEFAULT CONFIGURATION ==============================
# User-modifiable default values (auto-synced to help text)
DEFAULT_REPO_ALIASES = {
  "prod": "https://github.com/your-org/production-scripts.git",
  "test": "https://github.com/your-org/test-scripts.git"
}
DEFAULT_REPO_ALIAS = "prod"
DEFAULT_PROCESS_BRANCH = "main"
DEFAULT_OUTPUT_DIR = os.path.expanduser("./")
CONFIG_FILE_PATH = os.path.expanduser("~/.gvs.conf")  # Modified: Changed default to .gvs.conf
# Hidden file for permission storage (modifiable by admin)
PERMISSION_FILE_PATH = os.path.expanduser("~/.gvs_permission.conf")
VALID_SCRIPT_TYPES = ["flow", "signoff"]  # Kept for backward compatibility, not used in validation
DEFAULT_DEBUG_MODE = False
DEFAULT_FIND_SCOPE = "both"  # Default search scope for find mode (alias/path/both)

# Config permission control (ADMIN-MODIFIABLE IN CODE ONLY - no CLI option)
# Defines who can perform user management operations (--user-op + -u)
# Structure: list of system usernames (e.g., ["root", "admin"])
ALLOWED_USER_MANAGERS = ["root", "anrui.song"]  # Internal variable - edit here to modify
CONFIG_PERMISSIONS_SECTION = "ConfigAllowedUsers"  # Section name in permission file
# Valid permissions for config mode users (ONLY for repo alias operations: -a/--repo-alias + -p/--repo-path)
VALID_PERMISSIONS = ["add", "delete"]  # Updated: Removed "find" permission (find mode is public)
VALID_FIND_SCOPES = ["alias", "path", "both"]  # Valid search scopes for find mode

# User-defined commands (modify this list to add/remove commands)
# Structure: [{"alias": "command-alias", "command": "shell-command", "help": "command-description"}]
USER_DEFINED_COMMANDS = [
  {
    "alias": "source-env",
    "command": "source ./env.sh",
    "help": "Source environment configuration from env.sh in current directory. This loads all required environment variables, path configurations, and dependency settings needed for subsequent script execution."
  },
  {
    "alias": "run-flow",
    "command": "bash ./flow_scripts/run.sh",
    "help": "Execute flow script runner (requires flow_scripts/ directory). Automatically triggers the main workflow pipeline, including pre-processing, validation, and execution of sequential tasks defined in the flow configuration."
  }
]

# ============================== GLOBAL VARIABLES ==============================
DEBUG_MODE = DEFAULT_DEBUG_MODE
PERSISTENT_ALIASES = {}
CONFIG_ALLOWED_USERS = {}  # Stores users allowed to use config mode (loaded from permission file)

# ============================== UTILITY FUNCTIONS ==============================
def debug_log(message):
  if DEBUG_MODE:
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(f"[DEBUG] {timestamp}: {message}", file=sys.stderr)

def load_persistent_config():
  """Load repo aliases from config file"""
  global PERSISTENT_ALIASES
  if os.path.exists(CONFIG_FILE_PATH):
    config = configparser.ConfigParser()
    config.read(CONFIG_FILE_PATH)
    # Load repo aliases
    if "RepoAliases" in config.sections():
      PERSISTENT_ALIASES = dict(config["RepoAliases"])
      debug_log(f"Loaded persistent aliases: {PERSISTENT_ALIASES}")
  else:
    debug_log(f"Config file not found at {CONFIG_FILE_PATH}")
  
  merged_aliases = PERSISTENT_ALIASES.copy()
  merged_aliases.update(DEFAULT_REPO_ALIASES)
  return merged_aliases

def load_permission_config():
  """Load allowed users and their permissions from permission file (new indented format)"""
  global CONFIG_ALLOWED_USERS
  CONFIG_ALLOWED_USERS = {}
  
  # Ensure permission file exists (create empty if not)
  if not os.path.exists(PERMISSION_FILE_PATH):
    debug_log(f"Permission file not found - creating empty file at {PERMISSION_FILE_PATH}")
    with open(PERMISSION_FILE_PATH, "w") as f:
      f.write(f"[{CONFIG_PERMISSIONS_SECTION}]\n")
    return
  
  # Read permission file with custom handling for indented format
  try:
    with open(PERMISSION_FILE_PATH, "r") as f:
      lines = [line.strip() for line in f if line.strip() and not line.strip().startswith("#")]
    
    current_section = None
    current_user = None
    user_data = {}
    
    for line in lines:
      # Check for section header
      if line.startswith("[") and line.endswith("]"):
        current_section = line.strip("[]")
        continue
      
      # Only process lines in the target section
      if current_section != CONFIG_PERMISSIONS_SECTION:
        continue
      
      # Check if line is a username (no colon, not indented in original file)
      if ":" not in line:
        # Save previous user data if exists
        if current_user and user_data:
          CONFIG_ALLOWED_USERS[current_user] = user_data
        
        # Start new user
        current_user = line.strip()
        user_data = {
          "added_by": "unknown",
          "added_at": "unknown",
          "last_modified": "unknown",
          "permissions": []
        }
      elif current_user and line.count(":") >= 1:
        # Split key-value pairs (handle colon in values)
        key_part, value_part = line.split(":", 1)
        key = key_part.strip().lower()
        value = value_part.strip()
        
        # Map keys to standard user data fields
        if key == "added_by":
          user_data["added_by"] = value
        elif key == "added_at":
          user_data["added_at"] = value
        elif key in ["modified", "last_modified"]:
          user_data["last_modified"] = value
        elif key == "permissions":
          # Split comma-separated permissions
          permissions = [p.strip() for p in value.split(",")] if value else []
          user_data["permissions"] = [p for p in permissions if p and p in VALID_PERMISSIONS]
    
    # Save the last user
    if current_user and user_data:
      CONFIG_ALLOWED_USERS[current_user] = user_data
    
    debug_log(f"Loaded allowed config users: {list(CONFIG_ALLOWED_USERS.keys())}")
  except Exception as e:
    debug_log(f"Error loading permission file: {str(e)}")
    print(f"WARNING: Failed to parse permission file - {str(e)}", file=sys.stderr)

def save_permission_config(user_op=None, username=None, modifier=None, permissions=None):
  """Save user permission changes to hidden permission file (new indented format)"""
  # Load existing data first
  load_permission_config()
  
  # Read existing file content to preserve section structure
  existing_content = []
  if os.path.exists(PERMISSION_FILE_PATH):
    with open(PERMISSION_FILE_PATH, "r") as f:
      existing_content = f.readlines()
  
  # Parse existing content to separate sections
  sections = {}
  current_section = None
  section_lines = []
  
  for line in existing_content:
    stripped_line = line.strip()
    if stripped_line.startswith("[") and stripped_line.endswith("]"):
      if current_section is not None:
        sections[current_section] = section_lines
      current_section = stripped_line.strip("[]")
      section_lines = [line]
    else:
      section_lines.append(line)
  
  if current_section is not None:
    sections[current_section] = section_lines
  
  # Ensure target section exists
  if CONFIG_PERMISSIONS_SECTION not in sections:
    sections[CONFIG_PERMISSIONS_SECTION] = [f"[{CONFIG_PERMISSIONS_SECTION}]\n"]
  
  # Get current timestamp for modification
  current_timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
  
  # ------------------------------ Handle Add Operation ------------------------------
  if user_op == "add" and username and modifier and permissions:
    valid_perms = [p for p in permissions if p in VALID_PERMISSIONS] if permissions else []
    if not valid_perms:
      print(f"WARNING: No valid permissions specified. Valid permissions are: {', '.join(VALID_PERMISSIONS)}", file=sys.stderr)
      return False
    
    if username in CONFIG_ALLOWED_USERS:
      # Update existing user
      existing_user = CONFIG_ALLOWED_USERS[username]
      existing_perms = existing_user["permissions"]
      new_perms = [p for p in valid_perms if p not in existing_perms]
      
      if not new_perms:
        print(f"WARNING: User '{username}' already has all specified permissions - no changes made", file=sys.stderr)
        return True
      
      # Merge permissions
      merged_perms = list(dict.fromkeys(existing_perms + new_perms))
      existing_user["permissions"] = merged_perms
      existing_user["last_modified"] = current_timestamp
      
      debug_log(f"Updated user '{username}' permissions: added {new_perms} (merged: {merged_perms})")
      print(f"WARNING: User '{username}' already exists - added new permissions only: {', '.join(new_perms)}")
    else:
      # Add new user
      CONFIG_ALLOWED_USERS[username] = {
        "added_by": modifier,
        "added_at": current_timestamp,
        "last_modified": current_timestamp,
        "permissions": valid_perms
      }
      debug_log(f"Added new user '{username}' with permissions: {valid_perms}")
  
  # ------------------------------ Handle Delete Operation ------------------------------
  elif user_op == "delete" and username and modifier and permissions:
    valid_perms = [p for p in permissions if p in VALID_PERMISSIONS] if permissions else []
    if not valid_perms:
      print(f"WARNING: No valid permissions specified. Valid permissions are: {', '.join(VALID_PERMISSIONS)}", file=sys.stderr)
      return False
    
    if username not in CONFIG_ALLOWED_USERS:
      print(f"WARNING: User '{username}' not found in permission list - no changes made", file=sys.stderr)
      return True
    
    existing_user = CONFIG_ALLOWED_USERS[username]
    existing_perms = existing_user["permissions"]
    removed_perms = [p for p in valid_perms if p in existing_perms]
    
    if not removed_perms:
      print(f"WARNING: User '{username}' does not have any of the specified permissions - no changes made", file=sys.stderr)
      return True
    
    # Update permissions
    remaining_perms = [p for p in existing_perms if p not in removed_perms]
    existing_user["permissions"] = remaining_perms
    existing_user["last_modified"] = current_timestamp
    
    # Remove user if no permissions left
    if not remaining_perms:
      del CONFIG_ALLOWED_USERS[username]
      debug_log(f"Removed user '{username}' (no remaining permissions)")
      print(f"NOTICE: User '{username}' has no remaining permissions - deleted user record")
    else:
      debug_log(f"Updated user '{username}' permissions: removed {removed_perms} (remaining: {remaining_perms})")
      print(f"SUCCESS: Removed permissions from user '{username}': {', '.join(removed_perms)}")
  
  # ------------------------------ Handle Delete User Operation ------------------------------
  elif user_op == "delete_user" and username:
    if username in CONFIG_ALLOWED_USERS:
      del CONFIG_ALLOWED_USERS[username]
      debug_log(f"Removed user '{username}' from permission file")
      return True
    else:
      print(f"WARNING: User '{username}' not found in permission list", file=sys.stderr)
      return False
  
  # ------------------------------ Generate Updated Section Content ------------------------------
  # Clear existing section content (except header)
  updated_section = [f"[{CONFIG_PERMISSIONS_SECTION}]\n"]
  
  # Add users with indented format
  for user, data in sorted(CONFIG_ALLOWED_USERS.items()):
    updated_section.append(f"{user}\n")
    updated_section.append(f"    added_by: {data['added_by']}\n")
    updated_section.append(f"    added_at: {data['added_at']}\n")
    updated_section.append(f"    modified: {data['last_modified']}\n")
    permissions_str = ", ".join(data['permissions']) if data['permissions'] else ""
    updated_section.append(f"    permissions: {permissions_str}\n")
    updated_section.append("\n")  # Add blank line between users
  
  # Update the section in sections dictionary
  sections[CONFIG_PERMISSIONS_SECTION] = updated_section
  
  # ------------------------------ Write Back to File ------------------------------
  try:
    with open(PERMISSION_FILE_PATH, "w") as f:
      # Write all sections
      for section_name, section_content in sections.items():
        f.writelines(section_content)
    return True
  except Exception as e:
    print(f"ERROR: Failed to write to permission file: {str(e)}", file=sys.stderr)
    debug_log(f"Write error: {str(e)}")
    return False

def save_persistent_config(alias=None, path=None, delete_alias=None):
  """Save or delete repo aliases to config file"""
  config = configparser.ConfigParser()
  if os.path.exists(CONFIG_FILE_PATH):
    config.read(CONFIG_FILE_PATH)
  if "RepoAliases" not in config.sections():
    config.add_section("RepoAliases")
  
  # Handle delete operation
  if delete_alias:
    if delete_alias in config["RepoAliases"]:
      del config["RepoAliases"][delete_alias]
      debug_log(f"Deleted alias '{delete_alias}' from config file")
    else:
      debug_log(f"Alias '{delete_alias}' not found for deletion")
  
  # Handle add/update operation
  if alias and path:
    config["RepoAliases"][alias] = path
    debug_log(f"Saved alias '{alias}' -> '{path}'")
  
  # Write back to file (preserve other sections if any)
  with open(CONFIG_FILE_PATH, "w") as f:
    config.write(f)

def run_git_command(cmd, cwd=None, check=True):
  debug_log(f"Git command: {' '.join(cmd)}")
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
  debug_log(f"Fetching branches for: {repo_url}")
  # Distinguish local and remote repos: read branches directly for local, use ls-remote for remote
  if os.path.isdir(repo_url):
    result = run_git_command(["git", "branch", "--list"], cwd=repo_url)
    if not result:
      debug_log(f"Failed to fetch branches for local repo")
      return []
    branches = [line.strip().replace("* ", "") for line in result.stdout.splitlines()]  # Fixed ljust bug
  else:
    result = run_git_command(["git", "ls-remote", "--heads", repo_url])
    if not result:
      debug_log(f"Failed to fetch branches for remote repo")
      return []
    branches = [line.split("/")[-1].strip() for line in result.stdout.splitlines()]
  return branches

def list_remote_tags(repo_url):
  debug_log(f"Fetching tags for: {repo_url}")
  # Distinguish local and remote repos: read tags directly for local, use ls-remote for remote
  if os.path.isdir(repo_url):
    result = run_git_command(["git", "tag", "--list"], cwd=repo_url)
    if not result:
      debug_log(f"Failed to fetch tags for local repo")
      return []
    tags = [line.strip() for line in result.stdout.splitlines()]
  else:
    result = run_git_command(["git", "ls-remote", "--tags", repo_url], check=False)
    if not result or result.returncode != 0:
      debug_log("No tags found or failed to fetch")
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

def is_valid_git_repo(path):
  """Validate if path is a valid Git repo (supports bare repos)"""
  # Check 1: Path exists
  if not os.path.exists(path):
    return False, "Path does not exist"
  # Check 2: Use git rev-parse to verify non-bare repo (has worktree)
  result = run_git_command(["git", "rev-parse", "--is-inside-work-tree"], cwd=path, check=False)
  if result and result.returncode == 0:
    return True, "Non-bare Git repository"
  # Check 3: Verify bare repo (no worktree)
  result = run_git_command(["git", "rev-parse", "--is-bare-repository"], cwd=path, check=False)
  if result and result.returncode == 0 and result.stdout.strip() == "true":
    return True, "Bare Git repository"
  # Not a valid Git repo
  return False, "Missing Git repository structure (not a valid Git repo)"

def get_current_username():
  """Get current system username (cross-platform compatible)"""
  try:
    import getpass
    return getpass.getuser()
  except Exception:
    # Fallback for systems without getpass (e.g., some Windows environments)
    return os.environ.get("USER", os.environ.get("USERNAME", "unknown"))

def is_system_user_exists(username):
  """Validate if username exists in the system (cross-platform basic check)"""
  try:
    # Unix-like systems (Linux/macOS)
    pwd.getpwnam(username)
    return True
  except KeyError:
    # Check Windows environment variables as fallback
    if os.name == "nt":
      # Simple check: verify if username is in USER/USERNAME env (not 100% accurate but practical)
      current_users = [os.environ.get("USER", ""), os.environ.get("USERNAME", "")]
      return username.lower() in [u.lower() for u in current_users]
    return False
  except ImportError:
    # pwd module not available (unlikely on Unix-like systems)
    debug_log("pwd module not available - skipping system user validation")
    return True  # Fallback to allow if validation fails

def is_allowed_to_manage_users():
  """Check if current user is in ALLOWED_USER_MANAGERS (internal variable)"""
  current_user = get_current_username()
  allowed = current_user in ALLOWED_USER_MANAGERS
  debug_log(f"User management access: {current_user} - {'allowed' if allowed else 'denied'}")
  return allowed

def is_allowed_to_use_config(permission=None):
  """Check if current user is allowed to use config mode with specific permission (for repo alias operations)"""
  load_permission_config()  # Load latest allowed users
  current_user = get_current_username()
  
  if current_user not in CONFIG_ALLOWED_USERS:
    debug_log(f"Config mode access denied: {current_user} not in allowed list")
    return False
  
  # If no specific permission required, just check user exists in allowed list
  if not permission:
    debug_log(f"Config mode access allowed: {current_user}")
    return True
  
  # Check if user has the required permission for repo alias operations
  has_permission = permission in CONFIG_ALLOWED_USERS[current_user]["permissions"]
  debug_log(f"Permission check: {current_user} - {permission} - {'granted' if has_permission else 'denied'}")
  return has_permission

# ============================== COMMAND HANDLERS ==============================
def handle_config(args):
  global DEBUG_MODE
  DEBUG_MODE = args.debug
  load_permission_config()  # Load latest permissions on command start
  
  # Determine operation type
  config_op = None
  if args.user_op:
    config_op = "user-management"  # Manage allowed users or their permissions
  elif args.repo_alias and args.repo_path:
    config_op = "repo-alias-add"  # Add/update repo aliases (requires 'add' permission)
  elif args.delete_alias:
    config_op = "repo-alias-delete"  # Delete repo aliases (requires 'delete' permission)
  else:
    print("ERROR: Use one of the following operations:", file=sys.stderr)
    print("  1. Manage repo aliases (add/update): -a/--repo-alias + -p/--repo-path", file=sys.stderr)
    print("  2. Manage repo aliases (delete): -D/--delete-alias <alias-name>", file=sys.stderr)
    print("  3. Manage users/permissions: -o/--user-op + [-u/--username] + [-perms/--permissions]", file=sys.stderr)
    sys.exit(1)
  
  # ------------------------------ User Management Operations ------------------------------
  if config_op == "user-management":
    # Only ALLOWED_USER_MANAGERS can perform user management operations
    if not is_allowed_to_manage_users():
      current_user = get_current_username()
      print(f"ERROR: User '{current_user}' is not authorized to manage users/permissions", file=sys.stderr)
      print(f"Authorized managers: {', '.join(ALLOWED_USER_MANAGERS)}", file=sys.stderr)
      sys.exit(1)
    
    username = args.username.strip() if args.username else None
    modifier = get_current_username()
    
    # Execute single user operation (enforced one operation at a time)
    if args.user_op == "add":
      # Validate username and permissions are provided
      if not username:
        print("ERROR: --username (-u) is required for 'add' operation", file=sys.stderr)
        sys.exit(1)
      if not args.permissions:
        print(f"ERROR: --permissions (-perms) is required for 'add' operation. Valid values: {', '.join(VALID_PERMISSIONS)}", file=sys.stderr)
        sys.exit(1)
      
      # Validate system user exists
      if not is_system_user_exists(username):
        print(f"ERROR: System username '{username}' does not exist", file=sys.stderr)
        sys.exit(1)
      
      # Add permissions to user (supports new user or existing user)
      success = save_permission_config(
        user_op="add",
        username=username,
        modifier=modifier,
        permissions=args.permissions
      )
      if success:
        print(f"SUCCESS: Permission operation completed for user '{username}'")
        print(f"Storage: {PERMISSION_FILE_PATH}")
    
    elif args.user_op == "delete":
      # Two sub-operations for delete: delete user (no -perms) or delete permissions (with -perms)
      if not username:
        print("ERROR: --username (-u) is required for 'delete' operation", file=sys.stderr)
        sys.exit(1)
      
      if args.permissions:
        # Delete specific permissions from user
        success = save_permission_config(
          user_op="delete",
          username=username,
          modifier=modifier,
          permissions=args.permissions
        )
        if success:
          print(f"SUCCESS: Permission deletion completed for user '{username}'")
          print(f"Storage: {PERMISSION_FILE_PATH}")
      else:
        # Delete entire user entry (original delete user functionality)
        success = save_permission_config(user_op="delete_user", username=username)
        if success:
          print(f"SUCCESS: Removed user '{username}' from allowed list")
          print(f"Storage: {PERMISSION_FILE_PATH}")
    
    elif args.user_op == "find":
      # Validate username is provided
      if not username:
        print("ERROR: --username (-u) is required for 'find' operation", file=sys.stderr)
        sys.exit(1)
      
      # Validate system user exists
      if not is_system_user_exists(username):
        print(f"ERROR: System username '{username}' does not exist", file=sys.stderr)
        sys.exit(1)
      
      # Check and display user's details
      if username in CONFIG_ALLOWED_USERS:
        details = CONFIG_ALLOWED_USERS[username]
        print(f"User '{username}' - Allowed to manage repo aliases")
        print(f"  Added by: {details['added_by']}")
        print(f"  Added at: {details['added_at']}")
        print(f"  Last modified: {details['last_modified']}")
        print(f"  Permissions: {', '.join(details['permissions']) if details['permissions'] else 'None'}")
        print(f"Source: {PERMISSION_FILE_PATH}")
      else:
        print(f"User '{username}' - Not allowed to manage repo aliases")
    
    elif args.user_op == "list":
      # List all allowed users and their details
      if not CONFIG_ALLOWED_USERS:
        print("No users allowed to manage repo aliases yet")
        print(f"Grant access: 'config -o add -u <username> -perms <perm1 perm2>' (requires manager privileges)")
        print(f"Storage: {PERMISSION_FILE_PATH}")
        sys.exit(0)
      
      print(f"Allowed users ({len(CONFIG_ALLOWED_USERS)}) - Source: {PERMISSION_FILE_PATH}:\n")
      for uname, details in CONFIG_ALLOWED_USERS.items():
        print(f"Username: {uname}")
        print(f"  Added by: {details['added_by']}")
        print(f"  Added at: {details['added_at']}")
        print(f"  Last modified: {details['last_modified']}")
        print(f"  Permissions: {', '.join(details['permissions']) if details['permissions'] else 'None'}\n")
    
    sys.exit(0)
  
  # ------------------------------ Repo Alias Add/Update Operation ------------------------------
  if config_op == "repo-alias-add":
    # Check if current user has 'add' permission for repo alias operations
    if not is_allowed_to_use_config(permission="add"):
      current_user = get_current_username()
      print(f"ERROR: User '{current_user}' does not have 'add' permission for repo aliases", file=sys.stderr)
      print("Contact an authorized manager for access", file=sys.stderr)
      sys.exit(1)
    
    alias = args.repo_alias.strip()
    path = args.repo_path.strip()
    
    # Validate path: local directory or valid remote URL
    is_local_repo = os.path.isdir(path)
    is_remote_url = path.startswith(("https://", "git@", "ssh://"))
    
    if not (is_local_repo or is_remote_url):
      print(f"ERROR: Invalid repo path '{path}'.", file=sys.stderr)
      print("Valid formats: 1) Local directory 2) Remote URL (https://, git@, ssh://)", file=sys.stderr)
      sys.exit(1)
    
    # Validate local repo (supports bare repos)
    if is_local_repo:
      is_valid, repo_type = is_valid_git_repo(path)
      if not is_valid:
        print(f"ERROR: Local path '{path}' is not a valid Git repo - {repo_type}", file=sys.stderr)
        sys.exit(1)
      debug_log(f"Valid local repo: {path} ({repo_type})")
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
    print(f"SUCCESS: Repo alias saved - '{alias}' -> '{path}'")
    print(f"Storage: {CONFIG_FILE_PATH}")
    
    if DEBUG_MODE:
      print("\n[DEBUG] Repo Aliases Summary:")
      for a, p in load_persistent_config().items():
        source = "DEFAULT" if a in DEFAULT_REPO_ALIASES else "PERSISTENT"
        print(f"  {a}: {p} ({source})")
  
  # ------------------------------ Repo Alias Delete Operation ------------------------------
  if config_op == "repo-alias-delete":
    # Check if current user has 'delete' permission for repo alias operations
    if not is_allowed_to_use_config(permission="delete"):
      current_user = get_current_username()
      print(f"ERROR: User '{current_user}' does not have 'delete' permission for repo aliases", file=sys.stderr)
      print("Contact an authorized manager for access", file=sys.stderr)
      sys.exit(1)
    
    delete_alias = args.delete_alias.strip()
    debug_log(f"Deleting repo alias: '{delete_alias}'")
    
    # Check if alias is in default aliases (read-only)
    if delete_alias in DEFAULT_REPO_ALIASES:
      print(f"ERROR: '{delete_alias}' is a default system alias (read-only)", file=sys.stderr)
      sys.exit(1)
    
    # Load current persistent aliases
    load_persistent_config()
    
    # Check if alias exists in persistent config
    if delete_alias not in PERSISTENT_ALIASES:
      print(f"ERROR: Alias '{delete_alias}' not found in persistent config", file=sys.stderr)
      print("Available persistent aliases:", ", ".join(PERSISTENT_ALIASES.keys()) if PERSISTENT_ALIASES else "None", file=sys.stderr)
      sys.exit(1)
    
    # Perform deletion
    save_persistent_config(delete_alias=delete_alias)
    print(f"SUCCESS: Repo alias '{delete_alias}' deleted")
    print(f"Storage: {CONFIG_FILE_PATH}")
    
    if DEBUG_MODE:
      print("\n[DEBUG] Remaining Persistent Aliases:")
      load_persistent_config()  # Reload after deletion
      if PERSISTENT_ALIASES:
        for a, p in PERSISTENT_ALIASES.items():
          print(f"  {a}: {p}")
      else:
        print("  No persistent aliases remaining")

def handle_download(repo_alias, branch, output_dir, debug):
  global DEBUG_MODE
  DEBUG_MODE = debug
  
  repo_path = get_repo_url_by_alias(repo_alias)
  validate_process_branch(repo_path, branch)
  
  # Resolve absolute output directory path
  output_dir = os.path.abspath(output_dir)
  debug_log(f"Target directory: {output_dir}")
  
  # Create output directory if it doesn't exist
  if not os.path.exists(output_dir):
    debug_log(f"Creating output directory: {output_dir}")
    os.makedirs(output_dir, exist_ok=True)
  
  git_dir = os.path.join(output_dir, ".git")
  current_repo_url = get_current_remote_url(output_dir) if os.path.exists(git_dir) else None
  
  # Case 1: Output directory is not a Git repository (no .git folder)
  if not os.path.exists(git_dir):
    print(f"Cloning repository to '{output_dir}'...")
    clone_cmd = ["git", "clone", repo_path, "--branch", branch, "--single-branch", output_dir]
    clone_result = run_git_command(clone_cmd)
    
    if not clone_result or clone_result.returncode != 0:
      print(f"ERROR: Failed to clone repository to {output_dir}", file=sys.stderr)
      # Clean up incomplete directory if needed
      if os.path.exists(output_dir) and len(os.listdir(output_dir)) == 0:
        os.rmdir(output_dir)
      sys.exit(1)
    print(f"Successfully cloned to '{output_dir}'")
  
  # Case 2: Output directory is a Git repository
  else:
    print(f"Using existing repository: '{output_dir}'")
    
    # Subcase 2a: Existing repo remote does not match target repo
    if current_repo_url and current_repo_url != repo_path:
      print(f"ERROR: Repository mismatch!", file=sys.stderr)
      print(f"  Existing: {current_repo_url}", file=sys.stderr)
      print(f"  Target:   {repo_path}", file=sys.stderr)
      print("Use a different output directory or remove the existing .git folder", file=sys.stderr)
      sys.exit(1)
    
    # Subcase 2b: Check for uncommitted changes
    if not check_git_repo_clean(output_dir):
      print("ERROR: Uncommitted changes detected!", file=sys.stderr)
      print("Commit or stash changes before proceeding", file=sys.stderr)
      sys.exit(1)
    
    # Subcase 2c: Switch to target branch and pull latest changes
    print(f"Switching to branch '{branch}'...")
    checkout_result = run_git_command(["git", "checkout", branch], cwd=output_dir)
    if not checkout_result or checkout_result.returncode != 0:
      # Try to create branch from remote if it doesn't exist locally
      print(f"Creating branch '{branch}' from remote...")
      checkout_result = run_git_command(["git", "checkout", "-b", branch, f"origin/{branch}"], cwd=output_dir)
      if not checkout_result or checkout_result.returncode != 0:
        print(f"ERROR: Failed to checkout branch '{branch}'", file=sys.stderr)
        sys.exit(1)
    
    # Fetch latest changes from remote
    print("Fetching latest changes...")
    fetch_cmd = ["git", "fetch", "origin", branch]
    fetch_result = run_git_command(fetch_cmd, cwd=output_dir)
    if not fetch_result or fetch_result.returncode != 0:
      print("ERROR: Failed to fetch remote changes", file=sys.stderr)
      sys.exit(1)
    
    # Pull changes with conflict detection
    print(f"Merging changes for branch '{branch}'...")
    pull_result = run_git_command(["git", "pull", "origin", branch], cwd=output_dir)
    if not pull_result or pull_result.returncode != 0:
      print("ERROR: Merge conflict detected!", file=sys.stderr)
      print("Resolution steps:", file=sys.stderr)
      print("  1. cd", output_dir, file=sys.stderr)
      print("  2. Resolve conflicts manually", file=sys.stderr)
      print("  3. git add . && git commit -m 'Resolve conflicts'", file=sys.stderr)
      print("  4. Re-run download command", file=sys.stderr)
      sys.exit(1)
    
    print("Successfully updated repository")
  
  # Final success message
  print(f"\nSUCCESS: Repository operation completed")
  print(f"Directory: {output_dir}")
  print(f"History: Full")
  print(f"\nNext: cd {output_dir} && ./your_script.sh (adjust script name as needed)")

def handle_list(debug):
  global DEBUG_MODE
  DEBUG_MODE = debug
  load_permission_config()  # Load permissions for debug output
  
  merged_aliases = load_persistent_config()
  if not merged_aliases:
    print("ERROR: No repo aliases configured (use 'config' command first)", file=sys.stderr)
    sys.exit(1)
  
  print(f"Configured Repos ({len(merged_aliases)}):\n")
  for alias, repo_path in merged_aliases.items():
    print_repo_details(alias, repo_path)
  
  if DEBUG_MODE:
    print(f"\n[DEBUG] System Info:")
    print(f"  Config file: {CONFIG_FILE_PATH}")
    print(f"  Permission file: {PERMISSION_FILE_PATH}")
    print(f"  Allowed managers: {ALLOWED_USER_MANAGERS}")

def handle_find(pattern, search_scope, debug):
  """Handle find mode - search repos by regex pattern in alias/path (supports regex, public access)"""
  global DEBUG_MODE
  DEBUG_MODE = debug
  
  merged_aliases = load_persistent_config()
  if not merged_aliases:
    print("ERROR: No repo aliases configured (use 'config' command first)", file=sys.stderr)
    sys.exit(1)
  
  # Compile regex pattern (case-insensitive by default for better usability)
  try:
    regex = re.compile(pattern, re.IGNORECASE)
    debug_log(f"Find parameters - Pattern: '{pattern}', Scope: '{search_scope}'")
  except re.error as e:
    print(f"ERROR: Invalid regex pattern - {str(e)}", file=sys.stderr)
    sys.exit(1)
  
  # Filter matching repos based on search scope
  matching_repos = []
  for alias, repo_path in merged_aliases.items():
    match_alias = regex.search(alias) if search_scope in ["alias", "both"] else False
    match_path = regex.search(repo_path) if search_scope in ["path", "both"] else False
    
    if match_alias or match_path:
      matching_repos.append((alias, repo_path))
  
  # Display results
  if not matching_repos:
    print(f"No matches found - Pattern: '{pattern}', Scope: '{search_scope}'")
    sys.exit(0)
  
  print(f"Matching Repos ({len(matching_repos)}) - Pattern: '{pattern}', Scope: '{search_scope}':\n")
  for alias, repo_path in matching_repos:
    print_repo_details(alias, repo_path)
  
  if DEBUG_MODE:
    print(f"\n[DEBUG] Find Operation Summary:")
    print(f"  Pattern: '{pattern}' (case-insensitive)")
    print(f"  Scope: {search_scope}")
    print(f"  Total repos checked: {len(merged_aliases)}")
    print(f"  Matches found: {len(matching_repos)}")

def print_repo_details(alias, repo_path):
  """Helper function to print repo details (shared by list and find modes)"""
  print(f"=== Alias: {alias} ===")
  print(f"Path: {repo_path}")
  print(f"Type: {'Local' if os.path.isdir(repo_path) else 'Remote'}")
  if os.path.isdir(repo_path):
    is_valid, repo_type = is_valid_git_repo(repo_path)
    if is_valid:
      print(f"Repo Type: {repo_type}")
  print(f"Source: {'DEFAULT' if alias in DEFAULT_REPO_ALIASES else 'PERSISTENT'}")
  print(f"Editable: {'No' if alias in DEFAULT_REPO_ALIASES else 'Yes'}")
  
  # Get branches (with error handling)
  try:
    branches = list_remote_branches(repo_path)
    print(f"Branches ({len(branches)}):")
    for b in branches[:10]:  # Limit to 10 branches to avoid clutter
      print(f"  - {b}")
    if len(branches) > 10:
      print(f"  ... and {len(branches)-10} more")
  except Exception as e:
    print(f"Warning: Failed to fetch branches - {str(e)}")
  
  # Get tags (no error if none)
  tags = list_remote_tags(repo_path)
  if tags:
    print(f"Tags ({len(tags)}):")
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
    print("Tags: None")
  
  print()  # Add blank line between repos

def handle_exec(cmd_alias, debug):
  global DEBUG_MODE
  DEBUG_MODE = debug
  
  # List all available commands if no alias is provided
  if not cmd_alias:
    print("=== Available Commands ===")
    # Calculate max alias length for aligned formatting
    max_alias_len = max(len(cmd["alias"]) for cmd in USER_DEFINED_COMMANDS)
    # Define wrap width for help text (adjust based on terminal width, 60 = 80 - indentation)
    help_wrap_width = 60
    
    for cmd in USER_DEFINED_COMMANDS:
      # Left-align alias with fixed width for readability
      formatted_alias = cmd["alias"].ljust(max_alias_len)
      print(f"\n  Alias:   {formatted_alias}")
      print(f"  Command: {cmd['command']}")
      
      # Wrap long help text into multiple lines with consistent indentation
      wrapped_help = textwrap.wrap(cmd["help"], width=help_wrap_width, break_long_words=False)
      print(f"  Help:    {wrapped_help[0]}")  # First line with "Help:    " prefix
      # Subsequent lines with same indentation (8 spaces)
      for line in wrapped_help[1:]:
        print(f"           {line}")
    
    print("\nUsage:")
    print("  1. List commands: python script.py exec (or 'e')")
    print("  2. Run command:   python script.py exec <alias> (or 'e <alias>')")
    sys.exit(0)
  
  # Find target command by alias
  target_cmd = next((cmd for cmd in USER_DEFINED_COMMANDS if cmd["alias"] == cmd_alias), None)
  if not target_cmd:
    print(f"ERROR: Command alias '{cmd_alias}' not found!", file=sys.stderr)
    print("Available aliases:", ", ".join(cmd["alias"] for cmd in USER_DEFINED_COMMANDS), file=sys.stderr)
    sys.exit(1)
  
  # Execute the shell command
  debug_log(f"Executing command - Alias: {cmd_alias}, Command: {target_cmd['command']}")
  print(f"Running: {target_cmd['command']}\n")
  
  try:
    # Use shell=True to support shell features (e.g., source, pipes)
    result = subprocess.run(
      target_cmd["command"],
      shell=True,
      check=True,
      stdout=subprocess.PIPE,
      stderr=subprocess.PIPE,
      text=True
    )
    # Print command output (stdout + stderr)
    if result.stdout:
      print("Output:\n", result.stdout)
    if result.stderr:
      print("Stderr:\n", result.stderr, file=sys.stderr)
    print(f"\nSUCCESS: Command '{cmd_alias}' executed")
  except subprocess.CalledProcessError as e:
    print(f"ERROR: Command '{cmd_alias}' failed (exit code {e.returncode})", file=sys.stderr)
    if e.stdout:
      print("Output:\n", e.stdout, file=sys.stderr)
    if e.stderr:
      print("Stderr:\n", e.stderr, file=sys.stderr)
      sys.exit(1)
  except Exception as e:
    print(f"ERROR: Failed to execute '{cmd_alias}': {str(e)}", file=sys.stderr)
    sys.exit(1)

# ============================== MAIN ARGUMENT PARSER ==============================
def main():
  # Generate formatted command list for epilog (with line wrapping for help)
  epilog_command_list = []
  epilog_help_wrap_width = 55  # Wrap width for epilog help text (adjust based on terminal)
  for cmd in USER_DEFINED_COMMANDS:
    # Wrap help text for epilog
    wrapped_epilog_help = textwrap.wrap(cmd["help"], width=epilog_help_wrap_width, break_long_words=False)
    # First line: alias + command
    epilog_command_list.append(f"{cmd['alias']:<12} {cmd['command']}")
    # Subsequent lines: help text with indentation
    for i, help_line in enumerate(wrapped_epilog_help):
      if i == 0:
        epilog_command_list.append(f"{'':<14} {help_line}")  # Align with command
      else:
        epilog_command_list.append(f"{'':<14} {help_line}")
  
  # Top-level parser
  parser = argparse.ArgumentParser(
    description="Script Distributor - Manage/download flow/signoff scripts from Git (local/remote repos, supports bare repos)",
    formatter_class=argparse.RawDescriptionHelpFormatter,
    epilog=f"""
IMPORTANT NOTES:
  1. Default values are in script's top section (auto-synced to help)
  2. Default aliases can't be overwritten by 'config'
  3. Config files:
     - Repo aliases: {CONFIG_FILE_PATH}
     - Allowed users/permissions (hidden): {PERMISSION_FILE_PATH}
  4. Install Git first (required for all operations)
  5. Support both local Git repos (non-bare + bare) and remote URLs (https://, git@, ssh://)
  6. Two-level security for config mode:
     - User Managers: Defined in ALLOWED_USER_MANAGERS (code-only, manage users/permissions)
     - Allowed Users: Have permissions to manage repo aliases (stored in {PERMISSION_FILE_PATH})
     - Repo Alias Permissions: {', '.join(VALID_PERMISSIONS)} (control -a/-p and -D usage)
  7. Exec mode: Run user-defined shell commands (use 'exec'/'e' command to list all available commands)
  8. Find mode: Public search (no permissions required) - supports regex, search alias/path/both
     - Default search scope: {DEFAULT_FIND_SCOPE} (modify DEFAULT_FIND_SCOPE in script to change)
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
    help="Commands (use <cmd> -h for details): c=config, d=download, l=list, f=find, e=exec"
  )
  
  # ------------------------------ Config Command (c/config) ------------------------------
  config_parser = subparsers.add_parser(
    "config",
    aliases=["c"],
    help="Three main operations: 1) Add/update repo aliases (-a/-p) 2) Delete repo aliases (-D/--delete-alias) 3) Manage users/permissions (-o/-u/-perms) (short: c)",
    formatter_class=argparse.RawDescriptionHelpFormatter,
    epilog="""
Config Mode Operations (Three Separate Workflows):
  1. MANAGE REPO ALIASES (ADD/UPDATE) (requires 'add' permission for allowed users):
     - Purpose: Add/update persistent repo alias-path pairs
     - Command: %(prog)s -a <alias> -p <repo-path>
     - <repo-path>: Local directory (non-bare/bare Git repo) or remote URL (https://, git@, ssh://)
     - Alias storage: {CONFIG_FILE_PATH}
  
  2. MANAGE REPO ALIASES (DELETE) (requires 'delete' permission for allowed users):
     - Purpose: Delete persistent repo aliases (cannot delete default system aliases)
     - Command: %(prog)s -D <alias-name>
     - Restrictions: 
       - Cannot delete default aliases (defined in script: {default_aliases})
       - Only deletes aliases stored in {CONFIG_FILE_PATH}
       - Requires 'delete' permission (granted by user managers)
  
  3. MANAGE USERS/PERMISSIONS (only for USER MANAGERS - edit ALLOWED_USER_MANAGERS in code):
     - Purpose: Grant/revoke user access or modify repo alias permissions
     - Valid operations (ONE at a time):
       a. Add permissions to user (new or existing): %(prog)s -o add -u <username> -perms <perm1 perm2>
       b. Delete permissions from user: %(prog)s -o delete -u <username> -perms <perm1 perm2>
       c. Delete entire user: %(prog)s -o delete -u <username>
       d. List all users/permissions: %(prog)s -o list
       e. Find user details: %(prog)s -o find -u <username>
     - Valid permissions (for repo aliases): {permissions_list}
       - 'add': Allow adding/updating repo aliases (-a/-p)
       - 'delete': Allow deleting repo aliases (-D/--delete-alias)
     - Data storage: {PERMISSION_FILE_PATH}
     - Notes:
       - Adding existing permissions will show warning and skip duplicates
       - Deleting non-existent permissions will show warning and no changes
       - All permission changes update 'last_modified' timestamp in the file
       - Deleting all permissions of a user will automatically remove the user record

Examples:
  # 1. Repo Alias Management (ADD/UPDATE - allowed users with 'add' permission only)
  1. Add local bare repo alias:
     %(prog)s -a bare-prod -p /path/to/prod-repo.git
  2. Add remote repo alias:
     %(prog)s -a dev -p git@github.com:your-org/dev-scripts.git

  # 2. Repo Alias Management (DELETE - allowed users with 'delete' permission only)
  1. Delete a persistent alias:
     %(prog)s -D dev
  2. Delete with debug logs:
     %(prog)s -D bare-prod -d

  # 3. Users/Permissions Management (user managers only)
  1. Add 'delete' permission to existing user:
     %(prog)s -o add -u alice -perms delete
  2. Add both 'add' and 'delete' permissions:
     %(prog)s -o add -u bob -perms add delete
  3. Remove 'delete' permission from user:
     %(prog)s -o delete -u alice -perms delete
  4. List all users and their permissions:
     %(prog)s -o list
  5. Check user's permissions:
     %(prog)s -o find -u bob
    """.format(
      CONFIG_FILE_PATH=CONFIG_FILE_PATH,
      PERMISSION_FILE_PATH=PERMISSION_FILE_PATH,
      permissions_list=", ".join(VALID_PERMISSIONS),
      default_aliases=", ".join(DEFAULT_REPO_ALIASES.keys()),
    )
  )
  # Repo alias add/update options
  config_parser.add_argument(
    "-a", "--repo-alias",
    help="Repo alias (e.g., dev, vendor_x) - unique (for add/update operation)"
  )
  config_parser.add_argument(
    "-p", "--repo-path",
    help="Git repo path: local directory (non-bare/bare) or remote URL (for add/update operation)"
  )
  # Repo alias delete option (short: -D, long: --delete-alias)
  config_parser.add_argument(
    "-D", "--delete-alias",
    help="Repo alias name to delete (only persistent aliases, requires 'delete' permission)"
  )
  # User management options
  config_parser.add_argument(
    "-o", "--user-op",
    choices=["add", "delete", "list", "find"],
    help="Single user operation (manage users or their permissions) - short: -o"
  )
  config_parser.add_argument(
    "-u", "--username",
    help="System username (required for add/delete/find operations) - short: -u"
  )
  config_parser.add_argument(
    "-perms", "--permissions",
    nargs="+",
    choices=VALID_PERMISSIONS,
    help=f"Permissions to add/delete (required for '-o add' and '-o delete' permission operations, space-separated). Controls repo alias management access. Valid values: {', '.join(VALID_PERMISSIONS)}"
  )
  # Set handler
  config_parser.set_defaults(func=handle_config)
  
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
  2. Custom alias:
     %(prog)s -t dev -b vendor_a -o ~/work/vendor_a_scripts
  3. Explicit full history:
     %(prog)s -t test -b main -o ./scripts
  4. Debug mode:
     %(prog)s -t test -b vendor_b -o ./scripts -d
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
  download_parser.set_defaults(func=lambda args: handle_download(
    repo_alias=args.type,
    branch=args.branch,
    output_dir=args.output,
    debug=args.debug
  ))
  
  # ------------------------------ List Command (l/list) ------------------------------
  list_parser = subparsers.add_parser(
    "list",
    aliases=["l"],
    help="List all configured repo aliases with details (branches, tags, etc.) (short: l)",
    formatter_class=argparse.RawDescriptionHelpFormatter,
    epilog="""
Examples:
  1. Basic list:
     %(prog)s
  2. List with debug info:
     %(prog)s -d
    """
  )
  list_parser.set_defaults(func=lambda args: handle_list(debug=args.debug))
  
  # ------------------------------ Find Command (f/find) ------------------------------
  find_parser = subparsers.add_parser(
    "find",
    aliases=["f"],
    help="Public search for repos using regex pattern (no permissions required) (short: f)",
    formatter_class=argparse.RawDescriptionHelpFormatter,
    epilog="""
KEY FEATURES:
  - Public access: No permissions required (available to all users)
  - Regex support: Full Python regex syntax (case-insensitive by default)
  - Search scope: Choose to search alias, path, or both (default: {DEFAULT_FIND_SCOPE})
    - Modify DEFAULT_FIND_SCOPE in the script's top section to change the default scope
  - Output format: Same as 'list' command (consistent user experience)

REGEX EXAMPLES:
  1. Match aliases starting with 'prod': ^prod
  2. Match paths containing 'github': github
  3. Match aliases ending with 'test': test$
  4. Match either 'prod' or 'test' aliases: ^(prod|test)$
  5. Match paths with 'v1' or 'v2' tags: v[12]

USAGE EXAMPLES:
  1. Search with default scope (both alias and path):
     %(prog)s github
  2. Search only aliases:
     %(prog)s --scope alias ^dev
  3. Search only paths:
     %(prog)s --scope path vendor
  4. Debug mode:
     %(prog)s -d ^prod.*git
    """.format(DEFAULT_FIND_SCOPE=DEFAULT_FIND_SCOPE)
  )
  find_parser.add_argument(
    "pattern",
    help="Regex pattern to search for (supports full Python regex syntax, case-insensitive)"
  )
  find_parser.add_argument(
    "--scope",
    choices=VALID_FIND_SCOPES,
    default=DEFAULT_FIND_SCOPE,
    help=f"Search scope (default: {DEFAULT_FIND_SCOPE}). Valid values: {', '.join(VALID_FIND_SCOPES)}"
  )
  find_parser.set_defaults(func=lambda args: handle_find(
    pattern=args.pattern,
    search_scope=args.scope,
    debug=args.debug
  ))
  
  # ------------------------------ Exec Command (e/exec) ------------------------------
  exec_parser = subparsers.add_parser(
    "exec",
    aliases=["e"],
    help="Execute user-defined commands (use without arguments to list all) (short: e)",
    formatter_class=argparse.RawDescriptionHelpFormatter,
    epilog=f"""
Available Commands:
{'  ' + '\n  '.join(epilog_command_list)}

Examples:
  1. List all available commands:
     %(prog)s
  2. Run a specific command:
     %(prog)s source-env
  3. Run with debug logs:
     %(prog)s run-flow -d
    """
  )
  exec_parser.add_argument(
    "cmd_alias",
    nargs="?",
    default=None,
    help="Alias of command to execute (optional - omit to list all commands)"
  )
  exec_parser.set_defaults(func=lambda args: handle_exec(cmd_alias=args.cmd_alias, debug=args.debug))
  
  # Parse arguments and run
  args = parser.parse_args()
  args.func(args)

if __name__ == "__main__":
  main()
