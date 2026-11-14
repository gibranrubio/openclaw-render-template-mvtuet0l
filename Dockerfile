FROM node:26.1.0-slim

RUN apt-get update && apt-get install -y git curl procps python3 make g++ cron tini && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY package.json ./
RUN npm install --omit=dev --prefer-online && npm cache clean --force

# ── Self-heal the onboard auth-migration loop ──────────────────────────────
# OpenClaw 2026.11.3 rejects the wrapper's version-1 auth store as "legacy"
# (AUTH_PROFILE_MIGRATION_REQUIRED). The upstream fix (openclaw #187934) is not
# in any release yet. Shim `openclaw` so that any `onboard` invocation first
# runs `doctor --fix` in the same process (migrates the store), then onboards —
# the exact back-to-back sequence that works by hand. Remove this block once a
# released openclaw carries the fix.
RUN printf '#!/bin/sh\nREAL="/app/node_modules/openclaw/openclaw.mjs"\nif [ "$1" = "onboard" ]; then node "$REAL" doctor --fix --yes || true; fi\nexec node "$REAL" "$@"\n' > /usr/local/bin/openclaw \
  && chmod +x /usr/local/bin/openclaw

ENV PATH="/usr/local/bin:/app/node_modules/.bin:$PATH"
ENV ALPHACLAW_ROOT_DIR=/data

RUN mkdir -p /data

EXPOSE 3000

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["alphaclaw", "start"]
