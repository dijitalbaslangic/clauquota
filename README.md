# clauquota

Claude Code status line that shows your real-time rate limit usage.

![screenshot](https://img.shields.io/badge/Claude_Code-Status_Line-blue)

```
Opus 4.6 | 80k/1.0M | 6% used | 94% remain | 5h 2% @14:00 | 7d 29% @mar 06, 14:00 | $1.95
```

## What it shows

| Field | Description |
|-------|-------------|
| `Opus 4.6` | Current model |
| `80k/1.0M` | Tokens used / context window size |
| `6% used` | Context window usage |
| `94% remain` | Context window remaining |
| `5h 2%` | 5-hour rate limit utilization |
| `7d 29%` | 7-day rate limit utilization |
| `@mar 06, 14:00` | Rate limit reset time |
| `$1.95` | Session cost (USD) |

Colors change based on usage: green (< 50%), yellow (50-80%), red (> 80%).

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/dijitalbaslangic/clauquota/main/install.sh | bash
```

Then restart Claude Code.

## Requirements

- macOS
- Claude Code installed and logged in
- Claude Pro/Max subscription

## Uninstall

```bash
rm ~/.claude/statusline.sh ~/.claude/ratelimit_cache.json
```

Then remove the `"statusLine"` block from `~/.claude/settings.json`.
