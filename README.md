# BSD Sales Copilot

AI-powered text expansion for BSD sales team using Espanso.

## Features

- **Quick snippets**: Common greetings, closings, and signatures
- **AI polish**: Rewrite text in a professional tone (`;p1`, `;p2`, `;p3`)
- **AI reply**: Generate responses from knowledge base (`;reply`)
- **Cross-platform**: Works on Mac and Windows
- **Usage logging**: Track usage and identify knowledge gaps (optional)

## Quick Start (Mac)

```bash
# Clone or download to Google Drive for team sync
cd /path/to/bsd-salescopilot

# Run installer
./install-mac.sh
```

The installer will:
1. Check for Espanso and Python 3
2. Create symlinks to Espanso config
3. Set up environment variables
4. Prompt for API key configuration
5. Restart Espanso

## Available Triggers

| Trigger | Description |
|---------|-------------|
| `;hi` | Friendly greeting |
| `;hello` | Hello with help offer |
| `;thanks` | Thank you closing |
| `;sig` | Email signature |
| `;p1` | AI polish (1 option) |
| `;p2` | AI polish (2 options) |
| `;p3` | AI polish (3 options) |
| `;reply` | AI reply from knowledge base |

### FAQ Triggers

| Trigger | Description |
|---------|-------------|
| `;portal` | Portal access info |
| `;terms` | Payment terms |
| `;moq` | MOQ / FCL mixing |
| `;docs` | Document list |
| `;cif` | CIF shipping terms |
| `;noddp` | No DDP explanation |
| `;leadtime` | Lead time info |
| `;nolc` | No LC/Escrow policy |
| `;locate` | Office locations |
| `;trust` | Credibility/references |

## How to Use

1. **Copy text** you want to work with (for AI features)
2. **Type the trigger** (e.g., `;reply`) in any text field
3. **Wait a moment** — the response will replace the trigger

## Project Structure

```
bsd-salescopilot/
├── match/              # Espanso YAML configs
│   ├── base.yml        # Core snippets + AI triggers
│   └── faq.yml         # FAQ response snippets
├── scripts/            # Python scripts
│   ├── utils.py        # Shared utilities
│   ├── reply.py        # AI reply generator
│   ├── polish.py       # AI text polisher
│   ├── config.json     # Configuration (gitignored)
│   └── config.json.template
├── knowledge/          # Knowledge base
│   └── faq.md          # FAQ content for AI
├── db/                 # Database setup
│   └── supabase-setup.sql
├── install-mac.sh      # Mac installer
└── README.md
```

## Configuration

Configuration is stored in `scripts/config.json`:

```json
{
  "provider": "gemini",
  "gemini_api_key": "your-api-key",
  "supabase_url": "https://your-project.supabase.co",
  "supabase_anon_key": "your-anon-key",
  "log_usage": true,
  "log_responses": false,
  "user_id": "your-name"
}
```

### Environment Variables (Alternative)

```bash
export GEMINI_API_KEY="your-api-key"
export SUPABASE_URL="https://your-project.supabase.co"
export SUPABASE_ANON_KEY="your-anon-key"
export BSD_COPILOT_PATH="/path/to/bsd-salescopilot"
```

## Team Deployment

For team use with Google Drive:

1. Place this folder in Google Drive (shared folder)
2. Each team member runs `./install-mac.sh`
3. Updates to YAML files sync automatically
4. Each user has their own `config.json` (not synced)

## Usage Logging (Optional)

If Supabase is configured, the scripts will log:
- Which triggers are used
- Questions asked (for AI features)
- Confidence levels (HIGH, MEDIUM, LOW)

This helps identify:
- Popular snippets
- Knowledge gaps (LOW confidence answers)
- Usage patterns

### Supabase Setup

1. Create a Supabase project (free tier works)
2. Run `db/supabase-setup.sql` in the SQL Editor
3. Add credentials to `config.json`

## Troubleshooting

### Triggers not working

1. Make sure Espanso is running: `espanso status`
2. Restart Espanso: `espanso restart`
3. Check logs: `espanso log`

### AI features returning errors

1. Check API key is set correctly
2. Test the script directly:
   ```bash
   echo "test question" | pbcopy
   python3 scripts/reply.py
   ```

### Environment variable not found

Open a new terminal window after running the installer.

## Requirements

- **Mac**: macOS 10.15+, Espanso, Python 3.8+
- **Windows**: Windows 10+, Espanso, Python 3.8+

## License

Internal use only.
