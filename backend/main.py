"""
StyleSnap Bridge — connects the Flutter app to JoyAI-Video-Edit.

Endpoints:
  GET  /health            → bridge + GPU upstream status
  POST /api/tryon/photo   → person photo + garment image → try-on JPEG
  WS   /ws/live           → transparent proxy to JoyAI-Video-Edit /ws
                            (same protocol: start / frame_meta / binary / ping / stop)

Run:
  pip install -r requirements.txt
  JOYAI_UPSTREAM_URL=http://localhost:8080 uvicorn main:app --host 0.0.0.0 --port 8600

Without JOYAI_UPSTREAM_URL (or when upstream is down) the bridge runs in MOCK
mode so the whole app journey works end-to-end on any laptop.
"""

import asyncio
import base64
import io
import json
import os
import time
import uuid
from typing import Optional

from fastapi import FastAPI, UploadFile, File, Form, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, Response
import httpx
from PIL import Image, ImageDraw, ImageEnhance, ImageFont

from joyai_proxy import JoyAIStreamClient
from mock_engine import compose_photo_mock

APP_VERSION = "1.0.0"
UPSTREAM = os.environ.get("JOYAI_UPSTREAM_URL", "").rstrip("/")
PHOTO_FRAMES = int(os.environ.get("JOYAI_PHOTO_FRAMES", "48"))
FRAME_TIMEOUT = float(os.environ.get("JOYAI_FRAME_TIMEOUT", "90"))

app = FastAPI(title="StyleSnap Bridge", version=APP_VERSION)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


def _jpg_bytes(im: Image.Image, quality: int = 90) -> bytes:
    buf = io.BytesIO()
    im.convert("RGB").save(buf, format="JPEG", quality=quality)
    return buf.getvalue()


def _bucket_resize(im: Image.Image, long_edge: int = 720) -> Image.Image:
    w, h = im.size
    scale = long_edge / max(w, h)
    if scale < 1.0:
        im = im.resize((int(w * scale), int(h * scale)), Image.LANCZOS)
    return im


@app.get("/health")
async def health():
    upstream_ok = False
    if UPSTREAM:
        try:
            async with httpx.AsyncClient(timeout=4) as client:
                r = await client.get(f"{UPSTREAM}/health")
            upstream_ok = r.status_code == 200
        except Exception:
            upstream_ok = False
    return {
        "status": "ok",
        "version": APP_VERSION,
        "backend": "joyai" if upstream_ok else "mock",
        "gpu": upstream_ok,
        "upstream": UPSTREAM or None,
    }


@app.post("/api/tryon/photo")
async def photo_tryon(
    person: UploadFile = File(...),
    garment: UploadFile = File(...),
    instruction: str = Form(...),
    garment_name: str = Form("garment"),
):
    person_bytes = await person.read()
    garment_bytes = await garment.read()

    # 1) Real path — stream the still photo through JoyAI-Video-Edit as a
    #    short MJPEG clip with the garment as RV2V reference image.
    if UPSTREAM:
        try:
            result = await _joyai_photo(person_bytes, garment_bytes, instruction)
            if result:
                return Response(content=result, media_type="image/jpeg")
        except Exception as e:  # noqa: BLE001
            return JSONResponse(status_code=502, content={"error": f"upstream: {e}"})

    # 2) Mock path — honest local composite so the app journey works.
    result = compose_photo_mock(person_bytes, garment_bytes, garment_name)
    return Response(content=result, media_type="image/jpeg")


async def _joyai_photo(
    person_bytes: bytes, garment_bytes: bytes, instruction: str
) -> Optional[bytes]:
    """Send a still image as a short MJPEG stream; collect edited frames."""
    person = _bucket_resize(Image.open(io.BytesIO(person_bytes)).convert("RGB"))
    w, h = person.size
    frame = _jpg_bytes(person, quality=88)

    client = JoyAIStreamClient(upstream=UPSTREAM)
    outputs: list[bytes] = []
    try:
        await client.connect()
        await client.start(
            prompt=instruction,
            width=w,
            height=h,
            input_codec="mjpeg",
            output_codec="mjpeg",
            fps=12,
            ref_image_bytes=garment_bytes,
        )
        receiver = asyncio.create_task(client.collect_outputs(outputs, max_frames=999))

        # Stream the same still N times so the causal pipeline stabilises.
        for i in range(PHOTO_FRAMES):
            await client.send_frame(frame, seq=i)
            await asyncio.sleep(1 / 12)

        # Give the model a beat to flush trailing frames.
        deadline = time.time() + FRAME_TIMEOUT
        stable_since = None
        while time.time() < deadline:
            await asyncio.sleep(0.25)
            n = len(outputs)
            if n >= PHOTO_FRAMES:
                if stable_since is None:
                    stable_since = time.time()
                elif time.time() - stable_since > 2.0:
                    break
        client.stop()
        await receiver

        if not outputs:
            return None
        # Pick a late, stable frame (early ones show the source photo).
        idx = max(0, int(len(outputs) * 0.85))
        return outputs[idx]
    finally:
        await client.close()


# ---------------- Live WebSocket proxy ----------------

@app.websocket("/ws/live")
async def ws_live(ws: WebSocket):
    await ws.accept()
    session = str(uuid.uuid4())

    if UPSTREAM:
        # True bidirectional proxy to the GPU server.
        import websockets

        upstream_ws = f"{UPSTREAM.replace('http', 'ws', 1)}/ws"
        try:
            async with websockets.connect(
                upstream_ws, max_size=None, ping_interval=None
            ) as up:
                async def c2u():
                    try:
                        while True:
                            msg = await ws.receive()
                            if msg["type"] == "websocket.disconnect":
                                break
                            if "bytes" in msg and msg["bytes"] is not None:
                                await up.send(msg["bytes"])
                            elif "text" in msg and msg["text"] is not None:
                                await up.send(msg["text"])
                    except WebSocketDisconnect:
                        pass

                async def u2c():
                    try:
                        async for msg in up:
                            if isinstance(msg, (bytes, bytearray)):
                                await ws.send_bytes(msg)
                            else:
                                await ws.send_text(msg)
                    except Exception:
                        pass

                await asyncio.gather(c2u(), u2c())
        except Exception:
            await _mock_live(ws)
    else:
        await _mock_live(ws)


async def _mock_live(ws: WebSocket):
    """Echo frames back with a gentle brightness pulse so the live mirror
    has visible motion even without a GPU."""
    session = str(uuid.uuid4())
    print(f"[mock-live] session {session} (echo mode)")
    tick = 0
    try:
        while True:
            msg = await ws.receive()
            if msg["type"] == "websocket.disconnect":
                break
            if "text" in msg and msg["text"]:
                try:
                    data = json.loads(msg["text"])
                except Exception:
                    continue
                mtype = data.get("type")
                if mtype == "ping":
                    await ws.send_text(json.dumps({"type": "pong", "t": data.get("t")}))
                elif mtype == "start":
                    await ws.send_text(
                        json.dumps(
                            {
                                "type": "ack",
                                "session_id": session,
                                "mode": "mock",
                            }
                        )
                    )
                elif mtype == "frame_meta":
                    continue  # metadata — nothing to do in mock
            elif "bytes" in msg and msg["bytes"]:
                tick += 1
                try:
                    im = Image.open(io.BytesIO(msg["bytes"])).convert("RGB")
                    factor = 1.0 + 0.10 * (0.5 + 0.5 * ((tick % 12) / 12))
                    im = ImageEnhance.Brightness(im).enhance(factor)
                    out = _jpg_bytes(im, quality=80)
                    await ws.send_bytes(out)
                except Exception:
                    continue
    except WebSocketDisconnect:
        pass
    except Exception:
        pass
