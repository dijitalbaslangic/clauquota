# clauquota

Claude Code'da kalan kotanı anlık olarak gösteren status line.

```
Opus 4.6 | 80k/1.0M | 6% used | 94% remain | 5h 2% @14:00 | 7d 29% @mar 06, 14:00 | $1.95
```

## Ne gösterir?

| Alan | Açıklama |
|------|----------|
| `Opus 4.6` | Kullanılan model |
| `80k/1.0M` | Kullanılan token / toplam context window |
| `6% used` | Context window doluluk oranı |
| `94% remain` | Context window kalan oran |
| `5h 2%` | 5 saatlik rate limit kullanımı |
| `7d 29%` | 7 günlük rate limit kullanımı |
| `@mar 06, 14:00` | Rate limit sıfırlanma zamanı |
| `$1.95` | Oturum maliyeti (USD) |

Renkler kullanıma göre değişir: yeşil (< %50), sarı (%50-80), kırmızı (> %80).

## Kurulum

```bash
curl -fsSL https://raw.githubusercontent.com/dijitalbaslangic/clauquota/main/install.sh | bash
```

Sonra Claude Code'u yeniden başlat.

## Gereksinimler

- macOS
- Claude Code kurulu ve giriş yapılmış
- Claude Pro/Max aboneliği

## Kaldırma

```bash
rm ~/.claude/statusline.sh ~/.claude/ratelimit_cache.json
python3 -c "
import json, os
p = os.path.expanduser('~/.claude/settings.json')
s = json.load(open(p))
s.pop('statusLine', None)
json.dump(s, open(p, 'w'), indent=2)
"
```

Sonra Claude Code'u yeniden başlat.
