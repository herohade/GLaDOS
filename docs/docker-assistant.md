# The assistant in Docker

`docker-compose.assistant.yml` runs the extended profile: Parakeet speech recognition and the GLaDOS voice on the
CPU, and the conversation model in an Ollama container on an AMD GPU. `docker-compose.yml` is unchanged in
purpose: the TTS API on its own.

```bash
docker compose -f docker-compose.assistant.yml --profile setup run --rm pull-model   # once per model
docker compose -f docker-compose.assistant.yml up -d
```

The `glados` service uses the image published by `.github/workflows/docker-build.yml` (the same image as the TTS
API, which also contains `configs/`). If it can't be pulled, Compose builds it from this repo; add `--build` to
always build locally. `GLADOS_IMAGE=ghcr.io/herohade/glados:sha-<commit>` pins a specific build.

Pick another model with `OLLAMA_MODEL=<tag>` on the `pull-model` run, and set the same tag as `llm_model` in
`configs/docker_assistant.yaml` (mounted into the container: restart `glados` after editing it).
`OLLAMA_CONTEXT_LENGTH` sets the context size (default 16384).

## Microphone and speaker

The container has no sound devices. A browser tab streams the microphone over WebSocket on `localhost:5051`,
using the self-contained test pages in `tests/`. Browsers allow the microphone on `http://localhost`, so serve
them from loopback:

```bash
python3 -m http.server 8080 --bind 127.0.0.1 --directory tests
```

Open <http://localhost:8080/audio-websocket-both.html>, allow the microphone, and connect both the mic and the
speaker. The console is at <http://localhost:8050>.

## Security notes

- The console and the audio WebSocket have no authentication. Both are published on 127.0.0.1 only. Before
  opening them to the LAN, put an authenticating HTTPS reverse proxy in front.
- Ollama is not published at all; only the containers on the internal `backend` network reach it.
- Memory (`~/.glados`) lives in the `memory` volume. Models are in the image (ONNX) and the shared
  `ollama-models` volume (LLM).
