#!/bin/sh
# AlphaClaw onboard self-heal: openclaw 2026.11.3 rejects the wrapper's v1 auth
# store (AUTH_PROFILE_MIGRATION_REQUIRED) and onboard exits non-zero after only
# SAVING (not activating) the api key. Replicate the proven manual sequence:
# doctor --fix  ->  onboard  ->  activate the saved credential  ->  exit 0.
# Remove once a released openclaw carries the onboard fix (#187934).
REAL="/app/node_modules/openclaw/openclaw.mjs"
if [ "$1" = "onboard" ]; then
  node "$REAL" doctor --fix --yes || true
  OUT=$(node "$REAL" "$@" 2>&1)
  printf '%s\n' "$OUT"
  ACT=$(printf '%s\n' "$OUT" | grep -oE 'models auth activate [^ ]+ --agent [^ ]+' | head -1)
  if [ -n "$ACT" ]; then
    node "$REAL" $ACT || true
    exit 0
  fi
  printf '%s\n' "$OUT" | grep -qi 'credential saved' && exit 0
  exit 1
fi
exec node "$REAL" "$@"
