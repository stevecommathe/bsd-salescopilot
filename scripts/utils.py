#!/usr/bin/env python3
"""
Shared utilities for BSD Sales Copilot scripts
Cross-platform clipboard, logging, and configuration management
"""

import subprocess
import platform
import json
import os
import sys
from datetime import datetime
from urllib.request import Request, urlopen
from urllib.error import URLError, HTTPError

# Resolve paths relative to this file
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(SCRIPT_DIR)

# Config file location (check env var first, then local)
CONFIG_PATH = os.environ.get(
    "BSD_COPILOT_CONFIG",
    os.path.join(SCRIPT_DIR, "config.json")
)


def get_os():
    """Detect operating system"""
    system = platform.system().lower()
    if system == "darwin":
        return "mac"
    elif system == "windows":
        return "windows"
    return "linux"


def get_clipboard():
    """
    Get text from clipboard - cross-platform
    Returns clipboard text or empty string on error
    """
    os_type = get_os()

    try:
        if os_type == "mac":
            result = subprocess.run(
                ["pbpaste"],
                capture_output=True,
                text=True,
                timeout=5
            )
            return result.stdout.strip()

        elif os_type == "windows":
            # PowerShell Get-Clipboard is built-in on Windows 10+
            result = subprocess.run(
                ["powershell", "-Command", "Get-Clipboard"],
                capture_output=True,
                text=True,
                timeout=5
            )
            return result.stdout.strip()

        else:
            # Linux - try xclip first, then xsel
            try:
                result = subprocess.run(
                    ["xclip", "-selection", "clipboard", "-o"],
                    capture_output=True,
                    text=True,
                    timeout=5
                )
                return result.stdout.strip()
            except FileNotFoundError:
                result = subprocess.run(
                    ["xsel", "--clipboard", "--output"],
                    capture_output=True,
                    text=True,
                    timeout=5
                )
                return result.stdout.strip()

    except subprocess.TimeoutExpired:
        return ""
    except FileNotFoundError as e:
        print(f"Clipboard tool not found: {e}", file=sys.stderr)
        return ""
    except Exception as e:
        print(f"Clipboard error: {e}", file=sys.stderr)
        return ""


def load_config():
    """
    Load configuration from config.json
    Falls back to environment variables and defaults
    """
    config = {
        "provider": "gemini",
        "gemini_api_key": None,
        "supabase_url": None,
        "supabase_anon_key": None,
        "log_usage": True,
        "log_responses": False,  # Privacy: don't log full responses by default
        "user_id": None,  # Set per-machine during install
    }

    # Load from config file if exists
    if os.path.exists(CONFIG_PATH):
        try:
            with open(CONFIG_PATH, "r") as f:
                file_config = json.load(f)
                config.update(file_config)
        except (json.JSONDecodeError, IOError) as e:
            print(f"Warning: Could not load config.json: {e}", file=sys.stderr)

    # Environment variables override config file
    if os.environ.get("GEMINI_API_KEY"):
        config["gemini_api_key"] = os.environ["GEMINI_API_KEY"]
    if os.environ.get("SUPABASE_URL"):
        config["supabase_url"] = os.environ["SUPABASE_URL"]
    if os.environ.get("SUPABASE_ANON_KEY"):
        config["supabase_anon_key"] = os.environ["SUPABASE_ANON_KEY"]
    if os.environ.get("BSD_USER_ID"):
        config["user_id"] = os.environ["BSD_USER_ID"]

    # Legacy: check .env file for API key
    if not config["gemini_api_key"]:
        env_path = os.path.join(SCRIPT_DIR, ".env")
        if os.path.exists(env_path):
            with open(env_path) as f:
                for line in f:
                    line = line.strip()
                    if line.startswith("GEMINI_API_KEY="):
                        config["gemini_api_key"] = line.split("=", 1)[1]
                    elif line.startswith("SUPABASE_URL="):
                        config["supabase_url"] = line.split("=", 1)[1]
                    elif line.startswith("SUPABASE_ANON_KEY="):
                        config["supabase_anon_key"] = line.split("=", 1)[1]

    return config


def log_usage(trigger, question=None, response=None, confidence=None, config=None):
    """
    Log usage to Supabase (non-blocking, fails silently)

    Args:
        trigger: The Espanso trigger used (e.g., ";reply", ";p1")
        question: The input text (optional)
        response: The AI response (optional, only if log_responses=True)
        confidence: HIGH, MEDIUM, or LOW (optional)
        config: Config dict (will load if not provided)
    """
    if config is None:
        config = load_config()

    # Skip if logging disabled or Supabase not configured
    if not config.get("log_usage"):
        return
    if not config.get("supabase_url") or not config.get("supabase_anon_key"):
        return

    # Build log entry
    log_entry = {
        "trigger": trigger,
        "user_id": config.get("user_id", "unknown"),
        "os": get_os(),
        "timestamp": datetime.utcnow().isoformat() + "Z",
    }

    # Only include question/response if configured
    if question:
        # Truncate very long questions
        log_entry["question"] = question[:500] if len(question) > 500 else question

    if response and config.get("log_responses"):
        log_entry["response"] = response[:1000] if len(response) > 1000 else response

    if confidence:
        log_entry["confidence"] = confidence

    # Send to Supabase (fire and forget)
    try:
        url = f"{config['supabase_url']}/rest/v1/usage_logs"
        req = Request(
            url,
            data=json.dumps(log_entry).encode("utf-8"),
            headers={
                "Content-Type": "application/json",
                "apikey": config["supabase_anon_key"],
                "Authorization": f"Bearer {config['supabase_anon_key']}",
                "Prefer": "return=minimal",  # Don't need response body
            },
            method="POST"
        )
        urlopen(req, timeout=5)
    except (URLError, HTTPError, Exception):
        # Fail silently - logging should never break the main function
        pass


def log_gap(question, confidence, config=None):
    """
    Log a knowledge gap to Supabase gaps table
    Only logs MEDIUM and LOW confidence questions

    Args:
        question: The question that had low/medium confidence
        confidence: MEDIUM or LOW
        config: Config dict (will load if not provided)
    """
    if confidence not in ("MEDIUM", "LOW"):
        return

    if config is None:
        config = load_config()

    if not config.get("supabase_url") or not config.get("supabase_anon_key"):
        return

    gap_entry = {
        "question": question[:500] if len(question) > 500 else question,
        "confidence": confidence,
        "status": "new",
        "first_seen": datetime.utcnow().isoformat() + "Z",
    }

    try:
        url = f"{config['supabase_url']}/rest/v1/gaps"
        req = Request(
            url,
            data=json.dumps(gap_entry).encode("utf-8"),
            headers={
                "Content-Type": "application/json",
                "apikey": config["supabase_anon_key"],
                "Authorization": f"Bearer {config['supabase_anon_key']}",
                "Prefer": "return=minimal",
            },
            method="POST"
        )
        urlopen(req, timeout=5)
    except (URLError, HTTPError, Exception):
        pass


def parse_confidence(response_text):
    """
    Parse confidence level from AI response
    Returns tuple of (confidence, cleaned_response)
    """
    response = response_text.strip()

    if response.startswith("[NEEDS INFO]"):
        return "LOW", response[len("[NEEDS INFO]"):].strip()
    elif response.startswith("[REVIEW]"):
        return "MEDIUM", response[len("[REVIEW]"):].strip()
    else:
        return "HIGH", response


def get_project_dir():
    """Get the project root directory"""
    return PROJECT_DIR


def get_knowledge_base_path():
    """Get path to knowledge base file"""
    # Check config for custom path
    config = load_config()
    custom_path = config.get("knowledge_base_path")
    if custom_path and os.path.exists(custom_path):
        return custom_path

    # Default: relative to project
    return os.path.join(PROJECT_DIR, "knowledge", "faq.md")
