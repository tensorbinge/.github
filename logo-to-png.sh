#!/usr/bin/env bash
# Render logo.svg to a square PNG.
# Usage: ./logo-to-png.sh [SIZE] [INPUT_SVG] [OUTPUT_PNG]
#   SIZE        square edge length in px (default 460 — matches the GitHub org avatar)
#   INPUT_SVG   source SVG (default logo.svg)
#   OUTPUT_PNG  destination PNG (default logo.png)
set -euo pipefail

SIZE="${1:-460}"
INPUT="${2:-logo.svg}"
OUTPUT="${3:-logo.png}"

if ! [[ "$SIZE" =~ ^[0-9]+$ ]] || [ "$SIZE" -le 0 ]; then
  echo "error: SIZE must be a positive integer (got '$SIZE')" >&2
  exit 1
fi
if [ ! -f "$INPUT" ]; then
  echo "error: input SVG not found: $INPUT" >&2
  exit 1
fi

if command -v rsvg-convert >/dev/null 2>&1; then
  rsvg-convert -w "$SIZE" -h "$SIZE" "$INPUT" -o "$OUTPUT"
elif command -v magick >/dev/null 2>&1; then
  magick -background none -density 384 "$INPUT" -resize "${SIZE}x${SIZE}" "$OUTPUT"
else
  echo "error: need rsvg-convert or ImageMagick (magick) installed" >&2
  exit 1
fi

echo "wrote $OUTPUT (${SIZE}x${SIZE}) from $INPUT"
