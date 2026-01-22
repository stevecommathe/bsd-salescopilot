#!/usr/bin/env python3
"""
BSD Sales Copilot - Snippet Sync Script
Downloads latest snippets from GitHub and updates local copies

Runs every 5 minutes via launchd. Users never interact with this.
"""

import os
import sys
import json
import hashlib
import subprocess
from datetime import datetime
from urllib.request import urlopen, Request
from urllib.error import URLError, HTTPError

# Paths
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(SCRIPT_DIR)
CONFIG_FILE = os.path.join(SCRIPT_DIR, "config.json")
LOG_DIR = os.path.expanduser("~/Library/Logs/BSDSalesCopilot")
SYNC_LOG = os.path.join(LOG_DIR, "sync.log")
ERROR_LOG = os.path.join(LOG_DIR, "errors.log")

# Default config (can be overridden in config.json)
DEFAULT_CONFIG = {
    "github_repo": "stevecommathe/bsd-salescopilot",
    "github_branch": "main",
    "sync_enabled": True,
    "files_to_sync": [
        "match/base.yml",
        "match/faq.yml",
        "scripts/reply.py",
        "scripts/polish.py",
        "scripts/utils.py",
        "scripts/local_log.py",
        "scripts/log_snippet.py",
        "knowledge/faq.md",
    ]
}


def ensure_dirs():
    """Create necessary directories"""
    os.makedirs(LOG_DIR, exist_ok=True)


def log(message, level="INFO"):
    """Write to sync log"""
    ensure_dirs()
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    log_line = f"[{timestamp}] [{level}] {message}\n"

    with open(SYNC_LOG, "a") as f:
        f.write(log_line)

    if level == "ERROR":
        with open(ERROR_LOG, "a") as f:
            f.write(log_line)

    # Also print if running interactively
    if sys.stdout.isatty():
        print(log_line.strip())


def load_config():
    """Load config with defaults"""
    config = DEFAULT_CONFIG.copy()

    if os.path.exists(CONFIG_FILE):
        try:
            with open(CONFIG_FILE, "r") as f:
                user_config = json.load(f)
                config.update(user_config)
        except Exception as e:
            log(f"Warning: Could not load config.json: {e}", "WARN")

    return config


def get_file_hash(filepath):
    """Get MD5 hash of local file"""
    if not os.path.exists(filepath):
        return None

    with open(filepath, "rb") as f:
        return hashlib.md5(f.read()).hexdigest()


def download_file(repo, branch, filepath):
    """Download file from GitHub raw"""
    url = f"https://raw.githubusercontent.com/{repo}/{branch}/{filepath}"

    try:
        req = Request(url, headers={"User-Agent": "BSD-SalesCopilot-Sync/1.0"})
        with urlopen(req, timeout=30) as response:
            content = response.read()
            return content, hashlib.md5(content).hexdigest()
    except HTTPError as e:
        if e.code == 404:
            log(f"File not found on GitHub: {filepath}", "WARN")
            return None, None
        raise
    except Exception as e:
        raise


def sync_file(repo, branch, filepath, project_dir):
    """
    Sync a single file from GitHub
    Returns: "updated", "unchanged", or "error"
    """
    local_path = os.path.join(project_dir, filepath)
    local_hash = get_file_hash(local_path)

    try:
        content, remote_hash = download_file(repo, branch, filepath)

        if content is None:
            return "skipped"

        if local_hash == remote_hash:
            return "unchanged"

        # Ensure directory exists
        os.makedirs(os.path.dirname(local_path), exist_ok=True)

        # Write new content
        with open(local_path, "wb") as f:
            f.write(content)

        log(f"Updated: {filepath}")
        return "updated"

    except Exception as e:
        log(f"Failed to sync {filepath}: {e}", "ERROR")
        return "error"


def restart_espanso():
    """Restart Espanso to pick up changes"""
    try:
        result = subprocess.run(
            ["espanso", "restart"],
            capture_output=True,
            text=True,
            timeout=30
        )
        if result.returncode == 0:
            log("Espanso restarted successfully")
            return True
        else:
            log(f"Espanso restart failed: {result.stderr}", "ERROR")
            return False
    except FileNotFoundError:
        log("Espanso not found - is it installed?", "ERROR")
        return False
    except Exception as e:
        log(f"Failed to restart Espanso: {e}", "ERROR")
        return False


def main():
    """Main sync function"""
    log("=" * 50)
    log("Starting sync")

    config = load_config()

    # Check if sync is enabled
    if not config.get("sync_enabled", True):
        log("Sync disabled in config, skipping")
        return

    repo = config.get("github_repo", DEFAULT_CONFIG["github_repo"])
    branch = config.get("github_branch", DEFAULT_CONFIG["github_branch"])
    files = config.get("files_to_sync", DEFAULT_CONFIG["files_to_sync"])

    log(f"Repo: {repo} (branch: {branch})")
    log(f"Files to sync: {len(files)}")

    # Determine project directory
    # If BSD_COPILOT_PATH is set, use that; otherwise use relative to this script
    project_dir = os.environ.get("BSD_COPILOT_PATH", PROJECT_DIR)
    log(f"Project dir: {project_dir}")

    # Sync each file
    results = {"updated": 0, "unchanged": 0, "error": 0, "skipped": 0}

    for filepath in files:
        result = sync_file(repo, branch, filepath, project_dir)
        results[result] += 1

    # Summary
    log(f"Sync complete: {results['updated']} updated, {results['unchanged']} unchanged, {results['error']} errors, {results['skipped']} skipped")

    # Restart Espanso if any files were updated
    if results["updated"] > 0:
        log("Files changed, restarting Espanso...")
        restart_espanso()

    log("=" * 50)


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        log(f"Sync failed with exception: {e}", "ERROR")
        sys.exit(1)
