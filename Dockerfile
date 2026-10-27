# One image, two uses:
#   default CMD  the GLaDOS TTS API on :5050 (POST /v1/audio/speech), e.g. for Home Assistant
#   override     the full assistant (docker-compose.assistant.yml), with the LLM in a separate Ollama container
FROM python:3.12-slim-trixie

RUN apt-get update && apt-get install -y --no-install-recommends \
  libportaudio2 \
  libgl1 \
  libglib2.0-0 \
  git \
  && rm -rf /var/lib/apt/lists/*

# Pinned uv from its official image, instead of whatever `pip install uv` resolves at build time
COPY --from=ghcr.io/astral-sh/uv:0.13.6 /uv /uvx /bin/

# Create a non-root user for security
RUN useradd -m -u 1000 glados

WORKDIR /app

# Set ownership of /app so glados can create .venv
RUN chown glados:glados /app

COPY --chown=glados:glados pyproject.toml README.md ./
COPY --chown=glados:glados models/ ./models/
COPY --chown=glados:glados src/ ./src/
# The shipped profiles, so the image can also run the assistant
COPY --chown=glados:glados configs/ ./configs/

USER glados

# `glados download` checks each model file's SHA-256. ~/.glados holds the assistant's memory (a volume in compose).
RUN uv sync --extra api --extra cpu --no-dev \
  && uv run --no-sync glados download \
  && mkdir -p /home/glados/.glados

EXPOSE 5050 5051 8050
CMD ["uv", "run", "--no-sync", "litestar", "--app", "glados.api.app:create_app", "run", "--host", "0.0.0.0", "--port", "5050"]
