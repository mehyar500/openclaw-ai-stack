#!/usr/bin/env bash
set -euo pipefail

OLLAMA_PID=""

cleanup() {
  if [[ -n "${OLLAMA_PID}" ]] && kill -0 "${OLLAMA_PID}" 2>/dev/null; then
    kill "${OLLAMA_PID}" 2>/dev/null || true
    wait "${OLLAMA_PID}" 2>/dev/null || true
  fi
}
trap cleanup EXIT INT TERM

start_ollama() {
  export HOME="${HOME:-/home/node}"
  export OLLAMA_HOST="${OLLAMA_HOST:-127.0.0.1:11434}"
  export OLLAMA_MODELS="${OLLAMA_MODELS:-${HOME}/.ollama/models}"

  mkdir -p "${HOME}/.ollama" /tmp/ollama

  echo "[entrypoint] starting ollama on ${OLLAMA_HOST}"
  ollama serve >/tmp/ollama/ollama.log 2>&1 &
  OLLAMA_PID="$!"

  local ready=0
  for _ in $(seq 1 60); do
    if curl -fsS "http://${OLLAMA_HOST}/api/tags" >/dev/null 2>&1; then
      ready=1
      break
    fi
    sleep 1
  done

  if [[ "$ready" != "1" ]]; then
    echo "[entrypoint] ollama failed to become ready" >&2
    tail -100 /tmp/ollama/ollama.log >&2 || true
    exit 1
  fi

  if [[ -n "${OLLAMA_PULL_MODELS:-}" ]]; then
    for model in ${OLLAMA_PULL_MODELS}; do
      echo "[entrypoint] pre-pulling ollama model: ${model}"
      ollama pull "${model}"
    done
  fi
}

if [[ "${ENABLE_OLLAMA:-1}" == "1" ]]; then
  start_ollama
else
  echo "[entrypoint] ollama disabled"
fi

echo "[entrypoint] launching: $*"
exec "$@"
