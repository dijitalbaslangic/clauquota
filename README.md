# clauquota

Claude Code'da kalan kotanı anlık olarak gösteren durum çubuğu.

```
Opus 4.6 | 34k/200k | 5h 3% 4s39dk | 7d 37% 2g6s | 47/53% | $4.73 | 12g
```

## Ne gösterir?

| Alan | Açıklama |
|------|----------|
| `Opus 4.6` | Kullanılan model |
| `34k/200k` | Kullanılan token / toplam context window |
| `5h 3% 4s39dk` | 5 saatlik kota kullanımı ve sıfırlanmaya kalan süre |
| `7d 37% 2g6s` | 7 günlük kota kullanımı ve sıfırlanmaya kalan süre |
| `47/53%` | Context window kullanılan/kalan oranı |
| `$4.73` | Oturum maliyeti (USD) |
| `12g` | Abonelik yenilenmesine kalan gün |

Renkler kullanıma göre değişir: yeşil (< %50), sarı (%50-80), kırmızı (> %80).
Abonelik renkleri: yeşil (>10g), sarı (5-10g), turuncu (3-5g), kırmızı (≤3g).

## Kurulum

```bash
curl -fsSL https://raw.githubusercontent.com/dijitalbaslangic/clauquota/main/install.sh | bash
```

Kurulum sırasında abonelik yenileme gününüz sorulacaktır.

Sonra Claude Code'u yeniden başlat.

## Güncelleme

Aynı komutu tekrar çalıştırın:

```bash
curl -fsSL https://raw.githubusercontent.com/dijitalbaslangic/clauquota/main/install.sh | bash
```

Mevcut abonelik ayarınız korunur, isterseniz değiştirebilirsiniz.

## Gereksinimler

- macOS
- Claude Code kurulu ve giriş yapılmış
- Claude Pro/Max aboneliği

## Kaldırma

```bash
rm ~/.claude/statusline.sh ~/.claude/ratelimit_cache.json ~/.claude/subscription.json
python3 -c "
import json, os
p = os.path.expanduser('~/.claude/settings.json')
s = json.load(open(p))
s.pop('statusLine', None)
json.dump(s, open(p, 'w'), indent=2)
"
```

Sonra Claude Code'u yeniden başlat.
