#!/usr/bin/env bash
set -euo pipefail

if [[ "${ENABLE_OLLAMA:-1}" == "1" ]]; then
  mkdir -p /tmp/ollama
  ollama serve >/tmp/ollama/ollama.log 2>&1 &
fi

exec "$@"
