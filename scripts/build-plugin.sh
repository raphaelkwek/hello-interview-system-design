#!/usr/bin/env bash
# Builds dist/hello-interview-system-design.plugin, the zip claude.ai accepts as a plugin upload.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/dist/hello-interview-system-design.plugin"
mkdir -p "$ROOT/dist"
rm -f "$OUT"
cd "$ROOT"
zip -qr -X "$OUT" .claude-plugin skills README.md LICENSE
echo "$OUT"
