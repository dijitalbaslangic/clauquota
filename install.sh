#!/bin/bash
# Claude Code Kota Durum Çubuğu - Yükleyici
# Durum çubuğunda model, bağlam penceresi, 5s/7g hız limitlerini gösterir
# Gereksinimler: macOS, Claude Code, Claude Pro/Max aboneliği, python3

set -e

GREEN='\033[38;2;39;245;70m'
RED='\033[38;2;245;39;39m'
DIM='\033[2m'
RESET='\033[0m'

echo ""
echo "  ⚡ Claude Code Kota Durum Çubuğu Yükleyici"
echo "  ────────────────────────────────────────────"
echo ""

# Gereksinimleri kontrol et
if [[ "$(uname)" != "Darwin" ]]; then
    echo -e "  ${RED}✗${RESET} macOS gerekli (kimlik doğrulama için Keychain kullanılır)"
    exit 1
fi

if ! command -v python3 &>/dev/null; then
    echo -e "  ${RED}✗${RESET} python3 bulunamadı"
    exit 1
fi

if ! command -v claude &>/dev/null; then
    echo -e "  ${RED}✗${RESET} Claude Code bulunamadı. Kur: npm install -g @anthropic-ai/claude-code"
    exit 1
fi

# Claude Code kimlik bilgilerini kontrol et
if ! security find-generic-password -s "Claude Code-credentials" -w &>/dev/null; then
    echo -e "  ${RED}✗${RESET} Claude Code kimlik bilgileri bulunamadı. Önce 'claude' çalıştırıp giriş yapın."
    exit 1
fi

echo -e "  ${GREEN}✓${RESET} Tüm kontroller başarılı"
echo ""

# Durum çubuğu scriptini oluştur
mkdir -p ~/.claude

cat > ~/.claude/statusline.sh << 'STATUSLINE'
#!/usr/bin/env python3
# Claude Code Durum Çubuğu - Kota & Hız Limiti Takibi
# Oturum bilgisi + 5s/7g hız limiti kullanımını gösterir

import sys
import json
import os
import time
import subprocess

HOME = os.path.expanduser("~")
CACHE_FILE = os.path.join(HOME, ".claude", "ratelimit_cache.json")
CACHE_MAX_AGE = 300  # Her 5 dakikada yenile

# --- Stdin'den oturum verisi oku ---
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

# Model adını kısalt
model_short = model_name.replace(" (1M context)", "").replace("claude-", "")

# Bağlam penceresi formatla
def fmt_tokens(n):
    if n >= 1_000_000:
        return f"{n/1_000_000:.1f}M"
    if n >= 1_000:
        return f"{n/1_000:.0f}k"
    return str(n)

# --- Hız limiti verisi ---
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

# Önbellek tazeliğini kontrol et
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

# --- Yüzdeyi renklendir ---
def color_pct(utilization):
    pct = f"{utilization*100:.0f}%"
    if utilization < 0.5:
        return f"\033[38;2;39;245;70m{pct}\033[0m"  # yeşil
    elif utilization < 0.8:
        return f"\033[38;2;245;242;39m{pct}\033[0m"  # sarı
    else:
        return f"\033[38;2;245;39;39m{pct}\033[0m"  # kırmızı

def fmt_reset(ts):
    if not ts:
        return ""
    remaining = int(ts - time.time())
    if remaining <= 0:
        return "0dk"
    days = remaining // 86400
    hours = (remaining % 86400) // 3600
    mins = (remaining % 3600) // 60
    if days > 0:
        return f"{days}g {hours}s {mins}dk"
    elif hours > 0:
        return f"{hours}s {mins}dk"
    else:
        return f"{mins}dk"

# --- Çıktıyı formatla ---
util_5h = cache.get("5h_util", 0)
reset_5h = cache.get("5h_reset", 0)
util_7d = cache.get("7d_util", 0)
reset_7d = cache.get("7d_reset", 0)

pct_5h = color_pct(util_5h)
pct_7d = color_pct(util_7d)

# Renkler
DIM = "\033[2m"
GREEN = "\033[38;2;39;245;70m"
CYAN = "\033[36m"
YELLOW = "\033[38;2;245;242;39m"
RESET = "\033[0m"
BOLD = "\033[1m"

# Kullanıma göre bağlam rengi
if used_pct < 50:
    ctx_color = GREEN
elif used_pct < 80:
    ctx_color = YELLOW
else:
    ctx_color = "\033[38;2;245;39;39m"

line1_parts = [
    f"{CYAN}{model_short}{RESET}",
    f"{fmt_tokens(total_tokens)}/{fmt_tokens(cw_size)}",
    f"{ctx_color}%{used_pct} kull.{RESET}",
    f"{ctx_color}%{remaining_pct} kalan{RESET}",
    f"5h {pct_5h} {DIM}{fmt_reset(reset_5h)}{RESET}",
    f"7d {pct_7d} {DIM}{fmt_reset(reset_7d)}{RESET}",
    f"{DIM}${cost:.2f}{RESET}",
]

print(f" {DIM}|{RESET} ".join(line1_parts))
STATUSLINE

chmod +x ~/.claude/statusline.sh
echo -e "  ${GREEN}✓${RESET} ~/.claude/statusline.sh oluşturuldu"

# Update settings.json
SETTINGS_FILE="$HOME/.claude/settings.json"

if [ -f "$SETTINGS_FILE" ]; then
    # Mevcut ayarlara statusLine ekle
    python3 -c "
import json
with open('$SETTINGS_FILE') as f:
    s = json.load(f)
s['statusLine'] = {'type': 'command', 'command': '~/.claude/statusline.sh', 'padding': 1}
with open('$SETTINGS_FILE', 'w') as f:
    json.dump(s, f, indent=2)
"
else
    # Yeni ayar dosyası oluştur
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

echo -e "  ${GREEN}✓${RESET} ~/.claude/settings.json güncellendi"
echo ""
echo -e "  ${GREEN}Tamam!${RESET} Durum çubuğunu görmek için Claude Code'u yeniden başlatın."
echo ""
echo -e "  ${DIM}Gösterir: Model | Token | Bağlam % | 5s kota | 7g kota | Maliyet${RESET}"
echo ""
