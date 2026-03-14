# openclaw-ai-stack

Custom OpenClaw deployment stack for VPS use.

## What this repo contains

- A custom **OpenClaw** image based on `ghcr.io/openclaw/openclaw:latest`
- Bundled runtime tools for AI-agent operations:
  - **Chromium**
  - **Ollama**
  - **psql** client
  - common ops/debug tools (`curl`, `jq`, `git`, etc.)
- A **Docker Compose** deployment layout
- A separate **Postgres + pgvector** service for structured + vector workloads

## Why Postgres stays separate

This repo intentionally does **not** run the PostgreSQL server inside the same container as OpenClaw.
That is possible, but it is the wrong ops shape:

- harder restarts
- messy health checks
- poor failure isolation
- ugly upgrades
- harder backups

Instead:

- **OpenClaw container** = gateway/runtime + browser/tooling + optional Ollama runtime
- **Postgres container** = stateful database with `pgvector`

## Services

### `openclaw`
Custom image that includes:
- OpenClaw runtime
- Chromium
- Ollama binary/runtime
- PostgreSQL client

### `postgres`
- `pgvector/pgvector:pg16`
- local persistent volume
- `vector` extension bootstrapped automatically

## Files

- `Dockerfile` - custom OpenClaw image
- `docker-compose.yml` - deployment stack
- `.env.example` - environment template
- `scripts/entrypoint.sh` - container bootstrap logic
- `compose/init/01-pgvector.sql` - pgvector bootstrap

## Design notes

- Ollama is available **inside the OpenClaw container** at `http://127.0.0.1:11434`
- Postgres is a sibling container on the same compose network
- OpenClaw state is mounted at `/home/node/.openclaw`
- Secrets should be supplied via `.env`, not committed

## Build

```bash
docker build -t mehyar-us/openclaw-ai:latest .
```

## Run

```bash
cp .env.example .env
# fill in secrets

docker compose up -d --build
```

## Notes

- If you want OpenClaw to use Ollama-backed embeddings, wire that in carefully after the stack is healthy.
- Do not commit real API keys or passwords into this repo.
