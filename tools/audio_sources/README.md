# Внешние аудио-источники

Единственное исключение из правила «100 % программный синтез» (ПЛАН §10, R9) —
файлы с ЯВНО проверенной свободной лицензией, одобренные владельцем.

| Файл | Источник | Лицензия | Куда идёт |
|---|---|---|---|
| `42095__fauxpress__bell-meditation.mp3` | freesound.org/people/fauxpress/sounds/42095/ | **CC0** (атрибуция не требуется) | `assets/audio/common/gong.wav` |

Обработка гонга (ffmpeg, повторяемо):

```
ffmpeg -y -i tools/audio_sources/42095__fauxpress__bell-meditation.mp3 \
  -t 9 -af "volume=-1dB,afade=t=out:st=6.5:d=2.5" \
  -ar 44100 -ac 1 -sample_fmt s16 assets/audio/common/gong.wav
```

(−1 дБ приводит пик −2.0 → −3 dBFS — уровень гонга из манифеста; обрезка
30,5 с → 9 с с фейдом 2,5 с, чтобы хвост не растягивал таймлайн сессии.)

НЕ брать freesound 401336 (ckvoiceover) — CC-BY, требует атрибуции.
