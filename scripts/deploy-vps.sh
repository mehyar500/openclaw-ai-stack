#!/usr/bin/env bash
set -euo pipefail

APP_DIR="${APP_DIR:-/docker/claw-me-custom}"
IMAGE_TAG="${IMAGE_TAG:-mehyar500/openclaw-ai:latest}"
COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.yml}"
ENV_FILE="${ENV_FILE:-.env}"

need() {
  command -v "$1" >/dev/null 2>&1 || { echo "missing required command: $1" >&2; exit 1; }
}

need docker
need git

mkdir -p "$APP_DIR"
cd "$APP_DIR"

if [[ ! -d .git ]]; then
  git clone https://github.com/mehyar500/openclaw-ai-stack.git .
else
  git fetch origin
  git reset --hard origin/main
fi

if [[ ! -f "$ENV_FILE" ]]; then
  cp .env.example "$ENV_FILE"
  echo "created $APP_DIR/$ENV_FILE — fill in secrets before first real deploy" >&2
fi

if [[ ! -d /opt/openclaw/home ]]; then
  echo "/opt/openclaw/home missing; create or restore your OpenClaw state before deploy" >&2
  exit 1
fi

# Pull/build first without touching live state.
docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" build openclaw

echo "== dry validation =="
docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" config >/dev/null

echo "== deploy =="
docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" up -d postgres
docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" up -d openclaw

echo "== smoke tests =="
sleep 10
docker ps --format 'table {{.Names}}\t{{.Status}}' | egrep 'openclaw|ai-postgres' || true
docker logs --tail 120 openclaw || true

echo "Deployment attempt complete. Verify http://<host>:18789/healthz and the Control UI before changing any OpenClaw provider config."
