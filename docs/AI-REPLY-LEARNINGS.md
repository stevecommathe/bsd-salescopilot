# AI Reply System - Learnings & Recommendations

*Document for MD review and sign-off*
*Last updated: 2026-01-22*

---

## Executive Summary

We built an AI-powered reply system (`;reply` trigger) that generates WhatsApp responses based on BSD's knowledge base. After extensive testing and iteration, we've landed on a configuration that balances **warmth**, **accuracy**, and **cost**.

**Key Decision:** Use Gemini Flash (not Lite) - 33% more expensive but significantly warmer responses.

---

## What We Built

### Two Reply Modes

| Trigger | Use Case | Behavior |
|---------|----------|----------|
| `;reply` | Mid-funnel conversations | Answers warmly, NO closing question |
| `;replyclose` | Early funnel / qualifying | Answers warmly + asks for brands/port/timeline |

### Why Two Modes?

- **Early funnel:** You want to qualify → "What brands are you interested in?"
- **Mid-funnel:** You're already discussing specifics → don't keep asking the same qualifying question

### Supporting Snippets

| Trigger | Text | Use Case |
|---------|------|----------|
| `;next` | "What brands are you most interested in?" | Qualify interest |
| `;call` | "Happy to jump on a quick call..." | Offer call |
| `;quote` | "Let me know your destination port..." | Get quote info |
| `;timeline` | "What's your timeline for the first order?" | Qualify urgency |
| `;volume` | "What kind of volume are you looking at?" | Qualify size |
| `;ready` | "Are you ready to place an order?" | Close |
| `;deposit` | "I can send over a pro forma invoice..." | Move to order |
| `;followup` | "Just following up on this..." | Re-engage |
| `;intro` | "I'll connect you with a dedicated AM..." | Handoff |
| `;check` | "Let me check with the team..." | Buy time |

---

## Testing Methodology

### Approach

1. **Start with baseline** - Test simple factual questions
2. **Add rules iteratively** - Fix issues as they appear
3. **Test edge cases** - Out-of-knowledge, hallucinations, long messages
4. **Vary question types** - Simple, complex, conversational, mid-funnel
5. **Compare models** - Flash Lite vs Flash

### Test Categories (30 questions)

| Category | # Tests | Purpose |
|----------|---------|---------|
| Simple factual | 5 | Payment terms, shipping, MOQ, lead time |
| Trust/credibility | 3 | "How do I know you're legit?" |
| Mid-funnel KAM | 5 | Pricing reminders, ready to order, pro forma requests |
| Invoice/documents | 5 | CI, PL, COO requests, tracking, damaged goods |
| Shipping/logistics | 5 | Origin port, transit time, CIF vs FOB |
| Complex multi-part | 4 | Multiple brands, partnership inquiries |
| Conversational | 3 | "Thanks, I'll get back to you", picking up conversations |

---

## Model Comparison

### Gemini Flash Lite vs Gemini Flash

| Aspect | Flash Lite ($0.075/1M) | Flash ($0.10/1M) |
|--------|------------------------|------------------|
| **Warmth** | ⭐⭐ Terse, robotic | ⭐⭐⭐⭐ Natural, friendly |
| **Accuracy** | ⭐⭐⭐ Good | ⭐⭐⭐⭐ Better |
| **Speed** | Fast | Fast |
| **Cost/month*** | ~$0.50 | ~$0.67 |

*Estimated at 750 requests/day, 500 tokens avg

### Example Comparison

**Question:** "How do I know you're not a scam?"

| Flash Lite | Flash |
|------------|-------|
| "We understand that trust is important. We can provide customer references..." | "Totally understand - trust is huge in this business. We can definitely provide customer references..." |

**Recommendation:** Use Flash. The warmth difference is significant for sales conversations. Cost difference is negligible (~$0.17/month).

---

## Test Results Summary

### By Category

| Category | Warmth | Accuracy | Notes |
|----------|--------|----------|-------|
| Simple factual | ⭐⭐⭐⭐ | ✅ | Clear, helpful answers |
| Trust/credibility | ⭐⭐⭐⭐⭐ | ✅ | Best category - empathetic |
| Mid-funnel KAM | ⭐⭐⭐ | ✅ | Could be warmer |
| Invoice/documents | ⭐⭐⭐⭐ | ✅ | Good, mentions AM handoff |
| Shipping/logistics | ⭐⭐⭐⭐ | ✅ | Clear explanations |
| Complex multi-part | ⭐⭐⭐⭐ | ✅ | Addresses multiple parts |
| Conversational | ⭐⭐⭐⭐⭐ | ✅ | Natural acknowledgments |

### Sample Responses

**Best - Trust question:**
> "Totally understand - trust is huge in this business. We can definitely provide customer references and logistics partner references, where applicable, and business registration and certificates on request. We're also always happy to jump on a video call or meet in person!"

**Best - Warehouse delivery:**
> "Hi there, thanks for the question! We don't import, so our standard incoterms are CIF (to your destination port). That means we can ship to the port in Dubai, but not directly to your warehouse."

**Best - Picking up conversation:**
> "Absolutely, no problem at all. Happy to pick things up right where we left off."

---

## Issues Fixed During Development

### 1. Hallucination Problem

**Issue:** AI confidently answered questions not in knowledge base
- "Do you have organic products?" → "Yes, we have organic products!"

**Fix:** Added strict confidence rules with [NEEDS INFO] prefix

**Result:** Now correctly says "Let me check with the team and get back to you"

### 2. $500 Discount Leak

**Issue:** AI quoted specific dollar amounts from FAQ

**Fix:** Removed "$500 off" from FAQ, changed to "may offer a discount"

### 3. Internal Notes Exposure

**Issue:** FAQ had internal process notes that AI could leak

**Fix:** Deleted internal notes section from faq.md

### 4. Closing CTA in Mid-Funnel

**Issue:** AI kept asking "What brands are you interested in?" even mid-conversation

**Fix:** Created two modes - `;reply` (no close) and `;replyclose` (with close)

### 5. Prefix Placement

**Issue:** `[NEEDS INFO]` appeared in middle of response

**Fix:** Explicit prompt rule: "Prefix MUST be the very first characters"

### 6. Email Hallucination

**Issue:** "My colleague emailed you" → "I've received your colleague's email"

**Fix:** Added rule: "Never pretend you received something you didn't"

---

## Confidence System

### How It Works

| Confidence | Prefix | When Used |
|------------|--------|-----------|
| HIGH | (none) | Answer clearly in knowledge base |
| MEDIUM | `[REVIEW]` | Partially inferred, may need human check |
| LOW | `[NEEDS INFO]` | Not in knowledge base, will check with team |

### Why This Matters

1. **For sales reps:** See at a glance if they should verify before sending
2. **For analytics:** Track what questions the knowledge base doesn't cover
3. **For MD:** Identify gaps to add to FAQ

### Gap Logging

LOW and MEDIUM confidence questions are automatically logged to Supabase with:
- Verbatim question
- Confidence level
- AI-generated topic slug (e.g., "organic-products", "private-label")

This creates a backlog of FAQ gaps to review and address.

---

## Cost Analysis

### Current Model: Gemini Flash

| Metric | Value |
|--------|-------|
| Input cost | $0.10 / 1M tokens |
| Output cost | $0.40 / 1M tokens |
| Avg request | ~500 tokens |
| Est. daily requests | 750 (15 users × 50/day) |
| Est. monthly cost | **~$0.67** |

### Free Tier Limits

Gemini API free tier: 1,500 requests/day
Our usage: ~750/day = **well within free tier**

---

## Future Recommendations

### Short Term (Next 2 weeks)

1. **Test with real users** - Get 2-3 KAMs to use it for a week
2. **Review gap logs** - See what questions aren't being answered
3. **Expand FAQ** - Add missing topics based on gaps
4. **Tune warmth** - Adjust prompt based on user feedback

### Medium Term (1-2 months)

1. **Add more context** - Consider including customer name if available
2. **Seasonal prompts** - Holiday greetings, event-based messaging
3. **A/B test responses** - Try variations to see what converts better

### Long Term (3+ months)

1. **RAG system** - If FAQ grows beyond 500 items, move to vector search
2. **Multi-language** - Support for non-English markets
3. **Sentiment analysis** - Detect frustrated customers, escalate

---

## Sign-Off Checklist

Before rolling out to full team:

- [ ] MD reviews sample responses
- [ ] MD approves FAQ content
- [ ] Test on 2-3 KAMs first
- [ ] Collect feedback for 1 week
- [ ] Address any issues
- [ ] Full team rollout

---

## Appendix: Full Prompt

The current prompt is in `scripts/reply.py`. Key sections:

1. **Personality** - Warm, genuine, like a knowledgeable friend
2. **Warmth examples** - "Absolutely!", "Great question!", "Totally understand"
3. **Response format** - Hi greeting, 1-3 paragraphs, optional closing
4. **Confidence rules** - When to use [REVIEW] and [NEEDS INFO]
5. **Anti-hallucination** - Never guess, never pretend

---

*Document prepared by Claude Code for BSD Sales Copilot project*
