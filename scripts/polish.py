#!/usr/bin/env python3
"""
AI Polish Script - Takes clipboard text and rewrites it professionally
Uses Google Gemini API

Usage: python3 polish.py [num_options]
  - num_options: 1, 2, or 3 (default: 1)
  - Logs usage to Supabase (if configured)
"""

import urllib.request
import json
import sys
import time

# Import shared utilities
from utils import (
    get_clipboard,
    load_config,
    log_usage,
)


def polish_text(text, api_key, num_options=1):
    """Send text to Gemini API for polishing"""
    url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-lite:generateContent?key={api_key}"

    if num_options == 1:
        prompt = f"""Rewrite the following text in a friendly professional tone — warm and approachable, but still business-appropriate. Suitable for customer emails. Keep the same meaning and length. Only return the rewritten text, nothing else.

Text to polish:
{text}"""
    else:
        prompt = f"""Rewrite the following text in a friendly professional tone — warm and approachable, but still business-appropriate. Suitable for customer emails. Keep the same meaning and similar length.

Provide exactly {num_options} different versions, numbered like this:
[1]
(first version here)

[2]
(second version here)

{"[3]" + chr(10) + "(third version here)" if num_options == 3 else ""}

Text to polish:
{text}"""

    data = {
        "contents": [{
            "parts": [{"text": prompt}]
        }]
    }

    req = urllib.request.Request(
        url,
        data=json.dumps(data).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST"
    )

    max_retries = 3
    for attempt in range(max_retries):
        try:
            with urllib.request.urlopen(req, timeout=15) as response:
                result = json.loads(response.read().decode("utf-8"))
                return result["candidates"][0]["content"]["parts"][0]["text"]
        except urllib.error.HTTPError as e:
            if e.code == 429 and attempt < max_retries - 1:
                time.sleep(2)
                continue
            return f"Error: {e.code} - {e.reason}"
        except Exception as e:
            return f"Error: {str(e)}"

    return "Error: Rate limited. Please try again in a moment."


def main():
    # Load configuration
    config = load_config()
    api_key = config.get("gemini_api_key")

    if not api_key:
        print("Error: GEMINI_API_KEY not found")
        return

    # Get text from clipboard (cross-platform)
    clipboard_text = get_clipboard()
    if not clipboard_text:
        print("Error: Clipboard is empty")
        return

    # Get number of options from command line (default: 1)
    num_options = 1
    if len(sys.argv) > 1:
        try:
            num_options = int(sys.argv[1])
            num_options = max(1, min(3, num_options))  # Clamp between 1-3
        except ValueError:
            pass

    # Polish the text
    polished = polish_text(clipboard_text, api_key, num_options)

    # Log usage (non-blocking)
    log_usage(
        trigger=f";p{num_options}",
        question=clipboard_text,
        config=config
    )

    print(polished)


if __name__ == "__main__":
    main()
