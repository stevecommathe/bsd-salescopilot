# BSD Sales Copilot — Claude Code Guidelines

## Project Overview

- **What:** Espanso text expander configuration for BSD sales team
- **Tech:** Espanso (YAML configs) + Python scripts for dynamic lookups
- **Goal:** Help sales reps quickly respond to common customer questions with consistent, accurate snippets
- **Repo:** https://github.com/stevecommathe/bsd-salescopilot

---

## Session Start Checklist

*Claude: Run through this checklist at the start of every new session.*

1. **Confirm git status** — Run `git status` and `git branch`
2. **Review todo list** — Check Priority 1 items below
3. **Ask user** — "What would you like to work on today?"

---

## Todo List & Priorities

### Priority 1 (Do Next)
- [ ] Build `;reply` trigger — context-stuffed AI response (proof of concept)
- [ ] Test AI polish triggers with sales team

### Priority 2 (Soon)
- [ ] Explore RAG approach (vector DB for large knowledge base)
- [ ] Explore Google Grounding (simpler alternative to RAG)
- [ ] Document snippet library for sales team
- [ ] Salesforce data lookups (customer info, order status)

### Priority 3 (Later)
- [ ] Explore chatbot options (Chatbase, Botpress, or custom build)
- [ ] Team onboarding guide
- [ ] Multiple tone options (formal, casual, friendly)

### Completed
- [x] Set up project folder structure
- [x] Create CLAUDE.md
- [x] Create base.yml snippets (`;hi`, `;hello`, `;thanks`, `;sig`)
- [x] Create faq.yml snippets (10 FAQ responses)
- [x] Set up symlinks to Espanso config
- [x] Create AI polish script (`polish.py` with Gemini API)
- [x] Add AI polish triggers (`;p1`, `;p2`, `;p3`)

---

## User Context & Training Mode

### Background
- 20 years martech experience, former Deloitte Digital partner
- Specialization: analytics strategy, marketing automation, platform operations
- Managed dev teams — strong on concepts, new to hands-on coding
- Can read code, learning to write it
- New to terminal/CLI operations

### Current Level: 2 (Training Wheels)
*Explain new concepts only, confirm destructive operations, less verbose*

---

## Training Levels Reference

| Level | Name | Description |
|-------|------|-------------|
| 1 | Safety Net | Maximum guidance, confirm everything, explain everything |
| 2 | Training Wheels | Explain new concepts only, confirm destructive ops, less verbose |
| 3 | Riding Solo | Minimal explanation, just confirm destructive ops |
| 4 | Full Speed | Trust established, only warn on major risks |

---

## Active Training Wheels (Level 2)

Claude follows these practices at current level:

### Communication
- [ ] **Explain NEW commands/concepts only** — Skip explanation for familiar operations
- [ ] **Translate errors to plain English** — Never leave an error unexplained
- [ ] **Brief output recaps** — Keep summaries short

### Safety
- [ ] **Confirm before destructive operations** — Ask before: delete, overwrite, reset
- [ ] **Warn before irreversible operations** — Flag operations that can't be undone

### Workflow
- [ ] **Suggest commit points** — Prompt when it's a good time to commit
- [ ] **Review todos at session start** — Begin each session by checking the todo list

---

## Graduated Skills

*Skills where Claude can reduce hand-holding*

- [x] **Git basics** — add, commit, status (2026-01-19)
- [x] **File structure awareness** — No need to show tree after every change

---

## Workflow Rules

### Git Workflow
- Commit frequently (after each working unit)
- Branch naming: `feature/`, `fix/`, `docs/` prefixes
- Main branch stays stable

### Commit Message Style
```
type: Short description

Types: feat, fix, docs, refactor
```

---

## Project-Specific Notes

### File Structure
```
bsd-salescopilot/
├── match/
│   ├── base.yml      ← Core snippets + AI polish triggers
│   └── faq.yml       ← FAQ-based response snippets (10 triggers)
├── scripts/
│   ├── polish.py     ← AI polish script (Gemini API)
│   └── .env          ← API keys (not committed)
├── CLAUDE.md         ← This file
└── README.md         ← Project documentation
```

### Espanso YAML Format

Snippets use this format:
```yaml
matches:
  - trigger: ";shortcut"
    replace: "The expanded text goes here"
```

**Multi-line example:**
```yaml
matches:
  - trigger: ";sig"
    replace: |
      Best regards,
      [Name]
      BSD Sales Team
```

**With clipboard/cursor:**
```yaml
matches:
  - trigger: ";email"
    replace: "Hi $|$,\n\nThanks for reaching out!"
    # $|$ places cursor there after expansion
```

### Conventions
- All triggers start with semicolon (`;`)
- Use lowercase triggers
- Keep triggers short but memorable (`;inv`, `;track`, `;stock`)
- Group related snippets in the same file

### Key Commands
```bash
# Test espanso config
espanso path                    # Show config location

# Deploy snippets (symlink approach)
ln -sf ~/Documents/Projects/bsd-salescopilot/match/*.yml ~/.config/espanso/match/

# Restart espanso to pick up changes
espanso restart

# Check espanso status
espanso status

# View espanso logs (for debugging)
espanso log
```

### Python Scripts (Future)
Scripts in `scripts/` can be called from Espanso for dynamic content:
```yaml
matches:
  - trigger: ";lookup"
    replace: "{{output}}"
    vars:
      - name: output
        type: script
        params:
          args:
            - python3
            - /path/to/scripts/lookup.py
```

---

## Troubleshooting Log

*Issues encountered and their solutions — check here when things break*

### Gemini API 429 errors (rate limit)
**Problem:** New API keys or free tier projects return "429 Too Many Requests"
**Solution:** Use an API key from a project with billing enabled (paid tier). Free tier has very low limits and new keys need warmup time.

### Espanso trigger prefix conflicts
**Problem:** `;polish` was triggering instead of `;polish3`
**Solution:** Use non-overlapping trigger names (`;p1`, `;p2`, `;p3` instead of `;polish`, `;polish2`, `;polish3`)

---

## Decision Log

| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-01-19 | Use Espanso for text expansion | Cross-platform, YAML-based, supports scripts |
| 2026-01-19 | Semicolon prefix for triggers | Avoids accidental triggers, easy to type |
| 2026-01-19 | Separate base.yml and faq.yml | Organize by snippet type for maintainability |
| 2026-01-19 | Graduate to Level 2 | User comfortable with git basics, less verbosity needed |
| 2026-01-19 | Use Gemini API for AI features | Free tier available, user has paid account, cheap (~$0.0001/request) |
| 2026-01-19 | Short triggers for AI (`;p1`, `;p2`, `;p3`) | Avoid prefix conflicts (`;polish` was catching `;polish3`) |
| 2026-01-19 | Friendly professional tone for AI | Matches BSD brand voice — warm but business-appropriate |
| 2026-01-19 | Store API key in .env (gitignored) | Security best practice — keys never committed |

---

## Concept Translations

| Dev Concept | Martech Equivalent |
|-------------|-------------------|
| Espanso trigger | Merge tag / personalization token |
| YAML config | Campaign settings file |
| Python script | Custom function / API call |
| Symlink | Shortcut / alias |
| API key | Platform credentials / access token |
| .env file | Secure config storage (like a password vault) |
| RAG (Retrieval Augmented Generation) | Dynamic content lookup + AI response |
| Vector database | Smart search index for AI |
| Context stuffing | Including reference docs in AI prompt |

---

## Current Snippet Reference

### base.yml — Core snippets
| Trigger | Description |
|---------|-------------|
| `;hi` | Friendly greeting |
| `;hello` | Hello + how can I help |
| `;thanks` | Thank you closing |
| `;sig` | Email signature block |
| `;p1` | AI polish (1 option) |
| `;p2` | AI polish (2 options) |
| `;p3` | AI polish (3 options) |

### faq.yml — FAQ responses
| Trigger | Description |
|---------|-------------|
| `;portal` | Portal access + signup link |
| `;terms` | Payment terms (20/80 NET14) |
| `;moq` | MOQ / FCL mixing explanation |
| `;docs` | Full document list |
| `;cif` | CIF shipping terms |
| `;noddp` | No DDP explanation |
| `;leadtime` | Lead time info (2-3 weeks) |
| `;nolc` | No LC/Escrow policy |
| `;locate` | Office locations |
| `;trust` | Credibility/references response |

---

## Snippet Ideas (Backlog)

- [ ] `;reply` — AI-generated response based on knowledge base
- [ ] `;stock` — Stock availability response
- [ ] `;ship` — Shipping info
- [ ] `;return` — Return policy
- [ ] `;price` — Pricing inquiry response

---

*Last updated: 2026-01-19*
