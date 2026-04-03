# claurs

Personal Claude Code skills collection.

## Skills

### Finance (`skills/finance/`)

| Skill | Purpose |
|---|---|
| `financial-data` | Extract financial data from CAMS PDFs, Zerodha screenshots, broker apps into standardized CSVs |
| `financial-plan` | Build/review investment plan with multi-agent vetting loop (math, strategy, tax/regulatory checks) |

### Usage

Copy the skill files to your project's `.claude/commands/` directory:

```bash
cp skills/finance/financial-data.md /path/to/your/repo/.claude/commands/
cp skills/finance/financial-plan.md /path/to/your/repo/.claude/commands/
```

Then invoke in Claude Code:
```
/financial-data
/financial-plan
```

### Templates

| Template | Purpose |
|---|---|
| `templates/financial-profile-template.md` | Profile template for `source/profile.md` — required by both finance skills |

## Structure

```
claurs/
  skills/
    finance/
      financial-data.md
      financial-plan.md
  templates/
    financial-profile-template.md
```
