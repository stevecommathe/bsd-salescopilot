# BSD Sales Copilot — Claude Code Guidelines

## Project Overview

- **What:** Espanso text expander configuration for BSD sales team
- **Tech:** Espanso (YAML configs) + Python scripts for dynamic lookups
- **Goal:** Help sales reps quickly respond to common customer questions with consistent, accurate snippets
- **Repo:** [GitHub URL when created]

---

## Session Start Checklist

*Claude: Run through this checklist at the start of every new session.*

1. **Confirm git status** — Run `git status` and `git branch`
2. **Review todo list** — Check Priority 1 items below
3. **Ask user** — "What would you like to work on today?"

---

## Todo List & Priorities

### Priority 1 (Do Next)
- [ ] Create initial base.yml snippets (greetings, signatures, common phrases)
- [ ] Create initial faq.yml snippets (common customer questions)

### Priority 2 (Soon)
- [ ] Set up Python scripts for dynamic lookups (Salesforce integration?)
- [ ] Test deployment to ~/.config/espanso/match/
- [ ] Document snippet library for sales team

### Priority 3 (Later)
- [ ] AI-powered dynamic responses
- [ ] Salesforce data lookups (customer info, order status)
- [ ] Team onboarding guide

### Completed
- [x] Set up project folder structure
- [x] Create CLAUDE.md

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
│   ├── base.yml      ← Core snippets (greetings, signatures, common phrases)
│   └── faq.yml       ← FAQ-based response snippets
├── scripts/          ← Python scripts for dynamic lookups (Salesforce, AI)
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

(None yet — add as you encounter issues)

---

## Decision Log

| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-01-19 | Use Espanso for text expansion | Cross-platform, YAML-based, supports scripts |
| 2026-01-19 | Semicolon prefix for triggers | Avoids accidental triggers, easy to type |
| 2026-01-19 | Separate base.yml and faq.yml | Organize by snippet type for maintainability |
| 2026-01-19 | Graduate to Level 2 | User comfortable with git basics, less verbosity needed |

---

## Concept Translations

| Dev Concept | Martech Equivalent |
|-------------|-------------------|
| Espanso trigger | Merge tag / personalization token |
| YAML config | Campaign settings file |
| Python script | Custom function / API call |
| Symlink | Shortcut / alias |

---

## Snippet Ideas to Build

*Parking lot for snippet ideas*

### Greetings & Closings
- [ ] `;hi` — Friendly greeting
- [ ] `;sig` — Email signature
- [ ] `;thanks` — Thank you closing

### Common Responses
- [ ] `;stock` — Stock availability response
- [ ] `;ship` — Shipping info
- [ ] `;return` — Return policy
- [ ] `;price` — Pricing inquiry response

### FAQ Responses
- [ ] `;faq1` — [Most common question]
- [ ] `;faq2` — [Second most common]

---

*Last updated: 2026-01-19*
