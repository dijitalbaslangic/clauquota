#!/bin/bash
# Claude Code Quota Status Line - Installer
# Shows model, context window, 5h/7d rate limits in status bar
# Requirements: macOS, Claude Code, Claude Pro/Max subscription, python3

set -e

GREEN='\033[38;2;39;245;70m'
RED='\033[38;2;245;39;39m'
DIM='\033[2m'
RESET='\033[0m'

echo ""
echo "  ⚡ Claude Code Quota Status Line Installer"
echo "  ─────────────────────────────────────────"
echo ""

# Check requirements
if [[ "$(uname)" != "Darwin" ]]; then
    echo -e "  ${RED}✗${RESET} macOS required (uses Keychain for auth)"
    exit 1
fi

if ! command -v python3 &>/dev/null; then
    echo -e "  ${RED}✗${RESET} python3 not found"
    exit 1
fi

if ! command -v claude &>/dev/null; then
    echo -e "  ${RED}✗${RESET} Claude Code not found. Install: npm install -g @anthropic-ai/claude-code"
    exit 1
fi

# Check Claude Code credentials
if ! security find-generic-password -s "Claude Code-credentials" -w &>/dev/null; then
    echo -e "  ${RED}✗${RESET} Claude Code credentials not found. Run 'claude' first and log in."
    exit 1
fi

echo -e "  ${GREEN}✓${RESET} All checks passed"
echo ""

# Create statusline script
mkdir -p ~/.claude

cat > ~/.claude/statusline.sh << 'STATUSLINE'
#!/usr/bin/env python3
# Claude Code Status Line - Quota & Rate Limit Tracker
# Shows session info + 5h/7d rate limit utilization

import sys
import json
import os
import time
import subprocess

HOME = os.path.expanduser("~")
CACHE_FILE = os.path.join(HOME, ".claude", "ratelimit_cache.json")
CACHE_MAX_AGE = 300  # Refresh every 5 minutes

# --- Parse session data from stdin ---
try:
    session = json.load(sys.stdin)
except Exception:
    session = {}

cost = session.get("cost", {}).get("total_cost_usd", 0)
cw = session.get("context_window", {})
used_pct = cw.get("used_percentage", 0)
remaining_pct = cw.get("remaining_percentage", 100)
cw_size = cw.get("context_window_size", 0)
input_tokens = cw.get("total_input_tokens", 0)
output_tokens = cw.get("total_output_tokens", 0)
total_tokens = input_tokens + output_tokens
model_info = session.get("model", {})
if isinstance(model_info, dict):
    model_name = model_info.get("display_name", model_info.get("id", "unknown"))
else:
    model_name = str(model_info)

# Shorten model name
model_short = model_name.replace(" (1M context)", "").replace("claude-", "")

# Format context window
def fmt_tokens(n):
    if n >= 1_000_000:
        return f"{n/1_000_000:.1f}M"
    if n >= 1_000:
        return f"{n/1_000:.0f}k"
    return str(n)

# --- Rate limit data ---
def get_oauth_token():
    try:
        result = subprocess.run(
            ["security", "find-generic-password", "-s", "Claude Code-credentials", "-w"],
            capture_output=True, text=True, timeout=5
        )
        if result.returncode == 0:
            creds = json.loads(result.stdout.strip())
            return creds.get("claudeAiOauth", {}).get("accessToken", "")
    except Exception:
        pass
    return ""

def fetch_rate_limits(token):
    try:
        result = subprocess.run(
            ["curl", "-s", "-D", "-", "-o", "/dev/null",
             "https://api.anthropic.com/v1/messages",
             "-H", f"x-api-key: {token}",
             "-H", "anthropic-version: 2023-06-01",
             "-H", "content-type: application/json",
             "-d", '{"model":"claude-haiku-4-5-20251001","max_tokens":1,"messages":[{"role":"user","content":"h"}]}'],
            capture_output=True, text=True, timeout=10
        )
        headers = {}
        for line in result.stdout.split("\n"):
            if "anthropic-ratelimit-unified" in line:
                parts = line.strip().split(": ", 1)
                if len(parts) == 2:
                    key = parts[0].replace("anthropic-ratelimit-unified-", "")
                    headers[key] = parts[1].strip()
        return headers
    except Exception:
        return {}

def load_cache():
    try:
        with open(CACHE_FILE) as f:
            return json.load(f)
    except Exception:
        return {}

def save_cache(data):
    try:
        with open(CACHE_FILE, "w") as f:
            json.dump(data, f)
    except Exception:
        pass

# Check cache freshness
cache = load_cache()
cache_age = time.time() - cache.get("timestamp", 0)

if cache_age > CACHE_MAX_AGE:
    token = get_oauth_token()
    if token:
        rl = fetch_rate_limits(token)
        if rl:
            cache = {
                "timestamp": time.time(),
                "5h_util": float(rl.get("5h-utilization", 0)),
                "5h_reset": int(rl.get("5h-reset", 0)),
                "5h_status": rl.get("5h-status", "unknown"),
                "7d_util": float(rl.get("7d-utilization", 0)),
                "7d_reset": int(rl.get("7d-reset", 0)),
                "7d_status": rl.get("7d-status", "unknown"),
            }
            save_cache(cache)

# --- Colorize percentage ---
def color_pct(utilization):
    pct = f"{utilization*100:.0f}%"
    if utilization < 0.5:
        return f"\033[38;2;39;245;70m{pct}\033[0m"  # green
    elif utilization < 0.8:
        return f"\033[38;2;245;242;39m{pct}\033[0m"  # yellow
    else:
        return f"\033[38;2;245;39;39m{pct}\033[0m"  # red

def fmt_reset(ts):
    if not ts:
        return ""
    reset_time = time.localtime(ts)
    now = time.localtime()
    if reset_time.tm_yday == now.tm_yday and reset_time.tm_year == now.tm_year:
        return time.strftime("@%H:%M", reset_time)
    else:
        return time.strftime("@%b %d, %H:%M", reset_time).lower()

# --- Format output ---
util_5h = cache.get("5h_util", 0)
reset_5h = cache.get("5h_reset", 0)
util_7d = cache.get("7d_util", 0)
reset_7d = cache.get("7d_reset", 0)

pct_5h = color_pct(util_5h)
pct_7d = color_pct(util_7d)

# Colors
DIM = "\033[2m"
GREEN = "\033[38;2;39;245;70m"
CYAN = "\033[36m"
YELLOW = "\033[38;2;245;242;39m"
RESET = "\033[0m"
BOLD = "\033[1m"

# Context color based on usage
if used_pct < 50:
    ctx_color = GREEN
elif used_pct < 80:
    ctx_color = YELLOW
else:
    ctx_color = "\033[38;2;245;39;39m"

line1_parts = [
    f"{CYAN}{model_short}{RESET}",
    f"{fmt_tokens(total_tokens)}/{fmt_tokens(cw_size)}",
    f"{ctx_color}{used_pct}% used{RESET}",
    f"{ctx_color}{remaining_pct}% remain{RESET}",
    f"5h {pct_5h} {DIM}{fmt_reset(reset_5h)}{RESET}",
    f"7d {pct_7d} {DIM}{fmt_reset(reset_7d)}{RESET}",
    f"{DIM}${cost:.2f}{RESET}",
]

print(f" {DIM}|{RESET} ".join(line1_parts))
STATUSLINE

chmod +x ~/.claude/statusline.sh
echo -e "  ${GREEN}✓${RESET} Created ~/.claude/statusline.sh"

# Update settings.json
SETTINGS_FILE="$HOME/.claude/settings.json"

if [ -f "$SETTINGS_FILE" ]; then
    # Add statusLine to existing settings
    python3 -c "
import json
with open('$SETTINGS_FILE') as f:
    s = json.load(f)
s['statusLine'] = {'type': 'command', 'command': '~/.claude/statusline.sh', 'padding': 1}
with open('$SETTINGS_FILE', 'w') as f:
    json.dump(s, f, indent=2)
"
else
    # Create new settings file
    cat > "$SETTINGS_FILE" << 'SETTINGS'
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh",
    "padding": 1
  }
}
SETTINGS
fi

echo -e "  ${GREEN}✓${RESET} Updated ~/.claude/settings.json"
echo ""
echo -e "  ${GREEN}Done!${RESET} Restart Claude Code to see the status line."
echo ""
echo -e "  ${DIM}Shows: Model | Tokens | Context % | 5h rate limit | 7d rate limit | Cost${RESET}"
echo ""
