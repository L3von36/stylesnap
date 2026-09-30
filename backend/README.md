# StyleSnap Bridge

FastAPI server that connects the **StyleSnap** Flutter app to
**[JoyAI-Video-Edit](https://github.com/jd-opensource/JoyAI-Video-Edit)**.

```
Flutter app (StyleSnap)  ⇄  StyleSnap Bridge (this server, port 8600)  ⇄  JoyAI-Video-Edit (GPU, port 8080)
```

Two modes, chosen automatically:

| Mode | When | Photo try-on | Live mirror |
|---|---|---|---|
| **joyai** | `JOYAI_UPSTREAM_URL` set & reachable | Streams the still photo as a short MJPEG clip through the JoyAI pipeline with the garment as RV2V reference image, returns a stable late frame | Transparent WebSocket proxy to the JoyAI `/ws` endpoint |
| **mock** | no upstream / upstream down | Local PIL composite stamped `DEMO PREVIEW` | Echo frames with brightness pulse |

## 1. Install

```bash
cd backend
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
```

## 2. Mock-only mode (no GPU needed)

```bash
uvicorn main:app --host 0.0.0.0 --port 8600
```

Open the app → **Profile → Bridge server URL** → `http://<this-machine-ip>:8600` → **Test**.
The status dot turns green with `engine: mock`. Everything in the app works; results
are labelled demo previews.

## 3. Full GPU mode

First run JoyAI-Video-Edit on the GPU machine (see its
[DEPLOYMENT.md](https://github.com/jd-opensource/JoyAI-Video-Edit/blob/main/DEPLOYMENT.md) —
needs a 32 GB+ GPU, e.g. RTX 5090, and ~51 GB of weights):

```bash
cd JoyAI-Video-Edit/deploy
bash run_server.sh     # binds 0.0.0.0:8080
```

Then start this bridge next to it:

```bash
JOYAI_UPSTREAM_URL=http://localhost:8080 \
uvicorn main:app --host 0.0.0.0 --port 8600
```

`GET /health` now reports `"backend": "joyai", "gpu": true`, and the app's
photo + live try-on execute real RV2V editing with the instruction
*"Put the {coat/dress/…} from Image 1 on the person in the video"*.

## API

| Route | Description |
|---|---|
| `GET /health` | `{"status","version","backend":"joyai\|mock","gpu":bool}` |
| `POST /api/tryon/photo` | multipart: `person` (image), `garment` (image), `instruction` (str), `garment_name` (str) → `image/jpeg` |
| `WS /ws/live` | Proxies the JoyAI streaming protocol: `{"type":"start",...,"ref_image":"data:image/jpeg;base64,…"}` → `frame_meta` + binary JPEG frames |

### Protocol notes

- The bridge speaks the exact same WebSocket message shapes as the official
  JoyAI-Video-Edit web client (`deploy/static/index.html`): a `start` JSON with
  the prompt + `ref_image` data-URL, then `frame_meta` JSON followed by binary
  JPEG frames, with `ping`/`stop` control messages.
- Photo mode works by streaming the same still frame N times
  (`JOYAI_PHOTO_FRAMES`, default 48 ≈ 4 s at 12 fps) and returning a late,
  temporally stable output frame — early frames show the source image before
  the edit converges.
- Tunables via env: `JOYAI_UPSTREAM_URL`, `JOYAI_PHOTO_FRAMES`,
  `JOYAI_FRAME_TIMEOUT`.

## Production notes

- Put the bridge behind HTTPS (e.g. Caddy/nginx + Let's Encrypt); the app
  accepts `https://` and `wss://` URLs.
- The bridge is stateless — scale horizontally behind a load balancer; the GPU
  host(s) are the bottleneck, not this service.
- Add auth (e.g. API-key middleware) before exposing beyond a LAN.

## Android emulator tip

From the Android emulator, `localhost` of your dev machine is `10.0.2.2`, so the
default URL `http://10.0.2.2:8600` already points at a locally running bridge.
On a real phone, use the machine's LAN IP.
