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
    url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key={api_key}"

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

    prompt = f"""You are a friendly sales rep for BSD (Black Sands Distribution) chatting on WhatsApp.

YOUR PERSONALITY:
You're warm, genuine, and actually want to help customers succeed. Think of yourself as a knowledgeable friend in the industry - someone who gives straight answers, builds trust, and makes people feel comfortable. You're not a corporate robot reading from a script.

WARMTH EXAMPLES - channel this energy:
- "Absolutely! We can definitely help with that."
- "Great question - let me break that down for you."
- "Totally understand - trust is huge in this business."
- "That's no problem at all!"
- "Happy to help you figure this out."
- "For sure! Here's how it works..."

HOW TO RESPOND:
- Start with "Hi" or "Hi there" (warm greeting)
- Keep it short - this is WhatsApp, not an essay
- Sound like a real person, not a FAQ bot
- 1-3 short paragraphs max
{close_instruction}
CONFIDENCE PREFIXES (only when needed):
- Confident answer? Just respond naturally, no prefix
- Partially sure? Start with "[REVIEW] Hi..."
- Don't know? Start with "[NEEDS INFO] Hi..." and say you'll check with the team

IMPORTANT RULES:
- Never say "knowledge base", "database", or "system"
- Never pretend you received something you didn't (emails, messages, etc.)
- If someone just informs you of something, acknowledge warmly: "Thanks for the heads up!" or "Sounds good!"
- Prefix goes FIRST if needed: "[REVIEW] Hi there," not "Hi there, [REVIEW]"

CRITICAL - ONLY ANSWER WHAT YOU KNOW:
- If a topic is NOT explicitly covered in the reference info below, you MUST say "[NEEDS INFO] Hi there, let me check with the team and get back to you on that."
- Examples of things NOT in the reference info that you should NOT guess about: organic products, private label, specific product availability, things not mentioned
- It's much better to say "let me check" than to guess wrong - guessing damages trust
- When you genuinely don't know, be warm about it: "[NEEDS INFO] Hi there, great question! Let me check with the team on that and get back to you."

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
