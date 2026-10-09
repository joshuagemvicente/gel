#!/usr/bin/env bash
# Renders the composition (video + narration), then normalises loudness to −16 LUFS / −1 dBTP and adds +faststart.
# Spec: docs/deliverables/demo-video/spec.md → Output. Usage: scripts/render.sh <version-number>
set -euo pipefail
cd "$(dirname "$0")/.."
N="${1:-2}"
OUT_DIR="../media/out"
mkdir -p "$OUT_DIR" out
npx remotion render src/index.ts GelDemo out/gel-demo-raw.mp4 --codec h264 --crf 18 --audio-codec aac --log=error
ffmpeg -y -loglevel error -i out/gel-demo-raw.mp4 -c:v copy \
  -af "loudnorm=I=-16:TP=-1.5:LRA=11" -ar 48000 -c:a aac -b:a 160k -movflags +faststart "$OUT_DIR/gel-demo-v$N.mp4"
echo "wrote $OUT_DIR/gel-demo-v$N.mp4"
ffprobe -v error -show_entries stream=codec_name,width,height,r_frame_rate,sample_rate -show_entries format=duration -of default=nw=1 "$OUT_DIR/gel-demo-v$N.mp4"
ffmpeg -nostats -i "$OUT_DIR/gel-demo-v$N.mp4" -af ebur128=peak=true -f null - 2>&1 | grep -E "^\s+(I:|Peak:)" | tail -2
