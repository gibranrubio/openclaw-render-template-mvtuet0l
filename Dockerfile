FROM node:26.1.0-slim

RUN apt-get update && apt-get install -y git curl procps python3 make g++ cron tini && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY package.json ./
RUN npm install --omit=dev --prefer-online && npm cache clean --force

# ── Self-heal the onboard flow ─────────────────────────────────────────────
# OpenClaw 2026.11.3 loops on the wrapper's v1 auth store and exits non-zero
# after only saving (not activating) the api key. The shim runs the proven
# manual sequence (doctor --fix -> onboard -> activate) on every onboard call.
# Remove this once a released openclaw carries the fix (#187934).
COPY oclaw-shim.sh /usr/local/bin/openclaw
RUN chmod +x /usr/local/bin/openclaw

ENV PATH="/usr/local/bin:/app/node_modules/.bin:$PATH"
ENV ALPHACLAW_ROOT_DIR=/data

RUN mkdir -p /data

EXPOSE 3000

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["alphaclaw", "start"]
