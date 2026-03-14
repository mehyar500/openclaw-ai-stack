# openclaw-ai-stack

Custom OpenClaw VPS deployment stack.

## What this repo contains

- A custom **OpenClaw** image based on `ghcr.io/openclaw/openclaw:latest`
- Bundled runtime tools for AI-agent operations:
  - **Chromium**
  - **Ollama runtime**
  - **psql** client
  - common ops/debug tools (`curl`, `jq`, `git`, etc.)
- A **Docker Compose** deployment layout
- A separate **Postgres + pgvector** service for structured + vector workloads
- A staged VPS deployment script that avoids flipping critical OpenClaw config too early

## Why Postgres stays separate

This repo intentionally does **not** run the PostgreSQL server inside the same container as OpenClaw.
That is possible, but it is the wrong ops shape:

- harder restarts
- messy health checks
- poor failure isolation
- ugly upgrades
- harder backups

Instead:

- **OpenClaw container** = gateway/runtime + browser/tooling + Ollama runtime
- **Postgres container** = stateful database with `pgvector`

## Services

### `openclaw`
Custom image that includes:
- OpenClaw runtime
- Chromium
- Ollama runtime
- PostgreSQL client

### `postgres`
- `pgvector/pgvector:pg16`
- persistent volume
- `vector` extension bootstrapped automatically

## Files

- `Dockerfile` — custom OpenClaw image
- `docker-compose.yml` — deployment stack
- `.env.example` — environment template
- `scripts/entrypoint.sh` — container bootstrap logic
- `scripts/deploy-vps.sh` — staged VPS deploy helper
- `compose/init/01-pgvector.sql` — pgvector bootstrap
- `DEPLOYMENT.md` — rollout and rollback guide

## Important safety rule

This repo is designed so that you can deploy the image and the database stack **before** teaching OpenClaw to depend on Ollama for embeddings.

That avoids the exact failure mode where the live gateway is restarted into a broken provider configuration.

## Build

```bash
docker build -t mehyar500/openclaw-ai:latest .
```

## Run locally / on a VPS

```bash
cp .env.example .env
# fill in secrets

docker compose up -d --build
```

## Deploy on your VPS

See [DEPLOYMENT.md](./DEPLOYMENT.md).

Short version:

```bash
./scripts/deploy-vps.sh
```

## Notes

- Ollama runs **inside** the OpenClaw container in this design.
- Postgres remains a sibling container.
- Do not commit real API keys or passwords into this repo.
