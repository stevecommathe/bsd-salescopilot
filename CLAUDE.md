# BSD Sales Copilot — Claude Code Guidelines

## Project Overview

- **What:** Espanso text expander configuration for BSD sales team
- **Tech:** Espanso (YAML configs) + Python scripts + GitHub auto-sync
- **Goal:** Help sales reps quickly respond to common customer questions with consistent, accurate snippets
- **Target:** 15 concurrent users (Mac + Windows)
- **Repo:** https://github.com/stevecommathe/bsd-salescopilot (migrating to BSD org)

---

## Current State: Phase 1.5 Complete

**Status:** Core system built, ready for team testing

### What's Working
- ✅ All triggers functional (`;hi`, `;reply`, `;p1`, etc.)
- ✅ Local-first logging (~24ms overhead)
- ✅ Auto-sync from GitHub (every 5 min)
- ✅ Mac installer (one-command setup)
- ✅ Persists across reboots

### Immediate Next Steps
1. **Create BSD GitHub repo** (public recommended)
2. **Push code to BSD repo**
3. **Test installer on 2nd laptop**
4. **Set up Supabase** for usage analytics (optional)

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           ADMIN (Steven)                                 │
│  Edit YAML/Python → git commit → git push → GitHub                      │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                         GitHub (Source of Truth)                         │
│  stevecommathe/bsd-salescopilot (will migrate to BSD org)               │
│  • match/base.yml, faq.yml                                              │
│  • scripts/*.py                                                          │
│  • knowledge/faq.md                                                      │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                    ┌───────────────┼───────────────┐
                    ▼               ▼               ▼
┌─────────────────────┐ ┌─────────────────────┐ ┌─────────────────────┐
│   User Machine 1    │ │   User Machine 2    │ │   User Machine N    │
│                     │ │                     │ │                     │
│ ┌─────────────────┐ │ │ ┌─────────────────┐ │ │ ┌─────────────────┐ │
│ │ sync_snippets   │ │ │ │ sync_snippets   │ │ │ │ sync_snippets   │ │
│ │ (every 5 min)   │ │ │ │ (every 5 min)   │ │ │ │ (every 5 min)   │ │
│ │ Downloads from  │ │ │ │ Downloads from  │ │ │ │ Downloads from  │ │
│ │ GitHub → local  │ │ │ │ GitHub → local  │ │ │ │ GitHub → local  │ │
│ └────────┬────────┘ │ │ └────────┬────────┘ │ │ └────────┬────────┘ │
│          ▼          │ │          ▼          │ │          ▼          │
│ ┌─────────────────┐ │ │ ┌─────────────────┐ │ │ ┌─────────────────┐ │
│ │    Espanso      │ │ │ │    Espanso      │ │ │ │    Espanso      │ │
│ │ Reads local     │ │ │ │ Reads local     │ │ │ │ Reads local     │ │
│ │ YAML files      │ │ │ │ YAML files      │ │ │ │ YAML files      │ │
│ └────────┬────────┘ │ │ └────────┬────────┘ │ │ └────────┬────────┘ │
│          ▼          │ │          ▼          │ │          ▼          │
│ ┌─────────────────┐ │ │ ┌─────────────────┐ │ │ ┌─────────────────┐ │
│ │  Local Logs     │ │ │ │  Local Logs     │ │ │ │  Local Logs     │ │
│ │  (.jsonl file)  │ │ │ │  (.jsonl file)  │ │ │ │  (.jsonl file)  │ │
│ └────────┬────────┘ │ │ └────────┬────────┘ │ │ └────────┬────────┘ │
│          │          │ │          │          │ │          │          │
└──────────┼──────────┘ └──────────┼──────────┘ └──────────┼──────────┘
           │                       │                       │
           └───────────────────────┼───────────────────────┘
                                   ▼
                    ┌─────────────────────────┐
                    │   Supabase (Optional)   │
                    │   • usage_logs table    │
                    │   • gaps table          │
                    │   Background sync       │
                    └─────────────────────────┘
```

### Data Flow

| Trigger Type | Flow | Latency |
|--------------|------|---------|
| **Static** (`;hi`) | Espanso → log_snippet.py → local log → return text | ~24ms |
| **AI** (`;reply`) | Espanso → reply.py → Gemini API → local log → return text | ~1.2s |

### Background Services (launchd)

| Service | Runs | Purpose |
|---------|------|---------|
| `snippetsync` | Every 5 min | Downloads latest from GitHub, restarts Espanso if changed |
| `sync` | Every 5 min | Pushes local logs to Supabase (if configured) |
| `env` | At login | Sets BSD_COPILOT_PATH for GUI apps |

---

## Session Start Checklist

*Claude: Run through this checklist at the start of every new session.*

1. **Check central learnings** — Read `~/Documents/Projects/LEARNINGS.md`
2. **Check progress** — Read `~/Documents/Projects/CLAUDE-PROGRESS.md`
3. **Confirm git status** — Run `git status`
4. **Review current phase** — Check "Current State" section above
5. **Ask user** — "What would you like to work on today?"

---

## Todo List & Priorities

### Immediate (Before Team Rollout)
- [ ] Create BSD GitHub repo (public)
- [ ] Push code to BSD repo
- [ ] Update `github_repo` in install-mac.sh
- [ ] Test full install on 2nd laptop
- [ ] Verify auto-sync works end-to-end

### Phase 2: Windows + Analytics
- [ ] Create Windows installer (`install-windows.ps1`)
- [ ] Set up Supabase project
- [ ] Run `db/supabase-setup.sql`
- [ ] Create analytics script (`analytics.py`)
- [ ] Build Vercel dashboard (basic usage view)

### Phase 3: Polish & Scale
- [ ] Create AI client abstraction (`ai_client.py`)
- [ ] Add cost tracking to logging
- [ ] User guide for sales team
- [ ] Admin guide (KB updates, analytics)

### Phase 4: Future
- [ ] RAG for large knowledge base
- [ ] Salesforce data lookups
- [ ] Chatbot interface option

### Completed ✅
- [x] Espanso YAML configs (base.yml, faq.yml)
- [x] AI triggers (`;reply`, `;p1`, `;p2`, `;p3`)
- [x] Cross-platform clipboard (Mac + Windows ready)
- [x] Local-first logging system
- [x] GitHub auto-sync (sync_snippets.py)
- [x] Mac installer with background services
- [x] Environment variable persistence (launchd)
- [x] Supabase schema (db/supabase-setup.sql)
- [x] Knowledge base (knowledge/faq.md)
- [x] Documentation (README.md)

---

## File Structure

```
bsd-salescopilot/
├── match/
│   ├── base.yml              # Core snippets + AI triggers (all logged)
│   └── faq.yml               # FAQ response snippets (all logged)
├── scripts/
│   ├── utils.py              # Shared: clipboard, config, logging
│   ├── local_log.py          # Local JSONL logging
│   ├── log_snippet.py        # Wrapper for static triggers
│   ├── reply.py              # AI reply from knowledge base
│   ├── polish.py             # AI text polisher
│   ├── sync_snippets.py      # GitHub → local sync
│   ├── sync_logs.py          # Local → Supabase sync
│   ├── config.json           # User config (gitignored)
│   ├── config.json.template  # Config template
│   └── .logs/                # Local log files (gitignored)
├── knowledge/
│   └── faq.md                # Knowledge base for AI
├── db/
│   └── supabase-setup.sql    # Database schema
├── install/
│   ├── com.bsd.salescopilot.env.plist          # Env var persistence
│   ├── com.bsd.salescopilot.sync.plist         # Log sync service
│   └── com.bsd.salescopilot.snippetsync.plist  # Snippet sync service
├── install-mac.sh            # One-command Mac installer
├── CLAUDE.md                 # This file
└── README.md                 # User documentation
```

---

## Key Configuration

### config.json (per-user, gitignored)
```json
{
  "gemini_api_key": "...",
  "supabase_url": "https://xxx.supabase.co",
  "supabase_anon_key": "...",
  "user_id": "username",
  "github_repo": "BSD-ORG/bsd-salescopilot",
  "github_branch": "main",
  "sync_enabled": true,
  "log_usage": true
}
```

### Environment Variables
```bash
BSD_COPILOT_PATH="/path/to/bsd-salescopilot"  # Set by installer
```

---

## Troubleshooting

### Check sync logs
```bash
tail -20 ~/Library/Logs/BSDSalesCopilot/sync.log
```

### Check local usage logs
```bash
cat ~/path/to/bsd-salescopilot/scripts/.logs/usage.jsonl
```

### Manual sync test
```bash
python3 ~/path/to/bsd-salescopilot/scripts/sync_snippets.py
```

### Espanso not picking up changes
```bash
espanso restart
espanso log  # Check for errors
```

### Environment variable not set
```bash
launchctl setenv BSD_COPILOT_PATH "/path/to/bsd-salescopilot"
espanso restart
```

---

## Decision Log

| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-01-19 | Use Espanso | Cross-platform, YAML-based, script support |
| 2026-01-19 | Gemini API for AI | Cheap (~$0.0001/req), user has paid account |
| 2026-01-22 | Local-first logging | Fast (24ms), works offline, reliable |
| 2026-01-22 | GitHub raw URLs for sync | Simple, no git on user machines, versioned |
| 2026-01-22 | launchd for background | Native Mac, survives reboots, reliable |
| 2026-01-22 | Public repo recommended | Simplifies sync (no auth needed), code is just configs |

---

## Snippet Reference

### Static Triggers (all logged)
| Trigger | Description |
|---------|-------------|
| `;hi` | Friendly greeting |
| `;hello` | Hello + help offer |
| `;thanks` | Thank you closing |
| `;sig` | Email signature |
| `;portal` | Portal access info |
| `;terms` | Payment terms |
| `;moq` | MOQ / FCL mixing |
| `;docs` | Document list |
| `;cif` | CIF shipping |
| `;noddp` | No DDP explanation |
| `;leadtime` | Lead time info |
| `;nolc` | No LC/Escrow |
| `;locate` | Office locations |
| `;trust` | Credibility response |

### AI Triggers (logged with confidence)
| Trigger | Description |
|---------|-------------|
| `;p1` | AI polish (1 option) |
| `;p2` | AI polish (2 options) |
| `;p3` | AI polish (3 options) |
| `;reply` | AI reply from knowledge base |

---

## Migration Checklist (BSD Repo)

When ready to migrate to BSD's GitHub:

1. [ ] Create `bsd-salescopilot` repo in BSD org (PUBLIC)
2. [ ] `git remote add bsd https://github.com/BSD-ORG/bsd-salescopilot.git`
3. [ ] `git push bsd main`
4. [ ] Update `GITHUB_REPO` in `install-mac.sh`
5. [ ] Commit and push the change
6. [ ] Test sync on 2nd laptop

---

*Last updated: 2026-01-22 (Phase 1.5 complete)*
