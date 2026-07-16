#!/bin/bash
# scroll-world pipeline для лендинга «Дыши» — адаптация references/pipeline.md.
# Отличия от оригинала: jq нет → python; cwebp нет → ffmpeg (libwebp).
# Запуск постадийно (каждая стадия — в фоне, генерации идут 3–8 мин):
#   bash pipeline.sh stills   # 6 картинок сцен (gpt_image_2)
#   bash pipeline.sh webp     # png → webp-постеры в ../assets
#   bash pipeline.sh dives    # 6 дайв-клипов (VMODEL)
#   bash pipeline.sh frames   # граничные кадры из ОТРЕНДЕРЕННЫХ дайвов
#   bash pipeline.sh conns    # 5 коннекторов (start/end = кадры соседних дайвов!)
#   bash pipeline.sh encode   # перекодировка для скраба → ../assets/vid
# Перероллы поштучно: bash pipeline.sh still dawn | dive wimhof | conn 3

set -u
GEN="$(cd "$(dirname "$0")" && pwd)"
WORK="$GEN/work"
ASSETS="$GEN/../assets"
mkdir -p "$WORK" "$ASSETS/vid"
NAMES="dawn library practice wimhof sufi finale"

# Модель цепочки — ОДНА на все клипы (роль тира решается до запуска):
#   seedance_2_0 (Standard 1080p) | seedance_2_0_mini (draft 720p) | kling3_0 (запасная при NSFW)
VMODEL="${VMODEL:-seedance_2_0}"
case "$VMODEL" in
  kling3_0)          VOPTS="--mode std --sound off";        DIVE_DUR=10; CONN_DUR=5 ;;
  seedance_2_0_mini) VOPTS="--mode std --resolution 720p";  DIVE_DUR=8;  CONN_DUR=5 ;;
  *)                 VOPTS="--mode std --resolution 1080p"; DIVE_DUR=8;  CONN_DUR=5 ;;
esac

json_url() { python -c "import json,sys;d=json.load(open(sys.argv[1],encoding='utf-8'));print((d[0] or {}).get('result_url') or '')" "$1" 2>/dev/null; }

gen_still() { # name
  higgsfield generate create gpt_image_2 --prompt "$(cat "$GEN/still_$1.txt")" \
    --aspect_ratio 3:2 --resolution 2k --quality high --wait --wait-timeout 15m --json \
    > "$WORK/still_$1.json" 2> "$WORK/still_$1.err"
  url=$(json_url "$WORK/still_$1.json")
  [ -n "$url" ] && curl -fsSL "$url" -o "$WORK/still_$1.png" && echo "still $1 ok" || echo "still $1 FAIL (см. work/still_$1.err)"
}

gen_dive() { # name   ($VOPTS без кавычек намеренно — флаги словами)
  higgsfield generate create "$VMODEL" --prompt "$(cat "$GEN/dive_$1.txt")" \
    --start-image "$WORK/still_$1.png" \
    $VOPTS --aspect_ratio 16:9 --duration "$DIVE_DUR" \
    --wait --wait-timeout 20m --json > "$WORK/dive_$1.json" 2> "$WORK/dive_$1.err"
  url=$(json_url "$WORK/dive_$1.json")
  [ -n "$url" ] && curl -fsSL "$url" -o "$WORK/dive_$1.mp4" && echo "dive $1 ok" || echo "dive $1 FAIL (см. work/dive_$1.err)"
}

gen_conn() { # i startPng endPng
  higgsfield generate create "$VMODEL" --prompt "$(cat "$GEN/conn_$1.txt")" \
    --start-image "$2" --end-image "$3" \
    $VOPTS --aspect_ratio 16:9 --duration "$CONN_DUR" \
    --wait --wait-timeout 20m --json > "$WORK/conn_$1.json" 2> "$WORK/conn_$1.err"
  url=$(json_url "$WORK/conn_$1.json")
  [ -n "$url" ] && curl -fsSL "$url" -o "$WORK/conn_$1.mp4" && echo "conn $1 ok" || echo "conn $1 FAIL (см. work/conn_$1.err)"
}

enc() { ffmpeg -v error -y -i "$1" -an -vf "unsharp=5:5:0.8:5:5:0.0" \
  -c:v libx264 -preset slow -crf 20 -pix_fmt yuv420p \
  -g 8 -keyint_min 8 -sc_threshold 0 -movflags +faststart "$2" && echo "enc $(basename "$2") $(du -h "$2" | cut -f1)"; }

case "${1:-}" in
  stills) for n in $NAMES; do gen_still "$n" & done; wait ;;
  still)  gen_still "$2" ;;
  webp)   for n in $NAMES; do ffmpeg -v error -y -i "$WORK/still_$n.png" -vf "scale=1800:-2" -quality 84 "$ASSETS/$n.webp" && echo "webp $n ok"; done ;;
  dives)  for n in $NAMES; do gen_dive "$n" & done; wait ;;
  dive)   gen_dive "$2" ;;
  frames) # шов держится ТОЛЬКО на кадрах отрендеренных дайвов, не на картинках сцен
    for n in $NAMES; do
      ffmpeg -v error -y -ss 0 -i "$WORK/dive_$n.mp4" -frames:v 1 -q:v 2 "$WORK/first_$n.png"
      ffmpeg -v error -y -sseof -0.15 -i "$WORK/dive_$n.mp4" -frames:v 1 -q:v 2 "$WORK/last_$n.png"
    done; echo "frames ok" ;;
  conns)
    set -- $NAMES; i=0; prev=""
    for n in "$@"; do
      if [ -n "$prev" ]; then i=$((i+1)); gen_conn "$i" "$WORK/last_$prev.png" "$WORK/first_$n.png" & fi
      prev="$n"
    done; wait ;;
  conn) # переролл одного: bash pipeline.sh conn 3 (пары: 1=dawn>library 2=library>practice 3=practice>wimhof 4=wimhof>sufi 5=sufi>finale)
    set -- $NAMES; i=0; prev=""; pair_start=""; pair_end=""
    for n in "$@"; do
      if [ -n "$prev" ]; then i=$((i+1)); if [ "$i" = "${2:?номер коннектора}" ]; then pair_start="$WORK/last_$prev.png"; pair_end="$WORK/first_$n.png"; fi; fi
      prev="$n"
    done
    gen_conn "$2" "$pair_start" "$pair_end" ;;
  encode)
    for n in $NAMES; do enc "$WORK/dive_$n.mp4" "$ASSETS/vid/$n.mp4"; done
    i=0; for f in "$WORK"/conn_*.mp4; do i=$((i+1)); enc "$f" "$ASSETS/vid/conn$i.mp4"; done ;;
  *) echo "usage: bash pipeline.sh stills|still <n>|webp|dives|dive <n>|frames|conns|conn <i>|encode"; exit 1 ;;
esac
