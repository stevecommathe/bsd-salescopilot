#!/usr/bin/env python3
"""
Local-first logging for BSD Sales Copilot
Writes to JSONL file for fast, reliable logging
Background sync process pushes to Supabase
"""

import json
import os
import fcntl
from datetime import datetime

# Log file location
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
LOG_DIR = os.path.join(SCRIPT_DIR, ".logs")
LOG_FILE = os.path.join(LOG_DIR, "usage.jsonl")


def ensure_log_dir():
    """Create log directory if it doesn't exist"""
    if not os.path.exists(LOG_DIR):
        os.makedirs(LOG_DIR, exist_ok=True)


def log_local(entry: dict):
    """
    Append a log entry to local JSONL file
    Thread-safe using file locking

    Args:
        entry: Dict with log data (trigger, user_id, etc.)
    """
    ensure_log_dir()

    # Add timestamp if not present
    if "timestamp" not in entry:
        entry["timestamp"] = datetime.utcnow().isoformat() + "Z"

    try:
        with open(LOG_FILE, "a") as f:
            # Lock file for safe concurrent writes
            fcntl.flock(f.fileno(), fcntl.LOCK_EX)
            try:
                f.write(json.dumps(entry) + "\n")
            finally:
                fcntl.flock(f.fileno(), fcntl.LOCK_UN)
    except Exception:
        # Never fail - logging should not break main functionality
        pass


def read_logs():
    """
    Read all pending log entries
    Returns list of dicts
    """
    if not os.path.exists(LOG_FILE):
        return []

    entries = []
    try:
        with open(LOG_FILE, "r") as f:
            for line in f:
                line = line.strip()
                if line:
                    try:
                        entries.append(json.loads(line))
                    except json.JSONDecodeError:
                        pass
    except Exception:
        pass

    return entries


def clear_logs():
    """Clear all pending logs after successful sync"""
    try:
        if os.path.exists(LOG_FILE):
            os.remove(LOG_FILE)
    except Exception:
        pass


def archive_failed_logs(entries: list):
    """
    Archive logs that failed to sync
    Keeps them for retry on next sync
    """
    if not entries:
        return

    ensure_log_dir()
    archive_file = os.path.join(LOG_DIR, "failed.jsonl")

    try:
        with open(archive_file, "a") as f:
            for entry in entries:
                f.write(json.dumps(entry) + "\n")
    except Exception:
        pass


def get_log_stats():
    """Get stats about pending logs"""
    entries = read_logs()
    return {
        "pending_count": len(entries),
        "log_file": LOG_FILE,
        "log_dir": LOG_DIR,
    }
