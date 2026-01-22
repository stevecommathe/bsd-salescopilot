#!/usr/bin/env python3
"""
Log and return static snippets for Espanso
Usage: python3 log_snippet.py <trigger> <text>

Logs the trigger usage locally, then prints the text.
Fast (~25ms) because it only writes to local file.
"""

import sys
import os

# Add script dir to path for imports
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, SCRIPT_DIR)

from local_log import log_local
from utils import load_config, get_os


def main():
    if len(sys.argv) < 3:
        print("Usage: log_snippet.py <trigger> <text>", file=sys.stderr)
        sys.exit(1)

    trigger = sys.argv[1]
    text = sys.argv[2]

    # Load config for user_id
    config = load_config()

    # Log locally (fast)
    if config.get("log_usage", True):
        log_local({
            "type": "usage",
            "trigger": trigger,
            "user_id": config.get("user_id", "unknown"),
            "os": get_os(),
        })

    # Output the text
    print(text)


if __name__ == "__main__":
    main()
