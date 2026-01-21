#!/usr/bin/env python3
"""
AI Reply Script - Generates responses based on knowledge base
Uses Google Gemini API with context stuffing approach

Usage: python3 reply.py
  - Reads customer question from clipboard
  - Reads knowledge base from knowledge/faq.md
  - Returns AI-generated response
"""

import subprocess
import urllib.request
import json
import os
import sys
import time

# Path to knowledge base (relative to this script)
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(SCRIPT_DIR)
KNOWLEDGE_BASE_PATH = os.path.join(PROJECT_DIR, "knowledge", "faq.md")


def get_api_key():
    """Get API key from environment or .env file"""
    key = os.environ.get("GEMINI_API_KEY")
    if key:
        return key

    env_path = os.path.join(SCRIPT_DIR, ".env")
    if os.path.exists(env_path):
        with open(env_path) as f:
            for line in f:
                if line.startswith("GEMINI_API_KEY="):
                    return line.strip().split("=", 1)[1]
    return None


def get_clipboard():
    """Get text from macOS clipboard"""
    result = subprocess.run(["pbpaste"], capture_output=True, text=True)
    return result.stdout.strip()


def load_knowledge_base():
    """Load knowledge base content from file"""
    if not os.path.exists(KNOWLEDGE_BASE_PATH):
        return None
    with open(KNOWLEDGE_BASE_PATH, "r") as f:
        return f.read()


def generate_reply(question, knowledge_base, api_key):
    """Send question + knowledge base to Gemini API"""
    url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key={api_key}"

    prompt = f"""You are a helpful sales representative for BSD (Black Sands Distribution).
Use the knowledge base below to answer the customer's question.

IMPORTANT GUIDELINES:
- Be friendly and professional — warm but business-appropriate
- Keep responses concise (2-4 short paragraphs max)
- If the answer is in the knowledge base, use that information
- Don't make up information not in the knowledge base
- Include relevant links if available in the knowledge base
- End with an offer to help further or a next step

CONFIDENCE RATING:
Rate your confidence based on how well the knowledge base covers the question, then format accordingly:

- HIGH: Answer is clearly covered in the knowledge base. Just write the response normally with NO prefix.
- MEDIUM: Answer is partially covered or you're inferring. Start response with "[REVIEW] " prefix.
- LOW: Answer is NOT in the knowledge base. Start response with "[NEEDS INFO] " prefix and say you'll check with the team.

IMPORTANT: Do NOT write "HIGH", "MEDIUM", or "LOW" in your response. Only use the prefixes [REVIEW] or [NEEDS INFO] when needed.

KNOWLEDGE BASE:
{knowledge_base}

CUSTOMER QUESTION:
{question}

YOUR RESPONSE (remember to add [REVIEW] or [NEEDS INFO] prefix if confidence is not HIGH):"""

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
            with urllib.request.urlopen(req, timeout=30) as response:
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
    api_key = get_api_key()
    if not api_key:
        print("Error: GEMINI_API_KEY not found")
        return

    question = get_clipboard()
    if not question:
        print("Error: Clipboard is empty. Copy the customer question first.")
        return

    knowledge_base = load_knowledge_base()
    if not knowledge_base:
        print(f"Error: Knowledge base not found at {KNOWLEDGE_BASE_PATH}")
        return

    reply = generate_reply(question, knowledge_base, api_key)
    print(reply)


if __name__ == "__main__":
    main()
