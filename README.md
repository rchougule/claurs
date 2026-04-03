# claurs

Personal Claude Code skills collection. Skills are reusable slash commands that encode complex workflows — invoke them in any project with `/skill-name`.

## Quick Start

```bash
git clone git@github.com:rchougule/claurs.git
cd claurs
./setup.sh install          # install all skills globally
./setup.sh install finance  # or just one category
```

That's it. Open any project in Claude Code and the skills are available.

## Commands

```bash
./setup.sh install [category]    # Symlink skills to ~/.claude/commands/
./setup.sh list                  # List available skill categories and descriptions
./setup.sh status                # Show which skills are currently installed
./setup.sh uninstall [category]  # Remove installed skill symlinks
```

## Updating

```bash
cd claurs
git pull
./setup.sh install  # re-run to pick up new/changed skills
```

Symlinks point to the repo, so most changes take effect on `git pull` without re-running setup. Re-run setup only if new skill files were added.

## Skills

### Finance (`skills/finance/`)

| Skill | Invoke | Purpose |
|---|---|---|
| `financial-data` | `/financial-data` | Extract financial data from CAMS PDFs, Zerodha screenshots, broker apps into standardized CSVs |
| `financial-plan` | `/financial-plan` | Build or review an investment plan with multi-agent vetting loop (math, strategy, tax/regulatory checks) |

**Prerequisites:** Both finance skills expect a `source/profile.md` in your project repo. Use the template at `templates/financial-profile-template.md` to create one. The skill will also tell you if anything is missing.

**Workflow:**
1. Run `/financial-data` with your source documents (CAMS PDF, Zerodha screenshots, etc.)
2. Run `/financial-plan` to build or review your investment plan
3. The plan goes through parallel independent vetting (math, strategy, tax) before being finalized

## Templates

| Template | Purpose |
|---|---|
| `templates/financial-profile-template.md` | Profile template for `source/profile.md` — required by finance skills |

## How It Works

Skills are markdown files that Claude Code expands as prompts when you type the slash command. `setup.sh` symlinks them from this repo into `~/.claude/commands/` (Claude Code's global commands directory), making them available in every project.

```
~/.claude/commands/
  financial-data.md -> /path/to/claurs/skills/finance/financial-data.md
  financial-plan.md -> /path/to/claurs/skills/finance/financial-plan.md
```

## Adding New Skills

1. Create a new category directory under `skills/` (e.g., `skills/tax/`)
2. Add `.md` files — the filename becomes the command name
3. First line of the file should be a one-line description
4. Run `./setup.sh install` to symlink

## Structure

```
claurs/
  setup.sh                  # installer
  skills/
    finance/
      financial-data.md     # /financial-data
      financial-plan.md     # /financial-plan
  templates/
    financial-profile-template.md
```
