#!/usr/bin/env python3
"""
AI Reply Script - Generates responses based on knowledge base
Uses Google Gemini API with context stuffing approach

Usage: python3 reply.py
  - Reads customer question from clipboard
  - Reads knowledge base from knowledge/faq.md
  - Returns AI-generated response
  - Logs usage to Supabase (if configured)
"""

import urllib.request
import json
import os
import time

# Import shared utilities
from utils import (
    get_clipboard,
    load_config,
    log_usage,
    log_gap,
    parse_confidence,
    get_knowledge_base_path,
)


def load_knowledge_base():
    """Load knowledge base content from file"""
    kb_path = get_knowledge_base_path()
    if not os.path.exists(kb_path):
        return None, kb_path
    with open(kb_path, "r") as f:
        return f.read(), kb_path


def generate_reply(question, knowledge_base, api_key, include_close=False):
    """Send question + knowledge base to Gemini API"""
    url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-lite:generateContent?key={api_key}"

    # Build prompt based on whether closing CTA is wanted
    close_instruction = ""
    if include_close:
        close_instruction = """
CLOSING:
- End with a sales-focused call-to-action (ask for brands, port, timeline, or offer a call)
- Examples: "What brands are you interested in?", "What's your destination port?", "Happy to jump on a call if that helps"
"""
    else:
        close_instruction = """
CLOSING - CRITICAL:
- Do NOT end with a question
- Do NOT ask for brands, port, volume, timeline, or anything else
- Do NOT add any call-to-action
- Just answer the question warmly and STOP
- The sales rep will add their own follow-up manually
- Example of what NOT to do: "What brands are you interested in?" or "Let me know your port"
"""

    prompt = f"""You are a sales representative for BSD (Black Sands Distribution) responding on WhatsApp.

TONE & STYLE:
- Warm, friendly, and conversational - like texting a colleague
- Keep messages SHORT (this is WhatsApp, not email) but not cold or robotic
- Add small human touches like "absolutely", "definitely", "happy to help", "great question"
- Never sound like a chatbot or reference internal systems

RESPONSE FORMAT:
- ALWAYS start with "Hi" or "Hi there" (never skip the greeting)
- 1-3 short paragraphs MAX
- Be helpful and warm, even when the answer is short
{close_instruction}
CONFIDENCE RATING:
- If you can answer confidently from the reference info: Just start with "Hi" normally (NO prefix needed)
- If you're partially inferring or unsure: Start with "[REVIEW] Hi there," (prefix BEFORE greeting)
- If the topic is NOT covered: Start with "[NEEDS INFO] Hi there," then say "Let me check with the team"

PREFIX RULES:
- NEVER write "[HIGH]" - just start with "Hi" for confident answers
- Only use "[REVIEW] " or "[NEEDS INFO] " prefixes
- Prefix MUST be the very first characters: "[REVIEW] Hi there," NOT "Hi there, [REVIEW]"

CRITICAL - DO NOT HALLUCINATE:
- If a product category, service, or policy is NOT explicitly mentioned in the reference info, do NOT guess yes or no
- This MUST be marked as LOW confidence with the "[NEEDS INFO] " prefix
- It's BETTER to say "I'll confirm" than to guess wrong
- NEVER pretend you received an email, saw a message, or have information you don't have

NON-QUESTION MESSAGES:
- If the customer is just informing you of something (e.g., "my colleague emailed you", "I'll get back to you tomorrow")
- Respond with a brief acknowledgment like "Thanks for letting me know!" or "Great, looking forward to it!"
- Do NOT pretend you received or saw something you didn't

IMPORTANT:
- Do NOT write the words "HIGH", "MEDIUM", or "LOW" in your response
- But you MUST use "[REVIEW] " or "[NEEDS INFO] " prefixes when confidence is not high

NEVER:
- Say "knowledge base", "database", "system", or "information I have"
- Quote specific dollar amounts (direct to portal for pricing)
- Sound like a chatbot or AI
- Make up information that isn't in the reference info

ALWAYS:
- Mention the portal (blacksanddistribution.com) for pricing/product details when relevant
- Offer to connect them with a dedicated account manager for complex questions

TOPIC EXTRACTION (for internal use):
At the very END of your response, on a new line, add:
TOPIC: short-topic-slug

The topic should be a 2-4 word lowercase slug (e.g., "return-policy", "shipping-terms", "payment-terms", "moq-requirements").

REFERENCE INFORMATION:
{knowledge_base}

CUSTOMER MESSAGE:
{question}

YOUR RESPONSE:"""

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
    import sys

    # Check for --close flag
    include_close = "--close" in sys.argv

    # Load configuration
    config = load_config()
    api_key = config.get("gemini_api_key")

    if not api_key:
        print("Error: GEMINI_API_KEY not found")
        return

    # Get question from clipboard (cross-platform)
    question = get_clipboard()
    if not question:
        print("Error: Clipboard is empty. Copy the customer question first.")
        return

    # Load knowledge base
    knowledge_base, kb_path = load_knowledge_base()
    if not knowledge_base:
        print(f"Error: Knowledge base not found at {kb_path}")
        return

    # Generate reply
    raw_reply = generate_reply(question, knowledge_base, api_key, include_close)

    # Parse confidence, topic, and clean response
    confidence, topic, reply = parse_confidence(raw_reply)

    # Log usage (non-blocking)
    log_usage(
        trigger=";reply",
        question=question,
        response=reply if config.get("log_responses") else None,
        confidence=confidence,
        config=config
    )

    # Log gap if low/medium confidence
    if confidence in ("MEDIUM", "LOW"):
        log_gap(question, confidence, topic, config)

    # Output the cleaned response (TOPIC stripped, prefix kept for user visibility)
    if confidence == "HIGH":
        print(reply)
    else:
        # Re-add the prefix for user to see
        prefix = "[NEEDS INFO] " if confidence == "LOW" else "[REVIEW] "
        print(prefix + reply)


if __name__ == "__main__":
    main()
