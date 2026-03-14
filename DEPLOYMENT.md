# Deployment Guide

This stack is designed to be deployed **without changing OpenClaw memory/provider config first**.

## Safety rules

1. Deploy the custom image and Postgres first.
2. Confirm the gateway boots and the Control UI works.
3. Confirm Ollama is healthy inside the container.
4. Only then experiment with OpenClaw config that depends on Ollama.

## VPS rollout flow

### 1. Clone repo on VPS

```bash
mkdir -p /docker/claw-me-custom
cd /docker/claw-me-custom
git clone https://github.com/mehyar500/openclaw-ai-stack.git .
cp .env.example .env
```

### 2. Fill in `.env`

Copy your current secrets from the existing OpenClaw compose deployment.
Do **not** commit them.

### 3. Reuse existing OpenClaw state

This stack expects the live state at:

```bash
/opt/openclaw/home
```

That matches the current VPS layout.

### 4. Build and start

```bash
./scripts/deploy-vps.sh
```

Or manually:

```bash
docker compose --env-file .env build openclaw
docker compose --env-file .env up -d postgres
docker compose --env-file .env up -d openclaw
```

### 5. Verify before config changes

```bash
docker logs --tail 120 openclaw
curl http://127.0.0.1:18789/healthz
```

Verify Ollama from inside the container:

```bash
docker exec openclaw curl -s http://127.0.0.1:11434/api/tags
```

Verify pgvector:

```bash
docker exec ai-postgres psql -U openops -d openops -c 'select extname from pg_extension;'
```

## What not to do

Do **not** immediately set these in `openclaw.json` on the first deploy:

- `agents.defaults.memorySearch.provider = "ollama"`
- `models.providers.ollama = ...`

That should happen only after the base stack is confirmed healthy.

## Recommended phase 2

After the container proves healthy, add Ollama-backed embeddings in a small, reversible config change and restart once.

## Rollback

If something goes sideways:

```bash
docker compose down
```

Then revert to your previous compose deployment and restart the old `openclaw` container.
