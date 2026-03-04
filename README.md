# clauquota

Claude Code'da kalan kotanı anlık olarak gösteren durum çubuğu.

```
Opus 4.6 | 80k/1.0M | %6 kull. | %94 kalan | 5h 2% 4s 12dk | 7d 29% 2g 9s 30dk | $1.95 | 12g kaldı
```

## Ne gösterir?

| Alan | Açıklama |
|------|----------|
| `Opus 4.6` | Kullanılan model |
| `80k/1.0M` | Kullanılan token / toplam context window |
| `%6 kull.` | Context window doluluk oranı |
| `%94 kalan` | Context window kalan oran |
| `5h 2% 4s 12dk` | 5 saatlik kota kullanımı ve sıfırlanmaya kalan süre |
| `7d 29% 2g 9s 30dk` | 7 günlük kota kullanımı ve sıfırlanmaya kalan süre |
| `$1.95` | Oturum maliyeti (USD) |
| `12g kaldı` | Abonelik yenilenmesine kalan gün |

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
