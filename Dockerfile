FROM node:26.1.0-slim

RUN apt-get update && apt-get install -y git curl procps python3 make g++ cron tini && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY package.json ./
RUN npm install --omit=dev --prefer-online && npm cache clean --force

# ── gbrain: the engine the stock alert (and later the agent) reach the Supabase brain through ──
# bun is gbrain's runtime (bun-native, needs >=1.4). Pinned to the laptop's gbrain version so two
# clients sharing one Supabase brain don't fight over schema migrations. These are the exact
# commands proven working in this container on 2026-11-14 (version bumped to match the laptop on 2026-11-24). Config + the single-writer lock live on
# /data (GBRAIN_HOME, the Render persistent disk) so they survive rebuilds; the binary ships in the
# image so a redeploy can't wipe it.
RUN npm install -g bun && bun install -g github:garrytan/gbrain#v0.60.769.0
ENV GBRAIN_HOME=/data/.gbrain

# ── Self-heal the onboard flow ─────────────────────────────────────────────
# OpenClaw 2026.11.3 loops on the wrapper's v1 auth store and exits non-zero
# after only saving (not activating) the api key. The shim runs the proven
# manual sequence (doctor --fix -> onboard -> activate) on every onboard call.
# Remove this once a released openclaw carries the fix (#187934).
COPY oclaw-shim.sh /usr/local/bin/openclaw
RUN chmod +x /usr/local/bin/openclaw

ENV PATH="/usr/local/bin:/root/.bun/bin:/app/node_modules/.bin:$PATH"
ENV ALPHACLAW_ROOT_DIR=/data

RUN mkdir -p /data

EXPOSE 3000

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["alphaclaw", "start"]
