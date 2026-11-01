#!/bin/bash
set -e

PNG="${1:?PNG-Datei fehlt}"
OUT="${2:-${PNG%.*}.ttf}"
NAME="${3:-$(basename "${OUT%.*}")}"
SPACING="${4:-1}"
SPACE_WIDTH="${5:-4}"

WIDTH=$(identify -format '%w' "$PNG")
HEIGHT=$(identify -format '%h' "$PNG")

if [[ "$WIDTH" != 4096 || "$HEIGHT" != 16 ]]; then
    echo "Erwartet: 4096x16, gefunden: ${WIDTH}x${HEIGHT}"
    exit 1
fi

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

convert "$PNG" -depth 8 "rgba:$TMP/font.raw"

FONTFORGE_LOADPREFS=Never \
fontforge -lang=py -script "$(dirname "$0")/png2ttf.py" \
    "$TMP/font.raw" "$OUT" "$NAME" "$SPACING" "$SPACE_WIDTH"

echo "Fertig: $OUT"

