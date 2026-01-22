#!/usr/bin/env python3
"""
Background sync script - pushes local logs to Supabase
Run via launchd (Mac) or Task Scheduler (Windows) every 5 minutes

Usage: python3 sync_logs.py [--dry-run] [--verbose]
"""

import json
import sys
import os
from datetime import datetime
from urllib.request import Request, urlopen
from urllib.error import URLError, HTTPError

# Add script dir to path for imports
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, SCRIPT_DIR)

from local_log import read_logs, clear_logs, archive_failed_logs, get_log_stats
from utils import load_config


def sync_to_supabase(entries, config, verbose=False):
    """
    Sync log entries to Supabase
    Returns tuple of (success_count, failed_entries)
    """
    if not entries:
        return 0, []

    supabase_url = config.get("supabase_url")
    supabase_key = config.get("supabase_anon_key")

    if not supabase_url or not supabase_key:
        if verbose:
            print("Supabase not configured, skipping sync")
        return 0, entries

    success_count = 0
    failed_entries = []

    for entry in entries:
        entry_type = entry.pop("type", "usage")
        table = "gaps" if entry_type == "gap" else "usage_logs"

        try:
            url = f"{supabase_url}/rest/v1/{table}"
            req = Request(
                url,
                data=json.dumps(entry).encode("utf-8"),
                headers={
                    "Content-Type": "application/json",
                    "apikey": supabase_key,
                    "Authorization": f"Bearer {supabase_key}",
                    "Prefer": "return=minimal",
                },
                method="POST"
            )
            urlopen(req, timeout=10)
            success_count += 1
            if verbose:
                print(f"  Synced: {entry.get('trigger', entry_type)}")
        except (URLError, HTTPError) as e:
            if verbose:
                print(f"  Failed: {entry.get('trigger', entry_type)} - {e}")
            entry["type"] = entry_type  # Restore type for retry
            failed_entries.append(entry)
        except Exception as e:
            if verbose:
                print(f"  Error: {e}")
            entry["type"] = entry_type
            failed_entries.append(entry)

    return success_count, failed_entries


def main():
    dry_run = "--dry-run" in sys.argv
    verbose = "--verbose" in sys.argv or "-v" in sys.argv

    if verbose:
        print(f"BSD Sales Copilot - Log Sync")
        print(f"Time: {datetime.now().isoformat()}")
        print("-" * 40)

    # Get pending logs
    stats = get_log_stats()
    entries = read_logs()

    if verbose:
        print(f"Pending logs: {stats['pending_count']}")
        print(f"Log file: {stats['log_file']}")

    if not entries:
        if verbose:
            print("No logs to sync")
        return

    if dry_run:
        print(f"\nDry run - would sync {len(entries)} entries:")
        for entry in entries[:10]:  # Show first 10
            print(f"  {entry.get('type', 'usage')}: {entry.get('trigger', 'N/A')}")
        if len(entries) > 10:
            print(f"  ... and {len(entries) - 10} more")
        return

    # Load config
    config = load_config()

    if verbose:
        print(f"\nSyncing to Supabase...")

    # Sync to Supabase
    success_count, failed = sync_to_supabase(entries, config, verbose)

    if verbose:
        print(f"\nResults:")
        print(f"  Success: {success_count}")
        print(f"  Failed: {len(failed)}")

    # Clear successful logs
    if success_count > 0 and len(failed) == 0:
        clear_logs()
        if verbose:
            print("  Cleared local logs")
    elif len(failed) > 0:
        # Some failed - archive them for retry
        clear_logs()
        archive_failed_logs(failed)
        if verbose:
            print(f"  Archived {len(failed)} failed entries for retry")

    if verbose:
        print("-" * 40)
        print("Done")


if __name__ == "__main__":
    main()
