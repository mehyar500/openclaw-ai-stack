FROM ghcr.io/openclaw/openclaw:latest

USER root

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    chromium \
    chromium-sandbox \
    postgresql-client \
    curl \
    wget \
    jq \
    ca-certificates \
    gnupg \
    lsb-release \
    git \
    unzip \
    xz-utils \
    procps \
    tini \
  && rm -rf /var/lib/apt/lists/*

# Install Ollama runtime
RUN curl -fsSL https://ollama.com/install.sh | sh

COPY scripts/entrypoint.sh /usr/local/bin/custom-entrypoint.sh
RUN chmod +x /usr/local/bin/custom-entrypoint.sh

ENV OLLAMA_HOST=127.0.0.1:11434 \
    CHROME_BIN=/usr/bin/chromium

USER node

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/custom-entrypoint.sh"]
CMD ["node", "openclaw.mjs", "gateway", "--allow-unconfigured"]
